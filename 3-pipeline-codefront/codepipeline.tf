resource "aws_iam_role" "codepipeline_role" {
  name = "${var.app_name}-codepipeline-role"

  # Assume role policy for CodePipeline (update this as necessary)
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        },
      },
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "${var.app_name}-codepipeline-policy"
  role   = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ],
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "codestar-connections:UseConnection"
        ],
        Effect = "Allow",
        Resource = var.codestar_connection_arn
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.codebuild_artifacts.bucket}/*",
          "arn:aws:s3:::${aws_s3_bucket.codebuild_artifacts.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.app_static.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.app_static.bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_codepipeline" "frontend_pipeline" {
  name     = "${var.app_name}-codepipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = "${var.app_name}-codebuild-artifacts"
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name            = "Source"
      category        = "Source"
      owner           = "AWS"
      provider        = "CodeStarSourceConnection"
      version         = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.github_repo_full_name
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = "${var.app_name}-codebuild-project"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      input_artifacts  = ["build_output"]

      configuration = {
        BucketName = aws_s3_bucket.app_static.bucket
        Extract    = "true"
      }
    }
  }
}