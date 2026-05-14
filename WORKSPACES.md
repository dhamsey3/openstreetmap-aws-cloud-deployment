
# Terraform Workspace Environments

This project uses [Terraform workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces) to segment infrastructure into development (dev), acceptance (at), and production (pr) environments.

## How it works

- Each workspace has its own state and resources.
- Environment-specific variables are set in `terraform.tfvars.dev`, `terraform.tfvars.at`, and `terraform.tfvars.pr`.
- Resource names and settings can be dynamically adjusted using the `terraform.workspace` variable.

## Usage

1. **Create workspaces:**
   ```sh
   terraform workspace new dev
   terraform workspace new at
   terraform workspace new pr
   ```

2. **Switch workspace:**
   ```sh
   terraform workspace select dev
   # or
   terraform workspace select at
   # or
   terraform workspace select pr
   ```

3. **Apply with environment-specific variables:**
   ```sh
   terraform apply -var-file="terraform.tfvars.$(terraform workspace show)"
   ```

4. **Reference workspace in code:**
   ```hcl
   resource "aws_s3_bucket" "example" {
     bucket = "osm-${terraform.workspace}-bucket"
     # ...
   }
   ```

## Example variable files
- `terraform.tfvars.dev` — for development values
- `terraform.tfvars.at` — for acceptance/test values
- `terraform.tfvars.pr` — for production values

---

**Tip:**
- Always double-check the active workspace before applying changes.
- Use `terraform workspace list` to see all workspaces.
