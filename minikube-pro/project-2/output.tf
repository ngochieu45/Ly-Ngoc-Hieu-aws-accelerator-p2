output "ec2_public_ip" {
  value = module.ec2.public_ip
}

output "ec2_public_dns" {
  value = module.ec2.public_dns
}

output "web_url" {
  value = "http://${module.ec2.public_ip}:3000"
}

output "rds_endpoint" {
  value = module.rds.db_endpoint
}
