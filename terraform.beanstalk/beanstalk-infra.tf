
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket        = "${var.app_name}-pipeline-artifacts"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts" {
  bucket                  = aws_s3_bucket.pipeline_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline" {
  name               = "${var.app_name}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]
    resources = [
      aws_s3_bucket.pipeline_artifacts.arn,
      "${aws_s3_bucket.pipeline_artifacts.arn}/*",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.github.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "elasticbeanstalk:*",
      "autoscaling:*",
      "cloudformation:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "rds:*",
      "sns:ListSubscriptionsByTopic",
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = [
      "arn:aws:s3:::elasticbeanstalk-${var.region}-*",
      "arn:aws:s3:::elasticbeanstalk-${var.region}-*/*",
    ]
  }
}

resource "aws_iam_role_policy" "codepipeline" {
  name   = "${var.app_name}-codepipeline-policy"
  role   = aws_iam_role.codepipeline.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}


data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${var.app_name}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:*"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.pipeline_artifacts.arn,
      "${aws_s3_bucket.pipeline_artifacts.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "codebuild" {
  name   = "${var.app_name}-codebuild-policy"
  role   = aws_iam_role.codebuild.id
  policy = data.aws_iam_policy_document.codebuild_policy.json
}


data "aws_iam_policy_document" "beanstalk_ec2_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "beanstalk_ec2" {
  name               = "${var.app_name}-beanstalk-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.beanstalk_ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "beanstalk_web_tier" {
  role       = aws_iam_role.beanstalk_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "beanstalk_ssm" {
  role       = aws_iam_role.beanstalk_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "beanstalk_ec2" {
  name = "${var.app_name}-beanstalk-ec2-profile"
  role = aws_iam_role.beanstalk_ec2.name
}


# Add this policy for S3 patching resources
resource "aws_iam_role_policy" "beanstalk_service_s3_patch" {
  name = "${var.app_name}-beanstalk-service-s3-patch"
  role = aws_iam_role.beanstalk_service.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::elasticbeanstalk-env-resources-ap-south-1",
          "arn:aws:s3:::elasticbeanstalk-env-resources-ap-south-1/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "beanstalk_service" {
  name = "${var.app_name}-beanstalk-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "elasticbeanstalk.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "beanstalk_service_attach" {
  role       = aws_iam_role.beanstalk_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}


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
    value     = "application:application"
  }
}


resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.app_name}"
  retention_in_days = 14
}

resource "aws_codebuild_project" "app" {
  name         = "${var.app_name}-build"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
      status     = "ENABLED"
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}


resource "aws_codestarconnections_connection" "github" {
  name          = "${var.app_name}-github-connection"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "app" {
  name     = "${var.app_name}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name     = "GitHub_Source"
      category = "Source"
      owner    = "AWS"
      provider = "CodeStarSourceConnection"

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = var.github_branch
      }

      output_artifacts = ["source_output"]
      version          = "1"
    }
  }

  stage {
    name = "Build"
    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.app.name
      }

      version = "1"
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ElasticBeanstalk"
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName = aws_elastic_beanstalk_application.app.name
        EnvironmentName = aws_elastic_beanstalk_environment.env.name
      }

      version = "1"
    }
  }
}


output "beanstalk_endpoint" {
  value = aws_elastic_beanstalk_environment.env.endpoint_url
}

output "pipeline_name" {
  value = aws_codepipeline.app.name
}