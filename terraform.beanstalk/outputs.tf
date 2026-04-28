output "beanstalk_endpoint" {
  value = aws_elastic_beanstalk_environment.env.endpoint_url
}

output "pipeline_name" {
  value = aws_codepipeline.app.name
}