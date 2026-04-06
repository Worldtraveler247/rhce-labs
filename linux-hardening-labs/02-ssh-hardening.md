# 02 - SSH Hardening

**Series:** Linux Hardening Labs  
**Lab:** 02 | **Prereq:** 01-user-and-password-security.md  
**Goal:** Lock down SSH — the most commonly attacked service on any Linux server.

---

## 🧠 Why SSH Is a Target

SSH is almost always exposed. Automated bots scan the entire internet for port 22 continuously. A default SSH config is an open invitation for brute force attacks, root login attempts, and weak key exploitation.

---

## 🔬 Lab 1 — SSH Key-Based Authentication

**Rule #1: Never use passwords for SSH. Use keys.**

### Generate a strong key pair (on your local machine)

```bash
# Ed25519 — modern, fast, secure (preferred)
ssh-keygen -t ed25519 -C "ed@workstation" -f ~/.ssh/id_ed25519

# RSA 4096 — use if ed25519 not supported
ssh-keygen -t rsa -b 4096 -C "ed@workstation" -f ~/.ssh/id_rsa

# Always set a passphrase when prompted!
```

### Copy your public key to the server

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server-ip

# Manual method (if ssh-copy-id unavailable)
cat ~/.ssh/id_ed25519.pub | ssh user@server "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
```

### Verify key login works BEFORE disabling passwords

```bash
ssh -i ~/.ssh/id_ed25519 user@server-ip
# Confirm you can log in with the key
```

---

## 🔬 Lab 2 — Harden sshd_config

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak   # backup first!
sudo nano /etc/ssh/sshd_config
```

### Complete hardened sshd_config

```bash
# Change default port (obscures from automated scanners)
Port 2222

# Only listen on specific interface (if multi-homed)
# ListenAddress 192.168.1.10

# Protocol version (2 only — v1 is broken)
Protocol 2

# Allowed key types (modern only)
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

# =====================
# AUTHENTICATION
# =====================

# Disable root login ALWAYS
PermitRootLogin no

# Key-based auth only — disable passwords after keys are working
PasswordAuthentication no
PermitEmptyPasswords no

# Disable challenge-response (keyboard-interactive)
ChallengeResponseAuthentication no

# Disable PAM password auth
UsePAM yes
# (Keep UsePAM yes but passwords are disabled above)

# Max auth attempts before disconnect
MaxAuthTries 3

# Max SSH sessions per connection
MaxSessions 2

# =====================
# ACCESS CONTROL
# =====================

# Only allow specific users (whitelist)
AllowUsers ed adminuser

# Or allow specific groups only
# AllowGroups sshusers wheel

# Deny specific users
# DenyUsers baduser tempuser

# =====================
# SESSION SETTINGS
# =====================

# Disconnect idle sessions after 5 minutes
ClientAliveInterval 300
ClientAliveCountMax 2

# Disable X11 forwarding (unless needed)
X11Forwarding no

# Disable TCP forwarding (unless needed)
AllowTcpForwarding no

# Disable agent forwarding (unless needed)
AllowAgentForwarding no

# Disable port forwarding
GatewayPorts no

# =====================
# LOGGING
# =====================

# Log level (VERBOSE logs key fingerprints)
LogLevel VERBOSE
SyslogFacility AUTHPRIV

# =====================
# BANNERS
# =====================

# Show legal warning before login
Banner /etc/ssh/banner.txt
```

### Create a login banner

```bash
sudo nano /etc/ssh/banner.txt
```

```
***************************************************************************
                        AUTHORIZED ACCESS ONLY
This system is for authorized users only. All activity is monitored and
logged. Unauthorized access is prohibited and will be prosecuted.
***************************************************************************
```

### Validate and restart

```bash
# Validate config syntax BEFORE restarting
sudo sshd -t
# No output = no errors

# Restart SSH
sudo systemctl restart sshd

# Verify it's running
sudo systemctl status sshd
```

⚠️ **Keep your current session open when restarting SSH.** Test the new config in a new terminal window first.

---

## 🔬 Lab 3 — SSH Key Management

```bash
# View authorized keys for a user
cat ~/.ssh/authorized_keys

# Check key permissions (must be exactly this)
ls -la ~/.ssh/
# .ssh/          = drwx------ (700)
# authorized_keys = -rw------- (600)

# Fix permissions if wrong
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Remove a key (edit authorized_keys and delete the line)
nano ~/.ssh/authorized_keys

# Rotate keys — generate new pair, add new public key, remove old
```

---

## 🔬 Lab 4 — Fail2Ban (Block Brute Force)

Fail2ban monitors logs and automatically bans IPs that fail authentication.

```bash
sudo dnf install fail2ban -y

sudo nano /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
# Ban for 1 hour
bantime  = 3600

# Find window (10 minutes)
findtime = 600

# Max failures before ban
maxretry = 5

# Email alerts (optional)
# destemail = ed@example.com

[sshd]
enabled  = true
port     = 2222          # match your SSH port
filter   = sshd
logpath  = /var/log/secure
maxretry = 3
bantime  = 86400         # 24 hours for SSH
```

```bash
sudo systemctl enable fail2ban --now

# Check status
sudo fail2ban-client status
sudo fail2ban-client status sshd

# View banned IPs
sudo fail2ban-client status sshd | grep 'Banned IP'

# Unban an IP
sudo fail2ban-client set sshd unbanip 192.168.1.100
```

---

## 🔬 Lab 5 — SSH Port Knocking (Advanced)

Port knocking hides SSH — port 22 appears closed until you knock the right sequence:

```bash
sudo dnf install knock-server -y

sudo nano /etc/knockd.conf
```

```ini
[options]
    UseSyslog

[openSSH]
    sequence    = 7000,8000,9000
    seq_timeout = 5
    command     = /sbin/iptables -A INPUT -s %IP% -p tcp --dport 2222 -j ACCEPT
    tcpflags    = syn

[closeSSH]
    sequence    = 9000,8000,7000
    seq_timeout = 5
    command     = /sbin/iptables -D INPUT -s %IP% -p tcp --dport 2222 -j ACCEPT
    tcpflags    = syn
```

```bash
# From client — knock sequence, then connect
knock server-ip 7000 8000 9000
ssh -p 2222 user@server-ip
knock server-ip 9000 8000 7000   # close after
```

---

## 🔬 Lab 6 — SSH Audit Tool

```bash
# Install ssh-audit
pip3 install ssh-audit

# Scan your SSH server
ssh-audit localhost

# Scan remote
ssh-audit server-ip
```

Shows which algorithms are weak and recommends fixes.

---

## 🧪 Challenge

1. Generate an Ed25519 key pair
2. Copy the public key to your VM
3. Verify key-based login works
4. Apply the hardened `sshd_config` (change port to 2222, disable passwords, disable root)
5. Validate with `sshd -t` before restarting
6. Test login on new port: `ssh -p 2222 user@server`
7. Install and configure fail2ban with maxretry=3

---

## 📚 Key Takeaways

| Setting | Value | Why |
|---------|-------|-----|
| `PermitRootLogin` | `no` | Never allow direct root SSH |
| `PasswordAuthentication` | `no` | Keys only |
| `Port` | non-22 | Reduces automated scan noise |
| `MaxAuthTries` | `3` | Slow down brute force |
| `ClientAliveInterval` | `300` | Kill idle sessions |
| `AllowUsers` | whitelist | Only named users can SSH |
| `LogLevel` | `VERBOSE` | Log key fingerprints |

---

## ➡️ Next Lab

`03-firewall-firewalld.md` — Control network traffic with firewalld zones and rules.

---

*Lab created: 2026-04-07 | Linux Hardening Series*
