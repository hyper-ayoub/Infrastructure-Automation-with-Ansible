#!/bin/bash

# Function to prompt user for input
prompt_user() {
  read -p "$1: " input
  echo "$input"
}

# Function to configure AWS CLI with credentials
configure_aws_cli() {
  # Check if AWS CLI is already configured
  if [[ -z $(aws configure get aws_access_key_id) ]]; then
    access_key_id=$(prompt_user "Enter AWS access key ID")
    secret_access_key=$(prompt_user "Enter AWS secret access key")
    aws configure set aws_access_key_id "$access_key_id"
    aws configure set aws_secret_access_key "$secret_access_key"
    aws configure set default.region us-east-1  # Change the default region if needed
    aws configure set default.output json       # Set the default output format
    echo "AWS CLI configured with provided credentials."
  else
    echo "AWS CLI is already configured."
  fi
}

# Function to fetch and display options for subnet IDs in the specified region
get_subnet_options() {
  aws ec2 describe-subnets --query 'Subnets[*].[SubnetId, CidrBlock, VpcId, AvailabilityZone]' --output table --region "$1"
}

# Function to fetch and display options for security groups in the specified region
get_security_group_options() {
  aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupId, GroupName, VpcId, AvailabilityZone]' --output table --region "$1"
}

# Function to display AWS EC2 images (AWS EC2 Images)
display_ami_options() {
  echo "Fetching available Top 20 AMIs. Please wait..."
  aws ec2 describe-images --owners self amazon --query 'Images[0:25].[ImageId, Name]' --output table --region "$1"
}


# Function to fetch and display options for key pairs
get_key_pair_options() {
  aws ec2 describe-key-pairs --query 'KeyPairs[*].[KeyName]' --output table
}

# Function to create a new key pair
create_key_pair() {
  key_pair_name=$(prompt_user "Enter a name for the new key pair")
  aws ec2 create-key-pair --key-name "$key_pair_name" --query 'KeyMaterial' --output text > "$key_pair_name.pem"
  chmod 400 "$key_pair_name.pem"
  echo "Key pair '$key_pair_name' created and saved to '$key_pair_name.pem'."
}

# Function to check if a key pair exists
key_pair_exists() {
  key_name="$1"
  aws ec2 describe-key-pairs --key-names "$key_name" --query 'KeyPairs' --output text --region "$aws_region" > /dev/null 2>&1
}

# Function to display existing inbound rules for a security group
display_existing_rules() {
  sg_id="$1"
  echo "Existing Inbound Rules for Security Group $sg_id:"
  aws ec2 describe-security-groups --group-ids "$sg_id" --query 'SecurityGroups[0].IpPermissions' --output table --region "$aws_region"
}

# Function to add a custom inbound rule to a security group
add_custom_rule() {
  sg_id="$1"
  read -p "Enter the port for the inbound rule: " port
  read -p "Enter the protocol for the inbound rule (e.g., tcp, udp, icmp): " protocol
  read -p "Enter the CIDR IP range for the inbound rule (e.g., 0.0.0.0/0): " cidr_ip

  aws ec2 authorize-security-group-ingress \
    --group-id "$sg_id" \
    --protocol "$protocol" \
    --port "$port" \
    --cidr "$cidr_ip" \
    --region "$aws_region"
}

# Function to create an EC2 instance
create_ec2_instance() {
  # Prompt for AWS region
  aws_region=$(prompt_user "Enter AWS region (ap-south-1)")

  # Display and prompt for subnet options
  echo "Subnet Options:"
  get_subnet_options "$aws_region"
  read -p "Enter the Subnet ID: " subnet_id
  vpc_id=$(aws ec2 describe-subnets --subnet-ids "$subnet_id" --query 'Subnets[0].VpcId' --output text --region "$aws_region")

  # Display and prompt for security group options
  echo "Security Group Options:"
  get_security_group_options "$aws_region"
  echo -e  "\n *** Make Sure Both Subnet ID and Security Grop ID Have Same VPC ID   *** \n"
  read -p "Enter the Security Group ID : " security_group_id
  sg_vpc_id=$(aws ec2 describe-security-groups --group-ids "$security_group_id" --query 'SecurityGroups[0].VpcId' --output text --region "$aws_region")

  # Check if subnet and security group are in the same VPC
  while [ "$vpc_id" != "$sg_vpc_id" ]; do
    echo "Selected subnet and security group are not in the same VPC. Please select again."

    # Display options in the same region
    display_options_in_same_region "$aws_region"

    # Display and prompt for subnet options
    echo "Subnet Options:"
    get_subnet_options "$aws_region"
    read -p "Enter the Subnet ID: " subnet_id
    vpc_id=$(aws ec2 describe-subnets --subnet-ids "$subnet_id" --query 'Subnets[0].VpcId' --output text --region "$aws_region")

    # Display and prompt for security group options
    echo "Security Group Options:"
    get_security_group_options "$aws_region"
    read -p "Enter the Security Group ID: " security_group_id
    sg_vpc_id=$(aws ec2 describe-security-groups --group-ids "$security_group_id" --query 'SecurityGroups[0].VpcId' --output text --region "$aws_region")
  done

  # Display existing inbound rules for the selected security group
  display_existing_rules "$security_group_id"

  # Prompt user to add custom inbound rule
  read -p "Do you want to add a custom inbound rule to the security group? (yes/no): " add_rule
  if [ "$add_rule" == "yes" ]; then
    add_custom_rule "$security_group_id"
  fi

  # Display and prompt for key pair options
  echo "Key Pair Options:"
  get_key_pair_options
  read -p "Enter the Key Pair Name: " key_pair_name

  # Check if the specified key pair exists
  while ! key_pair_exists "$key_pair_name"; do
    echo "Key pair '$key_pair_name' does not exist."
    create_key_pair

    # Display and prompt for key pair options
    echo "Key Pair Options:"
    get_key_pair_options
    read -p "Enter the Key Pair Name: " key_pair_name
  done

  # Prompt for instance name
  instance_name=$(prompt_user "Enter a name for the instance")

  # Prompt for AMI ID
    # Prompt for AMI ID
  echo "AMI Options:"
  display_ami_options "$aws_region"
  read -p "Enter AMI ID: " ami_id

  # Prompt for instance type
  instance_type=$(prompt_user "Enter instance type (e.g., t2.micro)")

  # Prompt for instance count
  instance_count=$(prompt_user "Enter number of instances to launch")

  # Confirm user inputs
  echo -e "\nSummary of inputs:"
  echo -e "\e[93m------------------------\e[0m"
  echo -e "\e[93m| AWS Region         : $aws_region\e[0m"
  echo -e "\e[93m| AMI ID             : $ami_id\e[0m"
  echo -e "\e[93m| Instance Type      : $instance_type\e[0m"
  echo -e "\e[93m| Key Pair Name      : $key_pair_name\e[0m"
  echo -e "\e[93m| Security Group ID  : $security_group_id\e[0m"
  echo -e "\e[93m| Subnet ID          : $subnet_id\e[0m"
  echo -e "\e[93m| VPC ID             : $vpc_id\e[0m"
  echo -e "\e[93m| Instance Name      : $instance_name\e[0m"
  echo -e "\e[93m| Number of Instances: $instance_count\e[0m"
  echo -e "\e[93m------------------------\e[0m"

  read -p "Do you want to create the EC2 instance? (yes/no): " confirm
  if [ "$confirm" == "yes" ]; then
    # Run AWS CLI command to create EC2 instance
    aws ec2 run-instances \
      --image-id "$ami_id" \
      --instance-type "$instance_type" \
      --key-name "$key_pair_name" \
      --security-group-ids "$security_group_id" \
      --subnet-id "$subnet_id" \
      --count "$instance_count" \
      --region "$aws_region" \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]"

    echo "EC2 instance creation initiated. Check the AWS Management Console for status."
  else
    echo "EC2 instance creation canceled."
  fi
}

# Function to display options for subnets and security groups in the same region
display_options_in_same_region() {
  aws_region="$1"

  echo "Options in the same region as $aws_region:"
  echo -e "\nSubnet Options:"
  get_subnet_options "$aws_region"

  echo -e "\nSecurity Group Options:"
  get_security_group_options "$aws_region"
}

# Main script execution
configure_aws_cli
create_ec2_instance
