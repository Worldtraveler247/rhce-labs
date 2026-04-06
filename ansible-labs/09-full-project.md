# 09 - Full Project: Production Web Stack

**Series:** RHCE Ansible Labs  
**Lab:** 09 | **Prereq:** All previous labs  
**Goal:** Bring everything together — roles, vault, templates, handlers, error handling — to deploy a real web stack.

---

## 🏗️ What We're Building

A fully automated LEMP stack deployment:
- **L**inux (RHEL/Amazon Linux)
- **N**ginx (web server)
- **M**ySQL/MariaDB (database)
- **P**HP (application runtime)

With:
- Ansible Vault for secrets
- Jinja2 templates for configs
- Handlers for service management
- Roles for organization
- Error handling with block/rescue
- Rolling deployment support

---

## 📁 Project Structure

```
~/ansible-practice/full-project/
  site.yml                    ← master playbook
  ansible.cfg
  inventory/
    production.yml
    staging.yml
    group_vars/
      all/
        vars.yml
        vault.yml             ← encrypted secrets
      webservers.yml
      databases.yml
    host_vars/
      web01.yml
  roles/
    common/
    nginx/
    php/
    mariadb/
    app/
  templates/                  ← shared templates
```

---

## 🔬 Lab — Build It

### Step 1: Set up directory

```bash
mkdir -p ~/ansible-practice/full-project/{inventory/{group_vars/all,host_vars},roles,templates}
cd ~/ansible-practice/full-project
```

### Step 2: ansible.cfg

```bash
nano ansible.cfg
```

```ini
[defaults]
inventory       = inventory/
roles_path      = roles/
vault_password_file = ~/.vault_password
host_key_checking = False
retry_files_enabled = False

[ssh_connection]
pipelining = True
```

### Step 3: Inventory

```bash
nano inventory/production.yml
```

```yaml
---
all:
  children:
    webservers:
      hosts:
        web01:
          ansible_connection: local    # using local for lab
          nginx_port: 80
          php_version: "8.1"
        web02:
          ansible_connection: local
          nginx_port: 8080
          php_version: "8.1"

    databases:
      hosts:
        db01:
          ansible_connection: local
          mysql_port: 3306
          is_primary: true
```

### Step 4: Group Variables

```bash
nano inventory/group_vars/all/vars.yml
```

```yaml
---
# App config
app_name: "mywebapp"
app_version: "2.1.0"
app_user: "www-data"
deploy_dir: "/var/www/{{ app_name }}"

# Database config
db_name: "{{ app_name }}_db"
db_user: "{{ app_name }}_user"
db_password: "{{ vault_db_password }}"   # ← references vault variable

# Common
timezone: "Asia/Tokyo"
ntp_servers:
  - "0.pool.ntp.org"
  - "1.pool.ntp.org"
```

```bash
# Create encrypted vault file
ansible-vault create inventory/group_vars/all/vault.yml
```

```yaml
# Inside vault.yml (will be encrypted):
---
vault_db_password: "Pr0duct!onP@ssw0rd"
vault_db_root_password: "R00tS3cur3P@ss"
vault_app_secret_key: "django-secret-key-here"
```

### Step 5: Create Roles

```bash
cd roles
ansible-galaxy role init common
ansible-galaxy role init nginx
ansible-galaxy role init mariadb
ansible-galaxy role init app
```

### Step 6: Common Role

```bash
nano roles/common/tasks/main.yml
```

```yaml
---
- name: Set hostname
  hostname:
    name: "{{ inventory_hostname }}"
  when: ansible_connection != 'local'

- name: Create application user
  user:
    name: "{{ app_user }}"
    system: true
    shell: /sbin/nologin
    create_home: false
  ignore_errors: true    # may already exist

- name: Create required directories
  file:
    path: "{{ item }}"
    state: directory
    owner: "{{ app_user }}"
    mode: '0755'
  loop:
    - "{{ deploy_dir }}"
    - "{{ deploy_dir }}/releases"
    - "{{ deploy_dir }}/shared"
    - "/var/log/{{ app_name }}"

- name: Deploy common config
  template:
    src: app-common.conf.j2
    dest: "/tmp/{{ app_name }}-common.conf"
    mode: '0644'
```

```bash
nano roles/common/templates/app-common.conf.j2
```

```jinja2
# {{ app_name }} Common Configuration
# Generated: {{ ansible_date_time.iso8601 }}
# Host: {{ inventory_hostname }}

[app]
name     = {{ app_name }}
version  = {{ app_version }}
user     = {{ app_user }}
timezone = {{ timezone }}

[directories]
deploy   = {{ deploy_dir }}
logs     = /var/log/{{ app_name }}
```

### Step 7: Nginx Role

```bash
nano roles/nginx/tasks/main.yml
```

```yaml
---
- name: Install nginx
  package:
    name: nginx
    state: present
  notify: start nginx
  ignore_errors: true    # may not be available in local mode

- name: Deploy nginx configuration
  template:
    src: nginx.conf.j2
    dest: /tmp/nginx-{{ inventory_hostname }}.conf
    mode: '0644'
  notify: reload nginx

- name: Deploy virtual host config
  template:
    src: vhost.conf.j2
    dest: "/tmp/nginx-vhost-{{ app_name }}.conf"
    mode: '0644'
  notify: reload nginx
```

```bash
nano roles/nginx/handlers/main.yml
```

```yaml
---
- name: start nginx
  debug:
    msg: "Would start nginx service"

- name: reload nginx
  debug:
    msg: "Would reload nginx (config changed)"

- name: restart nginx
  debug:
    msg: "Would restart nginx"
```

```bash
nano roles/nginx/defaults/main.yml
```

```yaml
---
nginx_worker_processes: auto
nginx_worker_connections: 1024
nginx_keepalive_timeout: 65
nginx_client_max_body_size: "10m"
```

```bash
nano roles/nginx/templates/vhost.conf.j2
```

```jinja2
server {
    listen {{ nginx_port | default(80) }};
    server_name {{ inventory_hostname }};

    root {{ deploy_dir }}/current/public;
    index index.php index.html;

    access_log /var/log/{{ app_name }}/access.log;
    error_log  /var/log/{{ app_name }}/error.log;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php{{ php_version }}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
    }

    {% if enable_ssl | default(false) %}
    # SSL Configuration
    listen 443 ssl;
    ssl_certificate     /etc/ssl/certs/{{ app_name }}.crt;
    ssl_certificate_key /etc/ssl/private/{{ app_name }}.key;
    {% endif %}
}
```

### Step 8: MariaDB Role

```bash
nano roles/mariadb/tasks/main.yml
```

```yaml
---
- name: Simulate MariaDB install
  debug:
    msg: "Would install MariaDB {{ mariadb_version }}"

- name: Simulate database creation
  debug:
    msg: "Would create database: {{ db_name }}"

- name: Simulate user creation
  debug:
    msg: "Would create user: {{ db_user }} (password from vault)"
  no_log: true    # ← suppresses output for sensitive tasks

- name: Deploy MariaDB config
  template:
    src: my.cnf.j2
    dest: /tmp/mariadb-{{ inventory_hostname }}.cnf
```

```bash
nano roles/mariadb/defaults/main.yml
```

```yaml
---
mariadb_version: "10.11"
mariadb_max_connections: 150
mariadb_innodb_buffer_pool_size: "256M"
```

### Step 9: Master Playbook

```bash
cd ~/ansible-practice/full-project
nano site.yml
```

```yaml
---
# ============================================================
# FULL PROJECT — Production Web Stack
# Usage: ansible-playbook site.yml
# ============================================================

# Common setup — all hosts
- name: Common Configuration
  hosts: all
  become: false    # local mode doesn't need sudo
  roles:
    - common

# Web server configuration
- name: Web Server Deployment
  hosts: webservers
  serial: 1         # rolling update
  become: false

  pre_tasks:
    - name: Pre-flight — announce deployment
      debug:
        msg: "Deploying {{ app_name }} v{{ app_version }} to {{ inventory_hostname }}"

  roles:
    - nginx

  post_tasks:
    - name: Post-flight — verify config generated
      stat:
        path: "/tmp/nginx-vhost-{{ app_name }}.conf"
      register: vhost_check

    - name: Confirm config exists
      debug:
        msg: "✅ Vhost config generated: {{ vhost_check.stat.path }}"
      when: vhost_check.stat.exists

    - name: Fail if config missing
      fail:
        msg: "❌ Vhost config was not created!"
      when: not vhost_check.stat.exists

# Database configuration
- name: Database Configuration
  hosts: databases
  become: false

  roles:
    - mariadb
```

### Step 10: Run it!

```bash
cd ~/ansible-practice/full-project

# Syntax check
ansible-playbook site.yml --syntax-check

# Dry run
ansible-playbook site.yml --check

# Deploy
ansible-playbook site.yml

# Deploy with verbose output
ansible-playbook site.yml -v

# Deploy only nginx tasks
ansible-playbook site.yml --tags nginx

# Deploy to one host only
ansible-playbook site.yml --limit web01
```

---

## ✅ What You Built

- Multi-role playbook with `common`, `nginx`, `mariadb`
- Ansible Vault for secrets
- Jinja2 templates for all configs
- Handlers for service management
- `no_log: true` for sensitive tasks
- Rolling deployment with `serial: 1`
- Pre/post tasks for deployment verification
- `--check`, `--tags`, `--limit` workflow

---

## 🎓 You've Completed the Ansible Series

| Lab | Topic |
|-----|-------|
| 00 | Getting Started |
| 01 | Variables and Facts |
| 02 | Conditionals and Loops |
| 03 | Handlers and Templates |
| 04 | Roles |
| 05 | Inventory and Groups |
| 06 | Vault |
| 07 | Error Handling |
| 08 | Advanced Playbooks |
| **09** | **Full Production Project** ✅ |

**Next:** Take the RHCE exam. The exam is hands-on — you'll be writing playbooks under time pressure. Work through these labs until the patterns feel automatic.

---

*Lab created: 2026-04-07 | RHCE Ansible Series*
