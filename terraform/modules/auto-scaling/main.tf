variable "prj_name" {}
variable "ami_id" {}
variable "instance_type" {}
variable "instance_profile" {}
variable "vpc_id" {}
variable "public_sg_id" {}
variable "private_sg_id" {}
variable "public_subnet_ids" {}
variable "private_subnet_ids" {}
variable "user_data" {}

#data "template_file" "web_user_data" {
#  template = <<-EOF
#    #!/bin/bash
#    echo -n "checking git settings... "
#    if [ ! -f /home/ec2-user/.gitconfig ]; then
#      sudo -u ec2-user git config --global credential.helper '!aws codecommit credential-helper $@'
#      sudo -u ec2-user git config --global credential.UseHttpPath true
#      echo "not. initialized."
#    fi
#    echo "already set."
#    echo -n "checking monitoring repository... "
#    if [ -d /home/ec2-user/monitoring ]; then
#      echo "found."
#      echo -n "updating repository..."
#      cd /home/ec2-user/monitoring
#      sudo -u ec2-user git pull
#      echo "updated"
#    else
#      echo "not found."
#      echo -n "clone repository..."
#      sudo -u ec2-user git clone https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/monitoring /home/ec2-user/monitoring
#      cd /home/ec2-user/monitoring
#      echo "cloned"
#    fi
#    echo -n "updating collectd settiings..."
#    sudo cp -f common/collectd.conf /etc/collectd.conf
#    sudo cp -f common/collectd.d/* /etc/collectd.d/.
#    sudo cp -f common/plugins/* /usr/lib64/collectd/.
#    sudo cp -f web/collectd.d/* /etc/collectd.d/.
#    sudo cp -f web/plugins/* /usr/lib64/collectd/.
#    echo "done"
#    echo -n "restarting collectd..."
#    sudo systemctl restart collectd
#    echo  "done."
#    echo -n "updating & restarting cloudwatch agent..."
#    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-config-common
#    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a append-config -m ec2 -s -c ssm:AmazonCloudWatch-config-web
#    echo  "done."
#  EOF
#}
resource "aws_launch_template" "web" {
  name                   = "${var.prj_name}-web-launch-template"
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
  name_prefix               = "${var.prj_name}-web-asg-"
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
    value = "${var.prj_name}-web-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb" "web-nlb" {
  name               = "${var.prj_name}-web-alb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids 

  tags = {
    Name = "${var.prj_name}-web-alb"
  }
}

resource "aws_lb" "web-nlb-internal" {
  name               = "${var.prj_name}-web-alb-internal"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnet_ids 

  tags = {
    Name = "${var.prj_name}-web-alb-internal"
  }
}
resource "aws_lb_target_group" "web-nlb" {
  # https://thaim.hatenablog.jp/entry/2021/01/11/004738
  name     = "${var.prj_name}-w-tgtgrp-${substr(uuid(), 0, 6)}"
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
  name     = "${var.prj_name}-w-in-tgtgrp-${substr(uuid(), 0, 6)}"
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
