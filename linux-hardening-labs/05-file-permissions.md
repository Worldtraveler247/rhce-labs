# 05 - File Permissions and ACLs

**Series:** Linux Hardening Labs  
**Lab:** 05 | **Prereq:** 04-selinux.md  
**Goal:** Find and fix dangerous file permissions. Master SUID/SGID, sticky bit, and ACLs.

---

## 🔬 Lab 1 — Dangerous Permission Audit

```bash
# Find SUID files (run as file owner, regardless of who executes)
sudo find / -perm -4000 -type f 2>/dev/null

# Find SGID files (run as group owner)
sudo find / -perm -2000 -type f 2>/dev/null

# Find world-writable files (anyone can modify)
sudo find / -perm -0002 -type f -not -path "/proc/*" 2>/dev/null

# Find world-writable directories
sudo find / -perm -0002 -type d -not -path "/proc/*" 2>/dev/null

# Find files with no owner (orphaned)
sudo find / -nouser -o -nogroup 2>/dev/null | head -20

# Find files modified in last 24 hours (detect tampering)
sudo find /etc /usr/bin /usr/sbin -mtime -1 2>/dev/null
```

---

## 🔬 Lab 2 — SUID / SGID Deep Dive

```bash
# SUID = 4 (execute as file owner)
# SGID = 2 (execute as group owner)
# Sticky = 1 (only owner can delete in directory)

# View special permissions
ls -la /usr/bin/passwd    # -rwsr-xr-x (s = SUID)
ls -la /usr/bin/wall      # -rwxr-sr-x (s = SGID)
ls -la /tmp               # drwxrwxrwt (t = sticky bit)

# Set SUID on a binary (use with extreme caution)
sudo chmod u+s /path/to/binary
sudo chmod 4755 /path/to/binary

# Set SGID on a directory (new files inherit group)
sudo chmod g+s /shared/directory
sudo chmod 2775 /shared/directory

# Set sticky bit on directory
sudo chmod +t /tmp
sudo chmod 1777 /tmp

# Remove SUID (harden unnecessary binaries)
sudo chmod u-s /usr/bin/somebinary
```

### SUID binaries to audit

These are common SUID binaries — verify each one is expected:

```bash
# Expected on RHEL:
# /usr/bin/passwd, /usr/bin/sudo, /usr/bin/su, /usr/bin/chsh
# /usr/bin/chfn, /usr/bin/newgrp, /usr/bin/mount, /usr/bin/umount

# Remove SUID from anything not needed
# Example: remove SUID from at (job scheduler) if not used
sudo chmod u-s /usr/bin/at
```

---

## 🔬 Lab 3 — Access Control Lists (ACLs)

Regular Unix permissions are limited: one owner, one group, everyone else. ACLs let you set per-user, per-group permissions on any file.

```bash
# Check if ACL support is enabled
sudo tune2fs -l /dev/sda1 | grep "Default mount"
# or
mount | grep acl

# View ACLs on a file
getfacl /etc/myconfig.conf

# Set ACL — give user 'ed' read/write on a file
sudo setfacl -m u:ed:rw /etc/myconfig.conf

# Set ACL — give group 'developers' read access
sudo setfacl -m g:developers:r /var/www/html/

# Set default ACL on directory (new files inherit)
sudo setfacl -d -m u:ed:rwx /shared/project/

# Recursive ACL
sudo setfacl -R -m u:ed:rx /var/www/html/

# Remove ACL for a user
sudo setfacl -x u:ed /etc/myconfig.conf

# Remove all ACLs from file
sudo setfacl -b /etc/myconfig.conf

# Copy ACL from one file to another
getfacl source-file | setfacl --set-file=- dest-file
```

---

## 🔬 Lab 4 — Immutable Files with chattr

```bash
# Make a file immutable (even root can't modify or delete)
sudo chattr +i /etc/important-config.conf

# View attributes
lsattr /etc/important-config.conf
# ----i--------e-- /etc/important-config.conf

# Remove immutable flag (to make changes, then re-add)
sudo chattr -i /etc/important-config.conf

# Append-only (log files that should never be modified)
sudo chattr +a /var/log/secure

# Other useful attributes:
# +s = securely delete (zero out when deleted)
# +u = undeletable
# +c = compress
```

---

## 🔬 Lab 5 — Sensitive File Permissions Checklist

```bash
# Critical files — check their permissions
ls -la /etc/passwd       # should be 644
ls -la /etc/shadow       # should be 000 or 640
ls -la /etc/gshadow      # should be 000 or 640
ls -la /etc/sudoers      # should be 440
ls -la /etc/ssh/sshd_config  # should be 600

# Fix common issues
sudo chmod 644 /etc/passwd
sudo chmod 000 /etc/shadow
sudo chmod 440 /etc/sudoers
sudo chmod 600 /etc/ssh/sshd_config
sudo chmod 700 /root
sudo chmod 700 /home/username/.ssh
sudo chmod 600 /home/username/.ssh/authorized_keys

# Check home directory permissions
for dir in /home/*/; do
    echo "$dir: $(stat -c '%a %U' $dir)"
done
```

---

## 🔬 Lab 6 — umask (Default Permissions)

`umask` controls the default permissions for new files and directories:

```bash
# View current umask
umask
# 0022 = new files get 644, directories get 755

# Calculation:
# Files max = 666, directories max = 777
# Subtract umask from max
# 666 - 022 = 644 (files)
# 777 - 022 = 755 (directories)

# Stricter umask for better security
umask 027    # files = 640, dirs = 750 (group readable, others get nothing)
umask 077    # files = 600, dirs = 700 (private — no group/other access)

# Set globally for all users
echo "umask 027" | sudo tee -a /etc/profile.d/umask.sh
```

---

## 🧪 Challenge

1. Find all SUID binaries on your system — document which ones are expected
2. Find all world-writable files outside of /tmp and /proc
3. Create a shared directory `/shared/team` where:
   - Group `devteam` has read/write
   - User `ed` has read/write/execute
   - All new files inherit these ACLs
4. Make `/etc/crontab` immutable with `chattr`
5. Verify `/etc/shadow` has correct permissions (000 or 640)
6. Set system-wide umask to 027

---

## 📚 Key Takeaways

| Concept | Command | Notes |
|---------|---------|-------|
| Find SUID | `find / -perm -4000` | Audit regularly |
| Set SUID | `chmod u+s file` | Dangerous — use sparingly |
| Sticky bit | `chmod +t dir` | Only owner can delete |
| View ACL | `getfacl file` | Per-user permissions |
| Set ACL | `setfacl -m u:user:rwx file` | Fine-grained control |
| Default ACL | `setfacl -d -m ...` | New files inherit |
| Immutable | `chattr +i file` | Even root can't modify |
| Append-only | `chattr +a file` | Good for log files |
| umask 027 | `/etc/profile.d/` | Files=640, dirs=750 |

---

## ➡️ Next Lab

`06-auditd.md` — Log and monitor everything with auditd. Know when files are accessed, modified, or deleted.

---

*Lab created: 2026-04-07 | Linux Hardening Series*
