terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = var.region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    apigateway = var.endpoint
    s3         = var.endpoint
    sts        = var.endpoint
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = var.artifact_bucket
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_api_gateway_rest_api" "chave" {
  name = var.api_name
}

resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.chave.id
  parent_id   = aws_api_gateway_rest_api.chave.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_resource" "auth_proxy" {
  rest_api_id = aws_api_gateway_rest_api.chave.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "auth_root" {
  rest_api_id   = aws_api_gateway_rest_api.chave.id
  resource_id   = aws_api_gateway_resource.auth.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "auth_proxy" {
  rest_api_id   = aws_api_gateway_rest_api.chave.id
  resource_id   = aws_api_gateway_resource.auth_proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "auth_root" {
  rest_api_id             = aws_api_gateway_rest_api.chave.id
  resource_id             = aws_api_gateway_resource.auth.id
  http_method             = aws_api_gateway_method.auth_root.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${var.ms_auth_host}:${var.ms_auth_port}/auth"
}

resource "aws_api_gateway_integration" "auth_proxy" {
  rest_api_id             = aws_api_gateway_rest_api.chave.id
  resource_id             = aws_api_gateway_resource.auth_proxy.id
  http_method             = aws_api_gateway_method.auth_proxy.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${var.ms_auth_host}:${var.ms_auth_port}/auth/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_deployment" "chave" {
  rest_api_id = aws_api_gateway_rest_api.chave.id

  triggers = {
    redeploy = sha1(jsonencode([
      aws_api_gateway_integration.auth_root.id,
      aws_api_gateway_integration.auth_proxy.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.auth_root,
    aws_api_gateway_integration.auth_proxy,
  ]
}

resource "aws_api_gateway_stage" "local" {
  deployment_id = aws_api_gateway_deployment.chave.id
  rest_api_id   = aws_api_gateway_rest_api.chave.id
  stage_name    = var.api_stage
}

output "artifact_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}

output "gateway_url" {
  value = "${var.endpoint}/restapis/${aws_api_gateway_rest_api.chave.id}/${var.api_stage}/_user_request_"
}
