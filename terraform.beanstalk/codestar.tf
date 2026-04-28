resource "aws_codestarconnections_connection" "github" {
  name          = "${var.app_name}-github-connection"
  provider_type = "GitHub"
}