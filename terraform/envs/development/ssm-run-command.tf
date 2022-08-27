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

resource "aws_ssm_association" "test-df-web" {
  association_name = "test-df-web"
  name = aws_ssm_document.test-df.name
  schedule_expression = "cron(0/30 * * * ? *)"

  targets {
    key    = "tag:Name"
    values = ["my-sample-web-asg"]
  }
}

resource "aws_ssm_association" "test-df-mail" {
  association_name = "test-df-mail"
  name = aws_ssm_document.test-df.name
  schedule_expression = "cron(0/30 * * * ? *)"

  targets {
    key    = "tag:Name"
    values = ["my-sample-mail-asg"]
  }
}

resource aws_cloudwatch_event_rule test_df_web {
  name = "test_df_web"
  schedule_expression = "cron(0/5 * * * ? *)"
}

resource aws_cloudwatch_event_rule test_df_mail {
  name = "test_df_mail"
  schedule_expression = "cron(0/30 * * * ? *)"
}

resource aws_cloudwatch_event_target test_df_web {
  target_id = "test_df_web"
  rule     = aws_cloudwatch_event_rule.test_df_web.name
  role_arn = aws_iam_role.eventbridge-role-for-stepfunctions.arn
  arn = aws_ssm_document.test-df.arn
  run_command_targets {
    key    = "tag:Name"
    values = ["my-sample-web-asg"]
  }

}

resource aws_cloudwatch_event_target test_df_mail {
  target_id = "test_df_mail"
  rule     = aws_cloudwatch_event_rule.test_df_mail.name
  role_arn = aws_iam_role.eventbridge-role-for-stepfunctions.arn
  arn = aws_ssm_document.test-df.arn
  run_command_targets {
    key    = "tag:Name"
    values = ["my-sample-mail-asg"]
  }

}
resource "aws_ssm_document" "update_monitoring_web" {
  name          = "update_monitoring_web"
  document_type = "Command"

  content = <<-DOC
  {
    "schemaVersion": "2.2",
    "description": "update_monitoring_web",
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

resource "aws_ssm_document" "update_monitoring_mail" {
  name          = "update_monitoring_mail"
  document_type = "Command"

  content = <<-DOC
  {
    "schemaVersion": "2.2",
    "description": "update_monitoring_mail",
    "parameters": {
    },
    "mainSteps": [
      {
        "action": "aws:runShellScript",
        "name": "runShellScript",
        "inputs": {
          "runCommand": ${jsonencode(split("\n", var.mail_user_data))}
        }
      }
    ]
  }
DOC
}
