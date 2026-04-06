# 00 - Introduction to Terraform

**Series:** Terraform Labs (Beginner → Expert)  
**Lab:** 00 | **Prereq:** None  
**Goal:** Understand what Terraform is, how it thinks, and get your environment ready.

---

## 🧠 What Is Terraform?

Terraform is an **Infrastructure as Code (IaC)** tool by HashiCorp. Instead of clicking through cloud dashboards to create servers, networks, and databases — you **write code** that describes your infrastructure, and Terraform builds it for you.

### Why Does This Matter?
- **Repeatable** — run the same code 100 times, get the same result
- **Version controlled** — your infrastructure lives in Git like any other code
- **Cloud agnostic** — same tool works on AWS, Azure, GCP, and 1000+ providers
- **Destroyable** — tear down everything cleanly with one command
- **RHCE/Cloud Security relevance** — IaC is a core skill for any cloud security engineer

---

## 🔄 How Terraform Thinks

Terraform follows a simple mental model:

```
Write → Plan → Apply → Destroy
```

| Step | Command | What Happens |
|------|---------|--------------|
| Write | (edit .tf files) | You describe desired infrastructure |
| Init | `terraform init` | Downloads required providers/plugins |
| Plan | `terraform plan` | Shows what WILL happen — no changes yet |
| Apply | `terraform apply` | Actually builds the infrastructure |
| Destroy | `terraform destroy` | Tears everything down cleanly |

**The golden rule:** Terraform compares your **desired state** (your code) against the **actual state** (what exists) and figures out what needs to change. This is called **declarative** infrastructure.

---

## 📁 Key Files

| File | Purpose |
|------|---------|
| `main.tf` | Main configuration — resources go here |
| `variables.tf` | Input variable definitions |
| `outputs.tf` | Values to display after apply |
| `terraform.tfvars` | Variable values (like a config file) |
| `providers.tf` | Provider configuration (AWS, Azure, etc.) |
| `terraform.tfstate` | **State file** — Terraform's memory (never edit manually) |
| `.terraform/` | Downloaded providers (auto-generated, don't commit) |

---

## 🛠️ Environment Setup

### Verify installation
```bash
terraform version
```

### Install tfenv (version manager — recommended)
```bash
brew install tfenv
tfenv list-remote   # see available versions
tfenv install latest
tfenv use latest
```

### VS Code extension (optional but helpful)
```
HashiCorp Terraform (by HashiCorp)
```
Gives you syntax highlighting and autocomplete for `.tf` files.

### Set up your workspace
```bash
mkdir -p ~/terraform-labs
cd ~/terraform-labs
```

---

## 📚 The Lab Series

| Lab | Topic | Level |
|-----|-------|-------|
| 00 | Introduction + Setup | Beginner |
| 01 | Your First Resource (local file) | Beginner |
| 02 | Variables and Outputs | Beginner |
| 03 | Providers — AWS basics | Beginner |
| 04 | State Management | Intermediate |
| 05 | Modules — Reusable Infrastructure | Intermediate |
| 06 | Remote State + S3 Backend | Intermediate |
| 07 | Workspaces — Dev/Staging/Prod | Intermediate |
| 08 | Terraform + Ansible together | Advanced |
| 09 | Security — IAM, secrets, vault | Advanced |
| 10 | CI/CD with Terraform (GitHub Actions) | Expert |
| 11 | Full Project — Production VPC | Expert |

---

## ➡️ Next Lab

`01-first-resource.md` — Write your first Terraform config and apply it locally (no cloud account needed).

---

*Lab created: 2026-04-07 | Terraform Series*
