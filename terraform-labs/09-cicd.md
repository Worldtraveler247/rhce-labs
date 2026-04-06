# 09 - CI/CD with Terraform (GitHub Actions)

**Series:** Terraform Labs  
**Lab:** 09 | **Prereq:** 08-security.md  
**Goal:** Automate Terraform with GitHub Actions — plan on PR, apply on merge to main.

---

## 🧠 The Workflow

```
Developer pushes code
       ↓
PR opened → GitHub Actions runs terraform plan
       ↓
Team reviews plan output in PR comments
       ↓
PR merged to main → GitHub Actions runs terraform apply
       ↓
Infrastructure updated automatically
```

This is how real teams manage infrastructure — no one runs `terraform apply` from their laptop in production.

---

## 🔬 Lab 1 — Repository Setup

### Directory structure

```
my-terraform-project/
  .github/
    workflows/
      terraform.yml
  environments/
    dev/
      main.tf
      variables.tf
      outputs.tf
      terraform.tfvars
    prod/
      main.tf
      variables.tf
      outputs.tf
      terraform.tfvars
  modules/
    s3-bucket/
      main.tf
      variables.tf
      outputs.tf
  .gitignore
  README.md
```

### .gitignore

```
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
crash.log
*.tfvars        # keep out of git — use GitHub Secrets instead
```

---

## 🔬 Lab 2 — GitHub Actions Workflow

```bash
mkdir -p .github/workflows
nano .github/workflows/terraform.yml
```

```yaml
name: Terraform CI/CD

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

env:
  TF_VERSION: "1.14.7"
  WORKING_DIR: "./environments/dev"

permissions:
  contents: read
  pull-requests: write   # needed to post plan to PR comments

jobs:
  terraform:
    name: Terraform Plan & Apply
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ env.WORKING_DIR }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region:            us-east-1

      - name: Terraform Init
        id: init
        run: terraform init

      - name: Terraform Format Check
        id: fmt
        run: terraform fmt -check
        continue-on-error: true

      - name: Terraform Validate
        id: validate
        run: terraform validate

      - name: Terraform Plan
        id: plan
        run: terraform plan -no-color -out=tfplan
        continue-on-error: true

      # Post plan output as a PR comment
      - name: Comment Plan on PR
        uses: actions/github-script@v7
        if: github.event_name == 'pull_request'
        with:
          script: |
            const output = `#### Terraform Format 🖌 \`${{ steps.fmt.outcome }}\`
            #### Terraform Init ⚙️ \`${{ steps.init.outcome }}\`
            #### Terraform Validate 🤖 \`${{ steps.validate.outcome }}\`
            #### Terraform Plan 📖 \`${{ steps.plan.outcome }}\`

            <details><summary>Show Plan</summary>

            \`\`\`terraform
            ${{ steps.plan.outputs.stdout }}
            \`\`\`

            </details>

            *Pushed by: @${{ github.actor }}, Action: \`${{ github.event_name }}\`*`;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })

      # Only apply on push to main (not on PR)
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve tfplan
```

---

## 🔬 Lab 3 — GitHub Secrets Setup

In your repo: **Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Your IAM access key |
| `AWS_SECRET_ACCESS_KEY` | Your IAM secret key |

These are injected as environment variables during the workflow run — never stored in your code.

---

## 🔬 Lab 4 — Advanced: Environment Protection Rules

For production, add required approvals before apply:

**Settings → Environments → New environment → prod**
- Required reviewers: add yourself or team
- Wait timer: 5 minutes (gives time to cancel)

Update workflow to use environment:

```yaml
  - name: Terraform Apply (Production)
    if: github.ref == 'refs/heads/main'
    environment: prod    # ← triggers approval gate
    run: terraform apply -auto-approve tfplan
```

Now production deploys require manual approval in GitHub before proceeding.

---

## 🔬 Lab 5 — tfsec in CI

Add security scanning to your pipeline:

```yaml
      - name: Run tfsec
        uses: aquasecurity/tfsec-action@v1.0.3
        with:
          working_directory: ${{ env.WORKING_DIR }}
```

Fails the pipeline if security issues are found — catches problems before they reach production.

---

## 🧪 Challenge

1. Create a GitHub repo for your Terraform labs
2. Add the `terraform.yml` workflow
3. Set up `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets
4. Create a PR with a simple change — verify the plan posts as a PR comment
5. Merge to main — verify apply runs automatically

---

## 📚 Key Takeaways

| Concept | What to Remember |
|---------|-----------------|
| Plan on PR | Review changes before they're applied |
| Apply on merge | Automate apply — no local `terraform apply` in prod |
| GitHub Secrets | Never put credentials in code or workflow files |
| Environment gates | Require approval for production |
| `tfsec` in CI | Block insecure configs automatically |
| `-no-color` flag | Required for clean CI output |

---

## ➡️ Next Lab

`10-full-project.md` — Bring it all together: production-grade VPC with public/private subnets, EC2, RDS, and full CI/CD.

---

*Lab created: 2026-04-07 | Terraform Series*
