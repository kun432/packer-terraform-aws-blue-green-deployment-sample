data "aws_caller_identity" "self" { }

#----- step functions -----

data "aws_iam_policy_document" "stepfunctions_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "stepfunctions" {
  statement {
    actions = [
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DeleteAlarms",
    ]
    resources = ["*"]
    effect  = "Allow"
  }
}

resource "aws_iam_policy" "stepfunctions_cloudwatch_alarm_policy" {
    name = "stepfunctions-cloudwatch-alarm-policy"
    policy = data.aws_iam_policy_document.stepfunctions.json
}

resource "aws_iam_role" "stepfunctions_role_for_cloudwatch_alarm" {
    name = "stepfunctions-role-for-cloudwatch-alarm"
    assume_role_policy = data.aws_iam_policy_document.stepfunctions_assume_role.json
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment_stepfunctions_cloudwatch_alarm" {
    role = aws_iam_role.stepfunctions_role_for_cloudwatch_alarm.name
    policy_arn = aws_iam_policy.stepfunctions_cloudwatch_alarm_policy.arn
}

#----- eventbridge -----

data "aws_iam_policy_document" "eventbridge_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eventbridge" {
  statement {
    actions = [
      "states:StartExecution",
    ]
    resources = [
      "arn:aws:states:${var.region}:${data.aws_caller_identity.self.account_id}:stateMachine:*"
    ]
    effect  = "Allow"
  }
}

resource "aws_iam_policy" "eventbridge_stepfunctions_policy" {
    name = "eventbridge-stepfunctions-policy"
    policy = data.aws_iam_policy_document.eventbridge.json
}

resource "aws_iam_role" "eventbridge-role-for-stepfunctions" {
    name = "eventbridge-role-for-stepfunctions"
    assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role.json
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment_eventbridge_stepfunctions" {
    role = aws_iam_role.eventbridge-role-for-stepfunctions.name
    policy_arn = aws_iam_policy.eventbridge_stepfunctions_policy.arn
}

#----- alarm -----

resource aws_sfn_state_machine step-function-create-ec2-alarm-cpu {
  name     = "create-ec2-alarm-cpu"
  role_arn = aws_iam_role.stepfunctions_role_for_cloudwatch_alarm.arn

  definition = <<-EOF
  {
    "Comment": "create-ec2-alarm-cpu",
    "StartAt": "PutMetricAlarm",
    "States": {
      "PutMetricAlarm": {
        "Type": "Task",
        "End": true,
        "Parameters": {
          "AlarmName.$": "States.Format('${var.environ}-WEB_CPU_UTILIZATION-{}', $.detail.EC2InstanceId)",
          "AlarmDescription.$": "States.Format('${var.environ}-WEB_CPU_UTILIZATION-{}', $.detail.EC2InstanceId)",
          "AlarmActions": [
            "${aws_sns_topic.alarm_critical.arn}",
            "${aws_sns_topic.alarm_warning.arn}"
          ],
          "OkActions": [
            "${aws_sns_topic.alarm_critical.arn}",
            "${aws_sns_topic.alarm_warning.arn}"
          ],
          "Namespace": "AWS/EC2",
          "MetricName": "CPUUtilization",
          "Statistic": "Maximum",
          "Dimensions": [
            {
              "Name": "InstanceId",
              "Value.$": "$.detail.EC2InstanceId"
            }
          ],
          "Period": 300,
          "EvaluationPeriods": 1,
          "Threshold": 80,
          "DatapointsToAlarm": 1,
          "ComparisonOperator": "GreaterThanOrEqualToThreshold",
          "TreatMissingData": "breaching"
        },
        "Resource": "arn:aws:states:::aws-sdk:cloudwatch:putMetricAlarm"
      }
    }
  }
  EOF
}

resource aws_sfn_state_machine step-function-create-ec2-alarm-disk {
  name     = "create-ec2-alarm-disk"
  role_arn = aws_iam_role.stepfunctions_role_for_cloudwatch_alarm.arn

  definition = <<-EOF
  {
    "Comment": "create-ec2-alarm-disk",
    "StartAt": "PutMetricAlarm",
    "States": {
      "PutMetricAlarm": {
        "Type": "Task",
        "End": true,
        "Parameters": {
          "AlarmName.$": "States.Format('${var.environ}-WEB_DISK_USED_PERCENT_ROOT-{}', $.detail.EC2InstanceId)",
          "AlarmDescription.$": "States.Format('${var.environ}-WEB_DISK_USED_PERCENT_ROOT-{}', $.detail.EC2InstanceId)",
          "AlarmActions": [
            "${aws_sns_topic.alarm_critical.arn}",
            "${aws_sns_topic.alarm_warning.arn}"
          ],
          "OkActions": [
            "${aws_sns_topic.alarm_critical.arn}",
            "${aws_sns_topic.alarm_warning.arn}"
          ],
          "Namespace": "CWAgent",
          "MetricName": "disk_used_percent",
          "Statistic": "Maximum",
          "Dimensions": [
            {
              "Name": "InstanceId",
              "Value.$": "$.detail.EC2InstanceId"
            },
            {
              "Name": "AutoScalingGroupName",
              "Value.$": "$.detail.AutoScalingGroupName"
            },
            {
              "Name": "path",
              "Value": "/"
            },
            {
              "Name": "device",
              "Value": "xvda1"
            },
            {
              "Name": "fstype",
              "Value": "xfs"
            },
            {
              "Name": "InstanceType",
              "Value": "t2.micro"
            }
          ],
          "Period": 60,
          "EvaluationPeriods": 1,
          "Threshold": 80,
          "DatapointsToAlarm": 1,
          "ComparisonOperator": "GreaterThanOrEqualToThreshold",
          "TreatMissingData": "breaching"
        },
        "Resource": "arn:aws:states:::aws-sdk:cloudwatch:putMetricAlarm"
      }
    }
  }
  EOF
}
resource aws_sfn_state_machine step-function-delete-ec2-alarm-all {
  name     = "delete-ec2-alarm-all"
  role_arn = aws_iam_role.stepfunctions_role_for_cloudwatch_alarm.arn

  definition = <<-EOF
    {
      "Comment": "delete-ec2-alarm-all",
      "StartAt": "DeleteAlarms",
      "States": {
        "DeleteAlarms": {
          "Type": "Task",
          "End": true,
          "Parameters": {
            "AlarmNames.$": "States.Array(States.Format('${var.environ}-WEB_CPU_UTILIZATION-{}', $.detail.EC2InstanceId),States.Format('${var.environ}-WEB_DISK_USED_PERCENT_ROOT-{}', $.detail.EC2InstanceId))"
          },
          "Resource": "arn:aws:states:::aws-sdk:cloudwatch:deleteAlarms"
        }
      }
    }
  EOF
}

resource aws_cloudwatch_event_rule eb-asg-ec2-launch-successful {
  name = "eb_asg_ec2_launch_successful"
  event_pattern = <<-EOF
  {
    "source": ["aws.autoscaling"],
    "detail-type": ["EC2 Instance Launch Successful"]
  }
  EOF
}
resource aws_cloudwatch_event_target create-asg-alarm-cpu {
  rule     = aws_cloudwatch_event_rule.eb-asg-ec2-launch-successful.name
  arn      = aws_sfn_state_machine.step-function-create-ec2-alarm-cpu.arn
  role_arn = aws_iam_role.eventbridge-role-for-stepfunctions.arn
}

resource aws_cloudwatch_event_target create-asg-alarm-disk {
  rule     = aws_cloudwatch_event_rule.eb-asg-ec2-launch-successful.name
  arn      = aws_sfn_state_machine.step-function-create-ec2-alarm-disk.arn
  role_arn = aws_iam_role.eventbridge-role-for-stepfunctions.arn
}

resource aws_cloudwatch_event_rule eb-asg-ec2-terminate-successful {
  name = "eb_asg_ec2_terminate_successful"
  event_pattern = <<-EOF
  {
    "source": ["aws.autoscaling"],
    "detail-type": ["EC2 Instance Terminate Successful"]
  }
  EOF
}

resource aws_cloudwatch_event_target eb-asg-ec2-terminate-successful {
  rule     = aws_cloudwatch_event_rule.eb-asg-ec2-terminate-successful.name
  arn      = aws_sfn_state_machine.step-function-delete-ec2-alarm-all.arn
  role_arn = aws_iam_role.eventbridge-role-for-stepfunctions.arn
}
