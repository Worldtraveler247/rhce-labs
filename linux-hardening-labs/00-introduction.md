# 00 - Introduction to Linux Hardening

**Series:** Linux Hardening Labs  
**Lab:** 00 | **Prereq:** RHCSA complete  
**Goal:** Understand the Linux hardening mindset, threat model, and what this series covers.

---

## 🧠 What Is Linux Hardening?

Hardening means reducing the attack surface of a system — removing unnecessary services, locking down access, enabling audit logging, and configuring security controls so that if an attacker gets in, they can't do much.

The goal is never 100% security (impossible). The goal is:
- **Reduce exposure** — fewer entry points
- **Detect intrusions** — know when something is wrong
- **Limit blast radius** — if one thing breaks, it doesn't take everything down
- **Meet compliance** — CIS Benchmarks, STIG, SOC2, PCI-DSS

---

## 🎯 Threat Model — What Are We Defending Against?

| Threat | Example |
|--------|---------|
| Remote exploitation | Open ports, vulnerable services |
| Brute force | SSH password attacks |
| Privilege escalation | Local user → root |
| Lateral movement | Compromised host → other hosts |
| Data exfiltration | Sensitive files copied out |
| Insider threat | Malicious or careless admin |
| Persistence | Backdoors, cron jobs, modified binaries |

---

## 📚 The Lab Series

| Lab | Topic | Level |
|-----|-------|-------|
| 00 | Introduction + Mindset | Beginner |
| 01 | User and Password Security | Beginner |
| 02 | SSH Hardening | Beginner |
| 03 | Firewall with firewalld | Beginner |
| 04 | SELinux | Intermediate |
| 05 | File Permissions and SUID/SGID | Intermediate |
| 06 | Audit Logging with auditd | Intermediate |
| 07 | System Services and Attack Surface | Intermediate |
| 08 | Kernel Hardening with sysctl | Advanced |
| 09 | Intrusion Detection with AIDE | Advanced |
| 10 | Automation — Harden with Ansible | Advanced |
| 11 | Full Audit — CIS Benchmark | Expert |

---

## 🛠️ Lab Environment

These labs are designed for **RHEL/CentOS/Rocky Linux**. Some commands also work on macOS for practice. Where behavior differs, it will be noted.

For full practice: spin up a Rocky Linux 9 VM or use a cloud instance.

```bash
# Quick Rocky Linux VM with multipass (Mac)
brew install multipass
multipass launch --name rocky-lab --cpus 2 --mem 2G

# Or use Vagrant
vagrant init rockylinux/9
vagrant up
vagrant ssh
```

---

## 🔑 The Hardening Mindset

1. **Default deny** — block everything, open only what's needed
2. **Least privilege** — users and processes get minimum access required
3. **Defense in depth** — multiple layers, no single point of failure
4. **Assume breach** — design as if attackers are already inside
5. **Audit everything** — if you can't see it, you can't defend it

---

## ➡️ Next Lab

`01-user-and-password-security.md` — Lock down user accounts, password policies, and sudo.

---

*Lab created: 2026-04-07 | Linux Hardening Series*
