# Daily RHCE Practice Routine
*15–30 minutes a day. Do this every day.*

---

## 🌅 Morning Warm-Up (5 min) — Linux CLI Drills

Pick ONE of these each day and do it from memory in terminal:

### Week 1-2 Rotation
```bash
# Day 1 — File & directory navigation
ls -lah /etc | head -20
find /home -type f -name "*.log" 2>/dev/null
du -sh /var/log/*

# Day 2 — User & group management
id
whoami
cat /etc/passwd | grep -v nologin
groups

# Day 3 — Process management
ps aux | sort -k3 -rn | head -10   # top CPU users
top -bn1 | head -20
kill -l                             # list all signals

# Day 4 — Networking
ip a
ss -tulnp                          # open ports
ping -c 3 google.com
traceroute google.com

# Day 5 — Services (systemd)
systemctl list-units --type=service --state=running
systemctl status sshd
journalctl -n 50 --no-pager

# Day 6 — File permissions
ls -l /etc/shadow
chmod 600 testfile.txt && ls -l testfile.txt
stat testfile.txt

# Day 7 — Package management (if on RHEL/Rocky/Fedora VM)
dnf list installed | wc -l
dnf search httpd
rpm -qa | grep ssh
```

---

## 🔧 Main Practice (15–20 min) — Ansible Lab

Work through `ansible-labs/` in order. One lab per session.
See `ansible-labs/00-getting-started.md` to begin.

---

## 📝 End of Session (5 min) — Log It

Open `notes/progress-log.md` and write:
- What you practiced
- One thing you learned
- One thing you want to look up next

Keeping a log = résumé material + tracks your growth.

---

## 📌 Automation Tip
Run `~/Documents/rhce/scripts/daily-check.sh` each morning.
It will remind you what to practice and log your streak.
(Script in `scripts/` folder)
