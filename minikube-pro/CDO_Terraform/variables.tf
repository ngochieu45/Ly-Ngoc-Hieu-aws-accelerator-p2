variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "db_name" {
  default = "studentdb"
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  sensitive = true
}


