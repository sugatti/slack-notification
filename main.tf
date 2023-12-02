##########################################################
# SNS Topic
##########################################################
resource "aws_sns_topic" "snowflake_notification" {
  name = "${var.aws_sns_topic_name}"
}

##########################################################
# IAM Role for Cloud Notification Integration in Snowflake
##########################################################
resource "aws_iam_role" "snowflake_notification" {
  name = "${var.snowflake_notif_iam_role_name}"
  assume_role_policy = templatefile(
    "./roles/snowflake_assume_policy.json",
    {
      sns_user_arn = snowflake_notification_integration.notif_int.aws_sns_iam_user_arn,
      external_id = snowflake_notification_integration.notif_int.aws_sns_external_id
    }
  )
}

resource "aws_iam_role_policy" "snowflake_notification" {
  name = "snowflake-notification-policy"
  role = aws_iam_role.snowflake_notification.name
  policy = templatefile(
    "./roles/snowflake_notification.json",
    {
      sns_arn = aws_sns_topic.snowflake_notification.arn
    }
  )
}

##########################################################
# IAM role for Lambda for Slack notifications
##########################################################
resource "aws_iam_role" "slack_notification" {
  name = "slack-notification-lambda-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy" "slack_notification" {
  name = "slack-notification-lambda-policy"
  role = aws_iam_role.slack_notification.id
  policy = file("./roles/execution_lambda.json")
}


####################################################
# Lambda
####################################################
data archive_file "slack_notification" {
  type        = "zip"
  source_dir  = "lambda/src"
  output_path = "lambda/build/slack_notification.zip"
}

resource "aws_lambda_function" "slack_notification" {
  filename           = "${data.archive_file.slack_notification.output_path}"
  function_name      = "slack_notification"
  description        = "Lambda function that receives Snowflake errors from SNS and notifies Slack."
  role               = aws_iam_role.slack_notification.arn
  handler            = "lambda_function.lambda_handler"
  source_code_hash   = data.archive_file.slack_notification.output_base64sha256
  runtime            = "python3.8"
  timeout            = 60
  environment {
    variables = {
      LOG_LEVEL      = var.log_level
      WEBHOOK_URL    = var.webhook_url
      SLACK_CHANNEL  = var.slack_channel
      SLACK_USERNAME = var.slack_username
    }
  }
}

####################################################
# Lambda SNS Integration
####################################################
resource "aws_sns_topic_subscription" "slack_notification" {
  topic_arn = aws_sns_topic.snowflake_notification.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notification.arn
}

resource "aws_lambda_permission" "slack_notification" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notification.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.snowflake_notification.arn
}
