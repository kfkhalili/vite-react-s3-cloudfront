#### PACKAGE LAMBDA CODE ####
data "archive_file" "registerUserCognitoZip" {
    type        = "zip"
    source_file = "./registerUserCognito/index.js"
    output_path = "./registerUserCognito.zip"
}

data "archive_file" "authUserCognitoZip" {
    type        = "zip"
    source_file = "./authUserCognito/index.js"
    output_path = "./authUserCognito.zip"
}

#### COGNITO LAMBDAS ####
resource "aws_lambda_function" "register_user_lambda" {
  function_name = "${var.app_name}_registerUserCognito"
  role          = aws_iam_role.lambda_cognito_role.arn

  handler       = "index.handler"
  runtime       = "nodejs20.x"
  filename      = data.archive_file.registerUserCognitoZip.output_path
  source_code_hash = filebase64sha256(data.archive_file.registerUserCognitoZip.output_path)


  environment {
    variables = {
      COGNITO_CLIENT_ID = aws_cognito_user_pool_client.user_pool_client.id
    }
  }
}

resource "aws_lambda_function" "auth_user_lambda" {
  function_name = "${var.app_name}_authUserCognito"
  role          = aws_iam_role.lambda_cognito_role.arn

  handler       = "index.handler"
  runtime       = "nodejs20.x"
  filename      = data.archive_file.authUserCognitoZip.output_path
  source_code_hash = filebase64sha256(data.archive_file.authUserCognitoZip.output_path)

  environment {
    variables = {
      COGNITO_CLIENT_ID = aws_cognito_user_pool_client.user_pool_client.id
    }
  }
}

#### APPSYNC PERMISSION ####
resource "aws_lambda_permission" "allow_appsync_invoke_register_user" {
  statement_id  = "AllowAppSyncInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_user_lambda.function_name
  principal     = "appsync.amazonaws.com"
  source_arn    = aws_appsync_graphql_api.appsync_api.arn
}

resource "aws_lambda_permission" "allow_appsync_invoke_auth_user" {
  statement_id  = "AllowAppSyncInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_user_lambda.function_name
  principal     = "appsync.amazonaws.com"
  source_arn    = aws_appsync_graphql_api.appsync_api.arn
}


#### IAM ROLES ####
resource "aws_iam_role" "lambda_cognito_role" {
  name = "${var.app_name}_lambda_cognito_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_policy" "lambda_cognito_policy" {
  name        = "${var.app_name}_lambda_cognito_policy"
  description = "IAM policy for Lambda function to interact with Cognito"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "cognito-idp:SignUp",
          "cognito-idp:InitiateAuth"
        ],
        Effect = "Allow",
        Resource = "*"
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "lambda_cognito_attach" {
  role       = aws_iam_role.lambda_cognito_role.name
  policy_arn = aws_iam_policy.lambda_cognito_policy.arn
}
