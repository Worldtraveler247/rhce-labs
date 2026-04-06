# 11 - Full Audit — CIS Benchmark

**Series:** Linux Hardening Labs  
**Lab:** 11 | **Prereq:** All previous labs  
**Goal:** Audit your system against the CIS Benchmark, understand the scoring, and remediate findings.

---

## 🧠 What Is the CIS Benchmark?

The Center for Internet Security (CIS) publishes hardening benchmarks for every major OS. The RHEL/Rocky Linux benchmark has hundreds of checks, grouped by:

- **Level 1** — Basic, minimal impact on operations. Every server should pass.
- **Level 2** — Defense-in-depth, may impact some functionality. For high-security environments.

CIS Benchmarks are used for compliance (PCI-DSS, HIPAA, SOC2, FedRAMP).

---

## 🔬 Lab 1 — Install and Run Lynis

Lynis is a free, open-source tool that performs CIS-aligned checks:

```bash
sudo dnf install lynis -y

# Full system audit
sudo lynis audit system

# Save output to file
sudo lynis audit system 2>&1 | tee /var/log/lynis-$(date +%Y%m%d).log

# View the report
sudo cat /var/log/lynis-report.dat

# View just warnings and suggestions
sudo grep -E "warning|suggestion" /var/log/lynis-report.dat
```

### Understanding the Lynis score

```
Hardening index: 65 [#############       ]
```

- **< 60** — Basic hardening only
- **60–79** — Moderate hardening
- **80–89** — Strong hardening
- **90+** — Excellent (rare, high-security environments)

---

## 🔬 Lab 2 — CIS Benchmark Categories

Work through each section and fix findings:

### Section 1 — Initial Setup

```bash
# 1.1 Filesystem Configuration
# Check /tmp is on separate partition
mount | grep /tmp

# Check noexec on /tmp
mount | grep /tmp | grep noexec

# Fix: add to /etc/fstab
# tmpfs /tmp tmpfs defaults,nodev,nosuid,noexec 0 0

# 1.4 Secure Boot
# Check GRUB password is set
sudo grep "^GRUB2_PASSWORD" /boot/grub2/grub.cfg

# Set GRUB password
sudo grub2-setpassword

# 1.5 Additional Process Hardening
# Verify ASLR
sysctl kernel.randomize_va_space   # should be 2

# Verify prelink is disabled
sudo rpm -q prelink   # should not be installed
```

### Section 2 — Services

```bash
# Check for unnecessary services
# 2.1 Time Synchronization
sudo systemctl is-active chronyd
sudo systemctl is-active ntpd

# 2.2 Special Purpose Services
# These should NOT be running on a basic server:
for svc in avahi-daemon cups dhcpd slapd nfs rpcbind named vsftpd httpd dovecot smb squid snmpd; do
    status=$(systemctl is-active $svc 2>/dev/null)
    echo "$svc: $status"
done
```

### Section 3 — Network Configuration

```bash
# 3.1 Network Parameters (Host Only)
sysctl net.ipv4.ip_forward                    # should be 0
sysctl net.ipv4.conf.all.send_redirects       # should be 0
sysctl net.ipv4.conf.all.accept_source_route  # should be 0
sysctl net.ipv4.conf.all.accept_redirects     # should be 0
sysctl net.ipv4.conf.all.log_martians         # should be 1
sysctl net.ipv4.tcp_syncookies                # should be 1
```

### Section 4 — Logging and Auditing

```bash
# 4.1 Configure System Accounting (auditd)
sudo systemctl is-active auditd   # should be active

# Check audit rules exist
sudo auditctl -l | wc -l          # should be > 0

# Check auditd config
sudo grep max_log_file /etc/audit/auditd.conf
sudo grep max_log_file_action /etc/audit/auditd.conf

# 4.2 Configure Logging
sudo systemctl is-active rsyslog
sudo ls /var/log/messages
sudo ls /var/log/secure
sudo ls /var/log/audit/audit.log
```

### Section 5 — Access, Authentication, Authorization

```bash
# 5.1 Configure cron
sudo systemctl is-active crond
sudo ls /etc/cron.allow   # should exist
sudo ls /etc/cron.deny    # should not exist

# 5.2 SSH Server
sudo grep "^PermitRootLogin" /etc/ssh/sshd_config      # should be no
sudo grep "^PasswordAuthentication" /etc/ssh/sshd_config # should be no
sudo grep "^MaxAuthTries" /etc/ssh/sshd_config           # should be <= 4
sudo grep "^PermitEmptyPasswords" /etc/ssh/sshd_config   # should be no
sudo grep "^ClientAliveInterval" /etc/ssh/sshd_config    # should be <= 300

# 5.3 Configure PAM
sudo grep "pam_pwquality" /etc/pam.d/system-auth
sudo grep "pam_faillock" /etc/pam.d/system-auth

# 5.4 User Accounts and Environment
sudo grep "^PASS_MAX_DAYS" /etc/login.defs    # should be <= 90
sudo grep "^PASS_MIN_DAYS" /etc/login.defs    # should be >= 7
sudo grep "^PASS_WARN_AGE" /etc/login.defs    # should be >= 7

# Check for UID 0 accounts besides root
awk -F: '$3 == 0 {print $1}' /etc/passwd

# Check for empty password fields
sudo awk -F: '$2 == "" {print $1}' /etc/shadow
```

### Section 6 — System Maintenance

```bash
# 6.1 System File Permissions
sudo stat /etc/passwd   | grep Access   # should be 644
sudo stat /etc/shadow   | grep Access   # should be 000 or 640
sudo stat /etc/sudoers  | grep Access   # should be 440

# Check for world-writable files
sudo find / -xdev -perm -0002 -not -path "/proc/*" -type f 2>/dev/null

# Check SUID/SGID files
sudo find / -xdev \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null
```

---

## 🔬 Lab 3 — OpenSCAP (Official CIS Scanning)

OpenSCAP provides official CIS benchmark scanning on RHEL:

```bash
sudo dnf install openscap-scanner scap-security-guide -y

# List available profiles
sudo oscap info /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml | grep "Profile"

# Run CIS Level 1 scan
sudo oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis \
  --results /tmp/cis-results.xml \
  --report /tmp/cis-report.html \
  /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml

# Open the report
# (copy to your Mac and open in browser)
```

---

## 🔬 Lab 4 — Remediate Automatically with OpenSCAP

```bash
# Generate a remediation script
sudo oscap xccdf generate fix \
  --profile xccdf_org.ssgproject.content_profile_cis \
  --fix-type bash \
  /tmp/cis-results.xml > /tmp/cis-remediation.sh

# Review before running!
cat /tmp/cis-remediation.sh

# Run remediation (on a test system first!)
sudo bash /tmp/cis-remediation.sh

# Or generate an Ansible remediation playbook
sudo oscap xccdf generate fix \
  --profile xccdf_org.ssgproject.content_profile_cis \
  --fix-type ansible \
  /tmp/cis-results.xml > /tmp/cis-remediation.yml
```

---

## 🎓 You've Completed the Linux Hardening Series

| Lab | Topic | What You Can Do Now |
|-----|-------|-------------------|
| 00 | Introduction | Understand the threat model |
| 01 | User Security | Lock accounts, enforce passwords, harden sudo |
| 02 | SSH Hardening | Key-only auth, hardened config, fail2ban |
| 03 | Firewall | firewalld zones, rich rules, hardened profiles |
| 04 | SELinux | Enforcing mode, contexts, booleans, troubleshooting |
| 05 | File Permissions | SUID audit, ACLs, chattr, umask |
| 06 | auditd | Log file access, user activity, system events |
| 07 | Services | Minimize attack surface, disable unused services |
| 08 | Kernel | sysctl hardening, /proc restrictions |
| 09 | AIDE | Detect unauthorized filesystem changes |
| 10 | Ansible | Automate all hardening as code |
| **11** | **CIS Benchmark** | **Audit, score, and remediate** ✅ |

**Next:** Look at the AWS Security series — apply these same concepts to cloud infrastructure.

---

*Lab created: 2026-04-07 | Linux Hardening Series*
