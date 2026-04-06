# 10 - Automate Hardening with Ansible

**Series:** Linux Hardening Labs  
**Lab:** 10 | **Prereq:** 09-aide.md + Ansible Labs 00–04  
**Goal:** Write an Ansible role that automates all hardening steps from this series.

---

## 🧠 Why Automate Hardening?

Manual hardening is:
- Error-prone (forget a step)
- Not repeatable (differs server to server)
- Doesn't scale (100 servers = 100 manual configs)

Automated hardening with Ansible:
- Identical every time
- Version controlled
- Auditable
- Fast — dozens of servers in minutes

---

## 📁 Project Structure

```
~/ansible-practice/hardening/
  site.yml
  inventory.yml
  roles/
    hardening/
      tasks/
        main.yml
        users.yml
        ssh.yml
        firewall.yml
        selinux.yml
        kernel.yml
        auditd.yml
        aide.yml
      handlers/
        main.yml
      templates/
        sshd_config.j2
        pwquality.conf.j2
        hardening.sysctl.j2
        audit.rules.j2
      defaults/
        main.yml
      vars/
        main.yml
```

---

## 🔬 Lab 1 — Create the Role

```bash
mkdir -p ~/ansible-practice/hardening
cd ~/ansible-practice/hardening
ansible-galaxy role init roles/hardening
mkdir -p roles/hardening/tasks
```

---

## 🔬 Lab 2 — defaults/main.yml

```bash
nano roles/hardening/defaults/main.yml
```

```yaml
---
# SSH settings
ssh_port: 22
ssh_permit_root_login: "no"
ssh_password_auth: "no"
ssh_max_auth_tries: 3
ssh_client_alive_interval: 300
ssh_allowed_users: []          # empty = allow all (override in inventory)

# Password policy
pw_min_length: 14
pw_max_days: 90
pw_min_days: 7
pw_warn_days: 14

# Faillock
faillock_deny: 5
faillock_unlock_time: 900

# Kernel
disable_ipv6: true
enable_aslr: true

# Auditd
auditd_max_log_size: 100
auditd_num_logs: 10

# AIDE
aide_enabled: true
aide_cron_hour: "2"
aide_cron_minute: "0"

# Firewall — list of services to allow
firewall_allowed_services:
  - ssh
  - https

# Firewall — list of ports to allow
firewall_allowed_ports: []
```

---

## 🔬 Lab 3 — tasks/main.yml

```bash
nano roles/hardening/tasks/main.yml
```

```yaml
---
- name: Include user hardening tasks
  import_tasks: users.yml
  tags: users

- name: Include SSH hardening tasks
  import_tasks: ssh.yml
  tags: ssh

- name: Include firewall tasks
  import_tasks: firewall.yml
  tags: firewall

- name: Include SELinux tasks
  import_tasks: selinux.yml
  tags: selinux

- name: Include kernel hardening tasks
  import_tasks: kernel.yml
  tags: kernel

- name: Include auditd tasks
  import_tasks: auditd.yml
  tags: auditd

- name: Include AIDE tasks
  import_tasks: aide.yml
  tags: aide
  when: aide_enabled
```

---

## 🔬 Lab 4 — tasks/users.yml

```bash
nano roles/hardening/tasks/users.yml
```

```yaml
---
- name: Lock root account
  user:
    name: root
    password_lock: true

- name: Set password aging for all non-system users
  shell: |
    for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
      chage -M {{ pw_max_days }} -m {{ pw_min_days }} -W {{ pw_warn_days }} $user
    done
  changed_when: false

- name: Deploy pwquality configuration
  template:
    src: pwquality.conf.j2
    dest: /etc/security/pwquality.conf
    owner: root
    group: root
    mode: '0644'

- name: Configure faillock
  lineinfile:
    path: /etc/security/faillock.conf
    regexp: "^{{ item.key }}"
    line: "{{ item.key }} = {{ item.value }}"
    create: true
  loop:
    - { key: "deny", value: "{{ faillock_deny }}" }
    - { key: "unlock_time", value: "{{ faillock_unlock_time }}" }
    - { key: "even_deny_root", value: "true" }

- name: Set restrictive umask system-wide
  copy:
    content: "umask 027\n"
    dest: /etc/profile.d/hardening-umask.sh
    mode: '0644'
```

---

## 🔬 Lab 5 — tasks/ssh.yml

```bash
nano roles/hardening/tasks/ssh.yml
```

```yaml
---
- name: Deploy hardened sshd_config
  template:
    src: sshd_config.j2
    dest: /etc/ssh/sshd_config
    owner: root
    group: root
    mode: '0600'
    validate: '/usr/sbin/sshd -t -f %s'    # validate before replacing!
  notify: restart sshd

- name: Deploy SSH banner
  copy:
    content: |
      ***************************************************************************
                              AUTHORIZED ACCESS ONLY
      This system is for authorized users only. All activity is monitored.
      Unauthorized access is prohibited and will be prosecuted.
      ***************************************************************************
    dest: /etc/ssh/banner.txt
    mode: '0644'
```

---

## 🔬 Lab 6 — tasks/firewall.yml

```bash
nano roles/hardening/tasks/firewall.yml
```

```yaml
---
- name: Ensure firewalld is installed
  package:
    name: firewalld
    state: present

- name: Ensure firewalld is running
  service:
    name: firewalld
    state: started
    enabled: true

- name: Set default zone to public
  firewalld:
    zone: public
    state: present
    permanent: true

- name: Allow required services
  firewalld:
    service: "{{ item }}"
    zone: public
    state: enabled
    permanent: true
    immediate: true
  loop: "{{ firewall_allowed_services }}"

- name: Allow required ports
  firewalld:
    port: "{{ item }}"
    zone: public
    state: enabled
    permanent: true
    immediate: true
  loop: "{{ firewall_allowed_ports }}"
  when: firewall_allowed_ports | length > 0

- name: Remove default services that aren't needed
  firewalld:
    service: "{{ item }}"
    zone: public
    state: disabled
    permanent: true
    immediate: true
  loop:
    - dhcpv6-client
    - cockpit
  ignore_errors: true
```

---

## 🔬 Lab 7 — tasks/kernel.yml

```bash
nano roles/hardening/tasks/kernel.yml
```

```yaml
---
- name: Deploy kernel hardening sysctl config
  template:
    src: hardening.sysctl.j2
    dest: /etc/sysctl.d/99-hardening.conf
    owner: root
    group: root
    mode: '0644'
  notify: apply sysctl

- name: Deploy kernel module blacklist
  copy:
    content: |
      blacklist usb-storage
      install usb-storage /bin/false
      blacklist dccp
      install dccp /bin/false
      blacklist sctp
      install sctp /bin/false
      blacklist rds
      install rds /bin/false
    dest: /etc/modprobe.d/blacklist-hardening.conf
    mode: '0644'
```

---

## 🔬 Lab 8 — handlers/main.yml

```bash
nano roles/hardening/handlers/main.yml
```

```yaml
---
- name: restart sshd
  service:
    name: sshd
    state: restarted

- name: apply sysctl
  command: sysctl --system

- name: reload firewalld
  service:
    name: firewalld
    state: reloaded

- name: restart auditd
  service:
    name: auditd
    state: restarted
```

---

## 🔬 Lab 9 — The Master Playbook

```bash
nano ~/ansible-practice/hardening/site.yml
```

```yaml
---
- name: Linux System Hardening
  hosts: all
  become: true

  vars:
    ssh_port: 2222
    ssh_allowed_users:
      - ed
      - adminuser
    firewall_allowed_services:
      - https
    firewall_allowed_ports:
      - "2222/tcp"
    disable_ipv6: true

  roles:
    - hardening

  post_tasks:
    - name: Hardening complete — run verification
      debug:
        msg: |
          Hardening applied to {{ inventory_hostname }}
          - SSH port: {{ ssh_port }}
          - Root login: disabled
          - Password auth: disabled
          - Firewall: active
          - SELinux: enforcing
          - auditd: active
          - AIDE: {{ 'enabled' if aide_enabled else 'disabled' }}
```

---

## 🔬 Lab 10 — Run It

```bash
cd ~/ansible-practice/hardening

# Syntax check
ansible-playbook site.yml --syntax-check

# Dry run (check mode)
ansible-playbook site.yml --check --diff

# Apply only SSH hardening
ansible-playbook site.yml --tags ssh

# Apply only firewall and kernel
ansible-playbook site.yml --tags "firewall,kernel"

# Full apply
ansible-playbook site.yml
```

---

## 🧪 Challenge

1. Complete all task files (users, ssh, firewall, kernel, auditd, aide)
2. Create all templates (sshd_config.j2, pwquality.conf.j2, hardening.sysctl.j2)
3. Test with `--check --diff` first
4. Apply to your Rocky Linux VM
5. Run `lynis audit system` before and after — compare the scores

---

## 📚 Key Takeaways

| Concept | What to Remember |
|---------|-----------------|
| `validate:` in template | Test config before replacing (critical for sshd!) |
| Tags per task file | `--tags ssh` to apply only SSH hardening |
| `import_tasks` | Clean modular structure |
| `defaults/main.yml` | All variables overridable per host/group |
| `--check --diff` | Always dry-run before applying to production |
| Post-tasks verification | Confirm hardening was actually applied |

---

## ➡️ Next Lab

`11-cis-benchmark.md` — Full CIS Benchmark audit: score your system and remediate findings.

---

*Lab created: 2026-04-07 | Linux Hardening Series*
