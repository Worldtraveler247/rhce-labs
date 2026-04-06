# 09 - Intrusion Detection with AIDE

**Series:** Linux Hardening Labs  
**Lab:** 09 | **Prereq:** 08-kernel-hardening.md  
**Goal:** Use AIDE to create a filesystem baseline and detect unauthorized changes.

---

## 🧠 What Is AIDE?

AIDE (Advanced Intrusion Detection Environment) takes a **snapshot** of your filesystem — checksums, permissions, ownership, timestamps. Later, it compares the current state against the snapshot and alerts on anything that changed.

Think of it as a tripwire: if an attacker modifies a system binary, AIDE catches it.

---

## 🔬 Lab 1 — Install and Configure

```bash
sudo dnf install aide -y

# View the default config
sudo cat /etc/aide.conf | head -60
```

### Key config sections

```bash
sudo nano /etc/aide.conf
```

```ini
# Database locations
database=file:/var/lib/aide/aide.db.gz
database_out=file:/var/lib/aide/aide.db.new.gz

# Log location
report_url=file:/var/log/aide/aide.log
report_url=stdout

# Define what to check (rule groups)
# p=permissions, i=inode, n=link count, u=user, g=group
# s=size, m=mtime, c=ctime, md5, sha256, sha512

# Full file integrity check
FIPSR = p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha512

# Just check ownership and permissions
PERMS = p+i+n+u+g

# Check content too
CONTENT = sha256+ftype

# ========================
# What to watch
# ========================

# Critical system binaries
/bin FIPSR
/sbin FIPSR
/usr/bin FIPSR
/usr/sbin FIPSR

# Libraries
/lib FIPSR
/lib64 FIPSR
/usr/lib FIPSR
/usr/lib64 FIPSR

# Config files
/etc PERMS
/etc/ssh FIPSR
/etc/pam.d FIPSR
/etc/sudoers FIPSR
/etc/passwd FIPSR
/etc/shadow FIPSR

# Boot files
/boot FIPSR

# Exclude dynamic/changing directories
!/var/log
!/var/spool
!/var/cache
!/tmp
!/proc
!/sys
!/dev
!/run
```

---

## 🔬 Lab 2 — Initialize the Database

```bash
# Create initial baseline (run after fully hardening the system)
sudo aide --init

# The new database is at:
ls -la /var/lib/aide/aide.db.new.gz

# Rename it to the active database
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

# Verify
ls -la /var/lib/aide/aide.db.gz
```

⚠️ **Critical:** Initialize AIDE after hardening is complete on a known-good system. The baseline must reflect a clean, trusted state.

---

## 🔬 Lab 3 — Check for Changes

```bash
# Run an integrity check
sudo aide --check

# Output explanation:
# Added files:      f++ = new file detected
# Removed files:    f-- = file deleted
# Changed files:    f>< = file modified

# Example output:
# AIDE found differences between database and filesystem!
# Changed files:
# f>< /etc/passwd
# Changed attributes:
#  Mtime: 2026-04-01 12:00:00 -> 2026-04-07 06:00:00

# Verbose check
sudo aide --check --verbose=2

# Check and log to file
sudo aide --check 2>&1 | tee /var/log/aide/aide-check.log
```

---

## 🔬 Lab 4 — Automate with Cron

```bash
# Run AIDE check daily at 2 AM
sudo crontab -e
```

```bash
# AIDE daily integrity check
0 2 * * * root /usr/sbin/aide --check 2>&1 | mail -s "AIDE Report: $(hostname)" root
```

Or create a systemd timer:

```bash
sudo nano /etc/systemd/system/aide-check.service
```

```ini
[Unit]
Description=AIDE integrity check
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/aide --check
StandardOutput=journal
StandardError=journal
```

```bash
sudo nano /etc/systemd/system/aide-check.timer
```

```ini
[Unit]
Description=Daily AIDE check

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
sudo systemctl enable aide-check.timer --now
sudo systemctl list-timers | grep aide
```

---

## 🔬 Lab 5 — Update the Database After Legitimate Changes

After applying patches or making authorized changes, update the baseline:

```bash
# After patching, rebuild the database
sudo aide --update

# Review what changed (make sure it's expected)
sudo aide --check

# If all changes are legitimate, promote new database
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

# Store the database securely (read-only media or remote)
# The database must be protected from the attacker
sudo scp /var/lib/aide/aide.db.gz backup-server:/secure/aide/
```

---

## 🔬 Lab 6 — Protect the AIDE Database

The AIDE database is the attacker's first target — if they can modify it, they can hide their tracks:

```bash
# Make database immutable
sudo chattr +i /var/lib/aide/aide.db.gz

# Store a copy offline or on a read-only remote location
# Never store the database on the same system being monitored

# Verify file hasn't changed using stored hash
sha512sum /var/lib/aide/aide.db.gz > /secure/remote/aide-db.sha512
```

---

## 🧪 Challenge

1. Install AIDE and configure it to watch `/etc`, `/usr/bin`, `/usr/sbin`
2. Initialize the database
3. Make a small change: `sudo touch /usr/bin/testfile`
4. Run `aide --check` and observe the alert
5. Remove the test file and update the database
6. Set up a cron job or systemd timer to run daily checks

---

## 📚 Key Takeaways

| Command | What It Does |
|---------|-------------|
| `aide --init` | Create initial baseline database |
| `aide --check` | Compare filesystem against baseline |
| `aide --update` | Rebuild database after legitimate changes |
| `/etc/aide.conf` | Configure what to watch and how |
| `/var/lib/aide/aide.db.gz` | The baseline database |
| `chattr +i aide.db.gz` | Protect database from modification |
| Cron / systemd timer | Automate daily checks |

---

## ➡️ Next Lab

`10-ansible-hardening.md` — Automate everything: apply all hardening with a single Ansible playbook.

---

*Lab created: 2026-04-07 | Linux Hardening Series*
