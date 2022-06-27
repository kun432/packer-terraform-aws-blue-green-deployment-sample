resource "aws_cloudwatch_metric_alarm" "target_group_web_nlb_unhealthy_host_count" {
  alarm_name                = "target_group_web_nlb_unhealthy_host_count"
  alarm_description         = "Number of unhealthy hosts in target group web-nlb"
  namespace                 = "AWS/NetworkELB"
  metric_name               = "UnHealthyHostCount"
  period                    = 60
  evaluation_periods        = 1
  datapoints_to_alarm       = 1
  threshold                 = 0
  comparison_operator       = "GreaterThanThreshold"
  statistic                 = "Maximum"
  alarm_actions             = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
  ok_actions                = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
  dimensions = {
    TargetGroup  = module.auto-scaling.target_group_web_nlb_suffix
    LoadBalancer = module.auto-scaling.nlb_web_nlb_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "target_group_web_nlb_healthy_host_count" {
  alarm_name                = "target_group_web_nlb_healthy_host_count"
  alarm_description         = "Number of healthy hosts in target group web-nlb"
  namespace                 = "AWS/NetworkELB"
  metric_name               = "HealthyHostCount"
  period                    = 60
  evaluation_periods        = 1
  datapoints_to_alarm       = 1
  threshold                 = 1
  comparison_operator       = "LessThanThreshold"
  statistic                 = "Minimum"
  alarm_actions             = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
  ok_actions                = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
  dimensions = {
    TargetGroup  = module.auto-scaling.target_group_web_nlb_suffix
    LoadBalancer = module.auto-scaling.nlb_web_nlb_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu_alarm" {
  alarm_name          = "autostacling-group-cpu-utilization-alarm"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"
  treat_missing_data  = "breaching"
  depends_on = [
    module.auto-scaling.auto_scaling_group_web,
  ]
  dimensions = {
    AutoScalingGroupName = module.auto-scaling.auto_scaling_group_web
  }

  alarm_description = "This metric monitors autoscaling group cpu utilization"
  alarm_actions     = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
  ok_actions        = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
}

resource "aws_cloudwatch_metric_alarm" "asg_system_status_alarm" {
  alarm_name          = "autoscaling-group-system-status-check-alarm"
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = 60
  datapoints_to_alarm = 1
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  statistic           = "Maximum"
  treat_missing_data  = "breaching"
  depends_on = [
    module.auto-scaling.auto_scaling_group_web,
  ]
  dimensions = {
    AutoScalingGroupName = module.auto-scaling.auto_scaling_group_web
  }

  alarm_description = "This metric monitors asg system status check"
  alarm_actions     = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
  ok_actions        = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
}

resource "aws_cloudwatch_metric_alarm" "asg_instance_status_alarm" {
  alarm_name          = "autoscaling-group-instance-status-check-alarm"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed_Instance"
  period              = 60
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 0
  statistic           = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "breaching"
  depends_on = [
    module.auto-scaling.auto_scaling_group_web,
  ]
  dimensions = {
    AutoScalingGroupName = module.auto-scaling.auto_scaling_group_web
  }

  alarm_description = "This metric monitors asg instance status check"
  alarm_actions     = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
  ok_actions        = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
}