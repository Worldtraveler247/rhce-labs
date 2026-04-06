# 04 - SELinux

**Series:** Linux Hardening Labs  
**Lab:** 04 | **Prereq:** 03-firewall-firewalld.md  
**Goal:** Understand, manage, and troubleshoot SELinux — the most powerful security layer on RHEL.

---

## 🧠 What Is SELinux?

SELinux (Security Enhanced Linux) is a **Mandatory Access Control (MAC)** system built into the Linux kernel. Even if an attacker compromises a process (like Apache), SELinux confines it — it can only access exactly what the policy allows.

### DAC vs MAC

| Type | What It Is | Example |
|------|-----------|---------|
| DAC (Discretionary) | Unix permissions (owner controls) | chmod, chown |
| MAC (Mandatory) | System enforces policy regardless of owner | SELinux |

Even root is constrained by SELinux in enforcing mode.

---

## 🔬 Lab 1 — SELinux Status and Modes

```bash
# Check current mode
getenforce
# Outputs: Enforcing, Permissive, or Disabled

# Detailed status
sestatus

# Check all context info
sestatus -v
```

### Three modes

| Mode | Behavior |
|------|----------|
| `Enforcing` | SELinux is active — violations are blocked and logged |
| `Permissive` | SELinux logs violations but doesn't block them |
| `Disabled` | SELinux is completely off (bad!) |

```bash
# Temporarily switch to permissive (for troubleshooting)
sudo setenforce 0

# Switch back to enforcing
sudo setenforce 1

# Make permanent (survives reboot)
sudo nano /etc/selinux/config
# SELINUX=enforcing
```

⚠️ **Never disable SELinux** — set to permissive when troubleshooting, then back to enforcing. Disabling requires a full relabel on re-enable.

---

## 🔬 Lab 2 — SELinux Contexts

Every file, process, and network port has an SELinux context (label):

```bash
# View file contexts
ls -Z /var/www/html/
# -rw-r--r--. root root unconfined_u:object_r:httpd_sys_content_t:s0 index.html

# View process contexts
ps auxZ | grep httpd

# View port contexts
sudo semanage port -l | grep http

# View your own context
id -Z
```

### Context format: `user:role:type:level`
- **user** — SELinux user (unconfined_u, system_u)
- **role** — role (object_r, system_r)
- **type** — **most important** — defines what the object is
- **level** — MLS/MCS sensitivity level

---

## 🔬 Lab 3 — Managing File Contexts

```bash
# View default context for a path
sudo semanage fcontext -l | grep '/var/www'

# Change context of a file (temporary — lost on relabel)
sudo chcon -t httpd_sys_content_t /var/www/html/myfile.html

# Restore original context from policy
sudo restorecon -v /var/www/html/myfile.html

# Restore recursively
sudo restorecon -Rv /var/www/html/

# Add a permanent context rule (survives relabel)
sudo semanage fcontext -a -t httpd_sys_content_t "/mywebdir(/.*)?"
sudo restorecon -Rv /mywebdir/

# View custom context rules you've added
sudo semanage fcontext -l -C
```

---

## 🔬 Lab 4 — SELinux Booleans

Booleans are on/off switches that adjust SELinux policy without writing custom rules:

```bash
# List all booleans
sudo getsebool -a

# List with descriptions
sudo semanage boolean -l

# Check specific boolean
sudo getsebool httpd_can_network_connect

# Turn on temporarily
sudo setsebool httpd_can_network_connect on

# Turn on permanently (survives reboot)
sudo setsebool -P httpd_can_network_connect on

# Useful booleans for common scenarios:
sudo setsebool -P httpd_can_network_connect on      # Apache can make outbound connections
sudo setsebool -P httpd_can_connect_db on           # Apache can connect to database
sudo setsebool -P httpd_enable_homedirs on          # Apache can serve from home dirs
sudo setsebool -P allow_ftpd_full_access on         # FTP full access
sudo setsebool -P samba_enable_home_dirs on         # Samba home dirs
sudo setsebool -P ssh_sysadm_login on               # SSH sysadm role login
```

---

## 🔬 Lab 5 — Managing Port Contexts

SELinux also labels network ports. If Apache tries to listen on a non-standard port, it needs the right port context:

```bash
# List port contexts
sudo semanage port -l | grep http

# Add a port to an existing type (allow Apache on port 8888)
sudo semanage port -a -t http_port_t -p tcp 8888

# Modify existing port context
sudo semanage port -m -t http_port_t -p tcp 8080

# Delete a port context
sudo semanage port -d -t http_port_t -p tcp 8888

# Verify
sudo semanage port -l | grep 8888
```

---

## 🔬 Lab 6 — Troubleshooting with audit2allow

When SELinux blocks something, it logs it. These are your debug tools:

```bash
# View SELinux denials in audit log
sudo ausearch -m avc -ts recent
sudo ausearch -m avc -ts today

# View denials in human-readable form
sudo ausearch -m avc -ts recent | audit2why

# Generate a custom policy module to allow the denied action
sudo ausearch -m avc -ts recent | audit2allow -M mypolicy
sudo semodule -i mypolicy.pp    # install the policy

# Check SELinux messages in syslog
sudo grep "SELinux" /var/log/messages
sudo grep "denied" /var/log/audit/audit.log | head -20

# Use sealert for detailed analysis (install setroubleshoot)
sudo dnf install setroubleshoot-server -y
sudo sealert -a /var/log/audit/audit.log
```

### Common fix workflow

```
1. Something breaks
2. sudo ausearch -m avc -ts recent | audit2why
3. Read the output — it tells you what was denied and why
4. Fix: either change file context, set boolean, or add port context
5. If nothing works: audit2allow → review carefully → install
```

---

## 🔬 Lab 7 — SELinux Users and Roles

Map Linux users to SELinux users for stricter access control:

```bash
# View user mappings
sudo semanage login -l

# Map a user to confined_u (restricted)
sudo semanage login -a -s user_u ed

# Map a user to staff_u (can use sudo with proper role)
sudo semanage login -a -s staff_u ed

# Common SELinux users:
# unconfined_u - no restrictions (default for admins)
# user_u       - basic confined user
# staff_u      - can run sudo, switch roles
# sysadm_u     - system admin
# guest_u      - very restricted (no network, no sudo)
```

---

## 🧪 Challenge

1. Verify SELinux is in enforcing mode
2. Create a directory `/webdata` and add content
3. Try to serve it with Apache — observe it fails due to wrong context
4. Fix the context with `semanage fcontext` + `restorecon`
5. Find the boolean to allow Apache to connect to a database and enable it
6. Allow Apache to listen on port 9090 using `semanage port`
7. Check audit log for any denials

---

## 📚 Key Takeaways

| Command | What It Does |
|---------|-------------|
| `getenforce` | Check current SELinux mode |
| `setenforce 0/1` | Switch permissive/enforcing (temporary) |
| `ls -Z` | View file contexts |
| `chcon -t type file` | Change context (temporary) |
| `restorecon -Rv path` | Restore contexts from policy |
| `semanage fcontext` | Manage permanent context rules |
| `getsebool / setsebool -P` | Manage policy booleans |
| `semanage port` | Manage port contexts |
| `ausearch -m avc` | View SELinux denial logs |
| `audit2why` | Explain why something was denied |
| `audit2allow` | Generate policy to allow denied action |

---

## ➡️ Next Lab

`05-file-permissions.md` — Advanced file permissions: SUID, SGID, sticky bit, ACLs, and finding dangerous permissions.

---

*Lab created: 2026-04-07 | Linux Hardening Series*
