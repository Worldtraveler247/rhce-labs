# 06 - Ansible Vault — Encrypting Secrets

**Series:** RHCE Ansible Labs  
**Lab:** 06 | **Prereq:** 05-inventory-and-groups.md  
**Goal:** Encrypt passwords, API keys, and secrets so they're safe in Git — but still usable by Ansible.

---

## 🧠 What Is Ansible Vault?

Ansible Vault encrypts files or variables using AES-256. You can commit encrypted files to Git safely — only someone with the vault password can decrypt them.

---

## 🔬 Lab 1 — Encrypt a File

```bash
cd ~/ansible-practice
mkdir -p 06

# Create and encrypt a secrets file
ansible-vault create 06/secrets.yml
# You'll be prompted to set a vault password
# Enter: ansible123 (for this lab)
```

The editor opens. Type your secrets:
```yaml
---
db_password: "supersecret123"
api_key: "sk-abc123xyz789"
admin_user: "vaultadmin"
admin_password: "V@ult$ecure!"
```
Save and quit.

```bash
# View the encrypted file — looks like gibberish
cat 06/secrets.yml

# Decrypt and view
ansible-vault view 06/secrets.yml
# Enter vault password: ansible123

# Edit encrypted file
ansible-vault edit 06/secrets.yml
```

---

## 🔬 Lab 2 — Encrypt an Existing File

```bash
# Create a plain file first
cat > 06/plain-secrets.yml << 'EOF'
---
smtp_password: "mailpassword123"
aws_secret_key: "awssecretkey456"
EOF

# Encrypt it in place
ansible-vault encrypt 06/plain-secrets.yml

# Decrypt it (back to plaintext)
ansible-vault decrypt 06/plain-secrets.yml

# Re-encrypt it
ansible-vault encrypt 06/plain-secrets.yml
```

---

## 🔬 Lab 3 — Use Vault in a Playbook

```bash
nano 06/use-vault.yml
```

```yaml
---
- name: Vault Lab
  hosts: localhost
  connection: local
  vars_files:
    - secrets.yml    # encrypted file — Ansible decrypts at runtime

  tasks:
    - name: Show that secrets are loaded (DON'T do this in real playbooks!)
      debug:
        msg: "DB password length: {{ db_password | length }} chars"

    - name: Simulate DB connection
      debug:
        msg: "Connecting as {{ admin_user }} to database"

    - name: Show API key is available (masked)
      debug:
        msg: "API key starts with: {{ api_key[:5] }}..."
```

```bash
# Run with vault password prompt
ansible-playbook 06/use-vault.yml --ask-vault-pass
# Enter: ansible123
```

---

## 🔬 Lab 4 — Vault Password File

Typing the password every time gets old. Use a password file:

```bash
# Create a password file
echo "ansible123" > ~/.vault_password
chmod 600 ~/.vault_password     # restrict permissions!

# Run without prompt
ansible-playbook 06/use-vault.yml --vault-password-file ~/.vault_password
```

Or set it in `ansible.cfg`:

```bash
nano ~/ansible-practice/ansible.cfg
```

```ini
[defaults]
vault_password_file = ~/.vault_password
```

Now `--vault-password-file` isn't needed — Ansible finds it automatically.

---

## 🔬 Lab 5 — Encrypt Individual Variables (Inline Vault)

Instead of encrypting a whole file, encrypt just one variable:

```bash
# Encrypt a single value
ansible-vault encrypt_string 'supersecret123' --name 'db_password'
# Enter vault password: ansible123
```

Output looks like:
```yaml
db_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          66386439653236336462626566653337623062383435663832306...
```

Paste that directly into any YAML file — group_vars, host_vars, playbooks:

```yaml
---
# group_vars/databases.yml
db_host: "db01.example.com"
db_port: 5432
db_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          66386439653236336462626566653337623062383435663832306...
```

Only the password is encrypted — everything else stays readable.

---

## 🔬 Lab 6 — Multiple Vault Passwords (Vault IDs)

Use different passwords for dev and prod:

```bash
# Encrypt with a specific vault ID
ansible-vault encrypt_string 'devpassword' --name 'db_password' --vault-id dev@~/.vault_dev
ansible-vault encrypt_string 'prodpassword' --name 'db_password' --vault-id prod@~/.vault_prod

# Run playbook with multiple vault passwords
ansible-playbook site.yml --vault-id dev@~/.vault_dev --vault-id prod@~/.vault_prod
```

---

## 🔬 Lab 7 — Re-keying (Change Vault Password)

```bash
# Change the vault password on an encrypted file
ansible-vault rekey 06/secrets.yml
# Old vault password: ansible123
# New vault password: newpassword456
# Confirm: newpassword456
```

---

## 🔬 Lab 8 — What to Vault (Best Practices)

**Always vault:**
- Database passwords
- API keys and tokens
- SSH private keys
- TLS certificates/private keys
- SMTP passwords
- Any credential

**Never vault:**
- Hostnames, ports, usernames (unless the username is also sensitive)
- Non-sensitive config values
- Public keys

**Structure recommendation:**
```
group_vars/
  all/
    vars.yml       ← non-sensitive variables (committed plaintext)
    vault.yml      ← all secrets (committed encrypted)
```

Reference secrets in `vars.yml` so non-sensitive config stays readable:
```yaml
# vars.yml (plaintext)
db_password: "{{ vault_db_password }}"

# vault.yml (encrypted)
vault_db_password: "the-actual-password"
```

---

## 🧪 Challenge

1. Create an encrypted `06/prod-secrets.yml` with 5 fake credentials
2. Write a playbook that loads the vault file and prints the *length* of each secret (not the value)
3. Configure `ansible.cfg` to use a vault password file
4. Run the playbook without `--ask-vault-pass` (it should just work)

---

## 📚 Key Takeaways

| Command | What It Does |
|---------|-------------|
| `ansible-vault create file.yml` | Create new encrypted file |
| `ansible-vault encrypt file.yml` | Encrypt existing file |
| `ansible-vault decrypt file.yml` | Decrypt to plaintext |
| `ansible-vault view file.yml` | View without decrypting on disk |
| `ansible-vault edit file.yml` | Edit encrypted file |
| `ansible-vault rekey file.yml` | Change vault password |
| `ansible-vault encrypt_string` | Encrypt a single value inline |
| `--ask-vault-pass` | Prompt for password at runtime |
| `--vault-password-file` | Read password from file |

---

## ➡️ Next Lab

`07-error-handling.md` — Handle failures gracefully: ignore errors, rescue blocks, and rollback strategies.

---

*Lab created: 2026-04-07 | RHCE Ansible Series*
