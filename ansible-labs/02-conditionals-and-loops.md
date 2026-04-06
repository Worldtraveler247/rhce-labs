# 02 - Conditionals and Loops

**Series:** RHCE Ansible Labs  
**Lab:** 02 | **Prereq:** 01-variables-and-facts.md  
**Goal:** Control which tasks run with `when:` and repeat tasks with `loop:`.

---

## 🧠 Concepts

### Conditionals (`when:`)
Run a task only when a condition is true:
```yaml
- name: Install on RedHat only
  package:
    name: httpd
    state: present
  when: ansible_os_family == "RedHat"
```

### Loops (`loop:`)
Repeat a task over a list:
```yaml
- name: Install multiple packages
  package:
    name: "{{ item }}"
    state: present
  loop:
    - git
    - curl
    - vim
```

---

## 🔬 Lab 1 — Basic Conditionals

```bash
cd ~/ansible-practice
nano 02/conditionals.yml
```

```yaml
---
- name: Conditionals Lab
  hosts: localhost
  connection: local

  vars:
    install_tools: true
    environment: "dev"
    max_connections: 100

  tasks:
    - name: Run only when install_tools is true
      debug:
        msg: "Installing dev tools..."
      when: install_tools

    - name: Run only in dev environment
      debug:
        msg: "Dev mode is ON — verbose logging enabled"
      when: environment == "dev"

    - name: Warn on high connections
      debug:
        msg: "WARNING: High connection count!"
      when: max_connections > 50

    - name: Run only on macOS
      debug:
        msg: "You are on macOS"
      when: ansible_os_family == "Darwin"

    - name: Run only on Linux
      debug:
        msg: "You are on Linux"
      when: ansible_system == "Linux"
```

```bash
ansible-playbook 02/conditionals.yml
```

Notice tasks that don't match show `skipping` — they're not errors, just skipped.

---

## 🔬 Lab 2 — Multiple Conditions

```yaml
---
- name: Multiple Conditions Lab
  hosts: localhost
  connection: local

  vars:
    environment: "prod"
    app_version: "2.1"
    deploy_enabled: true

  tasks:
    # AND — both must be true
    - name: Deploy only in prod AND when enabled
      debug:
        msg: "Deploying to production!"
      when:
        - environment == "prod"
        - deploy_enabled == true

    # OR — either can be true
    - name: Run in dev OR staging
      debug:
        msg: "Running in lower environment"
      when: environment == "dev" or environment == "staging"

    # NOT
    - name: Skip in production
      debug:
        msg: "Not in prod — safe to run"
      when: environment != "prod"

    # Check if variable is defined
    - name: Run only if app_version is defined
      debug:
        msg: "App version is {{ app_version }}"
      when: app_version is defined
```

```bash
nano 02/multi-conditions.yml
# paste the above, then:
ansible-playbook 02/multi-conditions.yml
```

---

## 🔬 Lab 3 — Basic Loops

```bash
nano 02/loops.yml
```

```yaml
---
- name: Loops Lab
  hosts: localhost
  connection: local

  tasks:
    - name: Print each item in a list
      debug:
        msg: "Processing: {{ item }}"
      loop:
        - apple
        - banana
        - cherry

    - name: Create multiple files
      file:
        path: "/tmp/ansible-{{ item }}.txt"
        state: touch
      loop:
        - file1
        - file2
        - file3

    - name: Verify files were created
      command: ls /tmp/ansible-*.txt
      register: file_list

    - name: Show created files
      debug:
        var: file_list.stdout_lines
```

```bash
ansible-playbook 02/loops.yml
```

---

## 🔬 Lab 4 — Loops with Dictionaries

```yaml
---
- name: Dict Loop Lab
  hosts: localhost
  connection: local

  tasks:
    - name: Print user info from dict list
      debug:
        msg: "User: {{ item.name }} | Role: {{ item.role }} | Active: {{ item.active }}"
      loop:
        - { name: "ed", role: "admin", active: true }
        - { name: "victor", role: "operator", active: true }
        - { name: "marcus", role: "viewer", active: false }

    - name: Only process active users
      debug:
        msg: "Active user: {{ item.name }}"
      loop:
        - { name: "ed", role: "admin", active: true }
        - { name: "victor", role: "operator", active: true }
        - { name: "marcus", role: "viewer", active: false }
      when: item.active
```

```bash
nano 02/dict-loops.yml
ansible-playbook 02/dict-loops.yml
```

---

## 🔬 Lab 5 — Loop Control (index, labels)

```yaml
---
- name: Loop Control Lab
  hosts: localhost
  connection: local

  tasks:
    - name: Loop with index
      debug:
        msg: "Item {{ ansible_loop.index }} of {{ ansible_loop.length }}: {{ item }}"
      loop:
        - alpha
        - beta
        - gamma
      loop_control:
        extended: true

    - name: Custom loop label (cleaner output)
      debug:
        msg: "Installing {{ item.name }} version {{ item.version }}"
      loop:
        - { name: "nginx", version: "1.24" }
        - { name: "postgresql", version: "15" }
        - { name: "redis", version: "7.2" }
      loop_control:
        label: "{{ item.name }}"   # shows item name instead of full dict in output
```

---

## 🔬 Lab 6 — Combining Loops and Conditionals

```yaml
---
- name: Loop + Conditional
  hosts: localhost
  connection: local

  tasks:
    - name: Process only enabled services
      debug:
        msg: "Would start: {{ item.name }}"
      loop:
        - { name: "httpd",      enabled: true }
        - { name: "mysqld",     enabled: false }
        - { name: "redis",      enabled: true }
        - { name: "memcached",  enabled: false }
      when: item.enabled
      loop_control:
        label: "{{ item.name }}"
```

---

## 🧪 Challenge

Write `02/challenge.yml` that:
1. Has a list of servers: `web01`, `web02`, `db01`, `db02`
2. Prints "Processing web server: web01" for items starting with "web"
3. Prints "Processing DB server: db01" for items starting with "db"

> Hint: `item.startswith('web')` works in Ansible `when:` conditions

---

## 📚 Key Takeaways

| Concept | What to Remember |
|---------|-----------------|
| `when: condition` | Skip task if false — shows `skipping` |
| Multiple `when:` lines | AND logic (all must be true) |
| `or` / `not` / `!=` | OR/NOT logic in when |
| `is defined` | Check if variable exists |
| `loop:` | Repeat task for each item |
| `item` | The loop variable — current item |
| `loop_control: label:` | Cleaner loop output |
| `when: item.key` | Filter loop items with conditions |

---

## ➡️ Next Lab

`03-handlers-and-templates.md` — Trigger actions on change with handlers, and generate config files with Jinja2 templates.

---

*Lab created: 2026-04-07 | RHCE Ansible Series*
