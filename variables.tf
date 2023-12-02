variable "region" {
  description = "region"
  type        = string
  default     = "ap-northeast-1"
}
variable "profile_name" {}
variable "snowflake_account_id" {}
variable "snowflake_user" {}
variable "snowflake_notif_int_name" {}
variable "snowflake_notif_iam_role_name" {}
variable "aws_sns_topic_name" {}
variable "log_level" {}
variable "webhook_url" {}
variable "slack_channel" {}
variable "slack_username" {}
