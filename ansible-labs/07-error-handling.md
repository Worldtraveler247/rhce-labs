# 07 - Error Handling and Debugging

**Series:** RHCE Ansible Labs  
**Lab:** 07 | **Prereq:** 06-vault.md  
**Goal:** Handle failures gracefully, rescue from errors, and debug playbooks like a pro.

---

## 🧠 Default Ansible Behavior

By default, if any task fails, Ansible **stops the play** on that host immediately. Everything after the failure is skipped. Sometimes that's what you want — sometimes you need more control.

---

## 🔬 Lab 1 — ignore_errors

```bash
nano ~/ansible-practice/07/error-handling.yml
```

```yaml
---
- name: Error Handling Lab
  hosts: localhost
  connection: local

  tasks:
    - name: This command will fail
      command: /bin/false
      ignore_errors: true    # ← continue even if this fails

    - name: This still runs
      debug:
        msg: "I ran even though the previous task failed"

    - name: Check a file that doesn't exist
      stat:
        path: /tmp/nonexistent-file.txt
      register: file_check
      ignore_errors: true

    - name: Act based on whether file exists
      debug:
        msg: "File exists: {{ file_check.stat.exists }}"
      when: file_check is not failed
```

```bash
ansible-playbook ~/ansible-practice/07/error-handling.yml
```

---

## 🔬 Lab 2 — failed_when (Custom Failure Conditions)

Tell Ansible when to consider a task failed, even if it returned exit code 0:

```yaml
---
- name: Custom Failure Lab
  hosts: localhost
  connection: local

  tasks:
    - name: Check disk usage
      command: df -h /
      register: disk_output

    - name: Fail if disk output is empty
      debug:
        msg: "Disk check passed"
      failed_when: disk_output.stdout == ""

    - name: Run a script (fail if specific word in output)
      command: echo "WARNING: something happened"
      register: result
      failed_when: "'ERROR' in result.stdout"   # only fails on ERROR, not WARNING

    - name: Combine failed_when with ignore_errors
      command: echo "CRITICAL: disk full"
      register: critical_check
      failed_when: "'CRITICAL' in critical_check.stdout"
      ignore_errors: true

    - name: Show result
      debug:
        msg: "Critical check failed: {{ critical_check.failed }}"
```

---

## 🔬 Lab 3 — changed_when (Control Changed Status)

Commands always report `changed` even when they don't change anything. Fix that:

```yaml
---
- name: Changed When Lab
  hosts: localhost
  connection: local

  tasks:
    # This reports "changed" every time (annoying)
    - name: Check service status (bad)
      command: echo "service is running"
      register: status

    # This never reports "changed" (it's read-only)
    - name: Check service status (good)
      command: echo "service is running"
      register: status
      changed_when: false   # ← never mark as changed

    # Changed only when the output contains "restarted"
    - name: Conditional change report
      command: echo "service already running"
      register: svc_result
      changed_when: "'restarted' in svc_result.stdout"
```

---

## 🔬 Lab 4 — Block / Rescue / Always

Like try/catch/finally in programming:

```yaml
---
- name: Block Rescue Always Lab
  hosts: localhost
  connection: local

  tasks:
    - name: Full error handling block
      block:
        - name: Task 1 — succeeds
          debug:
            msg: "Block task 1 running"

        - name: Task 2 — intentionally fails
          command: /bin/false

        - name: Task 3 — never runs (task 2 failed)
          debug:
            msg: "This won't print"

      rescue:
        - name: Rescue — runs on any block failure
          debug:
            msg: "RESCUE: Something failed in the block, handling it..."

        - name: Rescue — notify team
          debug:
            msg: "Would send alert to ops team here"

      always:
        - name: Always — runs no matter what
          debug:
            msg: "ALWAYS: This runs whether block succeeded or failed"
```

```bash
ansible-playbook ~/ansible-practice/07/block-rescue.yml
```

**This is the most important pattern for production playbooks.**

---

## 🔬 Lab 5 — any_errors_fatal

Stop ALL hosts when any one host fails (useful for coordinated deployments):

```yaml
---
- name: All or Nothing
  hosts: all
  any_errors_fatal: true    # ← if web01 fails, stop web02 too

  tasks:
    - name: Pre-flight check
      command: /bin/true
```

---

## 🔬 Lab 6 — Debugging Techniques

```bash
# Verbose output — see what Ansible is actually doing
ansible-playbook playbook.yml -v      # basic
ansible-playbook playbook.yml -vv     # more detail
ansible-playbook playbook.yml -vvv    # connection details
ansible-playbook playbook.yml -vvvv   # full SSH debug

# Check syntax without running
ansible-playbook playbook.yml --syntax-check

# Dry run — shows what WOULD happen
ansible-playbook playbook.yml --check

# Dry run + show file diffs
ansible-playbook playbook.yml --check --diff

# Start at a specific task
ansible-playbook playbook.yml --start-at-task="Install packages"

# Run only specific tags
ansible-playbook playbook.yml --tags "install,configure"

# Step through tasks interactively
ansible-playbook playbook.yml --step
```

---

## 🔬 Lab 7 — Tags

Tags let you run specific parts of a playbook:

```yaml
---
- name: Tagged Playbook
  hosts: localhost
  connection: local

  tasks:
    - name: Install packages
      debug:
        msg: "Installing packages"
      tags:
        - install
        - packages

    - name: Configure app
      debug:
        msg: "Configuring app"
      tags:
        - configure

    - name: Deploy code
      debug:
        msg: "Deploying"
      tags:
        - deploy

    - name: Always runs
      debug:
        msg: "This always runs"
      tags:
        - always    # special tag — runs even when other tags are specified
```

```bash
# Run only install tasks
ansible-playbook playbook.yml --tags install

# Run everything EXCEPT deploy
ansible-playbook playbook.yml --skip-tags deploy

# List available tags
ansible-playbook playbook.yml --list-tags
```

---

## 🔬 Lab 8 — The debug Module

```yaml
- name: Debug variable
  debug:
    var: some_variable          # prints variable name and value

- name: Debug message
  debug:
    msg: "Value is {{ var }}"   # custom message

- name: Debug only in verbose mode
  debug:
    msg: "Only shows with -v"
    verbosity: 1                # requires at least -v
```

---

## 🧪 Challenge

Write `07/challenge.yml` that:
1. Tries to read a file that doesn't exist (use `command: cat /tmp/doesnotexist`)
2. Catches the failure in a `rescue` block
3. In rescue: creates the file with some content
4. In `always`: verifies the file now exists and prints its content

---

## 📚 Key Takeaways

| Concept | What to Remember |
|---------|-----------------|
| `ignore_errors: true` | Continue even if task fails |
| `failed_when:` | Custom failure condition |
| `changed_when: false` | Mark read-only commands as not changed |
| `block/rescue/always` | Try/catch/finally — production pattern |
| `any_errors_fatal: true` | Stop all hosts if any fail |
| `-v/-vv/-vvv` | Increase verbosity for debugging |
| `--check --diff` | Dry run with diff — always before prod |
| `--tags` | Run specific tagged tasks only |
| `--start-at-task` | Resume from a specific task |

---

## ➡️ Next Lab

`08-advanced-playbooks.md` — Delegation, serial execution, rolling updates, and advanced patterns.

---

*Lab created: 2026-04-07 | RHCE Ansible Series*
