resource "aws_s3_bucket" "assets" {
  bucket = "${var.project}-assets"
}

resource "aws_sqs_queue" "notifications" {
  name = "${var.project}-notifications"
}

resource "aws_dynamodb_table" "contacts" {
  name         = "${var.project}-contacts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
