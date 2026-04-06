# Ansible Labs — Beginner to Expert (RHCE Path)

**Location:** `~/Documents/rhce/ansible-labs/`  
**Practice files:** `~/ansible-practice/`  
**Goal:** Go from zero to RHCE-ready with Ansible

---

## Lab Series

| # | File | Topic | Level | Practice Files |
|---|------|-------|-------|---------------|
| 00 | `00-getting-started.md` | Install, first ad-hoc commands | Beginner | `first-playbook.yml` |
| 01 | `01-variables-and-facts.md` | Variables, facts, register | Beginner | `01-variables.yml`, `01-facts.yml`, `01-register.yml`, `01-vars-file.yml` |
| 02 | `02-conditionals-and-loops.md` | when:, loop:, dict loops | Beginner | `02/` directory |
| 03 | `03-handlers-and-templates.md` | Handlers, Jinja2 templates, filters | Intermediate | `03/` + `templates/` |
| 04 | `04-roles.md` | Role structure, galaxy, dependencies | Intermediate | `roles/` |
| 05 | `05-inventory-and-groups.md` | Groups, group_vars, dynamic inventory | Intermediate | `05/` |
| 06 | `06-vault.md` | Encrypt secrets with Vault | Intermediate | `06/` |
| 07 | `07-error-handling.md` | ignore_errors, block/rescue, debug | Advanced | `07/` |
| 08 | `08-advanced-playbooks.md` | Serial, delegation, async, rolling | Advanced | `08/` |
| 09 | `09-full-project.md` | Full LEMP stack — everything together | Expert | `full-project/` |

---

## Quick Start

```bash
# Verify Ansible is installed
ansible --version

# Run your first playbook
cd ~/ansible-practice
ansible-playbook first-playbook.yml

# Start Lab 01
ansible-playbook 01-variables.yml
```

---

## RHCE Exam Focus Areas

The RHCE exam tests these heavily — make sure you know them cold:

1. ✅ Variables, facts, and `register`
2. ✅ `when:` conditionals and `loop:`
3. ✅ Handlers and Jinja2 templates
4. ✅ Roles — write and use them
5. ✅ Inventory — groups, group_vars, host_vars
6. ✅ Ansible Vault — encrypt and use secrets
7. ✅ Error handling — block/rescue/always
8. ✅ `--check --diff` — always verify before applying

---

*Created: 2026-04-07*
