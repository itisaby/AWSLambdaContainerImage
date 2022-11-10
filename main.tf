terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.37.0"
    }
  }
  backend "s3" {
    bucket = "awslambdacontainerimageterraform"
    key    = "aws/ec2-deploy/terraform.tfstate"
    region = "us-east-1"
    # role_arn = "arn:aws:iam::219634475281:user/Terraform"
  }
}
resource "aws_iam_role" "lambda" {
  name               = local.name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": "sts:AssumeRole",
          "Principal": {
              "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow"
      }
  ]
}
  EOF
}
