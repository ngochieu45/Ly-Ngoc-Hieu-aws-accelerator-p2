variable "private_subnet_1" {
  type = string
}

variable "private_subnet_2" {
  type = string
}

variable "db_sg_id" {
  type = string
}

variable "db_name" {
  type    = string
  default = "studentdb"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}
