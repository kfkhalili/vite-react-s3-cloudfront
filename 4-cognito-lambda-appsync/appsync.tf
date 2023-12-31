resource "aws_appsync_graphql_api" "appsync_api" {
  name                = "${var.app_name}-appsync-api"
  authentication_type = "AMAZON_COGNITO_USER_POOLS"

  user_pool_config {
    user_pool_id   = aws_cognito_user_pool_client.user_pool_client.user_pool_id
    aws_region     = var.aws_region
    default_action = "ALLOW"
  }

  additional_authentication_provider {
    authentication_type = "AWS_IAM"
  }

  schema = file("./schema.graphql")

  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync_service_role.arn
    exclude_verbose_content  = false
    field_log_level          = "ALL"
  }
}

resource "aws_appsync_datasource" "register_user_datasource" {
  api_id = aws_appsync_graphql_api.appsync_api.id
  name   = "${local.app_name_title_case_together}RegisterUserLambdaDatasource"
  type   = "AWS_LAMBDA"

  lambda_config {
    function_arn = aws_lambda_function.register_user_lambda.arn
  }

  service_role_arn = aws_iam_role.appsync_service_role.arn
}

resource "aws_appsync_datasource" "auth_user_datasource" {
  api_id = aws_appsync_graphql_api.appsync_api.id
  name   = "${local.app_name_title_case_together}AuthUserLambdaDatasource"
  type   = "AWS_LAMBDA"

  lambda_config {
    function_arn = aws_lambda_function.auth_user_lambda.arn
  }

  service_role_arn = aws_iam_role.appsync_service_role.arn
}

#### APPSYNC IAM ROLES ####
resource "aws_iam_role" "appsync_service_role" {
  name = "${var.app_name}_appsync_service_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "appsync.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_role_policy" "appsync_service_policy" {
  role = aws_iam_role.appsync_service_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "lambda:invokeFunction"
        ],
        Effect = "Allow",
        Resource = [
          aws_lambda_function.register_user_lambda.arn,
          aws_lambda_function.auth_user_lambda.arn,
        ]
      },
    ],
  })
}

resource "aws_iam_role_policy" "appsync_cloudwatch_policy" {
  role = aws_iam_role.appsync_service_role.id

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
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

#### APPSYNC RESOLVERS ####
resource "aws_appsync_resolver" "register_user_resolver" {
  api_id      = aws_appsync_graphql_api.appsync_api.id
  type        = "Mutation"
  field       = "registerUser"
  data_source = aws_appsync_datasource.register_user_datasource.name

  request_template = <<EOF
{
    "version": "2017-02-28",
    "operation": "Invoke",
    "payload": $util.toJson($context.arguments)
}
EOF

  response_template = "$context.result.body"
}

resource "aws_appsync_resolver" "auth_user_resolver" {
  api_id      = aws_appsync_graphql_api.appsync_api.id
  type        = "Mutation"
  field       = "authUser"
  data_source = aws_appsync_datasource.auth_user_datasource.name

  request_template = <<EOF
{
    "version": "2017-02-28",
    "operation": "Invoke",
    "payload": $util.toJson($context.arguments)
}
EOF

  response_template = "$context.result.body"
}
