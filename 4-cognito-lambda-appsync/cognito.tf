# Cognito User Pool
resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.app_name}-user-pool"
  alias_attributes = [ "email" ]

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true

    string_attribute_constraints {
      min_length = 7
      max_length = 255
    }
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "${var.app_name}-user-pool-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

# Outputs
output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}