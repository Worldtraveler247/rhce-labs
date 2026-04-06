# 05 - Modules — Reusable Infrastructure

**Series:** Terraform Labs  
**Lab:** 05 | **Prereq:** 04-state-management.md  
**Goal:** Build reusable modules so you stop copy-pasting configs between environments.

---

## 🧠 What Are Modules?

A module is a **folder of .tf files** that you can call like a function. Instead of writing the same S3 bucket config in dev, staging, and prod — you write it once as a module and call it three times with different inputs.

```
modules/
  s3-bucket/
    main.tf       # the actual resources
    variables.tf  # inputs
    outputs.tf    # what it returns
```

Then in your root config:
```hcl
module "dev_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "my-dev-bucket"
  environment = "dev"
}
```

---

## 🔬 Lab 1 — Build Your First Module

### Structure

```bash
mkdir -p ~/terraform-labs/05-modules/modules/local-file
cd ~/terraform-labs/05-modules
```

### modules/local-file/variables.tf

```bash
nano modules/local-file/variables.tf
```

```hcl
variable "filename" {
  type        = string
  description = "Name of the file to create"
}

variable "content" {
  type        = string
  description = "File content"
}

variable "environment" {
  type        = string
  description = "Environment label"
  default     = "dev"
}
```

### modules/local-file/main.tf

```bash
nano modules/local-file/main.tf
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

resource "local_file" "this" {
  filename = "${path.module}/../../output/${var.environment}-${var.filename}"
  content  = "# ${var.environment} environment\n${var.content}\n"
}
```

### modules/local-file/outputs.tf

```bash
nano modules/local-file/outputs.tf
```

```hcl
output "file_path" {
  value = local_file.this.filename
}
```

### Root main.tf — Call the module 3 times

```bash
mkdir -p output
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

module "dev_config" {
  source      = "./modules/local-file"
  filename    = "config.txt"
  content     = "debug=true\nlog_level=verbose"
  environment = "dev"
}

module "staging_config" {
  source      = "./modules/local-file"
  filename    = "config.txt"
  content     = "debug=false\nlog_level=info"
  environment = "staging"
}

module "prod_config" {
  source      = "./modules/local-file"
  filename    = "config.txt"
  content     = "debug=false\nlog_level=error"
  environment = "prod"
}
```

### outputs.tf (root)

```bash
nano outputs.tf
```

```hcl
output "dev_path"     { value = module.dev_config.file_path }
output "staging_path" { value = module.staging_config.file_path }
output "prod_path"    { value = module.prod_config.file_path }
```

```bash
terraform init
terraform apply
ls output/
```

Three files created from one module definition. This is the power of modules.

---

## 🔬 Lab 2 — Public Registry Modules

HashiCorp maintains a public registry of modules at [registry.terraform.io](https://registry.terraform.io). Instead of building everything yourself:

```hcl
# Use a community VPC module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
}
```

```bash
terraform init   # downloads the module
terraform plan
```

---

## 🔬 Lab 3 — Module Versioning

When using modules from a registry or Git, pin versions:

```hcl
# From Terraform Registry (pinned version)
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.0"    # pin exact version in production
}

# From Git (pinned to tag)
module "custom_module" {
  source = "git::https://github.com/myorg/terraform-modules.git//s3-bucket?ref=v1.2.0"
}

# From local path (development)
module "local_module" {
  source = "./modules/s3-bucket"
}
```

---

## 🔬 Lab 4 — Module Composition (Modules calling modules)

Modules can call other modules — this lets you build complex stacks:

```
modules/
  networking/    # creates VPC, subnets
  security/      # creates security groups
  application/   # creates EC2, calls networking + security
```

```hcl
# modules/application/main.tf
module "network" {
  source = "../networking"
  cidr   = var.vpc_cidr
}

module "sg" {
  source = "../security"
  vpc_id = module.network.vpc_id
}

resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = module.network.public_subnet_id
  vpc_security_group_ids = [module.sg.app_sg_id]
}
```

---

## 🧪 Challenge

Build a module called `modules/environment` that:
1. Takes inputs: `env_name`, `app_name`, `config_values` (map of strings)
2. Creates a file `{env_name}-{app_name}.conf` with all config values
3. Outputs the filename and number of config keys
4. Call it for `dev`, `staging`, and `prod` environments from root `main.tf`

---

## 📚 Key Takeaways

| Concept | What to Remember |
|---------|-----------------|
| Module = folder of .tf files | Any directory is a module |
| `source = "./path"` | Local module reference |
| `source = "registry/module"` | Public registry module |
| `version = "~> x.y"` | Always pin versions |
| `module.name.output` | Access module outputs |
| DRY principle | Write once, call many times |

---

## ➡️ Next Lab

`06-remote-state-and-workspaces.md` — Share state between projects and manage dev/staging/prod with workspaces.

---

*Lab created: 2026-04-07 | Terraform Series*
