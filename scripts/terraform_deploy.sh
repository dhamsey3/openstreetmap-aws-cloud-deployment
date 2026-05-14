#!/bin/bash

# Ensure the script exits if any command fails
set -euo pipefail

: "${DB_PASSWORD:?DB_PASSWORD environment variable must be set}"
: "${DB_USERNAME:?DB_USERNAME environment variable must be set}"
: "${DB_NAME:?DB_NAME environment variable must be set}"
: "${KEY_NAME:?KEY_NAME environment variable must be set}"
: "${ACCOUNT_ID:?ACCOUNT_ID environment variable must be set}"
: "${IMAGE_TAG:?IMAGE_TAG environment variable must be set to an immutable image tag}"

if [ "$IMAGE_TAG" = "latest" ]; then
  echo "IMAGE_TAG must not be 'latest'; use an immutable tag such as a git SHA." >&2
  exit 1
fi

# Navigate to the root directory where the Terraform files are located
cd "$(dirname "$0")/.."

# Initialize Terraform
terraform init

# Run Terraform plan
terraform plan -var="db_password=${DB_PASSWORD}" -var="db_username=${DB_USERNAME}" -var="db_name=${DB_NAME}" -var="key_name=${KEY_NAME}" -var="account_id=${ACCOUNT_ID}" -var="image_tag=${IMAGE_TAG}"

# Commenting out the apply step for review
# Apply Terraform configuration
# terraform apply -var="db_password=${DB_PASSWORD}" -var="db_username=${DB_USERNAME}" -var="db_name=${DB_NAME}" -var="key_name=${KEY_NAME}" -var="account_id=${ACCOUNT_ID}" -var="image_tag=${IMAGE_TAG}"
