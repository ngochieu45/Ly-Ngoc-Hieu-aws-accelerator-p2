variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "public_subnet_id" {
  type = string
}

variable "web_sg_id" {
  type = string
}

variable "db_host" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}
