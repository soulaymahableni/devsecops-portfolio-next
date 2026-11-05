locals {
  prefix = "${var.project}-${var.environment}"
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# Clé gérée par le client pour chiffrer le bucket (AWS-0132)
resource "aws_kms_key" "data" {
  description         = "Chiffrement des données ${local.prefix}"
  enable_key_rotation = true
  tags                = local.tags
}

resource "aws_s3_bucket" "assets" {
  bucket = "${local.prefix}-assets"
  tags   = local.tags

  # Q135 : permet de détruire la plateforme même si le bucket contient des messages archivés
  force_destroy = true
}

# Aucun accès public possible (AWS-0086, 0087, 0091, 0093)
resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data.arn
    }
  }
}

resource "aws_s3_bucket_versioning" "assets" {
  count  = var.versioning ? 1 : 0
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

# File chiffrée (AWS-0096)
resource "aws_sqs_queue" "notifications" {
  name                      = "${local.prefix}-notifications"
  message_retention_seconds = var.queue_retention_seconds
  sqs_managed_sse_enabled   = true
  tags                      = local.tags
}

resource "aws_dynamodb_table" "contacts" {
  name         = "${local.prefix}-contacts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  tags         = local.tags

  attribute {
    name = "id"
    type = "S"
  }

  # Chiffrement avec notre clé KMS (règle Semgrep aws-dynamodb-table-unencrypted)
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.data.arn
  }
}
