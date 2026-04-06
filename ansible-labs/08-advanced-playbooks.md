# 08 - Advanced Playbooks

**Series:** RHCE Ansible Labs  
**Lab:** 08 | **Prereq:** 07-error-handling.md  
**Goal:** Rolling updates, delegation, serial execution, async tasks, and production deployment patterns.

---

## 🔬 Lab 1 — Serial Execution (Rolling Updates)

By default Ansible runs tasks on ALL hosts at the same time. `serial` controls how many hosts run at once — critical for zero-downtime deployments:

```yaml
---
- name: Rolling Update
  hosts: webservers
  serial: 1           # update one server at a time

  tasks:
    - name: Take host out of load balancer
      debug:
        msg: "Removing {{ inventory_hostname }} from LB"

    - name: Update application
      debug:
        msg: "Updating app on {{ inventory_hostname }}"

    - name: Health check
      debug:
        msg: "Health checking {{ inventory_hostname }}"

    - name: Put host back in load balancer
      debug:
        msg: "Adding {{ inventory_hostname }} back to LB"
```

```yaml
# Roll out in batches
serial: 2          # 2 at a time

# Percentage-based
serial: "25%"      # 25% of hosts at a time

# Progressive batches — start slow, speed up
serial:
  - 1              # first: just 1 host
  - 5              # then: 5 hosts
  - "50%"          # then: 50% at a time
```

---

## 🔬 Lab 2 — Delegation

Run a task on a different host than the current target. Classic use: remove a web server from a load balancer before updating it:

```yaml
---
- name: Delegation Lab
  hosts: webservers

  tasks:
    - name: Remove from load balancer (run on LB, not web server)
      command: "echo 'haproxy disable server {{ inventory_hostname }}'"
      delegate_to: loadbalancer01    # ← runs on LB, not the web server

    - name: Update the web server (runs normally on web server)
      debug:
        msg: "Updating {{ inventory_hostname }}"

    - name: Add back to load balancer
      command: "echo 'haproxy enable server {{ inventory_hostname }}'"
      delegate_to: loadbalancer01

    # delegate_to: localhost — common for local tasks during remote play
    - name: Log deployment to local file
      copy:
        content: "Deployed to {{ inventory_hostname }} at {{ ansible_date_time.iso8601 }}\n"
        dest: /tmp/deploy-log.txt
      delegate_to: localhost
```

---

## 🔬 Lab 3 — run_once

Run a task exactly once, even across multiple hosts:

```yaml
---
- name: Run Once Lab
  hosts: webservers

  tasks:
    - name: This runs on every host
      debug:
        msg: "Running on {{ inventory_hostname }}"

    - name: This runs once (on first host)
      debug:
        msg: "Database migration — only runs once!"
      run_once: true

    - name: Run once on a specific host
      debug:
        msg: "Running migration on db01"
      run_once: true
      delegate_to: db01
```

---

## 🔬 Lab 4 — Async Tasks

Run long tasks in the background and check on them later:

```yaml
---
- name: Async Lab
  hosts: localhost
  connection: local

  tasks:
    - name: Start a long-running task (background)
      command: sleep 10
      async: 60        # allow up to 60 seconds
      poll: 0          # don't wait — fire and forget
      register: long_task

    - name: Do other things while task runs
      debug:
        msg: "Doing other work while task runs in background"

    - name: Check if background task is done
      async_status:
        jid: "{{ long_task.ansible_job_id }}"
      register: task_result
      until: task_result.finished
      retries: 10
      delay: 3         # check every 3 seconds
```

---

## 🔬 Lab 5 — until / retries (Wait for Condition)

Retry a task until it succeeds or gives up:

```yaml
---
- name: Retry Lab
  hosts: localhost
  connection: local

  tasks:
    - name: Wait for a service to be ready
      uri:
        url: "http://localhost:8080/health"
        status_code: 200
      register: health_check
      until: health_check.status == 200
      retries: 10        # try 10 times
      delay: 5           # wait 5 seconds between tries
      ignore_errors: true

    - name: Wait for a file to exist
      wait_for:
        path: /tmp/ready.flag
        state: present
        timeout: 30       # give up after 30 seconds

    - name: Wait for a port to be open
      wait_for:
        host: localhost
        port: 5432
        state: started
        timeout: 60
```

---

## 🔬 Lab 6 — include_tasks and import_tasks

Split large playbooks into smaller files:

```yaml
# tasks/install.yml
- name: Install packages
  debug:
    msg: "Installing {{ item }}"
  loop: "{{ packages }}"

# tasks/configure.yml
- name: Configure app
  debug:
    msg: "Configuring..."
```

```yaml
# main playbook
---
- name: Modular Playbook
  hosts: localhost
  connection: local

  vars:
    packages: [git, curl, vim]

  tasks:
    # import_tasks — loaded at parse time (static, faster)
    - import_tasks: tasks/install.yml

    # include_tasks — loaded at runtime (dynamic, supports when/loop)
    - include_tasks: tasks/configure.yml
      when: configure_app | default(true)

    # Conditional include
    - include_tasks: "tasks/{{ ansible_os_family | lower }}.yml"
```

---

## 🔬 Lab 7 — Full Production Deployment Pattern

```yaml
---
- name: Production Deployment
  hosts: webservers
  serial: "25%"              # rolling update
  max_fail_percentage: 20    # fail if more than 20% of hosts fail

  pre_tasks:
    - name: Announce deployment start
      debug:
        msg: "Starting deployment of v{{ app_version }} to {{ inventory_hostname }}"

    - name: Remove from load balancer
      debug:
        msg: "Removing {{ inventory_hostname }} from LB"
      delegate_to: localhost

  roles:
    - common
    - webserver

  post_tasks:
    - name: Health check
      uri:
        url: "http://{{ ansible_host }}/health"
        status_code: 200
      register: health
      until: health.status == 200
      retries: 5
      delay: 10
      ignore_errors: true

    - name: Add back to load balancer
      debug:
        msg: "Adding {{ inventory_hostname }} back to LB"
      delegate_to: localhost
      when: health.status == 200

    - name: Fail if health check failed
      fail:
        msg: "Health check failed for {{ inventory_hostname }}!"
      when: health.status != 200
```

---

## 🧪 Challenge

Write a playbook that simulates a multi-server rolling deployment:
1. Use the local-inventory from Lab 05 (simulated webservers)
2. Roll out `serial: 1`
3. For each host: "remove from LB" → "update app" → "health check" → "add back to LB"
4. Use `delegate_to: localhost` for LB tasks
5. Use `block/rescue` to handle failures

---

## 📚 Key Takeaways

| Concept | What to Remember |
|---------|-----------------|
| `serial: 1` | One host at a time — zero downtime |
| `serial: "25%"` | Percentage-based batches |
| `delegate_to:` | Run task on different host |
| `run_once: true` | Run once even for multi-host plays |
| `async:` + `poll: 0` | Background tasks |
| `async_status:` | Check on background task |
| `until/retries/delay` | Retry until condition met |
| `include_tasks` | Dynamic file inclusion (supports when) |
| `import_tasks` | Static file inclusion (faster) |
| `pre_tasks/post_tasks` | Run before/after roles |

---

## ➡️ Next Lab

`09-cicd-and-awx.md` — Run Ansible at scale: AWX/Tower, CI/CD integration, and automation controller.

---

*Lab created: 2026-04-07 | RHCE Ansible Series*
