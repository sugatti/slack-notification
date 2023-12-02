terraform {
  required_version = "~> 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.25.0"
    }
    snowflake = {
        source  = "Snowflake-Labs/snowflake"
        version = "~> 0.75"
    }
  }
}

provider "aws" {
  region   = var.region
  profile  = var.profile_name
  default_tags {
    tags = {
        env = "slacke-notifications"
    }
  }
}

provider "snowflake" {
  account  = "${var.snowflake_account_id}"
  user     = "${var.snowflake_user}"
  role     = "SYSADMIN"
}