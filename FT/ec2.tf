#security group for ALB
resource "aws_security_group" "alb-sg" {
  name        = "mars-alb-sg"
  description = "security group for application load balancer"
  vpc_id      = aws_vpc.mars-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr-rt]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr-rt]
  }

  tags = {
    Name = "mars"
  }
}

#Security group for EC2
resource "aws_security_group" "ec2-sg" {
  name        = "mars-ec2-sg"
  description = "security group for EC2 instances"

  vpc_id = aws_vpc.mars-vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.alb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr-rt]
  }

  tags = {
    Name = "mars"
  }
}

#2 ALB
resource "aws_alb" "alb" {
  name               = "mars-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = tolist(aws_subnet.public-sub[*].id)
  depends_on         = [aws_internet_gateway.Igw-vpc]
}

#3 Target group for ALB
resource "aws_lb_target_group" "alb-tg" {
  name     = "alb-tg"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = aws_vpc.mars-vpc.id
  tags = {
    Name = "mars"
  }
}

#4 listener
resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg.arn
  }
  tags = {
    Name = "mars"
  }
}

#5 Launch template for EC2
resource "aws_launch_template" "ec2-temp" {
  name          = "mars-server"
  image_id      = var.ami
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2-sg.id]
  }

  user_data = filebase64("userdata.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "mars"
    }
  }
}

#6 Auto scaling
resource "aws_autoscaling_group" "asg" {
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  name                = "mars-asg"
  target_group_arns   = [aws_lb_target_group.alb-tg.arn]
  vpc_zone_identifier = tolist(aws_subnet.private-sub[*].id)
  launch_template {
    id      = aws_launch_template.ec2-temp.id
    version = "$Latest"
  }

  health_check_type = "EC2"
}

output "alb_dns_name" {
  value = aws_alb.alb.dns_name
}