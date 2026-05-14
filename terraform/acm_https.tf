# ACM Certificate for HTTPS (requires domain validation)
# Note: You need to manually validate the domain ownership via DNS or email
variable "domain_name" {
  description = "Domain name for the application (e.g., osm.example.com)"
  type        = string
  default     = "" # Set this in terraform.tfvars if you have a domain
}

resource "aws_acm_certificate" "main" {
  count             = var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "openstreetmap-cert"
  }
}

# HTTPS listener for ALB (only created if domain_name is set)
resource "aws_lb_listener" "https" {
  count             = var.domain_name != "" ? 1 : 0
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.main[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  depends_on = [aws_acm_certificate.main]
}

# Optional: Redirect HTTP to HTTPS
resource "aws_lb_listener_rule" "redirect_http_to_https" {
  count        = var.domain_name != "" ? 1 : 0
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
