# 03 - Firewall with firewalld

**Series:** Linux Hardening Labs  
**Lab:** 03 | **Prereq:** 02-ssh-hardening.md  
**Goal:** Control all inbound and outbound network traffic using firewalld zones and rules.

---

## 🧠 firewalld vs iptables

`firewalld` is the default firewall manager on RHEL/Rocky Linux. It sits on top of `nftables` (or iptables on older systems) and provides a higher-level interface with zones.

| Tool | Notes |
|------|-------|
| `firewalld` | Default on RHEL 7+. Zone-based. Preferred. |
| `iptables` | Lower level. Still works. Legacy. |
| `nftables` | Modern replacement for iptables. firewalld uses it. |

---

## 🧠 Zones — The Key Concept

A zone defines the trust level of a network connection. Every interface is assigned to a zone.

| Zone | Trust Level | Use Case |
|------|-------------|----------|
| `drop` | None | Drop all incoming, no reply |
| `block` | None | Reject all incoming |
| `public` | Low | Internet-facing servers |
| `external` | Low | External with masquerade |
| `dmz` | Medium | DMZ servers |
| `work` | Medium-High | Work network |
| `home` | Medium-High | Home network |
| `internal` | High | Internal network |
| `trusted` | Full | Accept everything |

---

## 🔬 Lab 1 — Basic firewalld Commands

```bash
# Check if firewalld is running
sudo systemctl status firewalld

# Start and enable
sudo systemctl enable firewalld --now

# Check overall status
sudo firewall-cmd --state

# List all zones
sudo firewall-cmd --get-zones

# Get active zones and their interfaces
sudo firewall-cmd --get-active-zones

# Get default zone
sudo firewall-cmd --get-default-zone

# List everything in the current zone
sudo firewall-cmd --list-all

# List everything in a specific zone
sudo firewall-cmd --zone=public --list-all
```

---

## 🔬 Lab 2 — Managing Services and Ports

```bash
# List available predefined services
sudo firewall-cmd --get-services

# Add a service (temporary — lost on reload)
sudo firewall-cmd --add-service=http

# Add a service (permanent — survives reboot)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# Remove a service
sudo firewall-cmd --permanent --remove-service=http

# Add a specific port
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=2222/tcp    # custom SSH port

# Add port range
sudo firewall-cmd --permanent --add-port=8000-9000/tcp

# Remove a port
sudo firewall-cmd --permanent --remove-port=8080/tcp

# RELOAD after permanent changes (required!)
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-all
```

---

## 🔬 Lab 3 — Zone Management

```bash
# Assign interface to a zone
sudo firewall-cmd --permanent --zone=public --change-interface=eth0

# Change default zone
sudo firewall-cmd --set-default-zone=public

# Add service to specific zone
sudo firewall-cmd --permanent --zone=internal --add-service=mysql

# List services in a zone
sudo firewall-cmd --zone=public --list-services

# Create a custom zone
sudo firewall-cmd --permanent --new-zone=webapp
sudo firewall-cmd --reload
sudo firewall-cmd --permanent --zone=webapp --add-service=http
sudo firewall-cmd --permanent --zone=webapp --add-service=https
sudo firewall-cmd --reload
```

---

## 🔬 Lab 4 — Rich Rules (Advanced Filtering)

Rich rules give you granular control — filter by source IP, destination, port, and action:

```bash
# Allow SSH only from specific IP
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.100/32"
  service name="ssh"
  accept'

# Block a specific IP entirely
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="10.0.0.50"
  drop'

# Rate limit — allow only 3 new SSH connections per minute
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  service name="ssh"
  limit value="3/m"
  accept'

# Allow HTTP from a subnet
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="10.0.1.0/24"
  port protocol="tcp" port="80"
  accept'

# Log and drop
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="10.0.0.99"
  log prefix="BLOCKED: " level="warning"
  drop'

sudo firewall-cmd --reload
sudo firewall-cmd --list-rich-rules
```

---

## 🔬 Lab 5 — Masquerading and Port Forwarding

```bash
# Enable masquerade (NAT — for routing/VPN setups)
sudo firewall-cmd --permanent --zone=external --add-masquerade

# Port forwarding — forward port 80 to 8080 locally
sudo firewall-cmd --permanent --add-forward-port=port=80:proto=tcp:toport=8080

# Forward to another host
sudo firewall-cmd --permanent --zone=external \
  --add-forward-port=port=80:proto=tcp:toport=80:toaddr=192.168.1.20

sudo firewall-cmd --reload
```

---

## 🔬 Lab 6 — Hardened Server Firewall Profile

A typical hardened web server — only allow what's needed:

```bash
# Start clean — set default zone to public
sudo firewall-cmd --set-default-zone=public

# Remove default services that may be open
sudo firewall-cmd --permanent --zone=public --remove-service=dhcpv6-client
sudo firewall-cmd --permanent --zone=public --remove-service=cockpit

# Add only what's needed
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --permanent --zone=public --add-port=2222/tcp    # custom SSH

# Allow monitoring from internal network only (rich rule)
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="10.0.0.0/8"
  port protocol="tcp" port="9100"
  accept'

# Rate limit SSH
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  service name="ssh"
  limit value="5/m"
  accept'

sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

---

## 🔬 Lab 7 — Panic Mode and Testing

```bash
# Panic mode — block ALL traffic immediately (emergency)
sudo firewall-cmd --panic-on

# Turn off panic mode
sudo firewall-cmd --panic-off

# Check if panic is on
sudo firewall-cmd --query-panic

# Query if a specific service is allowed
sudo firewall-cmd --query-service=http    # yes/no

# Test rules without making them permanent (will revert after reload)
sudo firewall-cmd --add-service=telnet    # no --permanent
sudo firewall-cmd --reload                # reverts
```

---

## 🧪 Challenge

Configure a hardened firewall for a web server:
1. Default zone = public
2. Allow: HTTPS (443), custom SSH port 2222
3. Block: everything else
4. Add a rich rule: rate limit SSH to 3 connections/minute
5. Add a rich rule: block IP 10.10.10.10 completely
6. Make all rules permanent and reload
7. Verify with `--list-all`

---

## 📚 Key Takeaways

| Command | What It Does |
|---------|-------------|
| `--list-all` | Show all rules in current zone |
| `--permanent` | Make rule survive reboot |
| `--reload` | Apply permanent rules (required after changes) |
| `--add-service=` | Allow a named service |
| `--add-port=` | Allow a specific port |
| `--add-rich-rule=` | Advanced filtering by source/rate/action |
| `--panic-on` | Emergency block all traffic |
| `--zone=` | Apply rule to specific zone |

---

## ➡️ Next Lab

`04-selinux.md` — SELinux: the most powerful and most misunderstood security tool on Linux.

---

*Lab created: 2026-04-07 | Linux Hardening Series*
