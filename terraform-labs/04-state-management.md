# 04 - State Management

**Series:** Terraform Labs  
**Lab:** 04 | **Prereq:** 03-aws-provider.md  
**Goal:** Understand Terraform state, why remote backends matter, and how to avoid state disasters.

---

## 🧠 What Is State?

Terraform state (`terraform.tfstate`) is how Terraform knows what it has built. It's a JSON file that maps your config to real-world resources.

**Without state, Terraform can't:**
- Know what already exists
- Calculate what needs to change
- Safely destroy resources

### The Problem with Local State
- If your laptop dies, state is gone
- If two people run `terraform apply` at the same time — chaos
- State can contain secrets (database passwords, etc.)

**Solution: Remote state** — store state in S3, Azure Blob, Terraform Cloud, etc.

---

## 🔬 Lab 1 — Inspect State

```bash
cd ~/terraform-labs/01-first-resource
terraform init
terraform apply -auto-approve

# View state
terraform show

# List all resources in state
terraform state list

# View specific resource
terraform state show local_file.hello
```

---

## 🔬 Lab 2 — Remote State with S3 Backend

This stores your state file in S3 with DynamoDB for state locking.

### Step 1: Create the backend infrastructure (one time)

```bash
mkdir -p ~/terraform-labs/04-backend-setup
cd ~/terraform-labs/04-backend-setup
nano main.tf
```

```hcl
provider "aws" {
  region = "us-east-1"
}

# S3 bucket to store state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "ed-terraform-state-2026"  # must be unique

  tags = {
    Name      = "Terraform State"
    ManagedBy = "Terraform"
  }
}

# Enable versioning on state bucket (so you can roll back)
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access to state bucket
resource "aws_s3_bucket_public_access_block" "state_block" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "Terraform State Locks"
    ManagedBy = "Terraform"
  }
}
```

```bash
terraform init && terraform apply
```

### Step 2: Use the remote backend in a project

```bash
mkdir -p ~/terraform-labs/04-remote-state
cd ~/terraform-labs/04-remote-state
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

  backend "s3" {
    bucket         = "ed-terraform-state-2026"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}
```

```bash
terraform init   # will migrate state to S3
terraform apply
```

Now your state is safe, shared, and locked against concurrent changes.

---

## 🔬 Lab 3 — State Commands (Important!)

```bash
# List all resources
terraform state list

# Show details of one resource
terraform state show aws_s3_bucket.lab_bucket

# Move a resource (rename without destroying)
terraform state mv aws_s3_bucket.lab_bucket aws_s3_bucket.main_bucket

# Remove from state (stops managing, doesn't destroy)
terraform state rm aws_s3_bucket.main_bucket

# Pull remote state to local file
terraform state pull > backup.tfstate

# Push local state to remote (use with caution)
terraform state push backup.tfstate
```

---

## 🔬 Lab 4 — Import Existing Resources

If someone created a resource manually (not via Terraform), you can import it:

```bash
# First, write the resource block in your config
# Then import the real resource into state

terraform import aws_s3_bucket.existing_bucket my-existing-bucket-name
```

After import, run `terraform plan` — if it shows no changes, your config matches reality.

---

## 🔬 Lab 5 — Terraform Refresh

Refreshes state to match actual infrastructure (if someone made manual changes):

```bash
terraform refresh    # updates state file
terraform plan       # now shows drift between config and reality
```

---

## 🧪 Challenge

1. Set up the S3 + DynamoDB backend infrastructure
2. Create a new project that uses the remote backend
3. Apply a simple resource (S3 bucket or local file)
4. Run `terraform state list` to confirm state is in S3
5. Try `terraform state show` on your resource

---

## 📚 Key Takeaways

| Concept | What to Remember |
|---------|-----------------|
| `terraform.tfstate` | Terraform's memory — never edit manually |
| Remote backend | Store state in S3 — required for teams |
| DynamoDB lock | Prevents two people applying at once |
| `terraform state list` | See what Terraform is managing |
| `terraform state mv` | Rename a resource without destroying it |
| `terraform state rm` | Stop managing a resource (no destroy) |
| `terraform import` | Bring existing resources under management |

---

## ➡️ Next Lab

`05-modules.md` — Stop copy-pasting. Build reusable infrastructure modules.

---

*Lab created: 2026-04-07 | Terraform Series*
