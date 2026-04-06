# 07 - Terraform + Ansible Together

**Series:** Terraform Labs  
**Lab:** 07 | **Prereq:** 06-workspaces.md + Ansible Labs 00-01  
**Goal:** Use Terraform to provision infrastructure, then Ansible to configure it. The ultimate IaC combo.

---

## 🧠 The Divide

| Tool | Job | Analogy |
|------|-----|---------|
| Terraform | Build the infrastructure | Contractor builds the house |
| Ansible | Configure what's on it | Interior designer furnishes it |

- Terraform creates the EC2 instance, VPC, security groups
- Ansible installs packages, configures services, deploys apps

They're not competitors — they're teammates.

---

## 🔬 Lab 1 — Terraform Outputs → Ansible Inventory

The key integration: Terraform outputs the IPs, Ansible reads them.

### Terraform side — output the IP

```bash
mkdir -p ~/terraform-labs/07-combined/terraform
cd ~/terraform-labs/07-combined/terraform
nano main.tf
```

```hcl
provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "web_sg" {
  name        = "terraform-ansible-lab"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name      = "terraform-ansible-web"
    ManagedBy = "Terraform+Ansible"
  }
}
```

```bash
nano variables.tf
```

```hcl
variable "key_name" {
  type        = string
  description = "Name of your EC2 key pair"
}
```

```bash
nano outputs.tf
```

```hcl
output "web_server_ip" {
  value = aws_instance.web_server.public_ip
}

output "web_server_id" {
  value = aws_instance.web_server.id
}
```

### Generate Ansible inventory from Terraform output

```bash
terraform apply
terraform output -raw web_server_ip
```

Create inventory dynamically:

```bash
# Auto-generate inventory file
echo "[webservers]
$(terraform output -raw web_server_ip) ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/your-key.pem" > ../ansible/inventory.ini
```

### Ansible side — configure the server

```bash
mkdir -p ~/terraform-labs/07-combined/ansible
cd ~/terraform-labs/07-combined/ansible
nano install-web.yml
```

```yaml
---
- name: Configure Web Server
  hosts: webservers
  become: true

  vars:
    packages:
      - httpd
      - git
      - curl

  tasks:
    - name: Wait for SSH to be available
      wait_for_connection:
        delay: 10
        timeout: 120

    - name: Install packages
      dnf:
        name: "{{ packages }}"
        state: present

    - name: Start and enable Apache
      service:
        name: httpd
        state: started
        enabled: true

    - name: Deploy index page
      copy:
        content: |
          <h1>Deployed by Terraform + Ansible</h1>
          <p>Server: {{ ansible_hostname }}</p>
          <p>IP: {{ ansible_default_ipv4.address }}</p>
        dest: /var/www/html/index.html
        owner: apache
        group: apache
        mode: '0644'

  handlers:
    - name: restart apache
      service:
        name: httpd
        state: restarted
```

```bash
ansible-playbook -i inventory.ini install-web.yml
```

### Verify

```bash
curl http://$(cd ../terraform && terraform output -raw web_server_ip)
```

---

## 🔬 Lab 2 — local-exec Provisioner (Terraform calls Ansible)

You can trigger Ansible directly from Terraform after provisioning:

```hcl
resource "aws_instance" "web_server" {
  # ... instance config ...

  provisioner "local-exec" {
    command = <<-EOT
      sleep 30  # wait for SSH
      ansible-playbook \
        -i '${self.public_ip},' \
        -u ec2-user \
        --private-key ~/.ssh/your-key.pem \
        ../ansible/install-web.yml
    EOT
  }
}
```

⚠️ **Note:** HashiCorp recommends avoiding provisioners when possible — prefer running Ansible separately or via CI/CD.

---

## 🔬 Lab 3 — Terraform Dynamic Inventory for Ansible

For larger setups, use Ansible's AWS dynamic inventory instead of static files:

```bash
pip install boto3 botocore
ansible-galaxy collection install amazon.aws

# Use dynamic inventory
ansible-inventory -i aws_ec2.yml --list

# Run playbook with dynamic inventory
ansible-playbook -i aws_ec2.yml install-web.yml
```

`aws_ec2.yml`:
```yaml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  tag:ManagedBy: "Terraform+Ansible"
keyed_groups:
  - key: tags.Environment
    prefix: env
```

---

## 🧪 Challenge

1. Terraform: provision an EC2 instance, output its IP
2. Write a shell script `deploy.sh` that:
   - Runs `terraform apply`
   - Captures the output IP
   - Generates `inventory.ini`
   - Runs `ansible-playbook`
3. Run the full pipeline end-to-end with one command: `./deploy.sh`

---

## 📚 Key Takeaways

| Concept | What to Remember |
|---------|-----------------|
| Terraform = provisioning | Creates the infrastructure |
| Ansible = configuration | Configures what's on it |
| `terraform output` | Bridge between the two tools |
| Dynamic inventory | Better than static for auto-scaling |
| `local-exec` | Lets Terraform call external tools (use sparingly) |

---

## ➡️ Next Labs

`08-security.md` — IAM, secrets, Vault, and Terraform security best practices  
`09-cicd.md` — Automate with GitHub Actions  
`10-full-project.md` — Production VPC with everything

---

*Lab created: 2026-04-07 | Terraform Series*
