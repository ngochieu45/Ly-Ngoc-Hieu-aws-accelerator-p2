terraform {
  required_version = ">= 1.5"
}

provider "aws" {
  region = "ap-southeast-1"
}


data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}


resource "aws_iam_role" "cw_role" {
  name = "cloudwatch-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cw_policy" {
  role       = aws_iam_role.cw_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "cw_profile" {
  name = "cloudwatch-agent-profile"
  role = aws_iam_role.cw_role.name
}


resource "aws_iam_role" "cloudtrail_role" {
  name = "cloudtrail-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_policy" {

  name = "cloudtrail-policy"

  role = aws_iam_role.cloudtrail_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]

      Resource = "*"
    }]
  })
}


locals {

  user_data = <<-EOF
#!/bin/bash

dnf update -y
dnf install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CONFIG'
{
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ]
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "resources": [
          "/"
        ]
      }
    }
  }
}
CONFIG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
-s

systemctl enable amazon-cloudwatch-agent
EOF

}


resource "aws_instance" "monitoring_demo" {

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  iam_instance_profile = aws_iam_instance_profile.cw_profile.name

  user_data = local.user_data

  tags = {
    Name = "monitoring-demo"
  }
}



resource "aws_sns_topic" "alerts" {
  name = "monitoring-alerts"
}

resource "aws_sns_topic_subscription" "email" {

  topic_arn = aws_sns_topic.alerts.arn

  protocol = "email"

  endpoint = var.alert_email
}


resource "aws_cloudwatch_metric_alarm" "high_cpu" {

  alarm_name = "ec2-high-cpu"

  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 1

  metric_name = "CPUUtilization"

  namespace = "AWS/EC2"

  period = 300

  statistic = "Average"

  threshold = 80

  dimensions = {
    InstanceId = aws_instance.monitoring_demo.id
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]
}



resource "aws_cloudwatch_metric_alarm" "high_memory" {

  alarm_name = "ec2-high-memory"

  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 1

  metric_name = "mem_used_percent"

  namespace = "CWAgent"

  period = 300

  statistic = "Average"

  threshold = 80

  dimensions = {
    InstanceId = aws_instance.monitoring_demo.id
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]
}


resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/root-login"
  retention_in_days = 30
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "cloudtrail-monitoring-demo-123456"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {

  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action = "s3:GetBucketAcl"

        Resource = aws_s3_bucket.cloudtrail.arn
      },

      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action = "s3:PutObject"

        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/*"

        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {

  depends_on = [
    aws_s3_bucket_policy.cloudtrail
  ]

  name                          = "security-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_role.arn
}


resource "aws_cloudwatch_log_metric_filter" "root_login" {

  name = "root-login-filter"

  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  pattern = "{ $.userIdentity.type = Root }"

  metric_transformation {
    name      = "RootAccountLoginCount"
    namespace = "Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_login_alarm" {

  alarm_name = "root-account-login"

  namespace = "Security"

  metric_name = "RootAccountLoginCount"

  statistic = "Sum"

  period = 300

  evaluation_periods = 1

  threshold = 1

  comparison_operator = "GreaterThanOrEqualToThreshold"

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]
}


output "instance_id" {
  value = aws_instance.monitoring_demo.id
}

output "public_ip" {
  value = aws_instance.monitoring_demo.public_ip
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}
