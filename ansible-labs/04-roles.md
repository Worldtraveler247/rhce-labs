# 04 - Roles — Organized, Reusable Playbooks

**Series:** RHCE Ansible Labs  
**Lab:** 04 | **Prereq:** 03-handlers-and-templates.md  
**Goal:** Stop writing monolithic playbooks. Use roles to organize tasks into reusable, shareable units.

---

## 🧠 What Is a Role?

A role is a **structured directory** that groups related tasks, variables, templates, and handlers. Instead of one 300-line playbook, you have clean, reusable components.

### Role Directory Structure

```
roles/
  webserver/
    tasks/
      main.yml       ← tasks go here
    handlers/
      main.yml       ← handlers go here
    templates/
      nginx.conf.j2  ← templates go here
    files/
      index.html     ← static files go here
    vars/
      main.yml       ← role-specific variables
    defaults/
      main.yml       ← default variables (lowest priority)
    meta/
      main.yml       ← role metadata, dependencies
```

Ansible automatically loads each `main.yml` when the role is called.

---

## 🔬 Lab 1 — Create Your First Role

```bash
cd ~/ansible-practice
ansible-galaxy role init roles/common
ls roles/common/
```

`ansible-galaxy role init` creates the full skeleton automatically.

### roles/common/tasks/main.yml

```bash
nano roles/common/tasks/main.yml
```

```yaml
---
- name: Print system info
  debug:
    msg: "Running on {{ ansible_hostname }} ({{ ansible_os_family }})"

- name: Create standard directories
  file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
  loop: "{{ common_directories }}"

- name: Create a welcome file
  template:
    src: welcome.txt.j2
    dest: /tmp/welcome.txt
```

### roles/common/defaults/main.yml

```bash
nano roles/common/defaults/main.yml
```

```yaml
---
common_directories:
  - /tmp/ansible-app
  - /tmp/ansible-logs
  - /tmp/ansible-config

common_owner: "ansible"
```

### roles/common/templates/welcome.txt.j2

```bash
nano roles/common/templates/welcome.txt.j2
```

```jinja2
Welcome to {{ ansible_hostname }}
====================================
OS Family   : {{ ansible_os_family }}
Date        : {{ ansible_date_time.date }}
Managed by  : Ansible
Owner       : {{ common_owner }}
```

### Call the role from a playbook

```bash
nano 04-use-roles.yml
```

```yaml
---
- name: Apply Common Role
  hosts: localhost
  connection: local
  roles:
    - common
```

```bash
ansible-playbook 04-use-roles.yml
cat /tmp/welcome.txt
```

---

## 🔬 Lab 2 — Role with Handlers

### roles/webserver/tasks/main.yml

```bash
ansible-galaxy role init roles/webserver
nano roles/webserver/tasks/main.yml
```

```yaml
---
- name: Create web root directory
  file:
    path: "{{ web_root }}"
    state: directory
    mode: '0755'

- name: Deploy index page
  template:
    src: index.html.j2
    dest: "{{ web_root }}/index.html"
  notify: web content updated

- name: Deploy nginx config
  template:
    src: nginx.conf.j2
    dest: /tmp/nginx-{{ app_name }}.conf
  notify: nginx config changed
```

### roles/webserver/handlers/main.yml

```bash
nano roles/webserver/handlers/main.yml
```

```yaml
---
- name: web content updated
  debug:
    msg: "Handler: Web content was updated, reloading..."

- name: nginx config changed
  debug:
    msg: "Handler: nginx config changed, would restart nginx"
```

### roles/webserver/defaults/main.yml

```bash
nano roles/webserver/defaults/main.yml
```

```yaml
---
app_name: "myapp"
web_root: "/tmp/webroot"
server_name: "localhost"
server_port: 80
```

### roles/webserver/templates/index.html.j2

```bash
nano roles/webserver/templates/index.html.j2
```

```jinja2
<!DOCTYPE html>
<html>
<head><title>{{ app_name }}</title></head>
<body>
  <h1>{{ app_name }}</h1>
  <p>Deployed by Ansible on {{ ansible_date_time.date }}</p>
  <p>Host: {{ ansible_hostname }}</p>
</body>
</html>
```

### Apply both roles

```bash
nano 04-multi-roles.yml
```

```yaml
---
- name: Full Stack Setup
  hosts: localhost
  connection: local
  roles:
    - common
    - webserver
```

```bash
ansible-playbook 04-multi-roles.yml
cat /tmp/webroot/index.html
```

---

## 🔬 Lab 3 — Role Variables and Override

Roles have two variable files:
- `defaults/main.yml` — lowest priority, easy to override
- `vars/main.yml` — higher priority, harder to override

```yaml
# Override defaults in your playbook:
- name: Deploy custom app
  hosts: localhost
  connection: local
  roles:
    - role: webserver
      vars:
        app_name: "mystore"
        server_port: 8443
        web_root: "/tmp/store"
```

---

## 🔬 Lab 4 — Role Dependencies

Roles can depend on other roles. Declare in `meta/main.yml`:

```bash
nano roles/webserver/meta/main.yml
```

```yaml
---
galaxy_info:
  author: ed
  description: Webserver role
  license: MIT

dependencies:
  - role: common    # common always runs first
```

Now whenever `webserver` is called, `common` runs automatically first.

---

## 🔬 Lab 5 — Ansible Galaxy (Public Roles)

Install community roles instead of writing your own:

```bash
# Search for roles
ansible-galaxy search nginx

# Install a role
ansible-galaxy install geerlingguy.nginx

# Install specific version
ansible-galaxy install geerlingguy.nginx,3.2.0

# Install from requirements file
ansible-galaxy install -r requirements.yml
```

`requirements.yml`:
```yaml
---
roles:
  - name: geerlingguy.nginx
    version: "3.2.0"
  - name: geerlingguy.postgresql
    version: "3.4.0"
```

```bash
# List installed roles
ansible-galaxy list
```

---

## 🔬 Lab 6 — Role Testing with --check

```bash
# Dry run — shows what WOULD happen without making changes
ansible-playbook 04-multi-roles.yml --check

# Dry run + diff — shows file content changes
ansible-playbook 04-multi-roles.yml --check --diff
```

Always use `--check --diff` before applying changes to production.

---

## 🧪 Challenge

Create a role called `database` that:
1. Creates a `/tmp/db-config` directory
2. Deploys a `database.conf` template with: `db_host`, `db_port`, `db_name`, `db_user` variables
3. Has a handler that prints "Database config reloaded"
4. Has sensible defaults for all variables
5. Call it from a playbook alongside the `common` role

---

## 📚 Key Takeaways

| Concept | What to Remember |
|---------|-----------------|
| Role = structured directory | Tasks, handlers, templates, vars all separated |
| `ansible-galaxy role init` | Creates role skeleton automatically |
| `defaults/main.yml` | Low-priority defaults — easy to override |
| `vars/main.yml` | High-priority vars — harder to override |
| `meta/main.yml` | Role dependencies declared here |
| `ansible-galaxy install` | Install community roles |
| `--check --diff` | Dry run — always do this before prod |

---

## ➡️ Next Lab

`05-inventory-and-groups.md` — Manage multiple hosts, groups, and host variables.

---

*Lab created: 2026-04-07 | RHCE Ansible Series*
