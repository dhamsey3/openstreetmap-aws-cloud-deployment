
# OpenStreetMap Cloud Deployment

Modern, Secure, and Scalable Infrastructure for OpenStreetMap

Welcome! This project demonstrates advanced DevOps, Infrastructure-as-Code, and CI/CD practices by deploying the OpenStreetMap website to AWS using Terraform, ECS (Fargate), and GitHub Actions. It also supports local development with Docker Compose.

---

## Project Highlights




## Example variable files
 - `envs/dev.tfvars` — for development values
 - `envs/at.tfvars` — for acceptance/test values
 - `envs/pr.tfvars` — for production values

## Recommended structure
 - Place all main Terraform code in the `terraform/` directory for clarity.
 - Place all environment-specific variable files in the `envs/` directory.

## Usage
```sh
terraform init
terraform workspace select dev # or at, pr
terraform apply -var-file="envs/dev.tfvars"
```
cd openstreetmap-website
cp config/example.storage.yml config/storage.yml
cp config/docker.database.yml config/database.yml
docker compose build
docker compose up -d
docker compose run --rm web bundle exec rails db:migrate
```bash
docker compose run --rm web osmosis \
  -verbose \
  --read-pbf monaco-latest.osm.pbf \
  --log-progress \
  --write-apidb \
    host="db" \
    database="openstreetmap" \
    user="openstreetmap" \
    validateSchemaVersion="no"
```


```bash
docker compose logs -f web


Important files:

- `main.tf` — existing Terraform for VPC, RDS, S3 and other resources
- `ecs_ecr.tf` — ECR repository + lifecycle policy
- `ecs_fargate.tf` — ECS cluster, ALB, task definition and service
- `ecs_outputs.tf` — helpful outputs (ECR repo URL, ALB DNS, ECS names)
- `.github/workflows/ci-ecr-deploy.yml` — CI workflow that builds/pushes image and updates ECS
- `ecs/task-definition.json` — task definition template used by CI

Required secrets for GitHub Actions (set these in the repo settings):

- `AWS_REGION` — e.g. `eu-central-1`
- `AWS_ACCOUNT_ID` — your AWS account id
- `AWS_ROLE_TO_ASSUME` (optional) — if you prefer role-based auth in Actions
- Alternatively, set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` (less recommended)

Local Terraform quickstart (manual flow)

1. Export AWS credentials (example):

```bash
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=eu-central-1
```

2. Initialize and apply Terraform (creates ECR, ECS, ALB, RDS):
```bash
cd /workspaces/openstreetmap-cloud-deployment
terraform init

ACCOUNT_ID=$(terraform output -raw ecr_repository_url | cut -d'.' -f1)
REGION=$(terraform output -raw ecr_repository_url | cut -d'.' -f4)
REPO_NAME=$(terraform output -raw ecr_repository_url | cut -d'/' -f2)
docker tag ${REPO_NAME}:${TAG} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${TAG}
```

4. Trigger a deployment (CI): push to `main` with required secrets set, or manually register a new task definition and force a new deployment with `aws ecs update-service --force-new-deployment`.
## Security & production notes

- RDS and ECS tasks are currently placed in public subnets in this scaffold for simplicity. For production you should move RDS into private subnets and set ECS tasks to run in private subnets too, exposing only the ALB.
- DB credentials are currently provided via `terraform.tfvars`. For production, store credentials in AWS Secrets Manager and reference them from the ECS task definition.
- Close the SSH ingress (port 22) on `web_sg` or limit it to your administrative IPs.
- Use immutable image tags (git SHA) in CI to avoid `:latest` surprises.
- Add CloudWatch/Prometheus/Grafana for monitoring and alerts.

## Next steps (I can implement)

- Wire Secrets Manager into the ECS task definition and remove DB credentials from `terraform.tfvars`.
- Move RDS to private subnets and create a NAT gateway for outbound internet (or VPC endpoints) so tasks don't require public IPs.
- Add a CI step that automatically updates the Terraform variable `image_tag` (or uses an image-based deployment strategy) to promote images to staging/production.

If you want me to proceed with any of the next steps above, tell me which one and I will implement it and run `terraform validate`/`plan` as appropriate.

---

License: see `LICENSE` in the repo.
