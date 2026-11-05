const mockS3Send = jest.fn(async () => ({}));
const mockSqsSend = jest.fn(async (cmd) =>
  cmd.constructor.name === "CreateQueueCommand"
    ? { QueueUrl: "http://floci:4566/000000000000/contact-notifications" }
    : {},
);

jest.mock("@aws-sdk/client-s3", () => {
  const cmd = (name) =>
    class {
      constructor(input) {
        this.input = input;
      }
      get [Symbol.toStringTag]() {
        return name;
      }
    };
  return {
    S3Client: class {
      send = mockS3Send;
    },
    HeadBucketCommand: cmd("HeadBucketCommand"),
    CreateBucketCommand: cmd("CreateBucketCommand"),
    PutObjectCommand: cmd("PutObjectCommand"),
  };
});

jest.mock("@aws-sdk/client-sqs", () => ({
  SQSClient: class {
    send = mockSqsSend;
  },
  CreateQueueCommand: class CreateQueueCommand {
    constructor(input) {
      this.input = input;
    }
  },
  SendMessageCommand: class SendMessageCommand {
    constructor(input) {
      this.input = input;
    }
  },
}));

describe("Intégration Floci (S3 + SQS)", () => {
  afterEach(() => {
    delete process.env.AWS_ENDPOINT_URL;
    jest.resetModules();
    jest.clearAllMocks();
  });

  test("sans AWS_ENDPOINT_URL : rien n'est envoyé", async () => {
    const { publishContact } = require("../src/aws");
    const res = await publishContact({ id: 1, name: "A", email: "a@b.fr", message: "salut" });
    expect(res.enabled).toBe(false);
    expect(mockS3Send).not.toHaveBeenCalled();
    expect(mockSqsSend).not.toHaveBeenCalled();
  });

  test("avec AWS_ENDPOINT_URL : archive S3 puis notification SQS", async () => {
    process.env.AWS_ENDPOINT_URL = "http://floci:4566";
    const { publishContact } = require("../src/aws");
    const res = await publishContact({ id: 7, name: "A", email: "a@b.fr", message: "salut" });
    expect(res).toMatchObject({ enabled: true, key: "messages/7.json" });
    const sqsCalls = mockSqsSend.mock.calls.map(([c]) => c.constructor.name);
    expect(sqsCalls).toEqual(["CreateQueueCommand", "SendMessageCommand"]);
    const sent = mockSqsSend.mock.calls[1][0].input;
    expect(JSON.parse(sent.MessageBody)).toMatchObject({ event: "contact.received", id: 7 });
  });
});
