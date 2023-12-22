resource "aws_s3_bucket" "codebuild_artifacts" {
  bucket = "${lower(replace(var.app_name, " ", "-"))}-codebuild-artifacts"
  force_destroy = true
}

resource "aws_s3_bucket" "app_static" {
  bucket = "${lower(replace(var.app_name, " ", "-"))}-static"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "app_static_bucket_policy" {
  bucket = aws_s3_bucket.app_static.id

  policy = jsonencode({
    Version = "2008-10-17",
    Id = "PolicyForCloudFrontPrivateContent",
    Statement = [
      {
        Sid = "AllowCloudFrontServicePrincipal",
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action   = "s3:GetObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.app_static.bucket}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" : "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.frontend_distribution.id}"
          }
        }
      }
    ]
  })
}
