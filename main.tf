terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.37.0"
    }
  }
  backend "s3" {
    bucket  = "terraformawslambda"
    key     = "aws/ec2-deploy/terraform.tfstate"
    region  = "us-east-1"
    # profile = "value"
    # role_arn = "arn:aws:iam::219634475281:user/Terraform"
  }
}
provider "aws" {
  # Configuration options
  region = "us-east-1"
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

resource "aws_lambda_function" "default" {
  function_name    = "GetPresignedLink"
  description      = "Slack Dynamic Data Source"
  role             = module.self_service_lambda_execution_role.arn
  handler          = "build/microservice/golang/SlackDynamicDataSource/main"
  runtime          = "go1.x"
  s3_bucket        = "temenos-deployment-artifacts-${local.environment_lower}"
  s3_key           = "microservice/golang/SlackDynamicDataSource/aws/main.zip"
  memory_size      = 512
  timeout          = 300
  source_code_hash = base64encode(sha256("~/Development/ACS-GitLab/self-service/build/SlackDynamicDataSource/main.zip"))
  environment {
    variables = {
      ShellySigningSecret = "SlackSigningSecret"
    }
  }
}

resource "aws_ecr_repository" "image_storage" {
  name                 = local.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_lambda_function" "executable" {
  function_name = var.function_name
  image_uri     = "${aws_ecr_repository.image_storage.repository_url}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
}

resource "aws_lambda_function" "bogo-lambda-function" {
  depends_on = [
    null_resource.ecr_image
  ]
  function_name = "${local.prefix}-lambda"
  role          = aws_iam_role.lambda.arn
  timeout       = 300
  image_uri     = "${aws_ecr_repository.repo.repository_url}@${data.aws_ecr_image.lambda_image.id}"
  package_type  = "Image"
}
