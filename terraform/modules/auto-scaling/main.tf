variable "prj_name" {}
variable "asg_name" {}
variable "ami_id" {}
variable "instance_type" {}
variable "instance_profile" {}
variable "vpc_id" {}
variable "public_sg_id" {}
variable "private_sg_id" {}
variable "public_subnet_ids" {}
variable "private_subnet_ids" {}
variable "user_data" {}

resource "aws_launch_template" "web" {
  name                   = "${var.prj_name}-${var.asg_name}-launch-template"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.private_sg_id]
  update_default_version = true

  iam_instance_profile {
    name = var.instance_profile
  }

  #monitoring {
  #  enabled = true
  #}

  #user_data = "${base64encode(data.template_file.web_user_data.rendered)}"
  user_data = "${base64encode(var.user_data)}"
}

resource "aws_autoscaling_group" "web" {
  name_prefix               = "${var.prj_name}-${var.asg_name}-asg-"
  max_size                  = 2
  min_size                  = 2
  desired_capacity          = 2
  health_check_grace_period = 60
  health_check_type         = "ELB"
  vpc_zone_identifier       = var.private_subnet_ids

  enabled_metrics = [
    "GroupMaxSize",
    "GroupMinSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ] 
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment#with-an-autoscaling-group-resource
  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

  tag {
    key   = "Name"
    value = "${var.prj_name}-${var.asg_name}-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb" "web-nlb" {
  name               = "${var.prj_name}-${var.asg_name}-alb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids 

  tags = {
    Name = "${var.prj_name}-${var.asg_name}-alb"
  }
}

resource "aws_lb" "web-nlb-internal" {
  name               = "${var.prj_name}-${var.asg_name}-alb-internal"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnet_ids 

  tags = {
    Name = "${var.prj_name}-${var.asg_name}-alb-internal"
  }
}
resource "aws_lb_target_group" "web-nlb" {
  # https://thaim.hatenablog.jp/entry/2021/01/11/004738
  name     = "${var.prj_name}-${var.asg_name}-tgtgrp-${substr(uuid(), 0, 6)}"
  port     = 8080
  protocol = "TCP"
  vpc_id   = var.vpc_id
  
  health_check {
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  } 

  lifecycle {
    create_before_destroy = true
    ignore_changes = [name]
  }
}

resource "aws_lb_target_group" "web-nlb-internal" {
  # https://thaim.hatenablog.jp/entry/2021/01/11/004738
  name     = "${var.prj_name}-${var.asg_name}-in-tgtgrp-${substr(uuid(), 0, 6)}"
  port     = 8080
  protocol = "TCP"
  vpc_id   = var.vpc_id
  
  health_check {
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  } 

  lifecycle {
    create_before_destroy = true
    ignore_changes = [name]
  }

  tags = {
    Name = "foobar"
  }
}
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web-nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-nlb.arn
  }
}

resource "aws_lb_listener" "web2" {
  load_balancer_arn = aws_lb.web-nlb.arn
  port              = "30080"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-nlb.arn
  }
}

resource "aws_lb_listener" "web-internal" {
  load_balancer_arn = aws_lb.web-nlb-internal.arn
  port              = "30080"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-nlb-internal.arn
  }
}
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.web.id
  alb_target_group_arn   = aws_lb_target_group.web-nlb.arn
}

resource "aws_autoscaling_attachment" "asg_attachment-internal" {
  autoscaling_group_name = aws_autoscaling_group.web.id
  alb_target_group_arn   = aws_lb_target_group.web-nlb-internal.arn
}

output target_group_web_nlb_suffix {
  value = aws_lb_target_group.web-nlb.arn_suffix
}
output nlb_web_nlb_suffix {
  value = aws_lb.web-nlb.arn_suffix
}

output auto_scaling_group_web {
  value = aws_autoscaling_group.web.name
}
