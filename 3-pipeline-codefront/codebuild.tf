provider "aws" {
  # Specify your provider configuration here, if necessary
}

resource "aws_iam_role" "codebuild_role" {
  name = "${var.app_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        },
      },
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "${var.app_name}-codebuild-policy"
  role   = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ],
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.codebuild_artifacts.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.codebuild_artifacts.bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_codebuild_project" "codebuild_project" {
  name         = "${var.app_name}-codebuild-project"
  description  = "CodeBuild for ${title(replace(var.app_name, "-", " "))}"
  service_role = aws_iam_role.codebuild_role
  
  artifacts {
    type = "CODEPIPELINE"
    name = "${var.app_name}-codebuild-project"
    packaging = "NONE"
    encryption_disabled = false
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
    type         = "ARM_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode = false
  }

  source {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
    s3_logs {
      status = "DISABLED"
    }
  }

  build_timeout = 60
  queued_timeout = 480
}