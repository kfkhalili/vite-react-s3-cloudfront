resource "aws_codestarconnections_connection" "github_connection" {
  name      = "github-connection"
  provider_type = "GitHub"
}

output "codestar_connection_arn" {
  value = aws_codestarconnections_connection.github_connection.arn
  description = "CodeStar Connection ARN"
}