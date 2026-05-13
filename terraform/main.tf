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

locals {
  cors_allow_headers = "Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token"
  cors_allow_methods = "GET,POST,PATCH,PUT,DELETE,OPTIONS"
  cors_allow_origin  = "http://localhost:3000"
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

resource "aws_api_gateway_resource" "root_proxy" {
  rest_api_id = aws_api_gateway_rest_api.chave.id
  parent_id   = aws_api_gateway_rest_api.chave.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "root" {
  rest_api_id   = aws_api_gateway_rest_api.chave.id
  resource_id   = aws_api_gateway_rest_api.chave.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "root_proxy" {
  rest_api_id   = aws_api_gateway_rest_api.chave.id
  resource_id   = aws_api_gateway_resource.root_proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
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

resource "aws_api_gateway_method" "cors_root_proxy" {
  rest_api_id   = aws_api_gateway_rest_api.chave.id
  resource_id   = aws_api_gateway_resource.root_proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_method_response" "cors_root_proxy" {
  rest_api_id = aws_api_gateway_rest_api.chave.id
  resource_id = aws_api_gateway_resource.root_proxy.id
  http_method = aws_api_gateway_method.cors_root_proxy.http_method
  status_code = "204"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Credentials" = true
    "method.response.header.Access-Control-Allow-Headers"     = true
    "method.response.header.Access-Control-Allow-Methods"     = true
    "method.response.header.Access-Control-Allow-Origin"      = true
  }
}

resource "aws_api_gateway_integration" "cors_root_proxy" {
  rest_api_id = aws_api_gateway_rest_api.chave.id
  resource_id = aws_api_gateway_resource.root_proxy.id
  http_method = aws_api_gateway_method.cors_root_proxy.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 204}"
  }
}

resource "aws_api_gateway_integration_response" "cors_root_proxy" {
  rest_api_id = aws_api_gateway_rest_api.chave.id
  resource_id = aws_api_gateway_resource.root_proxy.id
  http_method = aws_api_gateway_method.cors_root_proxy.http_method
  status_code = aws_api_gateway_method_response.cors_root_proxy.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
    "method.response.header.Access-Control-Allow-Headers"     = "'${local.cors_allow_headers}'"
    "method.response.header.Access-Control-Allow-Methods"     = "'${local.cors_allow_methods}'"
    "method.response.header.Access-Control-Allow-Origin"      = "'${local.cors_allow_origin}'"
  }

  depends_on = [aws_api_gateway_integration.cors_root_proxy]
}

resource "aws_api_gateway_method" "cors_auth_proxy" {
  rest_api_id   = aws_api_gateway_rest_api.chave.id
  resource_id   = aws_api_gateway_resource.auth_proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_method_response" "cors_auth_proxy" {
  rest_api_id = aws_api_gateway_rest_api.chave.id
  resource_id = aws_api_gateway_resource.auth_proxy.id
  http_method = aws_api_gateway_method.cors_auth_proxy.http_method
  status_code = "204"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Credentials" = true
    "method.response.header.Access-Control-Allow-Headers"     = true
    "method.response.header.Access-Control-Allow-Methods"     = true
    "method.response.header.Access-Control-Allow-Origin"      = true
  }
}

resource "aws_api_gateway_integration" "cors_auth_proxy" {
  rest_api_id = aws_api_gateway_rest_api.chave.id
  resource_id = aws_api_gateway_resource.auth_proxy.id
  http_method = aws_api_gateway_method.cors_auth_proxy.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 204}"
  }
}

resource "aws_api_gateway_integration_response" "cors_auth_proxy" {
  rest_api_id = aws_api_gateway_rest_api.chave.id
  resource_id = aws_api_gateway_resource.auth_proxy.id
  http_method = aws_api_gateway_method.cors_auth_proxy.http_method
  status_code = aws_api_gateway_method_response.cors_auth_proxy.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
    "method.response.header.Access-Control-Allow-Headers"     = "'${local.cors_allow_headers}'"
    "method.response.header.Access-Control-Allow-Methods"     = "'${local.cors_allow_methods}'"
    "method.response.header.Access-Control-Allow-Origin"      = "'${local.cors_allow_origin}'"
  }

  depends_on = [aws_api_gateway_integration.cors_auth_proxy]
}

resource "aws_api_gateway_integration" "root" {
  rest_api_id             = aws_api_gateway_rest_api.chave.id
  resource_id             = aws_api_gateway_rest_api.chave.root_resource_id
  http_method             = aws_api_gateway_method.root.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${var.ms_auth_host}:${var.ms_auth_port}"
}

resource "aws_api_gateway_integration" "root_proxy" {
  rest_api_id             = aws_api_gateway_rest_api.chave.id
  resource_id             = aws_api_gateway_resource.root_proxy.id
  http_method             = aws_api_gateway_method.root_proxy.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${var.ms_auth_host}:${var.ms_auth_port}/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
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
      aws_api_gateway_integration.root.id,
      aws_api_gateway_integration.root_proxy.id,
      aws_api_gateway_integration.auth_root.id,
      aws_api_gateway_integration.auth_proxy.id,
      aws_api_gateway_integration.cors_root_proxy.id,
      aws_api_gateway_integration.cors_auth_proxy.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.root,
    aws_api_gateway_integration.root_proxy,
    aws_api_gateway_integration.auth_root,
    aws_api_gateway_integration.auth_proxy,
    aws_api_gateway_integration.cors_root_proxy,
    aws_api_gateway_integration_response.cors_root_proxy,
    aws_api_gateway_integration.cors_auth_proxy,
    aws_api_gateway_integration_response.cors_auth_proxy,
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
  value = "${var.public_endpoint}/restapis/${aws_api_gateway_rest_api.chave.id}/${var.api_stage}/_user_request_"
}
