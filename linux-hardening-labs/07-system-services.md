# 07 - System Services and Attack Surface Reduction

**Series:** Linux Hardening Labs  
**Lab:** 07 | **Prereq:** 06-auditd.md  
**Goal:** Identify and disable unnecessary services, close unused ports, and minimize what an attacker can target.

---

## 🧠 Attack Surface = Everything Running

Every running service is a potential entry point. A web server only needs: SSH, HTTPS, maybe a monitoring agent. Everything else should be off.

**Rule:** If you don't need it, disable it.

---

## 🔬 Lab 1 — Audit Running Services

```bash
# List all running services
sudo systemctl list-units --type=service --state=running

# List all enabled services (will start on boot)
sudo systemctl list-unit-files --type=service --state=enabled

# Show all services — running and stopped
sudo systemctl list-units --type=service --all

# Check if a specific service is running
sudo systemctl is-active sshd
sudo systemctl is-enabled sshd
```

---

## 🔬 Lab 2 — Audit Open Ports

```bash
# Show all listening ports and which process owns them
sudo ss -tlnup

# Alternative with more detail
sudo netstat -tlnup     # (if net-tools installed)

# Show all established connections
sudo ss -tnup

# Check a specific port
sudo ss -tlnup | grep :22
sudo ss -tlnup | grep :80

# Map ports to services
sudo ss -tlnup | awk '{print $1, $4, $6}' | column -t
```

---

## 🔬 Lab 3 — Disable Unnecessary Services

Common services to evaluate and often disable on servers:

```bash
# Bluetooth (disable on servers always)
sudo systemctl disable bluetooth --now

# Avahi (mDNS/zero-conf — not needed on servers)
sudo systemctl disable avahi-daemon --now

# Cups (printing — not needed on servers)
sudo systemctl disable cups --now

# rpcbind (NFS-related — disable if not using NFS)
sudo systemctl disable rpcbind --now

# postfix (mail — disable if not sending mail locally)
sudo systemctl disable postfix --now

# NetworkManager (use on workstations, not servers — use network service instead)
# Evaluate based on your setup

# Check if NFS services are needed
sudo systemctl disable nfs-server --now
sudo systemctl disable nfs-client.target --now

# Disable cockpit (web management — remove if not used)
sudo systemctl disable cockpit.socket --now
```

### After disabling — verify

```bash
# Re-check open ports — fewer should show
sudo ss -tlnup

# Re-check running services
sudo systemctl list-units --type=service --state=running
```

---

## 🔬 Lab 4 — Remove Unnecessary Packages

Installed but unused packages are attack surface:

```bash
# List all installed packages
sudo rpm -qa | sort

# Find packages you probably don't need on a server
sudo rpm -qa | grep -E 'telnet|ftp|rsh|talk|tftp'

# Remove insecure legacy tools
sudo dnf remove telnet ftp rsh-server rsh tftp-server talk talk-server -y

# Remove X11/GUI packages on headless servers
sudo dnf group remove "Server with GUI" -y
sudo dnf remove xorg-x11* -y

# Check for and remove setuid binaries from removed packages
sudo find /usr/bin /usr/sbin -perm -4000 -type f 2>/dev/null

# List installed services via packages
sudo rpm -qa --queryformat '%{NAME}: %{SUMMARY}\n' | grep -i server
```

---

## 🔬 Lab 5 — Disable Unused Kernel Modules

```bash
# List loaded kernel modules
lsmod

# Disable modules permanently (add to blacklist)
sudo nano /etc/modprobe.d/blacklist-hardening.conf
```

```ini
# Disable USB storage (prevent data theft via USB)
blacklist usb-storage
install usb-storage /bin/false

# Disable legacy network protocols (rarely needed)
blacklist dccp
install dccp /bin/false

blacklist sctp
install sctp /bin/false

blacklist rds
install rds /bin/false

blacklist tipc
install tipc /bin/false

# Disable Firewire (if no Firewire devices)
blacklist firewire-core
install firewire-core /bin/false

# Disable Bluetooth (if already disabled via service)
blacklist bluetooth
install bluetooth /bin/false
```

```bash
# Rebuild initramfs to apply
sudo dracut -f

# Or just reboot
```

---

## 🔬 Lab 6 — Cron Security

Cron can be a persistence mechanism for attackers:

```bash
# List all crontabs
sudo crontab -l -u root
for user in $(cut -f1 -d: /etc/passwd); do
    crontab -l -u $user 2>/dev/null && echo "^ $user"
done

# Check all cron directories
sudo ls -la /etc/cron.d/
sudo ls -la /etc/cron.daily/
sudo ls -la /etc/cron.weekly/
sudo ls -la /etc/cron.monthly/
sudo ls -la /var/spool/cron/

# Restrict cron to specific users
sudo echo "root" > /etc/cron.allow
sudo rm -f /etc/cron.deny

# Restrict at to specific users
sudo echo "root" > /etc/at.allow
sudo rm -f /etc/at.deny

# Lock down cron directories
sudo chmod 700 /etc/cron.d /etc/cron.daily /etc/cron.weekly /etc/cron.monthly
sudo chmod 600 /etc/crontab
```

---

## 🔬 Lab 7 — Systemd Service Hardening

Harden specific systemd services with security directives:

```bash
# Create a drop-in override for a service
sudo systemctl edit nginx
```

```ini
[Service]
# Run as non-root user
User=nginx
Group=nginx

# Restrict filesystem access
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/nginx /var/cache/nginx

# No new privileges
NoNewPrivileges=true

# Restrict system calls
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM

# Network access
PrivateNetwork=false   # set true to completely isolate network

# Temp directory isolation
PrivateTmp=true

# Deny capability elevation
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart nginx

# Check security score of a service
sudo systemd-analyze security nginx
# Shows a score — lower is more hardened
```

---

## 🧪 Challenge

1. Run `sudo ss -tlnup` — document every open port and what it is
2. Disable at least 3 services not needed on a web server
3. Remove telnet, ftp, and rsh if installed
4. Restrict cron to root only using `/etc/cron.allow`
5. Blacklist `usb-storage` and `dccp` kernel modules
6. Run `systemd-analyze security sshd` and note the score

---

## 📚 Key Takeaways

| Command | What It Does |
|---------|-------------|
| `systemctl list-units --state=running` | All running services |
| `ss -tlnup` | All open ports + owning processes |
| `systemctl disable svc --now` | Stop and disable a service |
| `dnf remove package` | Remove unneeded packages |
| `/etc/modprobe.d/blacklist.conf` | Disable kernel modules |
| `cron.allow` | Whitelist who can use cron |
| `systemctl edit service` | Add hardening to a service |
| `systemd-analyze security` | Score a service's security |

---

## ➡️ Next Lab

`08-kernel-hardening.md` — Harden the kernel itself with sysctl parameters.

---

*Lab created: 2026-04-07 | Linux Hardening Series*
