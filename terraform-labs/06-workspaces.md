# 06 - Workspaces — Dev / Staging / Prod

**Series:** Terraform Labs  
**Lab:** 06 | **Prereq:** 05-modules.md  
**Goal:** Use Terraform workspaces to manage multiple environments from a single config.

---

## 🧠 What Are Workspaces?

Workspaces let you maintain **separate state files** for different environments using the same Terraform config. Think of them as branches — same code, different state.

```
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

Each workspace gets its own `terraform.tfstate`. When you apply in `dev`, it doesn't touch `prod`.

---

## 🔬 Lab 1 — Basic Workspace Commands

```bash
cd ~/terraform-labs/06-workspaces
mkdir -p ~/terraform-labs/06-workspaces
cd ~/terraform-labs/06-workspaces

# See current workspace (default = "default")
terraform workspace show

# List all workspaces
terraform workspace list

# Create new workspace
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch workspace
terraform workspace select dev
terraform workspace show   # confirms you're in dev
```

---

## 🔬 Lab 2 — Environment-Aware Config

Use `terraform.workspace` to make your config change behavior per environment:

### main.tf

```bash
nano main.tf
```

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

locals {
  env_config = {
    dev = {
      instance_count = 1
      log_level      = "debug"
      debug_enabled  = "true"
    }
    staging = {
      instance_count = 2
      log_level      = "info"
      debug_enabled  = "false"
    }
    prod = {
      instance_count = 5
      log_level      = "error"
      debug_enabled  = "false"
    }
  }

  # Current workspace config (falls back to dev if unknown)
  config = lookup(local.env_config, terraform.workspace, local.env_config["dev"])
}

resource "local_file" "env_config" {
  filename = "${path.module}/${terraform.workspace}-config.txt"
  content  = <<-EOT
    environment     = ${terraform.workspace}
    instance_count  = ${local.config.instance_count}
    log_level       = ${local.config.log_level}
    debug_enabled   = ${local.config.debug_enabled}
  EOT
}
```

### outputs.tf

```bash
nano outputs.tf
```

```hcl
output "current_workspace" {
  value = terraform.workspace
}

output "instance_count" {
  value = local.config.instance_count
}
```

### Test each environment

```bash
terraform init

terraform workspace select dev
terraform apply -auto-approve
cat dev-config.txt

terraform workspace select prod
terraform apply -auto-approve
cat prod-config.txt
```

Different files, different configs, same code.

---

## 🔬 Lab 3 — Workspace-Based Naming (AWS Example)

Use workspaces to name resources uniquely per environment:

```hcl
resource "aws_s3_bucket" "app_bucket" {
  bucket = "myapp-${terraform.workspace}-storage"

  tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
  }
}
```

In `dev` workspace: creates `myapp-dev-storage`  
In `prod` workspace: creates `myapp-prod-storage`

---

## 🔬 Lab 4 — Remote State with Workspaces

When using S3 backend with workspaces, state files are automatically organized:

```
s3://your-state-bucket/
  env:/
    dev/terraform.tfstate
    staging/terraform.tfstate
    prod/terraform.tfstate
```

Your backend config stays the same — Terraform handles the path automatically.

---

## ⚠️ Workspace Limitations

Workspaces are good for **simple environment separation**, but for large teams consider:
- **Separate directories** per environment (more isolation)
- **Separate AWS accounts** per environment (best practice for prod)
- **Terragrunt** (wrapper tool that adds env management on top of Terraform)

---

## 🧪 Challenge

1. Create 3 workspaces: `dev`, `staging`, `prod`
2. Write a config that creates an output file per environment
3. Each environment should have different `retention_days` (7, 30, 365)
4. Apply in all 3 workspaces and verify different outputs

---

## 📚 Key Takeaways

| Command | What It Does |
|---------|-------------|
| `terraform workspace list` | List all workspaces |
| `terraform workspace new name` | Create a workspace |
| `terraform workspace select name` | Switch workspace |
| `terraform workspace show` | Show current workspace |
| `terraform.workspace` | Reference workspace name in config |

---

## ➡️ Next Lab

`07-terraform-and-ansible.md` — Use Terraform and Ansible together: Terraform builds it, Ansible configures it.

---

*Lab created: 2026-04-07 | Terraform Series*
