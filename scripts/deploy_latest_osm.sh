#!/bin/bash
# This script pulls the latest OpenStreetMap website code, builds a Docker image, pushes it to ECR, and triggers ECS deployment.

set -e

# Variables (customize as needed)
OSM_REPO_URL="https://github.com/openstreetmap/openstreetmap-website.git"
OSM_CLONE_DIR="/tmp/openstreetmap-website"
AWS_REGION="us-east-1" # Change to your region
ECR_REPO="<your-account-id>.dkr.ecr.${AWS_REGION}.amazonaws.com/openstreetmap-website"
IMAGE_TAG="latest"

# 1. Clone or update the OSM website repo
if [ -d "$OSM_CLONE_DIR" ]; then
  git -C "$OSM_CLONE_DIR" pull
else
  git clone "$OSM_REPO_URL" "$OSM_CLONE_DIR"
fi

# 2. Build the Docker image
cd "$OSM_CLONE_DIR"
docker build -t "$ECR_REPO:$IMAGE_TAG" .

# 3. Authenticate Docker to ECR
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REPO"

# 4. Push the image to ECR
docker push "$ECR_REPO:$IMAGE_TAG"

# 5. Trigger ECS deployment (Terraform apply)
cd "${OLDPWD:-$PWD}"
cd "$(dirname "$0")/.."
terraform apply -auto-approve

echo "Deployment triggered with the latest OpenStreetMap website code."
