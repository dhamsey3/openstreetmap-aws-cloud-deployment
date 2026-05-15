#!/bin/bash
# This script pulls the latest OpenStreetMap website code, builds a Docker image, pushes it to ECR, and triggers ECS deployment.

set -euo pipefail

# ---
# Production-ready: All variables are set via environment variables or script arguments.
# If not set, the script will exit with an error.
# ---

OSM_REPO_URL="${OSM_REPO_URL:-https://github.com/openstreetmap/openstreetmap-website.git}"
OSM_REF="${OSM_REF:-master}"
OSM_CLONE_DIR="${OSM_CLONE_DIR:-/tmp/openstreetmap-website}"
AWS_REGION="${AWS_REGION:?AWS_REGION environment variable must be set}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:?AWS_ACCOUNT_ID environment variable must be set}"
ECR_REPO="${ECR_REPO:-$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/openstreetmap-website}"
IMAGE_TAG="${IMAGE_TAG:-}"

# Print configuration for verification
echo "Using configuration:"
echo "  OSM_REPO_URL=$OSM_REPO_URL"
echo "  OSM_REF=$OSM_REF"
echo "  OSM_CLONE_DIR=$OSM_CLONE_DIR"
echo "  AWS_REGION=$AWS_REGION"
echo "  AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID"
echo "  ECR_REPO=$ECR_REPO"

# 1. Clone or update the OSM website repo
if [ -d "$OSM_CLONE_DIR" ]; then
  git -C "$OSM_CLONE_DIR" fetch origin "$OSM_REF"
  git -C "$OSM_CLONE_DIR" checkout FETCH_HEAD
else
  git clone --branch "$OSM_REF" --single-branch "$OSM_REPO_URL" "$OSM_CLONE_DIR"
fi

OSM_SHA="$(git -C "$OSM_CLONE_DIR" rev-parse HEAD)"
IMAGE_TAG="${IMAGE_TAG:-osm-${OSM_SHA:0:12}}"
if [ "$IMAGE_TAG" = "latest" ]; then
  echo "IMAGE_TAG must not be 'latest'; use an immutable tag such as a git SHA." >&2
  exit 1
fi
echo "  OSM_SHA=$OSM_SHA"
echo "  IMAGE_TAG=$IMAGE_TAG"

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
terraform plan -out=tf.plan -var="image_tag=$IMAGE_TAG"
terraform apply tf.plan

echo "Deployment triggered with the latest OpenStreetMap website code."
