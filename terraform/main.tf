# --- Secrets Module ---
module "secrets" {
  source      = "./modules/secrets"
  db_username = var.db_username
  db_password = var.db_password
  db_name     = var.db_name
}

module "network" {
  source = "./modules/network"

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.3.0/24", "10.0.4.0/24"]
  private_subnet_cidrs = ["10.0.5.0/24", "10.0.6.0/24"]
  azs                  = ["eu-central-1a", "eu-central-1b"]
}

# Example: Use workspace for resource naming
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Example: Use workspace in resource names
# resource "aws_s3_bucket" "example" {
#   bucket = "osm-${terraform.workspace}-${random_string.bucket_suffix.result}"
# }



# Create a security group
resource "aws_security_group" "web_sg" {
  vpc_id = module.network.vpc_id

  # Restrict SSH to a trusted IP (replace with your admin IP or CIDR)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # Restrict HTTP (80) to a trusted CIDR (e.g., office IP or ALB SG)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.http_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "openstreetmap-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "openstreetmap-alb-sg"
  }
}

# Security group for ECS tasks
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id

  # allow traffic from the ALB
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for RDS
resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an RDS instance for the database
resource "aws_db_instance" "osm_db" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "13.15"
  instance_class         = "db.t3.micro"
  identifier             = "openstreetmapdb"
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  # Production settings
  multi_az                  = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "openstreetmap-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  backup_retention_period   = 7
  backup_window             = "03:00-04:00"
  maintenance_window        = "mon:04:00-mon:05:00"

  # Enable enhanced monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  # Enable encryption
  storage_encrypted = true

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.web_sg
  ]
}

# Create a DB subnet group with a unique name
resource "aws_db_subnet_group" "main" {
  name = "main-${random_string.bucket_suffix.result}"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = {
    Name = "main-${random_string.bucket_suffix.result}"
  }
}

// Secrets Manager secrets will be created in secrets.tf
