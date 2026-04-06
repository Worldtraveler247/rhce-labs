# 03 - AWS Provider Basics

**Series:** Terraform Labs  
**Lab:** 03 | **Prereq:** 02-variables-and-outputs.md  
**Goal:** Connect Terraform to AWS and create real cloud resources — S3 bucket and EC2 instance.

---

## ⚠️ Prerequisites

- AWS account (free tier is fine)
- AWS CLI installed: `brew install awscli`
- AWS credentials configured: `aws configure`

```bash
aws configure
# AWS Access Key ID: (from IAM console)
# AWS Secret Access Key: (from IAM console)
# Default region: us-east-1
# Default output format: json
```

> If you don't have AWS credentials yet, do Labs 1-2 (local provider) and come back when you do. Never hardcode credentials in .tf files.

---

## 🧠 Concepts

### Providers
A provider is a plugin that lets Terraform talk to a specific platform. AWS, Azure, GCP all have their own providers. You declare which ones you need in the `terraform {}` block.

```hcl
provider "aws" {
  region = "us-east-1"
}
```

Terraform pulls credentials from:
1. Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
2. `~/.aws/credentials` file (set by `aws configure`)
3. IAM instance roles (when running on EC2)

**Never put credentials in .tf files or commit them to Git.**

---

## 🔬 Lab 1 — S3 Bucket (Safe, Free Tier)

### Setup

```bash
mkdir -p ~/terraform-labs/03-aws
cd ~/terraform-labs/03-aws
```

### providers.tf

```bash
nano providers.tf
```

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}
```

### variables.tf

```bash
nano variables.tf
```

```hcl
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "bucket_name" {
  type        = string
  description = "Must be globally unique"
}

variable "environment" {
  type    = string
  default = "dev"
}
```

### main.tf

```bash
nano main.tf
```

```hcl
resource "aws_s3_bucket" "lab_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "lab_bucket_versioning" {
  bucket = aws_s3_bucket.lab_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

### outputs.tf

```bash
nano outputs.tf
```

```hcl
output "bucket_name" {
  value = aws_s3_bucket.lab_bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.lab_bucket.arn
}
```

### terraform.tfvars

```bash
nano terraform.tfvars
```

```hcl
aws_region  = "us-east-1"
bucket_name = "ed-terraform-lab-2026"   # change this — must be globally unique
environment = "dev"
```

### Apply

```bash
terraform init
terraform plan
terraform apply
```

Verify in AWS console or CLI:
```bash
aws s3 ls | grep ed-terraform-lab
```

### Clean up (important — avoid charges)

```bash
terraform destroy
```

---

## 🔬 Lab 2 — EC2 Instance

⚠️ **EC2 costs money if left running.** Always destroy when done.

Add to `main.tf`:

```hcl
# Look up the latest Amazon Linux 2023 AMI automatically
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "lab_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"   # free tier eligible

  tags = {
    Name      = "terraform-lab-server"
    ManagedBy = "Terraform"
  }
}
```

Add to `outputs.tf`:

```hcl
output "instance_id" {
  value = aws_instance.lab_server.id
}

output "instance_public_ip" {
  value = aws_instance.lab_server.public_ip
}
```

```bash
terraform plan
terraform apply
```

Check it:
```bash
aws ec2 describe-instances --filters "Name=tag:ManagedBy,Values=Terraform" \
  --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]" \
  --output table
```

**Destroy when done:**
```bash
terraform destroy
```

---

## 🔬 Lab 3 — Data Sources

`data` blocks **read** existing resources without managing them. Use when you need info about something Terraform didn't create.

```hcl
# Get info about your AWS account
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

# Get info about available AZs in your region
data "aws_availability_zones" "available" {
  state = "available"
}

output "availability_zones" {
  value = data.aws_availability_zones.available.names
}
```

---

## 🧪 Challenge

1. Create an S3 bucket with a unique name
2. Enable versioning on it
3. Add a bucket policy that blocks all public access
4. Output the bucket ARN and region
5. Destroy when done

> Hint: look up `aws_s3_bucket_public_access_block` resource

---

## 📚 Key Takeaways

| Concept | What to Remember |
|---------|-----------------|
| `provider "aws" {}` | Configures the AWS provider |
| `data "aws_ami" {}` | Read existing resources (don't manage them) |
| `resource.type.name.attribute` | Reference another resource's attribute |
| Never hardcode credentials | Use `aws configure` or env vars |
| Always `terraform destroy` | Don't leave cloud resources running |
| Tags everything | `ManagedBy = "Terraform"` makes cleanup easy |

---

## ➡️ Next Lab

`04-state-management.md` — Understand Terraform state, remote backends, and state locking.

---

*Lab created: 2026-04-07 | Terraform Series*
