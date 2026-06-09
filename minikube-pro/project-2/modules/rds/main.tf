resource "aws_db_subnet_group" "main" {
  name = "student-db-subnet-group"

  subnet_ids = [
    var.private_subnet_1,
    var.private_subnet_2
  ]

  tags = {
    Name = "student-db-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier             = "student-mysql-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]

  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "student-mysql-db"
  }
}
