variable "app_name" {
  type    = string
  default = "my-python-app"
}

variable "env_name" {
  type    = string
  default = "production"
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "github_owner" {
  default = "naveen-2111-dev"
}

variable "github_repo" {
  default = ""
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "solution_stack" {
  type    = string
  default = "64bit Amazon Linux 2023 v4.0.0 running Python 3.13"
}
