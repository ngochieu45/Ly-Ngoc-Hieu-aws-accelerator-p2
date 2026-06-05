resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_outbound" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}


resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Security group for EC2 Minikube"
  vpc_id      = var.vpc_id

  tags = {
    Name = "ec2-sg"
  }
}


resource "aws_vpc_security_group_ingress_rule" "ec2_ssh" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = var.my_ip
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ec2_nodeport" {
  security_group_id = aws_security_group.ec2.id

  referenced_security_group_id = aws_security_group.alb.id

  from_port   = 30080
  to_port     = 30080
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ec2_outbound" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}
