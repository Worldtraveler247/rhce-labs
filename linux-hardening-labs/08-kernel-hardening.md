# 08 - Kernel Hardening with sysctl

**Series:** Linux Hardening Labs  
**Lab:** 08 | **Prereq:** 07-system-services.md  
**Goal:** Harden the Linux kernel using sysctl parameters — disable dangerous features, enable protections.

---

## 🧠 What Is sysctl?

`sysctl` lets you read and write kernel parameters at runtime. These control network behavior, memory protections, file system limits, and security features. Changes can be made live or persisted across reboots.

---

## 🔬 Lab 1 — View and Set sysctl Parameters

```bash
# View all parameters
sudo sysctl -a

# View a specific parameter
sudo sysctl net.ipv4.ip_forward
sudo sysctl kernel.randomize_va_space

# Set a parameter temporarily (lost on reboot)
sudo sysctl -w net.ipv4.ip_forward=0

# Set permanently (persists across reboots)
echo "net.ipv4.ip_forward = 0" | sudo tee -a /etc/sysctl.d/99-hardening.conf

# Apply all sysctl config files
sudo sysctl --system

# Apply a specific file
sudo sysctl -p /etc/sysctl.d/99-hardening.conf
```

---

## 🔬 Lab 2 — Complete Hardened sysctl Config

```bash
sudo nano /etc/sysctl.d/99-hardening.conf
```

```ini
# ============================================================
# LINUX KERNEL HARDENING — sysctl
# Based on CIS Benchmark + STIG recommendations
# ============================================================

# ========================
# NETWORK — IP Forwarding
# ========================
# Disable IP forwarding (not a router)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# ========================
# NETWORK — Source Routing
# ========================
# Disable source routing (attacker-controlled routing)
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# ========================
# NETWORK — ICMP Redirects
# ========================
# Disable ICMP redirect acceptance (man-in-the-middle prevention)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Disable sending ICMP redirects (not a router)
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# ========================
# NETWORK — Secure ICMP
# ========================
# Ignore bogus ICMP responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Ignore ICMP broadcast (smurf attack prevention)
net.ipv4.icmp_echo_ignore_broadcasts = 1

# ========================
# NETWORK — TCP Hardening
# ========================
# Enable TCP SYN cookies (SYN flood protection)
net.ipv4.tcp_syncookies = 1

# RFC 1337 TIME-WAIT assassination fix
net.ipv4.tcp_rfc1337 = 1

# Reverse path filtering (anti-spoofing)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Disable TCP timestamps (hides uptime, reduces info leakage)
net.ipv4.tcp_timestamps = 0

# ========================
# NETWORK — IPv6
# ========================
# Disable IPv6 if not needed
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

# ========================
# KERNEL — Memory Protections
# ========================
# Address Space Layout Randomization (ASLR)
# 0=off, 1=conservative, 2=full (use 2)
kernel.randomize_va_space = 2

# Restrict kernel pointer leaks in /proc
kernel.kptr_restrict = 2

# Restrict dmesg to root only
kernel.dmesg_restrict = 1

# Restrict perf_event (hardware performance counters)
kernel.perf_event_paranoid = 3

# ========================
# KERNEL — ptrace (process tracing)
# ========================
# Restrict ptrace — prevent process injection
# 0=all, 1=child only, 2=with CAP_SYS_PTRACE, 3=disabled
kernel.yama.ptrace_scope = 1

# ========================
# KERNEL — Core Dumps
# ========================
# Disable core dumps (contain sensitive data)
fs.suid_dumpable = 0
kernel.core_uses_pid = 1

# ========================
# KERNEL — Magic SysRq
# ========================
# Disable magic SysRq key (physical access attack)
kernel.sysrq = 0

# ========================
# FILE SYSTEM
# ========================
# Protected hardlinks (prevent link attacks in /tmp)
fs.protected_hardlinks = 1
fs.protected_symlinks = 1

# Restrict /proc access
# (use hidepid=2 via mount options instead)

# ========================
# NETWORK — Additional
# ========================
# Log martian packets (packets with impossible source addresses)
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
```

```bash
# Apply immediately
sudo sysctl --system

# Verify key settings
sudo sysctl kernel.randomize_va_space
sudo sysctl net.ipv4.tcp_syncookies
sudo sysctl kernel.kptr_restrict
```

---

## 🔬 Lab 3 — Restrict /proc Filesystem

`/proc` can leak process information. Mount it with restrictions:

```bash
sudo nano /etc/fstab
```

```fstab
# Restrict /proc — users can't see other users' processes
proc /proc proc defaults,hidepid=2,gid=proc 0 0
```

```bash
# Apply without reboot
sudo mount -o remount,hidepid=2,gid=proc /proc

# Verify
ls /proc/*/cmdline 2>/dev/null | head -5
# Should only see your own processes
```

---

## 🔬 Lab 4 — Disable Unnecessary Kernel Features

```bash
# Check if exec-shield is supported (older kernels)
sudo sysctl kernel.exec-shield 2>/dev/null

# Check NX (no-execute) bit
sudo dmesg | grep NX

# Verify ASLR
cat /proc/sys/kernel/randomize_va_space
# Should be 2

# Check if SELinux is enforcing (kernel-level)
cat /sys/fs/selinux/enforce
# Should be 1
```

---

## 🔬 Lab 5 — Verify with Lynis

Lynis is a security auditing tool that checks sysctl and much more:

```bash
# Install
sudo dnf install lynis -y
# or
sudo yum install lynis -y

# Run a full audit
sudo lynis audit system

# Check specific sysctl findings
sudo lynis audit system | grep -A2 "sysctl"

# View the report
sudo cat /var/log/lynis-report.dat | grep "suggestion\|warning" | head -30
```

---

## 🧪 Challenge

1. Create `/etc/sysctl.d/99-hardening.conf` with all the settings from Lab 2
2. Apply with `sudo sysctl --system`
3. Verify these specific values:
   - `kernel.randomize_va_space = 2`
   - `net.ipv4.tcp_syncookies = 1`
   - `net.ipv4.ip_forward = 0`
   - `kernel.kptr_restrict = 2`
4. Mount `/proc` with `hidepid=2`
5. Run `lynis audit system` and document your hardening score

---

## 📚 Key Takeaways

| Parameter | Value | Protection |
|-----------|-------|-----------|
| `kernel.randomize_va_space` | `2` | ASLR — randomizes memory layout |
| `net.ipv4.tcp_syncookies` | `1` | SYN flood protection |
| `net.ipv4.ip_forward` | `0` | Not a router |
| `kernel.kptr_restrict` | `2` | Hide kernel pointers |
| `kernel.dmesg_restrict` | `1` | Root-only dmesg |
| `fs.protected_hardlinks` | `1` | Prevent link attacks |
| `kernel.yama.ptrace_scope` | `1` | Restrict process injection |
| `kernel.sysrq` | `0` | Disable magic SysRq |
| `net.ipv4.conf.all.rp_filter` | `1` | Anti-spoofing |

---

## ➡️ Next Lab

`09-aide.md` — Detect file tampering with AIDE (Advanced Intrusion Detection Environment).

---

*Lab created: 2026-04-07 | Linux Hardening Series*
