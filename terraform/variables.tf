variable "endpoint" {
  default = "http://localhost:4566"
}

variable "region" {
  default = "us-east-1"
}

variable "artifact_bucket" {
  default = "chave-artifacts-local"
}

variable "api_name" {
  default = "chave-local-api"
}

variable "api_stage" {
  default = "v1"
}

variable "ms_auth_host" {
  default = "chave-ms-auth"
}

variable "ms_auth_port" {
  default = "3001"
}
