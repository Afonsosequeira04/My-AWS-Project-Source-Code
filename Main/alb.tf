module "alb_http_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "~> 4.0"

  name        = var.alb_sg_name
  vpc_id      = module.vpc.vpc_id
  description = var.alb_sg_description

  ingress_cidr_blocks = var.alb_sg_ingress_cidr_blocks
  tags                = var.alb_sg_tags
}

resource "aws_security_group_rule" "alb_https_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = module.alb_http_sg.security_group_id
  cidr_blocks       = var.alb_sg_ingress_cidr_blocks
  description       = "Allow HTTPS inbound traffic"
}

# Add this to allow inbound traffic on port 8080 to ALB security group
resource "aws_security_group_rule" "alb_http_8080_ingress" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  security_group_id = module.alb_http_sg.security_group_id
  cidr_blocks       = var.alb_sg_ingress_cidr_blocks
  description       = "Allow HTTP inbound traffic on port 8080"
}

module "alb" {
  source          = "terraform-aws-modules/alb/aws"
  version         = "~> 6.0"
  name            = var.alb_name
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.alb_http_sg.security_group_id]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"

      action_type = "redirect"

      redirect = {
        protocol    = "HTTPS"
        port        = "443"
        status_code = "HTTP_301"
      }
    },
    {
      port        = 8080
      protocol    = "HTTP"

      default_action = {
        type               = "forward"
        target_group_index = 1  # Jenkins target group index
      }
    }
  ]

  https_listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.acm_certificate_arn
      ssl_policy      = "ELBSecurityPolicy-2016-08"

      default_action = {
        type               = "forward"
        target_group_index = 0
      }
    }
  ]

  https_listener_rules = [
    {
      https_listener_index = 0
      priority             = 100

      actions = [
        {
          type                       = "authenticate-cognito"
          user_pool_arn              = aws_cognito_user_pool.auth_pool.arn
          user_pool_client_id        = aws_cognito_user_pool_client.auth_client.id
          user_pool_domain           = aws_cognito_user_pool_domain.auth_domain.domain
          on_unauthenticated_request = "authenticate"
        },
        {
          type               = "forward"
          target_group_index = 0
        }
      ]

      conditions = [
        {
          path_patterns = ["/*"]
        }
      ]
    }
  ]

  target_groups = [
    {
      name             = var.alb_target_group_name
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      stickiness       = { enabled = true, type = "lb_cookie" }
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/phpinfo.php"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    },
    {
      name             = "${var.alb_target_group_name}-jenkins"
      backend_protocol = "HTTP"
      backend_port     = 8080
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"       # Adjust if you want a different health check for Jenkins
        port                = "8080"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  ]

  tags = var.alb_tags
}
