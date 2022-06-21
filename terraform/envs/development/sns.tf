resource "aws_sns_topic" "alarm_critical" {
  name = "alarm_critical"
}

resource "aws_sns_topic_subscription" "alarm_critical_email" {
  topic_arn = aws_sns_topic.alarm_critical.arn
  protocol  = "email"
  endpoint  = var.mail_alert_critical
}

resource "aws_sns_topic" "alarm_warning" {
  name = "alerm_warning"
}

resource "aws_sns_topic_subscription" "alarm_warning_email" {
  topic_arn = aws_sns_topic.alarm_warning.arn
  protocol  = "email"
  endpoint  = var.mail_alert_warning
}
