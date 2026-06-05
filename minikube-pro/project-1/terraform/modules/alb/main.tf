resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    var.alb_sg_id
  ]

  subnets = var.subnet_ids

  tags = {
    Name = "main-alb"
  }
}

resource "aws_lb_target_group" "main" {
  name        = "main-tg"
  port        = 30080
  protocol    = "HTTP"
  target_type = "instance"

  vpc_id = var.vpc_id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_lb_target_group.main.arn

  target_id = var.instance_id

  port = 30080
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.main.arn
  }
}
