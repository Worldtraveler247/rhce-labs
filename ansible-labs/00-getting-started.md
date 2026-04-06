# Ansible Lab 00 — Getting Started on macOS

## Goal
Install Ansible on your Mac and run your first command.

---

## Step 1: Install Ansible

Open Terminal and run:
```bash
brew install ansible
ansible --version
```

---

## Step 2: Your First Ansible Command (Ad-Hoc)

Test Ansible against localhost:
```bash
ansible localhost -m ping
ansible localhost -m command -a "uptime"
ansible localhost -m shell -a "df -h"
```

What just happened:
- `-m ping` — used the ping module (tests connectivity)
- `-m command` — ran a shell command
- `-a` — arguments passed to the module

---

## Step 3: Create Your Inventory File

```bash
mkdir ~/ansible-practice
cd ~/ansible-practice
cat > inventory.ini << EOF
[local]
localhost ansible_connection=local
EOF
```

Test it:
```bash
ansible -i inventory.ini local -m ping
```

---

## Step 4: Your First Playbook

```bash
cat > first-playbook.yml << EOF
---
- name: My first playbook
  hosts: localhost
  connection: local
  tasks:
    - name: Print a message
      debug:
        msg: "Ansible is working on {{ inventory_hostname }}"

    - name: Check disk space
      command: df -h
      register: disk_output

    - name: Show disk output
      debug:
        var: disk_output.stdout_lines
EOF
```

Run it:
```bash
ansible-playbook -i inventory.ini first-playbook.yml
```

---

## ✅ Checkpoint
You've installed Ansible, run ad-hoc commands, and written your first playbook.
Move on to `01-variables-and-facts.md` when ready.

## Key Concepts Learned
- **Module** — a reusable Ansible unit of work (ping, command, shell, debug)
- **Inventory** — list of hosts Ansible manages
- **Playbook** — YAML file defining automation tasks
- **Ad-hoc command** — one-off Ansible command without a playbook
