# 01 - Variables and Facts in Ansible

**Series:** RHCE Ansible Labs  
**Lab:** 01 | **Prereq:** 00-getting-started.md  
**Goal:** Understand how Ansible stores and uses data — variables you define and facts it discovers automatically.

---

## 🧠 Concepts First

### What Are Variables?
Variables let you store values and reuse them across tasks, plays, and roles. Instead of hardcoding things like package names, paths, or usernames — you define them once and reference them everywhere.

```yaml
# Instead of this:
name: "Install httpd"
  package:
    name: httpd

# You can do this:
vars:
  web_package: httpd

tasks:
  - name: Install web server
    package:
      name: "{{ web_package }}"
```

The `{{ }}` syntax is **Jinja2 templating** — that's how Ansible evaluates variables.

---

### What Are Facts?
Facts are variables that Ansible **automatically discovers** about your managed hosts when a play runs. Things like:
- IP addresses
- OS version
- CPU count
- Available memory
- Hostname

Ansible collects these via the `gather_facts` module (runs automatically at the start of every play unless you disable it).

---

## 🔬 Lab 1 — Define and Use Variables

### Step 1: Create the playbook

```bash
cd ~/ansible-practice
nano 01-variables.yml
```

Paste this in:

```yaml
---
- name: Variables Lab
  hosts: localhost
  connection: local

  vars:
    greeting: "Hello from Ansible"
    student_name: "Ed"
    favorite_distro: "RHEL"

  tasks:
    - name: Print greeting
      debug:
        msg: "{{ greeting }}, {{ student_name }}!"

    - name: Print favorite distro
      debug:
        msg: "Favorite distro: {{ favorite_distro }}"
```

### Step 2: Run it

```bash
ansible-playbook 01-variables.yml
```

**Expected output:**
```
TASK [Print greeting] ***
ok: [localhost] => {
    "msg": "Hello from Ansible, Ed!"
}

TASK [Print favorite distro] ***
ok: [localhost] => {
    "msg": "Favorite distro: RHEL"
}
```

✅ You just defined variables in a play and referenced them with `{{ }}`.

---

## 🔬 Lab 2 — Explore Ansible Facts

### Step 1: See ALL facts for your host

```bash
ansible localhost -m setup | less
```

This dumps every fact Ansible collects. Use `/` to search inside `less`. Try searching for `ansible_os` or `ansible_hostname`.

### Step 2: Use facts in a playbook

```bash
nano 01-facts.yml
```

```yaml
---
- name: Facts Lab
  hosts: localhost
  connection: local

  tasks:
    - name: Show hostname
      debug:
        msg: "This machine is: {{ ansible_hostname }}"

    - name: Show OS family
      debug:
        msg: "OS Family: {{ ansible_os_family }}"

    - name: Show total RAM
      debug:
        msg: "Total RAM: {{ ansible_memtotal_mb }} MB"

    - name: Show default IPv4 address
      debug:
        msg: "IP Address: {{ ansible_default_ipv4.address }}"
```

### Step 3: Run it

```bash
ansible-playbook 01-facts.yml
```

You'll see real system data pulled automatically — no manual input needed.

---

## 🔬 Lab 3 — Variable Precedence (Important!)

Ansible has **22 levels** of variable precedence. For the RHCE, you need to know the big ones (lowest → highest priority):

| Priority | Source |
|----------|--------|
| 1 (lowest) | Role defaults (`defaults/main.yml`) |
| 5 | Inventory variables |
| 10 | Playbook `vars:` block |
| 14 | `vars_files:` |
| 16 | `set_fact` / registered vars |
| 18 | Extra vars (`-e` flag) ← **always wins** |

### Test it — extra vars override playbook vars

```bash
ansible-playbook 01-variables.yml -e "student_name=Victor"
```

Even though `student_name` is defined as "Ed" in the playbook, `-e` overrides it.

---

## 🔬 Lab 4 — vars_files (Clean Separation)

Instead of jamming all vars into the playbook, store them in a separate file:

```bash
nano vars/app_config.yml
```

```yaml
---
app_name: myapp
app_port: 8080
app_owner: ed
```

Then reference it in your playbook:

```yaml
---
- name: Vars File Lab
  hosts: localhost
  connection: local
  vars_files:
    - vars/app_config.yml

  tasks:
    - name: Show app config
      debug:
        msg: "{{ app_name }} runs on port {{ app_port }}, owned by {{ app_owner }}"
```

```bash
mkdir -p vars
ansible-playbook 01-vars-file.yml
```

---

## 🔬 Lab 5 — Register Variables (Capture Output)

`register` saves the output of a task into a variable you can use later.

```yaml
---
- name: Register Lab
  hosts: localhost
  connection: local

  tasks:
    - name: Get current date
      command: date
      register: current_date

    - name: Show the result
      debug:
        msg: "The date is: {{ current_date.stdout }}"
```

`register` captures the full task result object. `.stdout` pulls just the text output.

---

## 🧪 Challenge (Do This On Your Own)

Write a playbook called `01-challenge.yml` that:

1. Defines a variable `my_name` with your name
2. Uses `register` to capture the output of `whoami`
3. Prints a message like: `"My name is Ed, logged in as adminuser"`

> Hint: `whoami` output will be in `result.stdout` (whatever you name the register variable)

---

## 📚 Key Takeaways

| Concept | What to Remember |
|---------|-----------------|
| `{{ var }}` | Jinja2 syntax — how you reference any variable |
| `vars:` | Define variables inline in a play |
| `vars_files:` | Load variables from an external YAML file |
| `ansible_*` | Auto-collected facts — always available |
| `register:` | Capture task output into a variable |
| `-e "key=val"` | Extra vars — highest precedence, override everything |
| `gather_facts: false` | Disable fact collection to speed up plays that don't need it |

---

## ➡️ Next Lab

`02-conditionals-and-loops.md` — Control task flow with `when:` and repeat tasks with `loop:`

---

*Lab created: 2026-04-07 | RHCE Series*
