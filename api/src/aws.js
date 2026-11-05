// Q114 : intégration avec un service AWS émulé en local (Floci).
// Activée uniquement si AWS_ENDPOINT_URL est défini : sans cette variable,
// l'API fonctionne comme avant (tests, CI, production sans Floci).
const {
  S3Client,
  HeadBucketCommand,
  CreateBucketCommand,
  PutObjectCommand,
} = require("@aws-sdk/client-s3");
const { SQSClient, CreateQueueCommand, SendMessageCommand } = require("@aws-sdk/client-sqs");

const QUEUE_NAME = process.env.CONTACT_QUEUE_NAME || "contact-notifications";
const BUCKET_NAME = process.env.CONTACT_BUCKET_NAME || "contact-archives";

const isEnabled = () => Boolean(process.env.AWS_ENDPOINT_URL);

let ready; // promesse mémorisée : les ressources sont créées une seule fois

function init() {
  if (!ready) {
    const config = {
      endpoint: process.env.AWS_ENDPOINT_URL,
      region: process.env.AWS_REGION || "us-east-1",
    };
    const s3 = new S3Client({ ...config, forcePathStyle: true });
    const sqs = new SQSClient(config);
    ready = (async () => {
      try {
        await s3.send(new HeadBucketCommand({ Bucket: BUCKET_NAME }));
      } catch {
        await s3.send(new CreateBucketCommand({ Bucket: BUCKET_NAME }));
      }
      const { QueueUrl } = await sqs.send(new CreateQueueCommand({ QueueName: QUEUE_NAME }));
      return { s3, sqs, queueUrl: QueueUrl };
    })().catch((err) => {
      ready = undefined; // on réessaiera à la prochaine requête
      throw err;
    });
  }
  return ready;
}

// Archive le message dans S3 puis envoie une notification dans SQS.
async function publishContact(contact) {
  if (!isEnabled()) return { enabled: false };
  const { s3, sqs, queueUrl } = await init();
  const key = `messages/${contact.id}.json`;
  await s3.send(
    new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
      Body: JSON.stringify(contact),
      ContentType: "application/json",
    }),
  );
  await sqs.send(
    new SendMessageCommand({
      QueueUrl: queueUrl,
      MessageBody: JSON.stringify({
        event: "contact.received",
        id: contact.id,
        name: contact.name,
        email: contact.email,
        s3: `s3://${BUCKET_NAME}/${key}`,
      }),
    }),
  );
  return { enabled: true, bucket: BUCKET_NAME, key, queue: QUEUE_NAME };
}

module.exports = { publishContact, isEnabled };
