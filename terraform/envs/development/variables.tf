variable "stage" {
  default = "my"
}

variable "project" {
  default = "sample"
}

locals {
  prj_name = "${var.stage}-${var.project}"
}

variable "environ" {
  default = "dev"
}
variable "region" {
  default = "ap-northeast-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "web_ami_id" {
  default = "ami-XXXXXXXXXXXXXXXXX"
}

variable "web_instance_type" {
  default = "t2.micro"
}

variable "mail_alert_critical" {
  default = "alert-critical@example.com"
}
variable "mail_alert_warning" {
  default = "alert-warning@example.com"
}

variable "web_user_data" {
  default = <<-EOF
    #!/bin/bash
    echo -n 'checking git settings...'
    if [ ! -f /home/ec2-user/.gitconfig ]; then
      sudo -u ec2-user git config --global credential.helper '!aws codecommit credential-helper $@'
      sudo -u ec2-user git config --global credential.UseHttpPath true
      echo "not. initialized."
    fi
    echo 'already set.'
    echo -n 'checking monitoring repository...'
    if [ -d /home/ec2-user/monitoring ]; then
      echo 'found.'
      echo -n 'updating repository...'
      cd /home/ec2-user/monitoring
      sudo -u ec2-user git pull
      echo 'updated'
    else
      echo 'not found.'
      echo -n 'clone repository...'
      sudo -u ec2-user git clone https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/monitoring /home/ec2-user/monitoring
      cd /home/ec2-user/monitoring
      echo 'cloned'
    fi
    echo -n 'updating collectd settiings...'
    sudo cp -f common/collectd.conf /etc/collectd.conf
    sudo cp -f common/collectd.d/* /etc/collectd.d/.
    sudo cp -f common/plugins/* /usr/lib64/collectd/.
    sudo cp -f web/collectd.d/* /etc/collectd.d/.
    sudo cp -f web/plugins/* /usr/lib64/collectd/.
    echo 'done'
    echo -n 'restarting collectd...'
    sudo systemctl restart collectd
    echo 'done.'
    echo -n 'updating & restarting cloudwatch agent...'
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-config-common
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a append-config -m ec2 -s -c ssm:AmazonCloudWatch-config-web
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a append-config -m ec2 -s -c ssm:AmazonCloudWatch-config-mail
    echo 'done.'
  EOF
}
