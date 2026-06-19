variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for resource names"
  type        = string
  default     = "macie-lab"
}

variable "alert_email" {
  description = "Email to receive Macie alerts"
  type        = string
}
