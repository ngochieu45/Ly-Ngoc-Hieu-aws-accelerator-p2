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

locals {

  cw_config = jsonencode({
    metrics = {
      namespace = "CWAgent"

      metrics_collected = {

        mem = {
          measurement = [
            "mem_used_percent"
          ]
        }

        disk = {
          measurement = [
            "used_percent"
          ]

          resources = [
            "/"
          ]
        }
      }
    }
  })

  user_data = <<-EOF
#!/bin/bash

dnf update -y

dnf install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CONFIG'
${jsonencode({
  metrics = {
    namespace = "CWAgent"

    metrics_collected = {
      mem = {
        measurement = ["mem_used_percent"]
      }

      disk = {
        measurement = ["used_percent"]
        resources   = ["/"]
      }
    }
  }
})}
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

  threshold = 80

  period = 300

  statistic = "Average"

  namespace = "AWS/EC2"

  metric_name = "CPUUtilization"

  alarm_description = "CPU > 80% trong 5 phút"

  dimensions = {
    InstanceId = aws_instance.monitoring_demo.id
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {

  alarm_name = "ec2-high-memory"

  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 1

  threshold = 80

  period = 300

  statistic = "Average"

  namespace = "CWAgent"

  metric_name = "mem_used_percent"

  dimensions = {
    InstanceId = aws_instance.monitoring_demo.id
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]
}
