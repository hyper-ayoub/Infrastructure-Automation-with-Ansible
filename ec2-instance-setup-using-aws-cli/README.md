# Complete Guide: Creating EC2 Instances Using AWS CLI
<img width="1536" height="1024" alt="Copilot_20250802_122335" src="https://github.com/user-attachments/assets/eb00ab23-e36e-4119-97b7-dc30cccb93d5" />

## Table of Contents
1. [Create EC2 instance Using AWS CLI](#1-create-ec2-instance-using-aws-cli)
2. [Get VPC ID and Subnet ID](#2-get-vpc-id-and-subnet-id)
3. [Get AMI Id](#3-get-ami-id)
4. [Install AWS CLI](#4-install-aws-cli)
5. [Create Security Group](#5-create-security-group)
6. [Create SSH Key Pair](#6-create-ssh-key-pair)
7. [AWS CLI Command to Create EC2](#7-aws-cli-command-to-create-ec2)
8. [AWS CLI Command to Create EC2 Instance With User Data](#8-aws-cli-command-to-create-ec2-instance-with-user-data)
9. [Script Created by me to automate the creation of EC2 instance on Linux](#9-script-created-by-me-to-automate-the-creation-of-ec2-instance-on-linux)
10. [Conclusion](#10-conclusion)

---

## 1. Create EC2 instance Using AWS CLI

To create an EC2 instance using CLI, you need the following components:

- **Security group ID**
- **Key pair name**
- **AMI Id**
- **Subnet ID**

This guide will walk you through obtaining each of these components and then creating your EC2 instance.

---

## 2. Get VPC ID and Subnet ID

To create a security group, you need the following two IDs:

- **VPC ID**: To create a security group
- **Subnet ID**: To launch EC2 instance

![0_JiGZDGhcqeL22kZU](https://github.com/user-attachments/assets/1b9111a3-a812-4eb0-b0fe-3c1fd7469f67)


### Getting IDs from AWS Management Console

1. Go to the **VPC dashboard** and click on **VPC**
2. You will get the **VPC ID** from the VPC list
3. Click on **Subnets** and search with the VPC ID to list all subnets associated with that VPC

### Example values used in this guide:
- **VPC ID**: `vpc-0a5ebf77670c8b2f0`
- **Subnet ID**: `subnet-043f148b27d3434a2`

*Replace these IDs with your actual VPC and subnet IDs.*

---

## 3. Get AMI Id

Next, you need to get the AMI ID to be used with EC2 CLI.

AMI ID could be:
- A base image AMI ID from AWS
- ID of a custom image created by you or your team

### Getting AMI ID from AWS Console

1. Go to **EC2 Dashboard** → **AMI Catalog**
2. Find the list of base images from AWS along with their AMI IDs
3. All custom AMIs are present under the **AMIs** option
<img width="1024" height="826" alt="image" src="https://github.com/user-attachments/assets/ec0f297f-2136-4e07-81d4-c801e1bdf389" />

### Example AMI ID used in this guide:
- **AWS Ubuntu AMI**: `ami-04ec97dc75ac850b1` (for region eu-west-3)

---

## 4. Install AWS CLI

### For Windows

You can read the full documentation for installation details.

```cmd
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

### Verify Installation
```bash
aws --version
```

### Configure AWS CLI
```bash
aws configure
```

When prompted, enter:
1. **Access Key**: Your AWS access key
2. **Secret Key**: Your AWS secret access key  
3. **Region name**: Your preferred region (e.g., eu-west-3)
4. **Output format**: json

**Done!** Your AWS CLI is now configured and ready to use.

---

## 5. Create Security Group

Our next requirement is a security group ID to be attached to the EC2 instance. You can attach more than one security group.

Either you can use the ID of an existing security group or create one using the following command.

### Create Security Group
Replace `vpc-0a5ebf77670c8b2f0` with your VPC ID:

```bash
aws ec2 create-security-group \
  --group-name ayoubbouagna \
  --description "AWS EC2 CLI Demo SG" \
  --tag-specifications ResourceType=security-group,Tags=[{Key=Name,Value=ayoubbouagna}] \
  --vpc-id "vpc-0a5ebf77670c8b2f0"
```

### Expected Output
Note down the security group ID from the output:

```json
{
    "GroupId": "sg-0aff1d86e623aa55c",
    "Tags": [
        {
            "Key": "Name",
            "Value": "ayoubbouagna"
        }
    ]
}
```

### Add Inbound Rules

Now, you need to add inbound (ingress) firewall rules to the security group. Replace `sg-0aff1d86e623aa55c` with your security group ID.

#### Add SSH Access (Port 22)
```bash
aws ec2 authorize-security-group-ingress \
  --group-id "sg-0aff1d86e623aa55c" \
  --protocol tcp \
  --port 22 \
  --cidr "0.0.0.0/0"
```

#### Add Multiple Ports and CIDRs
If you want to add multiple ports and multiple CIDRs to the security group using the CLI:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id "sg-0aff1d86e623aa55c" \
  --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Name,Value=demo-sg}]" \
  --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=0.0.0.0/0},{CidrIp=10.0.0.0/24}]" \
  --ip-permissions "IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0},{CidrIp=10.0.0.0/24}]"
```

---

## 6. Create SSH Key Pair

If you have an existing PEM key, you can use it. If you don't, you can create an SSH key pair using the following command.

### Create Key Pair
Using the key name from your examples (`ubuntukey`):

```bash
aws ec2 create-key-pair --key-name ubuntukey --query 'KeyMaterial' --output text > ubuntukey.pem
```

### Set Proper Permissions (Linux/Mac)
```bash
chmod 400 ubuntukey.pem
```

### For Windows
The key file will be created in your current directory. Make sure to store it securely as this is your private key for SSH access.

**Note**: The output key gets stored in your current working directory (or `~/.ssh` location if you specify the path).

---

## 7. AWS CLI Command to Create EC2

Here is the AWS CLI command to create an EC2 instance using all the components we've gathered:

```bash
aws ec2 run-instances \
  --image-id ami-04ec97dc75ac850b1 \
  --count 1 \
  --instance-type t2.micro \
  --key-name ubuntukey \
  --security-group-ids sg-0aff1d86e623aa55c \
  --subnet-id subnet-043f148b27d3434a2 \
  --block-device-mappings "[{\"DeviceName\":\"/dev/sdf\",\"Ebs\":{\"VolumeSize\":30,\"DeleteOnTermination\":false}}]" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ayoub-server}]' 'ResourceType=volume,Tags=[{Key=Name,Value=demo-server-disk}]'
```

### Command Parameters Explained:
- `--image-id`: The AMI ID to use
- `--count`: Number of instances to launch (1)
- `--instance-type`: Instance type (t2.micro for free tier)
- `--key-name`: SSH key pair name for access
- `--security-group-ids`: Security group ID(s) to attach
- `--subnet-id`: Subnet where instance will be launched
- `--block-device-mappings`: Additional EBS volume (30GB)
- `--tag-specifications`: Tags for the instance and volumes

---

## 8. AWS CLI Command to Create EC2 Instance With User Data

With EC2 CLI, you can pass the EC2 user data script using the `--user-data` flag.

### Method 1: Using User Data Script File

First, create a user data script file. For example, a shell script named `script.sh`:

```bash
#!/bin/bash
apt-get update -y
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
```

**Note**: Fixed the nginx commands - should be `apt-get install -y nginx` and `systemctl start nginx` (not `sudo systemctl nginx start`).

### Run EC2 Instance with User Data File

```bash
aws ec2 run-instances \
  --image-id ami-04ec97dc75ac850b1 \
  --count 1 \
  --instance-type t2.micro \
  --key-name ubuntukey \
  --security-group-ids sg-0aff1d86e623aa55c \
  --subnet-id subnet-043f148b27d3434a2 \
  --block-device-mappings "[{\"DeviceName\":\"/dev/sdf\",\"Ebs\":{\"VolumeSize\":30,\"DeleteOnTermination\":false}}]" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=ayoub-server}]" "ResourceType=volume,Tags=[{Key=Name,Value=demo-server-disk}]" \
  --user-data file://C:/Users/hp/.ssh/script.sh
```

### Method 2: Using Inline User Data

If it is a single-line command, you can pass it directly without an external file:

```bash
aws ec2 run-instances \
  --image-id ami-04ec97dc75ac850b1 \
  --count 1 \
  --instance-type t2.micro \
  --key-name ubuntukey \
  --security-group-ids sg-0aff1d86e623aa55c \
  --subnet-id subnet-043f148b27d3434a2 \
  --block-device-mappings "[{\"DeviceName\":\"/dev/sdf\",\"Ebs\":{\"VolumeSize\":30,\"DeleteOnTermination\":false}}]" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=ayoub-server}]" "ResourceType=volume,Tags=[{Key=Name,Value=demo-server-disk}]" \
  --user-data "sudo systemctl start nginx"
```

---

## 9. Script Created by me to automate the creation of EC2 instance on Linux

### EC2 Creation Script

Meet the **EC2 Creation Script**: Your hassle-free solution for quick and easy instance deployment.

**Features:**
- **Automated AWS Console Interaction**: Say goodbye to manual searches for security group IDs, VPC IDs, and key pair names
- **Streamlined Process**: The script fetches all required details directly from your AWS console, eliminating the need for tedious searches
- **User-Friendly Bash File**: Enjoy a simple and intuitive interface that prompts you for essential information

### GitHub Repository Script

The complete automation script is available at: **[MyScripts - EC2 Instance Creation](https://github.com/hyper-ayoub/Infrastructure-Automation-with-Ansible/blob/main/ec2-instance-setup-using-aws-cli/ec2InstanceCreation.sh)**

This script provides automated EC2 instance creation with all the necessary components integrated.

1. **Run the script** and enter the AWS region like "eu-west-3"
2. **It will show you the already available IDs** of security groups, VPC IDs, subnet IDs - just select from them

<img width="1100" height="570" alt="image" src="https://github.com/user-attachments/assets/2f47c2a5-440a-4605-8c0f-d325aab6e0c6" />

3. **Enter the ami (Amazon Machine ID)

4. **type of instance like based on the ram, vcpu’s storage you want.

5. **number of instances to launch

6. **It will ask you for yes or no by showing all your inputs

<img width="1100" height="399" alt="image" src="https://github.com/user-attachments/assets/2a5bfbb5-da1d-4ecc-986c-3f521f187311" />

7. **If you click yes the instance will be created.
 <img width="1100" height="623" alt="image" src="https://github.com/user-attachments/assets/b723b610-9cd6-4c2f-a1f5-c76763812930" />


# Here is the screenshot of ec2 instance created on aws console.

<img width="1100" height="188" alt="image" src="https://github.com/user-attachments/assets/bc803f48-7e09-4883-8954-4b1451316519" />




## 10. Conclusion

This comprehensive guide demonstrates how to create and manage EC2 instances using AWS CLI. The process involves several key steps:

1. **Installing and configuring AWS CLI**
2. **Gathering required information** (VPC ID, Subnet ID, AMI ID)
3. **Creating security groups** with appropriate rules
4. **Creating SSH key pairs** for secure access
5. **Launching EC2 instances** with optional user data scripts
6. **Automating the entire process** with custom scripts

### Key Benefits of Using AWS CLI for EC2 Management:

- **Automation**: Scripts can be created to automate repetitive tasks
- **Consistency**: Ensures consistent deployment across environments
- **Version Control**: Commands can be stored in version control systems
- **Integration**: Easy integration with CI/CD pipelines
- **Cost-Effective**: Programmatic management reduces manual errors

### Best Practices:

- Always use specific security group rules instead of allowing all traffic (0.0.0.0/0) when possible
- Regularly update and patch your instances
- Use IAM roles instead of hardcoded credentials
- Tag your resources for better organization and cost tracking
- Monitor your instances using CloudWatch
- Backup important data and create AMIs of configured instances

### Troubleshooting Tips:

- Check your AWS credentials and permissions
- Verify VPC and subnet configurations
- Ensure security groups allow necessary traffic
- Monitor AWS CLI output for error messages
- Use `--dry-run` parameter to test commands without executing them

This guide provides you with the foundation to create and manage EC2 instances efficiently using AWS CLI. Remember to always follow AWS security best practices and monitor your resource usage to optimize costs.
