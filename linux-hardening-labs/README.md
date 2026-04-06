# Linux Hardening Labs — Beginner to Expert

**Location:** `~/Documents/rhce/linux-hardening-labs/`  
**Recommended VM:** Rocky Linux 9 (multipass, Vagrant, or AWS t2.micro)  
**Goal:** Harden Linux systems to CIS Benchmark standards

---

## Lab Series

| # | File | Topic | Level |
|---|------|-------|-------|
| 00 | `00-introduction.md` | Hardening mindset and threat model | Beginner |
| 01 | `01-user-and-password-security.md` | Accounts, PAM, faillock, sudo | Beginner |
| 02 | `02-ssh-hardening.md` | Key auth, sshd_config, fail2ban | Beginner |
| 03 | `03-firewall-firewalld.md` | Zones, rich rules, hardened profile | Beginner |
| 04 | `04-selinux.md` | Contexts, booleans, ports, troubleshoot | Intermediate |
| 05 | `05-file-permissions.md` | SUID audit, ACLs, chattr, umask | Intermediate |
| 06 | `06-auditd.md` | Audit rules, ausearch, aureport | Intermediate |
| 07 | `07-system-services.md` | Service audit, attack surface reduction | Intermediate |
| 08 | `08-kernel-hardening.md` | sysctl, ASLR, /proc, anti-spoofing | Advanced |
| 09 | `09-aide.md` | Filesystem baseline, change detection | Advanced |
| 10 | `10-ansible-hardening.md` | Automate all hardening as a role | Advanced |
| 11 | `11-cis-benchmark.md` | Lynis, OpenSCAP, full audit + remediation | Expert |

---

## Quick Start (get a VM first)

```bash
# Option 1: multipass
brew install multipass
multipass launch --name rocky-lab --cpus 2 --mem 2G
multipass shell rocky-lab

# Option 2: AWS free tier
# Launch Amazon Linux 2023 or RHEL instance
# t2.micro — free tier eligible
```

---

## RHCE + Cloud Security Relevance

| Lab | RHCE | Cloud Security |
|-----|------|---------------|
| SSH Hardening | ✅ | ✅ |
| firewalld | ✅ | ✅ |
| SELinux | ✅ Core topic | ✅ |
| auditd | ✅ | ✅ Compliance |
| Ansible Hardening | ✅ Core topic | ✅ |
| CIS Benchmark | — | ✅ Essential |

---

*Created: 2026-04-07*
