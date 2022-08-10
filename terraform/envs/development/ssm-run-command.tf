resource "aws_ssm_document" "test-df" {
  name          = "test_df"
  document_type = "Command"

  content = <<-DOC
  {
    "schemaVersion": "2.2",
    "description": "test df command",
    "parameters": {
    },
    "mainSteps": [
      {
        "action": "aws:runShellScript",
        "name": "runShellScript",
        "inputs": {
          "runCommand": [
            "#!/usr/bin/env bash",
            "df -h"
          ]
        }
      }
    ]
  }
DOC
}

resource "aws_ssm_association" "test-df" {
  association_name = "test-df"
  name = aws_ssm_document.test-df.name
  schedule_expression = "cron(0/30 * * * ? *)"

  targets {
    key    = "tag:Name"
    values = ["my-sample-web-asg"]
  }
}

resource aws_cloudwatch_event_rule test_df {
  name = "test_df"
  schedule_expression = "cron(0/5 * * * ? *)"
}

resource aws_cloudwatch_event_target test_df {
  target_id = "test_df"
  rule     = aws_cloudwatch_event_rule.test_df.name
  role_arn = aws_iam_role.eventbridge-role-for-stepfunctions.arn
  arn = aws_ssm_document.test-df.arn
  run_command_targets {
    key    = "tag:Name"
    values = ["my-sample-web-asg"]
  }

}

resource "aws_ssm_document" "update_monitoring" {
  name          = "update_monitorinng"
  document_type = "Command"

  content = <<-DOC
  {
    "schemaVersion": "2.2",
    "description": "update_monitoring",
    "parameters": {
    },
    "mainSteps": [
      {
        "action": "aws:runShellScript",
        "name": "runShellScript",
        "inputs": {
          "runCommand": ${jsonencode(split("\n", var.web_user_data))}
        }
      }
    ]
  }
DOC
}
