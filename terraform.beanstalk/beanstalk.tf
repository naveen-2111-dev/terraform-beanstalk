resource "aws_elastic_beanstalk_application" "app" {
  name        = var.app_name
  description = "Python application managed by Terraform"
}

resource "aws_elastic_beanstalk_environment" "env" {
  name                = "${var.app_name}-${var.env_name}"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = var.solution_stack

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.beanstalk_ec2.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.beanstalk_service.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:elasticbeanstalk:container:python"
    name      = "WSGIPath"
    value     = "main:app"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "GUNICORN_CMD_ARGS"
    value     = "--workers=4 --worker-class=uvicorn.workers.UvicornWorker"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_REGION"
    value     = "ap-south-1"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_ACCESS_KEY_ID"
    value     = var.aws_access_key_id
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PYTHONPATH"
    value     = "/var/app/current"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_SECRET_ACCESS_KEY"
    value     = var.aws_secret_access_key
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "TABLE_NAME"
    value     = "FastAPIData"
  }
}