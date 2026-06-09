data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
}

resource "tls_private_key" "student_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.student_key.private_key_pem
  filename        = "${path.module}/student-key.pem"
  file_permission = "0400"
}

resource "aws_key_pair" "student" {
  key_name   = "student-key"
  public_key = tls_private_key.student_key.public_key_openssh
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.web_sg_id]

  key_name = aws_key_pair.student.key_name

  user_data = templatefile("${path.root}/user_data.sh", {
    db_host     = var.db_host
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
  })

  depends_on = [
    aws_key_pair.student
  ]
}
