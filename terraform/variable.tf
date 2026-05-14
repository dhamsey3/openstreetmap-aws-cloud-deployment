variable "http_cidr" {
  description = "CIDR block for public HTTP access to the ALB"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.http_cidr, 0))
    error_message = "http_cidr must be a valid CIDR block."
  }
}
variable "admin_cidr" {
  description = "CIDR block for SSH admin access (e.g., your office IP)"
  type        = string
  default     = "127.0.0.1/32"

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && var.admin_cidr != "0.0.0.0/0"
    error_message = "admin_cidr must be a valid, non-public CIDR block."
  }
}
variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}


variable "db_password" {
  description = "The database password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "db_password must be at least 16 characters long."
  }
}

variable "db_username" {
  description = "The database username"
  type        = string
}

variable "db_name" {
  description = "The database name"
  type        = string
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-central-1"
}

variable "aws_region" {
  description = "AWS region (alias for region variable)"
  type        = string
  default     = "eu-central-1"
}

variable "ecr_repo_name" {
  description = "ECR repository name for the application"
  type        = string
  default     = "openstreetmap-website"
}

variable "image_tag" {
  description = "Immutable image tag to deploy (CI should set this to the git SHA)"
  type        = string

  validation {
    condition     = var.image_tag != "latest"
    error_message = "image_tag must be immutable; use a commit SHA or release tag instead of latest."
  }
}

variable "enable_alb_deletion_protection" {
  description = "Enable deletion protection on the application load balancer"
  type        = bool
  default     = true
}

variable "enable_ecs_execute_command" {
  description = "Allow ECS Exec into running tasks"
  type        = bool
  default     = false
}
