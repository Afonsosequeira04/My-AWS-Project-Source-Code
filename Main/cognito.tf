resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_cognito_user_pool" "auth_pool" {
  name = "web-users"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_client" "auth_client" {
  name                       = "web-app-client"
  user_pool_id               = aws_cognito_user_pool.auth_pool.id
  generate_secret            = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows        = ["code"]
  allowed_oauth_scopes       = ["openid", "email", "profile"]
  callback_urls = ["https://checkthattask.xyz/oauth2/idpresponse"]
  logout_urls   = ["https://checkthattask.xyz/"]
  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "auth_domain" {
  domain       = "web-login-${random_id.suffix.hex}"
  user_pool_id = aws_cognito_user_pool.auth_pool.id
}
