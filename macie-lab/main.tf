terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ──────────────────────────────────────────
# 1. S3 BUCKET
# ──────────────────────────────────────────
resource "aws_s3_bucket" "macie_lab" {
  bucket        = "${var.project_name}-bucket-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_versioning" "macie_lab" {
  bucket = aws_s3_bucket.macie_lab.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "macie_lab" {
  bucket = aws_s3_bucket.macie_lab.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "macie_lab" {
  bucket                  = aws_s3_bucket.macie_lab.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ──────────────────────────────────────────
# 2. UPLOAD SAMPLE FILES
# ──────────────────────────────────────────
resource "aws_s3_object" "sample_csv" {
  bucket       = aws_s3_bucket.macie_lab.id
  key          = "sample-data/sensitive_data.csv"
  content      = <<-CSV
    name,email,ssn,credit_card,phone
    John Doe,john.doe@example.com,123-45-6789,4111111111111111,555-123-4567
    Jane Smith,jane.smith@example.com,987-65-4321,5500005555555559,555-987-6543
  CSV
  content_type = "text/csv"
}

resource "aws_s3_object" "sample_json" {
  bucket = aws_s3_bucket.macie_lab.id
  key    = "sample-data/personal_info.json"
  content = jsonencode({
    employees = [
      { name = "Alice Brown", ssn = "321-54-9876", passport = "A12345678" }
    ]
  })
  content_type = "application/json"
}

# ──────────────────────────────────────────
# 3. ENABLE AMAZON MACIE
# ──────────────────────────────────────────
resource "aws_macie2_account" "main" {
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  status                       = "ENABLED"
}

# ──────────────────────────────────────────
# 4. MACIE CLASSIFICATION JOB
# ──────────────────────────────────────────
resource "aws_macie2_classification_job" "lab_job" {
  name       = "${var.project_name}-classification-job"
  job_type   = "ONE_TIME"
  depends_on = [aws_macie2_account.main]

  s3_job_definition {
    bucket_definitions {
      account_id = data.aws_caller_identity.current.account_id
      buckets    = [aws_s3_bucket.macie_lab.id]
    }
  }
  tags = local.common_tags

}

# ──────────────────────────────────────────
# 5. SNS TOPIC
# ──────────────────────────────────────────
resource "aws_sns_topic" "macie_alerts" {
  name = "${var.project_name}-macie-alerts"
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.macie_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_sns_topic_policy" "macie_alerts" {
  arn    = aws_sns_topic.macie_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.macie_alerts.arn]
  }
}

# ──────────────────────────────────────────
# 6. EVENTBRIDGE RULE
# ──────────────────────────────────────────
resource "aws_cloudwatch_event_rule" "macie_findings" {
  name        = "${var.project_name}-macie-findings-rule"
  description = "Capture Macie findings and send to SNS"

  event_pattern = jsonencode({
    source      = ["aws.macie"]
    detail-type = ["Macie Finding"]
  })
  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.macie_findings.name
  target_id = "MacieFindingsToSNS"
  arn       = aws_sns_topic.macie_alerts.arn

  input_transformer {
    input_paths = {
      findingId   = "$.detail.id"
      severity    = "$.detail.severity.description"
      type        = "$.detail.type"
      bucket      = "$.detail.resourcesAffected.s3Bucket.name"
      description = "$.detail.description"
      time        = "$.time"
    }
    input_template = <<-TEMPLATE
      "Amazon Macie Finding Alert"
      "Finding ID : <findingId>"
      "Type       : <type>"
      "Severity   : <severity>"
      "Bucket     : <bucket>"
      "Time       : <time>"
      "Description: <description>"
    TEMPLATE
  }
}

# ──────────────────────────────────────────
# 7. DATA SOURCES
# ──────────────────────────────────────────
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
