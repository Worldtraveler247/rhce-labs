# 01 - User and Password Security

**Series:** Linux Hardening Labs  
**Lab:** 01 | **Prereq:** 00-introduction.md  
**Goal:** Lock down user accounts, enforce strong password policies, and harden sudo access.

---

## 🧠 Why This Matters

Weak user accounts are one of the most common attack vectors. Default passwords, unused accounts, and overprivileged sudo access create easy wins for attackers. Fix these first.

---

## 🔬 Lab 1 — Audit Existing Accounts

```bash
# List all users with a shell (real accounts)
grep -v '/sbin/nologin\|/bin/false' /etc/passwd

# List users with UID 0 (should only be root)
awk -F: '$3 == 0 {print $1}' /etc/passwd

# Find accounts with empty passwords (DANGER)
sudo awk -F: '$2 == "" {print $1}' /etc/shadow

# List all groups
cat /etc/group

# Find users in the wheel/sudo group
grep -E '^wheel|^sudo' /etc/group

# Show last login times
lastlog | grep -v 'Never logged in' | head -20

# Show currently logged in users
who
w
```

---

## 🔬 Lab 2 — Password Policy with PAM

PAM (Pluggable Authentication Modules) controls password requirements on Linux.

### Install pwquality

```bash
sudo dnf install libpwquality -y    # RHEL/Rocky
```

### Configure password strength

```bash
sudo nano /etc/security/pwquality.conf
```

```ini
# Minimum length
minlen = 14

# Require at least 1 uppercase
ucredit = -1

# Require at least 1 lowercase
lcredit = -1

# Require at least 1 digit
dcredit = -1

# Require at least 1 special character
ocredit = -1

# Reject passwords containing username
usercheck = 1

# Reject passwords similar to old password
difok = 8

# Number of recent passwords to remember
remember = 5
```

### Configure password aging

```bash
sudo nano /etc/login.defs
```

```ini
# Password maximum age (days)
PASS_MAX_DAYS   90

# Password minimum age (days) - prevents immediate change
PASS_MIN_DAYS   7

# Warning before expiry (days)
PASS_WARN_AGE   14
```

### Apply aging to existing users

```bash
# Set password aging for a specific user
sudo chage -M 90 -m 7 -W 14 username

# View current aging settings
sudo chage -l username

# Force password change on next login
sudo chage -d 0 username

# Set account expiry date
sudo chage -E 2026-12-31 username
```

---

## 🔬 Lab 3 — Lock and Manage Accounts

```bash
# Lock a user account (can't log in)
sudo usermod -L username
sudo passwd -l username

# Unlock
sudo usermod -U username
sudo passwd -u username

# Disable shell (prevent interactive login but keep account)
sudo usermod -s /sbin/nologin username

# Delete unused account
sudo userdel -r username    # -r removes home directory too

# Check for accounts that haven't logged in recently
sudo lastlog -b 90    # no login in last 90 days
```

### Lock down system accounts

```bash
# System service accounts should have no shell
# Check which ones have shells that shouldn't
awk -F: '$3 < 1000 && $7 != "/sbin/nologin" && $7 != "/bin/false" {print $1, $7}' /etc/passwd
```

---

## 🔬 Lab 4 — Sudo Hardening

```bash
sudo visudo    # always use visudo, never edit sudoers directly
```

### Best practices for /etc/sudoers

```bash
# BAD — gives full root access
username ALL=(ALL) ALL

# BETTER — requires password
username ALL=(ALL) ALL

# BEST — specific commands only
username ALL=(ALL) /usr/bin/systemctl restart httpd, /usr/bin/systemctl status httpd

# Allow a group (wheel) with password required
%wheel ALL=(ALL) ALL

# NEVER do this (passwordless sudo)
# username ALL=(ALL) NOPASSWD: ALL   ← extremely dangerous

# Log all sudo commands
Defaults logfile=/var/log/sudo.log
Defaults log_input, log_output

# Require TTY (prevents sudo from cron/scripts without explicit allow)
Defaults requiretty

# Set sudo session timeout (minutes)
Defaults timestamp_timeout=5
```

### Drop-in sudoers files (safer than editing main file)

```bash
# Create specific config in /etc/sudoers.d/
sudo visudo -f /etc/sudoers.d/ed-permissions

# Contents:
ed ALL=(ALL) /usr/bin/systemctl, /usr/bin/journalctl
```

---

## 🔬 Lab 5 — Root Account

```bash
# Disable direct root login (force use of sudo)
sudo passwd -l root

# Verify root is locked
sudo passwd -S root
# Should show: root L (L = locked)

# Prevent root SSH login (covered in Lab 02 too)
sudo grep PermitRootLogin /etc/ssh/sshd_config
# Should be: PermitRootLogin no
```

---

## 🔬 Lab 6 — Account Lockout Policy (pam_faillock)

Lock accounts after too many failed login attempts:

```bash
sudo nano /etc/security/faillock.conf
```

```ini
# Lock after 5 failures
deny = 5

# Lockout for 15 minutes
unlock_time = 900

# Count failures within this window (seconds)
fail_interval = 900

# Also lock root
even_deny_root = true
```

```bash
# Check lockout status for a user
sudo faillock --user username

# Unlock a locked account
sudo faillock --user username --reset
```

---

## 🧪 Challenge

On your Rocky Linux VM (or note the answers for your system):

1. Find all users with UID 0 — are there any besides root?
2. Check all accounts for empty passwords
3. Set password aging on your test user: max 90 days, warn at 14 days
4. Configure `pwquality.conf` with minlen=14 and require all character types
5. Add a sudoers drop-in that allows a test user to run `systemctl` only
6. Lock the root account and verify

---

## 📚 Key Takeaways

| Command | What It Does |
|---------|-------------|
| `chage -l username` | View password aging settings |
| `chage -M 90 username` | Set max password age |
| `passwd -l username` | Lock an account |
| `usermod -s /sbin/nologin` | Disable shell without deleting |
| `visudo` | Safely edit sudoers |
| `faillock --user` | Check account lockout status |
| `/etc/security/pwquality.conf` | Password strength rules |
| `/etc/security/faillock.conf` | Account lockout rules |

---

## ➡️ Next Lab

`02-ssh-hardening.md` — Lock down SSH, the most common remote attack vector.

---

*Lab created: 2026-04-07 | Linux Hardening Series*
