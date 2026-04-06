# 10 - Full Project: Production-Grade VPC

**Series:** Terraform Labs  
**Lab:** 10 | **Prereq:** All previous labs  
**Goal:** Build a complete, production-grade AWS environment — VPC, subnets, EC2, security groups, remote state, and CI/CD.

---

## 🏗️ What We're Building

```
                    Internet
                       |
               [Internet Gateway]
                       |
            ┌──────────┴──────────┐
            │      Public Subnet   │  (10.0.1.0/24)
            │   [Bastion Host]     │
            │   [Load Balancer]    │
            └──────────┬──────────┘
                       │
            ┌──────────┴──────────┐
            │      Private Subnet  │  (10.0.2.0/24)
            │   [App Servers]      │
            │   [RDS Database]     │
            └─────────────────────┘
```

This is a standard 2-tier architecture. Public subnet for edge traffic, private subnet for sensitive resources.

---

## 📁 Project Structure

```
prod-vpc/
  providers.tf
  variables.tf
  outputs.tf
  terraform.tfvars
  modules/
    networking/
      main.tf
      variables.tf
      outputs.tf
    security-groups/
      main.tf
      variables.tf
      outputs.tf
    compute/
      main.tf
      variables.tf
      outputs.tf
  .github/
    workflows/
      terraform.yml
```

---

## 🔬 Lab — Build It Step by Step

### Step 1: providers.tf

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "prod/vpc/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}
```

### Step 2: variables.tf

```hcl
variable "aws_region"    { type = string; default = "us-east-1" }
variable "project_name"  { type = string; default = "rhce-lab" }
variable "environment"   { type = string; default = "prod" }
variable "owner"         { type = string; default = "ed" }

variable "vpc_cidr"      { type = string; default = "10.0.0.0/16" }
variable "public_cidrs"  { type = list(string); default = ["10.0.1.0/24", "10.0.3.0/24"] }
variable "private_cidrs" { type = list(string); default = ["10.0.2.0/24", "10.0.4.0/24"] }

variable "instance_type" { type = string; default = "t2.micro" }
variable "key_name"      { type = string }
```

### Step 3: modules/networking/main.tf

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  count                   = length(var.public_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count             = length(var.private_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway — lets private subnet reach internet (one-way)
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
```

### Step 4: modules/security-groups/main.tf

```hcl
resource "aws_security_group" "bastion" {
  name        = "${var.project}-bastion-sg"
  description = "SSH access to bastion"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]   # your IP only
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app" {
  name        = "${var.project}-app-sg"
  description = "App server access"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]   # SSH only from bastion
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### Step 5: modules/compute/main.tf

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.bastion_sg_id]
}

resource "aws_instance" "app" {
  count                  = var.app_count
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  key_name               = var.key_name
  vpc_security_group_ids = [var.app_sg_id]
}
```

### Step 6: Root main.tf — wire it all together

```hcl
module "networking" {
  source        = "./modules/networking"
  vpc_cidr      = var.vpc_cidr
  public_cidrs  = var.public_cidrs
  private_cidrs = var.private_cidrs
}

module "security_groups" {
  source     = "./modules/security-groups"
  vpc_id     = module.networking.vpc_id
  project    = var.project_name
  admin_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}

data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

module "compute" {
  source            = "./modules/compute"
  instance_type     = var.instance_type
  key_name          = var.key_name
  public_subnet_id  = module.networking.public_subnet_ids[0]
  private_subnet_ids = module.networking.private_subnet_ids
  bastion_sg_id     = module.security_groups.bastion_sg_id
  app_sg_id         = module.security_groups.app_sg_id
  app_count         = 2
}
```

---

## 🏁 Deploy

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

---

## ✅ What You Built

- Multi-AZ VPC with public and private subnets
- Internet Gateway + NAT Gateway
- Bastion host (SSH jump server)
- App servers in private subnet
- Security groups with least-privilege access
- Remote state in S3 with DynamoDB locking
- Everything tagged, modular, and reusable

---

## 📚 What to Do Next

1. **Add RDS** — `aws_db_instance` in the private subnet
2. **Add ALB** — Application Load Balancer in front of app servers
3. **Add Route53** — DNS pointing to your ALB
4. **Add ACM** — SSL certificate for HTTPS
5. **Add CloudWatch** — monitoring and alerts
6. **Connect Ansible** — configure the app servers after Terraform provisions them
7. **Add to GitHub** — wire up the CI/CD pipeline from Lab 09

---

## 🎓 You've Completed the Terraform Series

| Lab | Topic |
|-----|-------|
| 00 | Introduction |
| 01 | First Resource |
| 02 | Variables & Outputs |
| 03 | AWS Provider |
| 04 | State Management |
| 05 | Modules |
| 06 | Workspaces |
| 07 | Terraform + Ansible |
| 08 | Security |
| 09 | CI/CD |
| **10** | **Full Production Project** ✅ |

**Next recommended path:** HashiCorp Terraform Associate certification (exam is well-aligned with what you just learned).

---

*Lab created: 2026-04-07 | Terraform Series*
