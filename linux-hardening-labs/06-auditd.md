# 06 - Audit Logging with auditd

**Series:** Linux Hardening Labs  
**Lab:** 06 | **Prereq:** 05-file-permissions.md  
**Goal:** Configure auditd to log file access, user activity, and system events. Know when anything changes.

---

## 🧠 What Is auditd?

`auditd` is the Linux audit daemon — it records system calls and file access at the kernel level. Unlike application logs, it can't be bypassed by userspace processes. It's your source of truth for:

- Who accessed or modified a file
- Who executed what commands
- Who logged in and when
- Privilege escalation events
- System call violations

---

## 🔬 Lab 1 — Setup and Status

```bash
# Install
sudo dnf install audit audit-libs -y

# Enable and start
sudo systemctl enable auditd --now

# Check status
sudo systemctl status auditd

# View audit log
sudo tail -f /var/log/audit/audit.log

# Main config file
sudo cat /etc/audit/auditd.conf
```

### Key auditd.conf settings

```bash
sudo nano /etc/audit/auditd.conf
```

```ini
# Log file location
log_file = /var/log/audit/audit.log

# Max log file size in MB
max_log_file = 100

# Action when log is full: rotate, keep_logs, suspend, halt
max_log_file_action = rotate

# Number of rotated logs to keep
num_logs = 10

# Space left action (when disk is low)
space_left_action = email
admin_space_left_action = halt    # halt system if critically low (compliance)

# Disk full action
disk_full_action = suspend

# Flush frequency
flush = incremental_async
```

---

## 🔬 Lab 2 — Audit Rules

Rules tell auditd what to watch. Add them to `/etc/audit/rules.d/`:

```bash
sudo nano /etc/audit/rules.d/hardening.rules
```

### Key syntax
```
-w /path/to/watch -p permissions -k keyname
```
- `-w` = watch this file/directory
- `-p` = permissions to watch: `r`=read, `w`=write, `x`=execute, `a`=attribute change
- `-k` = keyword tag (for searching logs later)

### Essential audit rules

```bash
# ========================
# Identity and auth files
# ========================
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k sudo_changes
-w /etc/sudoers.d/ -p wa -k sudo_changes

# ========================
# SSH
# ========================
-w /etc/ssh/sshd_config -p wa -k sshd_config

# ========================
# Login and logout
# ========================
-w /var/log/lastlog -p wa -k logins
-w /var/run/faillock/ -p wa -k logins

# ========================
# Network config
# ========================
-w /etc/hosts -p wa -k network
-w /etc/sysconfig/network -p wa -k network

# ========================
# System startup
# ========================
-w /etc/crontab -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
-w /var/spool/cron/ -p wa -k cron
-w /etc/rc.d/init.d/ -p wa -k init

# ========================
# Kernel modules
# ========================
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules

# ========================
# Privilege escalation
# ========================
-w /usr/bin/sudo -p x -k privilege_escalation
-w /usr/bin/su -p x -k privilege_escalation
-w /bin/su -p x -k privilege_escalation

# ========================
# System calls — privilege escalation attempts
# ========================
-a always,exit -F arch=b64 -S setuid -S setgid -k setuid_setgid
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -k permission_changes
-a always,exit -F arch=b64 -S chown -S fchown -S lchown -k ownership_changes

# ========================
# Unauthorized access attempts
# ========================
-a always,exit -F arch=b64 -S open -F exit=-EACCES -k access_denied
-a always,exit -F arch=b64 -S open -F exit=-EPERM -k access_denied

# ========================
# Make audit config immutable (reboot required to change)
# ========================
# -e 2    # Uncomment when rules are finalized
```

```bash
# Reload rules
sudo augenrules --load
# or
sudo service auditd restart

# Verify rules are loaded
sudo auditctl -l
```

---

## 🔬 Lab 3 — Searching Audit Logs

```bash
# Search by keyword tag
sudo ausearch -k identity
sudo ausearch -k sudo_changes
sudo ausearch -k sshd_config

# Search by time
sudo ausearch -ts today
sudo ausearch -ts recent          # last 10 minutes
sudo ausearch -ts "03/01/2026 00:00:00" -te "03/31/2026 23:59:59"

# Search by user
sudo ausearch -ua ed
sudo ausearch -ui 1000            # by UID

# Search by event type
sudo ausearch -m USER_LOGIN
sudo ausearch -m USER_AUTH
sudo ausearch -m SYSCALL

# Combine filters
sudo ausearch -k sudo_changes -ts today -ui 1000

# Pipe to aureport for summary
sudo ausearch -k identity | aureport --summary
```

---

## 🔬 Lab 4 — aureport (Summary Reports)

```bash
# Overall summary
sudo aureport

# Authentication report
sudo aureport -au

# Login report
sudo aureport -l

# Failed logins
sudo aureport -l --failed

# File access report
sudo aureport -f

# System call report
sudo aureport -s

# User command report (what commands were run)
sudo aureport -x

# Anomaly report
sudo aureport --anomaly

# Report for today
sudo aureport --start today --end now
```

---

## 🔬 Lab 5 — Real-Time Monitoring with audispd

Forward audit events to syslog or a SIEM in real time:

```bash
# Enable syslog plugin
sudo nano /etc/audit/plugins.d/syslog.conf
```

```ini
active = yes
direction = out
path = builtin_syslog
type = builtin
args = LOG_INFO
format = string
```

```bash
sudo service auditd restart

# Now audit events appear in syslog too
sudo tail -f /var/log/messages | grep audit
```

---

## 🔬 Lab 6 — Watch a Specific File in Real Time

```bash
# Add a watch for a specific sensitive file
sudo auditctl -w /etc/passwd -p wa -k passwd_watch

# Trigger it — modify the file
sudo touch /etc/passwd

# Search for the event
sudo ausearch -k passwd_watch -ts recent

# Output will show:
# type=SYSCALL — what system call was made
# uid, auid — user who made the change
# comm — command that made the change
# name — file that was accessed
```

---

## 🧪 Challenge

1. Create a custom rules file `/etc/audit/rules.d/challenge.rules` with:
   - Watch `/etc/passwd`, `/etc/shadow` for writes
   - Watch `/usr/bin/sudo` for execution
   - Log all failed file access attempts
2. Reload rules and verify with `auditctl -l`
3. Trigger some events: run sudo, try to access a file you can't read
4. Use `ausearch -k` to find your events
5. Generate an authentication report with `aureport -au`

---

## 📚 Key Takeaways

| Command | What It Does |
|---------|-------------|
| `auditctl -l` | List active rules |
| `auditctl -w /path -p wa -k tag` | Watch file for writes |
| `ausearch -k tag` | Search by keyword |
| `ausearch -ts today` | Search today's events |
| `ausearch -ua username` | Search by user |
| `aureport` | Summary report |
| `aureport -au` | Authentication report |
| `aureport --failed` | Failed events |
| `/etc/audit/rules.d/` | Where rules live |
| `augenrules --load` | Load rules from rules.d |

---

## ➡️ Next Lab

`07-system-services.md` — Reduce attack surface by auditing and disabling unnecessary services.

---

*Lab created: 2026-04-07 | Linux Hardening Series*
