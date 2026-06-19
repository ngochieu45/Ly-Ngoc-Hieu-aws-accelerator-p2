output "s3_bucket_name" {
  value = aws_s3_bucket.macie_lab.id
}

output "macie_job_id" {
  value = aws_macie2_classification_job.lab_job.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.macie_alerts.arn
}
