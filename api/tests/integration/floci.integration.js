// Q116 : test d'intégration contre un vrai service Floci (conteneur de service en CI).
// Lancé avec : npm run test:integration (nécessite AWS_ENDPOINT_URL).
const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
const { SQSClient, GetQueueUrlCommand, ReceiveMessageCommand } = require("@aws-sdk/client-sqs");
const { publishContact } = require("../../src/aws");

const suite = process.env.AWS_ENDPOINT_URL ? describe : describe.skip;

suite("Intégration Floci (S3 + SQS)", () => {
  const config = {
    endpoint: process.env.AWS_ENDPOINT_URL,
    region: process.env.AWS_REGION || "us-east-1",
  };

  test("le message est archivé dans S3 et notifié dans SQS", async () => {
    const id = Date.now();
    const res = await publishContact({
      id,
      name: "CI",
      email: "ci@example.com",
      message: "test d'intégration",
    });
    expect(res.enabled).toBe(true);

    const s3 = new S3Client({ ...config, forcePathStyle: true });
    const obj = await s3.send(new GetObjectCommand({ Bucket: res.bucket, Key: res.key }));
    const archived = JSON.parse(await obj.Body.transformToString());
    expect(archived).toMatchObject({ id, name: "CI", email: "ci@example.com" });

    const sqs = new SQSClient(config);
    const { QueueUrl } = await sqs.send(new GetQueueUrlCommand({ QueueName: res.queue }));
    const received = await sqs.send(
      new ReceiveMessageCommand({ QueueUrl, MaxNumberOfMessages: 10, WaitTimeSeconds: 2 }),
    );
    const notif = (received.Messages || []).map((m) => JSON.parse(m.Body)).find((m) => m.id === id);
    expect(notif).toMatchObject({ event: "contact.received", name: "CI" });
  }, 30000);
});
