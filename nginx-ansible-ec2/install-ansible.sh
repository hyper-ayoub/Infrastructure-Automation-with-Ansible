#!/bin/bash

# Update the package index
sudo apt update

# Install the required dependencies
sudo apt install software-properties-common

# Add the Ansible repository
sudo apt-add-repository --yes --update ppa:ansible/ansible

# Install Ansible
sudo apt install ansible
