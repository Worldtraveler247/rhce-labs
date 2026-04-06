# 01 - Your First Terraform Resource

**Series:** Terraform Labs  
**Lab:** 01 | **Prereq:** 00-introduction.md  
**Goal:** Write, plan, apply, and destroy your first Terraform config — no cloud account needed.

---

## 🧠 Concepts

We'll start with the **local provider** — it creates files on your machine. No AWS account, no cost, no risk. Perfect for learning the workflow.

### HCL — HashiCorp Configuration Language
Terraform configs are written in HCL. It looks like this:

```hcl
resource "resource_type" "resource_name" {
  argument = "value"
}
```

- `resource_type` — what you're creating (e.g., `local_file`, `aws_instance`)
- `resource_name` — your label for this resource (can be anything)
- Arguments inside `{}` — the settings for that resource

---

## 🔬 Lab 1 — Hello Terraform

### Step 1: Create your workspace

```bash
mkdir -p ~/terraform-labs/01-first-resource
cd ~/terraform-labs/01-first-resource
```

### Step 2: Create main.tf

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

resource "local_file" "hello" {
  filename = "${path.module}/hello.txt"
  content  = "Hello, Terraform! Written by Ed.\n"
}
```

**What this does:**
- `terraform {}` block — declares which providers we need
- `local_file` resource — creates a file on disk
- `${path.module}` — built-in reference to the current directory
- `content` — what goes inside the file

### Step 3: Initialize

```bash
terraform init
```

This downloads the `local` provider. You'll see a `.terraform/` directory appear.

```
Initializing provider plugins...
- Finding hashicorp/local versions matching "~> 2.0"...
- Installing hashicorp/local v2.x.x...
Terraform has been successfully initialized!
```

### Step 4: Plan

```bash
terraform plan
```

Terraform shows you exactly what it WILL do — nothing is created yet:

```
Terraform will perform the following actions:

  # local_file.hello will be created
  + resource "local_file" "hello" {
      + content  = "Hello, Terraform! Written by Ed.\n"
      + filename = "./hello.txt"
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

✅ Always review the plan before applying. This is your safety check.

### Step 5: Apply

```bash
terraform apply
```

Type `yes` when prompted. Then check:

```bash
cat hello.txt
```

You should see:
```
Hello, Terraform! Written by Ed.
```

### Step 6: Look at the state file

```bash
cat terraform.tfstate
```

This is Terraform's memory — it tracks everything it created. **Never edit this manually.**

### Step 7: Modify and re-apply

Change the content in `main.tf`:

```hcl
content = "Hello, Terraform! Updated by Ed.\n"
```

Run plan again:

```bash
terraform plan
```

Notice Terraform shows:
```
~ resource "local_file" "hello" {
    ~ content = "Hello, Terraform! Written by Ed.\n" -> "Hello, Terraform! Updated by Ed.\n"
  }

Plan: 0 to add, 1 to change, 0 to destroy.
```

Apply it:
```bash
terraform apply
```

### Step 8: Destroy

```bash
terraform destroy
```

Type `yes`. The file is deleted. Check:

```bash
ls hello.txt  # should be gone
```

---

## 🔬 Lab 2 — Multiple Resources

```bash
nano main.tf
```

Replace contents with:

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "config" {
  filename = "${path.module}/config.txt"
  content  = "environment = production\nowner = ed\n"
}

resource "local_file" "readme" {
  filename = "${path.module}/README.txt"
  content  = "This infrastructure was created by Terraform.\n"
}
```

```bash
terraform apply
ls *.txt
```

Two files created in one apply. Terraform manages them both.

---

## 🔬 Lab 3 — Terraform fmt and validate

Two commands you should always run before applying:

```bash
# Auto-format your .tf files (fixes indentation, spacing)
terraform fmt

# Check for syntax errors
terraform validate
```

Try breaking something on purpose — add a typo to main.tf, then run `terraform validate` to see the error message.

---

## 🧪 Challenge

Create a new directory `~/terraform-labs/01-challenge/` with a `main.tf` that:

1. Creates a file called `my-servers.txt`
2. Content should list 3 fake server names (one per line)
3. Run `fmt`, `validate`, `plan`, and `apply`
4. Verify the file was created with `cat`

---

## 📚 Key Takeaways

| Concept | What to Remember |
|---------|-----------------|
| `terraform init` | Always first — downloads providers |
| `terraform plan` | Preview changes — no risk |
| `terraform apply` | Execute the plan |
| `terraform destroy` | Tear it all down |
| `terraform fmt` | Auto-format your code |
| `terraform validate` | Check for syntax errors |
| `terraform.tfstate` | Terraform's memory — don't touch |
| HCL syntax | `resource "type" "name" { }` |

---

## ➡️ Next Lab

`02-variables-and-outputs.md` — Stop hardcoding values. Use variables to make configs reusable.

---

*Lab created: 2026-04-07 | Terraform Series*
