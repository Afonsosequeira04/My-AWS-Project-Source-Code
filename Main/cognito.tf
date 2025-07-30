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

resource "aws_cognito_user_pool_ui_customization" "auth_ui" {
  client_id    = aws_cognito_user_pool_client.auth_client.id
  user_pool_id = aws_cognito_user_pool.auth_pool.id

  css = <<CSS
  /* Light modern theme - modify colors as needed */

  /* Header area */
  .banner-customizable {
    background: #2563eb;
    padding: 1.5rem 0;
  }

  /* Logo (add your own via image_file later) */
  .logo-customizable {
    max-height: 50px;
  }

  /* Input fields */
  .inputField-customizable {
    border: 1px solid #d1d5db;
    border-radius: 0.375rem;
    padding: 0.5rem;
  }

  /* Submit button */
  .submitButton-customizable {
    background: #2563eb;
    font-weight: 500;
    border-radius: 0.375rem;
    padding: 0.5rem 1rem;
  }
  .submitButton-customizable:hover {
    background: #1d4ed8;
  }

  /* Text styles */
  .textDescription-customizable {
    color: #374151;
    margin-bottom: 1rem;
  }
CSS
}
