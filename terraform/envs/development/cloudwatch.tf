resource "aws_cloudwatch_metric_alarm" "target_group_web_nlb_unhealthy_host_count" {
  alarm_name                = "target_group_web_nlb_unhealthy_host_count"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "UnHealthyHostCount"
  namespace                 = "AWS/NetworkELB"
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = 0
  alarm_description         = "Number of unhealthy hosts in target group web-nlb"
  alarm_actions             = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
  ok_actions                = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
  dimensions = {
    TargetGroup  = module.auto-scaling.target_group_web_nlb_suffix
    LoadBalancer = module.auto-scaling.nlb_web_nlb_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "target_group_web_nlb_healthy_host_count" {
  alarm_name                = "target_group_web_nlb_healthy_host_count"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "HealthyHostCount"
  namespace                 = "AWS/NetworkELB"
  period                    = "60"
  statistic                 = "Minimum"
  threshold                 = 2
  alarm_description         = "Number of healthy hosts in target group web-nlb"
  alarm_actions             = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
  ok_actions                = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
  dimensions = {
    TargetGroup  = module.auto-scaling.target_group_web_nlb_suffix
    LoadBalancer = module.auto-scaling.nlb_web_nlb_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "EC2_metric_alarm" {
  alarm_name          = "EC2-metric-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = 80
  treat_missing_data = "notBreaching"
  datapoints_to_alarm = 1
  depends_on = [
    module.auto-scaling.auto_scaling_group_web,
  ]
  dimensions = {
    AutoScalingGroupName = module.auto-scaling.auto_scaling_group_web
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
  ok_actions        = [aws_sns_topic.alarm_critical.arn,aws_sns_topic.alarm_warning.arn]
}
