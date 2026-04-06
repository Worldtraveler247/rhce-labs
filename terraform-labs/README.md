# Terraform Labs — Beginner to Expert

**Location:** `~/Documents/rhce/terraform-labs/`  
**Terraform version:** 1.14.7 (installed at `/opt/homebrew/bin/terraform`)  
**Goal:** Go from zero to production-grade Terraform

---

## Lab Series

| # | File | Topic | Level |
|---|------|-------|-------|
| 00 | `00-introduction.md` | What Terraform is, how it works, setup | Beginner |
| 01 | `01-first-resource.md` | First config, init/plan/apply/destroy | Beginner |
| 02 | `02-variables-and-outputs.md` | Variables, tfvars, outputs | Beginner |
| 03 | `03-aws-provider.md` | Connect to AWS, S3, EC2 | Beginner |
| 04 | `04-state-management.md` | State, remote backends, S3+DynamoDB | Intermediate |
| 05 | `05-modules.md` | Reusable modules | Intermediate |
| 06 | `06-workspaces.md` | Dev/staging/prod environments | Intermediate |
| 07 | `07-terraform-and-ansible.md` | Terraform + Ansible together | Advanced |
| 08 | `08-security.md` | IAM, secrets, tfsec | Advanced |
| 09 | `09-cicd.md` | GitHub Actions automation | Expert |
| 10 | `10-full-project.md` | Production VPC — the full stack | Expert |

---

## Start Here

```bash
cd ~/terraform-labs
terraform version   # verify install
open ~/Documents/rhce/terraform-labs/00-introduction.md
```

Labs 00-02 require no AWS account. Start there, come back for 03+ when ready.

---

*Created: 2026-04-07*
