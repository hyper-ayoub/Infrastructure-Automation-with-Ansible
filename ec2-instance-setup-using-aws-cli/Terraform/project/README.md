
```
┌─────────────────────────────────────────────────────────────┐
│                         AWS VPC                            │
│  CIDR: 10.0.0.0/16                                        │
│                                                            │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Public Subnet                          │    │
│  │          CIDR: 10.0.1.0/24                         │    │
│  │                                                     │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │    │
│  │  │ Controller  │  │  Target-1   │  │  Target-2   │ │    │
│  │  │    EC2      │  │    EC2      │  │    EC2      │ │    │
│  │  │  (Ansible)  │  │  (Docker)   │  │  (Docker)   │ │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘ │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                            │
│  Internet Gateway ←→ Route Table                           │
└─────────────────────────────────────────────────────────────┘
```
  
  
  **Create a VPC with networking components**  
  **Launch a control EC2 with Ansible installed**  
  **Launch 2 target EC2s (Ubuntu)**  
  **Use Ansible with AWS Dynamic Inventory to install Docker on both targets**

##  **1\. Prerequisites**

You need:

* AWS account

* IAM user with EC2, VPC, IAM, and S3 full access

* `terraform`, `ansible`, `awscli` installed

* SSH key pair (or generate one in Terraform)

* Your public key ready (`id_rsa.pub`)

##  **2\. Terraform Structure**

**`project/`**  
**`│`**  
**`├── terraform/`**  
**`│   ├── main.tf`**  
**`│   ├── variables.tf`**  
**`│   ├── outputs.tf`**  
**`│`**  
**`├── ansible/`**  
**`│   ├── install_docker.yml`**  
**`│   ├── ansible.cfg`**  
**`│   ├── aws_ec2.yml`**  
**`│`**  
**`└── keys/`**  
    **`└── id_rsa.pub  (your public key)`**

## **3\. Terraform Infrastructure (`terraform/`)**

### **`variables.tf`**

`variable "region" { default = "us-east-1" }`  
`variable "key_name" { default = "devops-key" }`

###  **`main.tf`**

**`provider "aws" {`**  
  **`region = var.region`**  
**`}`**

**`resource "aws_key_pair" "devops_key" {`**  
  **`key_name   = var.key_name`**  
  **`public_key = file("../keys/id_rsa.pub")`**  
**`}`**

**`resource "aws_vpc" "main" {`**  
  **`cidr_block = "10.0.0.0/16"`**  
**`}`**

**`resource "aws_internet_gateway" "gw" {`**  
  **`vpc_id = aws_vpc.main.id`**  
**`}`**

**`resource "aws_subnet" "subnet" {`**  
  **`vpc_id                  = aws_vpc.main.id`**  
  **`cidr_block              = "10.0.1.0/24"`**  
  **`map_public_ip_on_launch = true`**  
**`}`**

**`resource "aws_route_table" "rt" {`**  
  **`vpc_id = aws_vpc.main.id`**

  **`route {`**  
    **`cidr_block = "0.0.0.0/0"`**  
    **`gateway_id = aws_internet_gateway.gw.id`**  
  **`}`**  
**`}`**

**`resource "aws_route_table_association" "a" {`**  
  **`subnet_id      = aws_subnet.subnet.id`**  
  **`route_table_id = aws_route_table.rt.id`**  
**`}`**

**`resource "aws_security_group" "allow_ssh" {`**  
  **`vpc_id = aws_vpc.main.id`**

  **`ingress {`**  
    **`from_port   = 22`**  
    **`to_port     = 22`**  
    **`protocol    = "tcp"`**  
    **`cidr_blocks = ["0.0.0.0/0"]`**  
  **`}`**

  **`egress {`**  
    **`from_port   = 0`**  
    **`to_port     = 0`**  
    **`protocol    = "-1"`**  
    **`cidr_blocks = ["0.0.0.0/0"]`**  
  **`}`**  
**`}`**

**`resource "aws_instance" "controller" {`**  
  **`ami                         = "ami-0fc5d935ebf8bc3bc" # Ubuntu 22.04 us-east-1`**  
  **`instance_type               = "t2.micro"`**  
  **`key_name                    = aws_key_pair.devops_key.key_name`**  
  **`subnet_id                   = aws_subnet.subnet.id`**  
  **`vpc_security_group_ids      = [aws_security_group.allow_ssh.id]`**  
  **`associate_public_ip_address = true`**  
  **`tags = {`**  
    **`Name = "controller"`**  
    **`Role = "ansible-controller"`**  
  **`}`**  
**`}`**

**`resource "aws_instance" "targets" {`**  
  **`count                       = 2`**  
  **`ami                         = "ami-0fc5d935ebf8bc3bc"`**  
  **`instance_type               = "t2.micro"`**  
  **`key_name                    = aws_key_pair.devops_key.key_name`**  
  **`subnet_id                   = aws_subnet.subnet.id`**  
  **`vpc_security_group_ids      = [aws_security_group.allow_ssh.id]`**  
  **`associate_public_ip_address = true`**  
  **`tags = {`**  
    **`Name = "target-${count.index + 1}"`**  
    **`Role = "ansible-target"`**  
  **`}`**  
**`}`**

###  **`outputs.tf`**

**`output "controller_public_ip" {`**  
  **`value = aws_instance.controller.public_ip`**  
**`}`**

**`output "target_ips" {`**  
  **`value = [for instance in aws_instance.targets : instance.public_ip]`**  
**`}`**

**4\. Deploy the Infra**

`cd terraform`  
`terraform init`  
`terraform apply`

<img width="1548" height="540" alt="Capture d’écran 2025-08-01 152826" src="https://github.com/user-attachments/assets/595f03dd-d24b-43c8-9cda-dfdb42f5b8a5" />
**5\. Connect to Controller EC2**

`ssh -i ../keys/id_rsa ubuntu@<controller_public_ip>`

Inside the controller:

## **6\. Ansible Dynamic Inventory Setup**

### **`ansible/ansible.cfg`**

**`[defaults]`**  
**`inventory = aws_ec2.yml`**  
**`host_key_checking = False`**  
**`private_key_file = ../keys/id_rsa`**

### **`ansible/aws_ec2.yml`**

**`plugin: amazon.aws.aws_ec2`**  
**`regions:`**  
  **`- us-east-1`**  
**`filters:`**  
  **`tag:Role: ansible-target`**  
**`keyed_groups:`**  
  **`- key: tags.Name`**  
    **`prefix: ec2`**  
**`hostnames:`**  
  **`- public-ip-address`**
## ⚠️ IMPORTANT CHANGES YOU MUST MAKE:

### 1. Update AMI IDs in main.tf
Replace the AMI IDs with the correct Ubuntu 22.04 AMI for your region.

### 2. Update Provider Configuration in main.tf
```hcl
provider "aws" {
  region  = var.region
  profile = "default"
}
```

### 3. Update variables.tf
```hcl
variable "region" { 
  default = "eu-west-3"  # Change to your preferred region
}
variable "key_name" { 
  default = "devops-key"  # Change to your own key name
}
```

### 4. Update ansible/aws_ec2.yml
```yaml
plugin: amazon.aws.aws_ec2
regions:
  - eu-west-3  # Change to match your region
filters:
  tag:Role: ansible-target
keyed_groups:
  - key: tags.Name
    prefix: ec2
hostnames:
  - public-ip-address
```
Make sure to install the plugin:

**`ansible-galaxy collection install amazon.aws`**

**7\. Ansible Playbook to Install Docker**


###  **`ansible/install_docker.yml`**

**`- name: Install Docker on all EC2`**  
  **`hosts: all`**  
  **`become: yes`**

  **`tasks:`**  
    **`- name: Update APT`**  
      **`apt:`**  
        **`update_cache: yes`**

    **`- name: Install Docker packages`**  
      **`apt:`**  
        **`name: [docker.io]`**  
        **`state: present`**

    **`- name: Enable and start Docker`**  
      **`systemd:`**  
        **`name: docker`**  
        **`enabled: yes`**  
        **`state: started`**

    **`- name: Check Docker version`**  
      **`command: docker --version`**  
      **`register: docker_version`**

    **`- debug:`**  
        **`var: docker_version.stdout`**

##  **8\. Run the Playbook**

`cd ansible`  
`ansible-playbook install_docker.yml`

## **9\. Validate**

**`ansible all -m ping`**  
**`ansible all -a "docker --version"`**

## **10\. Clean Up**

`cd terraform`  
`terraform destroy`

**Conclusion**

With this setup, you:

* Created a fully working VPC and EC2 setup with Terraform

* Installed Ansible on a controller

* Used AWS dynamic inventory plugin

* Installed Docker on remote EC2s automatically

