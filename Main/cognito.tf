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
.background-customizable {
    background:rgb(116, 215, 35);
  }

  .banner-customizable {
    background:rgb(106, 209, 227);
    padding: 1.5rem 0;
  }

  .logo-customizable {
    max-height: 350px;
    width: 100%;
    margin-bottom: 1rem;
  }

  .inputField-customizable {
    border: 1px solid #d1d5db;
    border-radius: 0.375rem;
    padding: 0.5rem;
  }

  .submitButton-customizable {
    background: rgb(106, 209, 227);
    font-weight: 500;
    border-radius: 0.375rem;
    padding: 0.5rem 1rem;
  }

  .submitButton-customizable:hover {
    background: rgb(149, 217, 227);
  }

  .textDescription-customizable {
    color: #374151;
    margin-bottom: 1rem;
  }
CSS

    image_file = filebase64("${path.module}/../images/ChatGPT Image 12_07_2025, 22_56_04 (3).png")
}