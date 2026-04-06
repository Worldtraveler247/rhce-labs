# 05 - Inventory and Groups

**Series:** RHCE Ansible Labs  
**Lab:** 05 | **Prereq:** 04-roles.md  
**Goal:** Manage multiple hosts, groups, group variables, and dynamic inventory.

---

## 🧠 What Is Inventory?

Inventory tells Ansible **what to manage**. It lists hosts and groups them logically.

---

## 🔬 Lab 1 — Static Inventory (INI format)

```bash
nano ~/ansible-practice/05/inventory.ini
```

```ini
# Individual host
192.168.1.10

# Group of web servers
[webservers]
web01.example.com
web02.example.com
192.168.1.20 ansible_port=2222   # custom SSH port

# Group of database servers
[databases]
db01.example.com
db02.example.com

# Group of all app servers
[appservers]
web01.example.com
db01.example.com

# Group of groups (parent group)
[datacenter:children]
webservers
databases

# Group variables (applies to all in group)
[webservers:vars]
http_port=80
https_port=443
ansible_user=ec2-user

[databases:vars]
db_port=5432
ansible_user=dbadmin
```

---

## 🔬 Lab 2 — Static Inventory (YAML format — preferred)

```bash
nano ~/ansible-practice/05/inventory.yml
```

```yaml
---
all:
  children:
    webservers:
      hosts:
        web01:
          ansible_host: 192.168.1.10
          ansible_user: ec2-user
          http_port: 80
        web02:
          ansible_host: 192.168.1.11
          ansible_user: ec2-user
          http_port: 8080
      vars:
        server_role: web
        deploy_dir: /var/www/html

    databases:
      hosts:
        db01:
          ansible_host: 192.168.1.20
          ansible_user: dbadmin
          db_port: 5432
        db02:
          ansible_host: 192.168.1.21
          ansible_user: dbadmin
          db_port: 5432
      vars:
        server_role: database
        backup_enabled: true

    # Group of groups
    datacenter:
      children:
        webservers:
        databases:
```

---

## 🔬 Lab 3 — group_vars and host_vars

Instead of cramming variables into inventory, use dedicated variable files:

```bash
mkdir -p ~/ansible-practice/05/group_vars
mkdir -p ~/ansible-practice/05/host_vars
```

### group_vars/webservers.yml

```bash
nano ~/ansible-practice/05/group_vars/webservers.yml
```

```yaml
---
http_port: 80
https_port: 443
web_root: /var/www/html
worker_processes: 4
```

### group_vars/all.yml (applies to EVERY host)

```bash
nano ~/ansible-practice/05/group_vars/all.yml
```

```yaml
---
ansible_user: ec2-user
ntp_server: pool.ntp.org
timezone: Asia/Tokyo
deploy_user: deploy
log_retention_days: 30
```

### host_vars/web01.yml (specific to one host)

```bash
nano ~/ansible-practice/05/host_vars/web01.yml
```

```yaml
---
# Overrides for web01 specifically
http_port: 8080
is_primary: true
```

Ansible loads these automatically when it runs — no explicit reference needed.

---

## 🔬 Lab 4 — Targeting Groups in Playbooks

```bash
nano ~/ansible-practice/05/deploy.yml
```

```yaml
---
# Run on ALL hosts
- name: Common setup
  hosts: all
  tasks:
    - debug:
        msg: "Running on {{ inventory_hostname }}"

# Run only on web servers
- name: Web server setup
  hosts: webservers
  tasks:
    - debug:
        msg: "Web task on {{ inventory_hostname }}"

# Run on databases EXCEPT db02
- name: DB setup (skip db02)
  hosts: databases:!db02
  tasks:
    - debug:
        msg: "DB task on {{ inventory_hostname }}"

# Run on hosts in BOTH groups (intersection)
- name: Hosts in both groups
  hosts: webservers:&appservers
  tasks:
    - debug:
        msg: "In both groups: {{ inventory_hostname }}"
```

### Host patterns

```bash
# All hosts
ansible all -i inventory.yml -m ping

# Specific group
ansible webservers -i inventory.yml -m ping

# Specific host
ansible web01 -i inventory.yml -m ping

# Multiple groups
ansible webservers:databases -i inventory.yml -m ping

# Exclude a group
ansible all:!databases -i inventory.yml -m ping

# Wildcard
ansible web* -i inventory.yml -m ping
```

---

## 🔬 Lab 5 — Dynamic Inventory (AWS)

For cloud environments, hosts change constantly. Dynamic inventory queries the cloud in real time:

```bash
pip install boto3 botocore
ansible-galaxy collection install amazon.aws

nano ~/ansible-practice/05/aws_ec2.yml
```

```yaml
---
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  instance-state-name: running
  tag:Environment: production
keyed_groups:
  - key: tags.Role
    prefix: role
  - key: tags.Environment
    prefix: env
hostnames:
  - ip-address
```

```bash
# List dynamic inventory
ansible-inventory -i aws_ec2.yml --list
ansible-inventory -i aws_ec2.yml --graph

# Run playbook with dynamic inventory
ansible-playbook -i aws_ec2.yml deploy.yml
```

---

## 🔬 Lab 6 — Inventory with localhost (for practice)

Since you don't have remote hosts yet, simulate multiple hosts with localhost:

```bash
nano ~/ansible-practice/05/local-inventory.yml
```

```yaml
---
all:
  children:
    webservers:
      hosts:
        web_sim_01:
          ansible_connection: local
          http_port: 80
          server_type: nginx
        web_sim_02:
          ansible_connection: local
          http_port: 8080
          server_type: apache

    databases:
      hosts:
        db_sim_01:
          ansible_connection: local
          db_port: 5432
          db_engine: postgresql

  vars:
    ansible_python_interpreter: /usr/bin/python3
```

```bash
nano ~/ansible-practice/05/multi-host-sim.yml
```

```yaml
---
- name: Simulate multi-host deployment
  hosts: all
  gather_facts: false

  tasks:
    - name: Show host info
      debug:
        msg: "Host: {{ inventory_hostname }} | Group: {{ group_names }}"

- name: Configure web servers
  hosts: webservers
  gather_facts: false

  tasks:
    - name: Simulate web config
      debug:
        msg: "Configuring {{ server_type }} on port {{ http_port }}"

- name: Configure databases
  hosts: databases
  gather_facts: false

  tasks:
    - name: Simulate DB config
      debug:
        msg: "Setting up {{ db_engine }} on port {{ db_port }}"
```

```bash
ansible-playbook -i ~/ansible-practice/05/local-inventory.yml ~/ansible-practice/05/multi-host-sim.yml
```

---

## 🧪 Challenge

1. Create a YAML inventory with 3 groups: `frontend`, `backend`, `monitoring`
2. Add 2 simulated hosts per group (using `ansible_connection: local`)
3. Create `group_vars/all.yml` with shared variables
4. Create group-specific vars for each group
5. Write a playbook that prints different messages per group

---

## 📚 Key Takeaways

| Concept | What to Remember |
|---------|-----------------|
| Inventory = host list | INI or YAML format |
| `[group:children]` | Group of groups |
| `group_vars/` | Variables for a whole group |
| `host_vars/` | Variables for a specific host |
| `group_vars/all.yml` | Variables for every host |
| `hosts: webservers:!db02` | Exclude specific hosts |
| Dynamic inventory | Cloud-aware, queries AWS/GCP in real time |
| `ansible-inventory --graph` | Visualize your inventory |

---

## ➡️ Next Lab

`06-vault.md` — Encrypt secrets with Ansible Vault so passwords never appear in plaintext.

---

*Lab created: 2026-04-07 | RHCE Ansible Series*
