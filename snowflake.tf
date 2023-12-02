data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

##########################################################
# Notification integration(AWS SNS)
##########################################################
resource "snowflake_notification_integration" "notif_int" {
  name     = var.snowflake_notif_int_name
  comment  = "Snowpipe・タスク エラー通知のためのnotification integration"

  enabled   = true
  type      = "QUEUE"
  direction = "OUTBOUND"

  # AWS_SNS
  notification_provider = "AWS_SNS"
  aws_sns_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.snowflake_notif_iam_role_name}"
  aws_sns_topic_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.aws_sns_topic_name}"
}