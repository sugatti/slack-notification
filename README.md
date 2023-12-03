# slack-notification

## Overview
The Terraform code in this project connects AWS SNS with Snowflake's cloud notification integration and configures a resource to notify Slack of messages in a Lambda function.
See [blog post](https://www.clue-tec.com/blog/snowflake_notification/) for details

## Prerequisites
* Terraform installed
* Appropriate access to cloud providers and Snowflake

## Configuration
* Set variables by editing environment variables or the terraform.tfvars file.
  * profile_name : Set the AWS CLI named profile name
  * snowflake_account_id : Set your Snowflake account ID
  * snowflake_user : Configure the Snowflake user
  * If you want to use a password for Snowflake authentication, set the environment variable SNOWFLAKE_PASSWORD
* Initialize Terraform:

```
terraform init
```

## Execution
* Execute the Terraform plan to review the changes with the following command:

```
terraform plan
```

* If there are no issues with the changes, apply Terraform with:

```
terraform apply
```

## Notes
* Proper access rights to the cloud provider are necessary to execute Terraform.

## License
* This project is published under the Apache License 2.0.
