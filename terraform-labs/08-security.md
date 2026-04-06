# 08 - Security — IAM, Secrets, and Best Practices

**Series:** Terraform Labs  
**Lab:** 08 | **Prereq:** 07-terraform-and-ansible.md  
**Goal:** Write secure Terraform configs — least privilege IAM, secrets management, and hardening.

---

## 🧠 Why Terraform Security Matters

Terraform can create and destroy entire cloud environments. Done wrong:
- Credentials leak into Git history
- Resources are publicly exposed
- Overprivileged IAM roles create blast radius
- State files contain secrets in plaintext

---

## 🔬 Lab 1 — Never Hardcode Credentials

❌ **Never do this:**
```hcl
provider "aws" {
  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  region     = "us-east-1"
}
```

✅ **Do this instead:**

```bash
# Option 1: aws configure (stores in ~/.aws/credentials)
aws configure

# Option 2: Environment variables
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG"
export AWS_DEFAULT_REGION="us-east-1"
```

```hcl
# Provider picks up credentials automatically
provider "aws" {
  region = "us-east-1"
}
```

### .gitignore — always include these

```bash
nano .gitignore
```

```
# Terraform
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars           # may contain secrets
.terraform.lock.hcl
crash.log
override.tf
```

---

## 🔬 Lab 2 — Least Privilege IAM

Create a dedicated IAM role for Terraform with only the permissions it needs:

```hcl
# IAM policy — only what Terraform needs
resource "aws_iam_policy" "terraform_policy" {
  name        = "TerraformDeployPolicy"
  description = "Minimal permissions for Terraform deployments"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3StateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::your-state-bucket",
          "arn:aws:s3:::your-state-bucket/*"
        ]
      },
      {
        Sid    = "DynamoDBLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:us-east-1:*:table/terraform-state-locks"
      }
    ]
  })
}
```

**Principle:** Give Terraform the minimum permissions to do its job — nothing more.

---

## 🔬 Lab 3 — Sensitive Variables and Outputs

```hcl
# variables.tf
variable "db_password" {
  type        = string
  description = "Database master password"
  sensitive   = true
}

variable "api_key" {
  type      = string
  sensitive = true
}

# outputs.tf
output "db_endpoint" {
  value = aws_db_instance.main.endpoint
  # Not sensitive — just a hostname
}

output "db_password_reminder" {
  value     = var.db_password
  sensitive = true  # Won't print in logs
}
```

Pass secrets at runtime, never in tfvars committed to git:

```bash
terraform apply -var="db_password=$DB_PASSWORD" -var="api_key=$API_KEY"
```

---

## 🔬 Lab 4 — AWS Secrets Manager Integration

Store secrets in AWS Secrets Manager, reference them in Terraform:

```hcl
# Read an existing secret
data "aws_secretsmanager_secret" "db_creds" {
  name = "prod/myapp/database"
}

data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = data.aws_secretsmanager_secret.db_creds.id
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)
}

resource "aws_db_instance" "main" {
  username = local.db_creds["username"]
  password = local.db_creds["password"]
  # ...
}
```

---

## 🔬 Lab 5 — Encrypt State at Rest

Your state file may contain passwords and secrets. Always encrypt it:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true    # ← AES-256 encryption at rest
    kms_key_id     = "arn:aws:kms:us-east-1:123456789:key/your-kms-key-id"
    dynamodb_table = "terraform-state-locks"
  }
}
```

---

## 🔬 Lab 6 — Security Group Hardening

Avoid `0.0.0.0/0` (open to internet) except where truly needed:

```hcl
# ❌ Bad — SSH open to internet
resource "aws_security_group_rule" "ssh_open" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]   # ← Never do this in prod
}

# ✅ Good — SSH only from your IP
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_security_group_rule" "ssh_restricted" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
}
```

---

## 🔬 Lab 7 — tfsec (Static Security Scanner)

```bash
# Install
brew install tfsec

# Scan your Terraform code
cd ~/terraform-labs/03-aws
tfsec .

# Output as JSON for CI/CD
tfsec . --format json
```

`tfsec` catches common issues:
- Unencrypted S3 buckets
- Public security groups
- Unencrypted RDS instances
- Missing logging

---

## 🧪 Challenge

Audit your Lab 03 AWS config with `tfsec`. For each finding:
1. Understand what the risk is
2. Fix it in your config
3. Re-run tfsec until it passes clean

---

## 📚 Key Takeaways

| Rule | Why It Matters |
|------|---------------|
| Never hardcode credentials | Leaks in git history are permanent |
| Always `.gitignore` .tfstate | State contains secrets |
| `sensitive = true` | Prevents secrets appearing in logs |
| Least privilege IAM | Limits blast radius if compromised |
| Encrypt state (S3 + KMS) | State files can contain passwords |
| Run `tfsec` | Catch security issues before they go live |
| No `0.0.0.0/0` in prod | Lock down ingress to known IPs |

---

## ➡️ Next Lab

`09-cicd.md` — Automate Terraform with GitHub Actions: plan on PR, apply on merge.

---

*Lab created: 2026-04-07 | Terraform Series*
