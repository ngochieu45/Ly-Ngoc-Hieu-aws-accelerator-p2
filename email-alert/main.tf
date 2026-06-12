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

  filter {
    name   = "state"
    values = ["available"]
  }
}

# EC2
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  tags = {
    Name = "demo-instance"
  }
}

# SNS Topic
resource "aws_sns_topic" "cpu_alert" {
  name = "cpu-alert-topic"
}

# Email Subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.cpu_alert.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "ec2-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  alarm_description = "CPU > 80% trong 5 phút"

  dimensions = {
    InstanceId = aws_instance.web.id
  }

  alarm_actions = [
    aws_sns_topic.cpu_alert.arn
  ]

  ok_actions = [
    aws_sns_topic.cpu_alert.arn
  ]
}
