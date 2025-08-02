# Streamlining Nginx Deployment with Ansible on AWS EC2 Instances

## Introduction

In today's fast-paced technological landscape, deploying and managing web servers efficiently is paramount. This blog post aims to provide a detailed guide on using Ansible to streamline the deployment of Nginx across four AWS EC2 instances — one serving as the Ansible master and the remaining three as Nginx servers. We'll walk through the process of creating the instances, installing Ansible, and orchestrating Nginx deployment.

## Step 1: Setting Up AWS EC2 Instances

### Server Configuration:
Launch four AWS EC2 instances with the following specifications:
- **Instance Type**: t2.micro
- **Operating System**: Ubuntu

### Instance Naming:
Assign distinct names to the instances for clarity:
- Instance 1: Ansible-Master
- Instance 2: Server-1
- Instance 3: Server-2
- Instance 4: Server-3

## Step 2: Installing Ansible on Ansible-Master

Here are the steps to install Ansible on an Ubuntu EC2 instance:

```bash
# Update the package index
sudo apt update

# Install the required dependencies
sudo apt install software-properties-common

# Add the Ansible repository
sudo apt-add-repository --yes --update ppa:ansible/ansible

# Install Ansible
sudo apt install ansible
```

## Step 3: Ansible Configuration

### Understanding the Ansible Inventory File

The Ansible inventory file/Host file is a critical component that defines the hosts to be managed and includes variables that tailor the configuration to specific needs.

Edit `/etc/ansible/hosts` to include the IP addresses of Server-1, Server-2, and Server-3.

```bash
ubuntu@ip-172-31-37-65:~$ sudo vim /etc/ansible/hosts
```

```ini
[servers]
server1 ansible_host=18.206.189.126
server2 ansible_host=3.81.158.72
server3 ansible_host=54.162.81.197

[servers:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_user=ubuntu
ansible_ssh_private_key_file=/home/ubuntu/.ssh/ansible-key.pem
```

## Step 4: Connectivity Testing with Ansible Ping

Use the Ansible ping module to test connectivity between the Ansible host and the deployed servers. Confirm that all servers respond successfully, ensuring a well-connected infrastructure.

Ansible trying to establish an SSH connection to the target hosts.

```bash
ansible servers -m ping -k
```

The ansible-inventory command is part of Ansible and can be used to list information about the configured inventory.

```bash
ansible-inventory --list
```

This command will output the inventory in JSON format, displaying information about hosts, groups, and variables defined in your inventory.

## Step 5: Ansible Playbook for Nginx Installation

It's designed to install Nginx on the hosts specified in the servers group and start the Nginx service. The `become: yes` is used to run the tasks with elevated privileges (sudo).

```yaml
---
- name: This playbook will install nginx
  hosts: servers
  become: yes
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: latest
    
    - name: Start nginx
      service:
        name: nginx
        state: started
        enabled: yes
```

To run this playbook, save it to a file (e.g., `nginx_install.yml`) and execute the following command:

To run an Ansible playbook, you need to use the ansible-playbook command followed by the filename of your playbook.

```bash
ansible-playbook istall_nginx_play.yaml
```

## Step 6: Web Content Deployment

Now that we have successfully installed Nginx on Server-3, it's time to deploy a beautiful static page and ensure that it's seamlessly accessible through the web server. In this step, we'll create an index.html file and use Ansible to copy it to the appropriate directory on Server-3.

### Create the index.html file:

Using your preferred text editor, create a simple yet engaging HTML file.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ayoub Bouagna Ansible Blog</title>
    <style>
        body {
            font-family: 'Roboto', 'Arial', sans-serif;
            margin: 0;
            padding: 0;
            background-color: #ffffff;
            color: #333;
        }

        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            text-align: center;
            color: white;
            transition: all 0.3s ease;
        }

        header:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(102, 126, 234, 0.3);
        }

        main {
            padding: 40px;
            text-align: center;
        }

        section {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 5px 20px rgba(0, 0, 0, 0.1);
            transition: all 0.3s ease;
        }

        .ansible-image {
            width: 200px;
            height: 200px;
            margin: 20px auto;
            border-radius: 15px;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s ease;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            overflow: hidden;
        }

        .ansible-image img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            border-radius: 15px;
        }

        .ansible-image:hover {
            transform: scale(1.05);
            box-shadow: 0 15px 40px rgba(0, 0, 0, 0.3);
        }

        section:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 35px rgba(102, 126, 234, 0.2);
        }

        h1 {
            margin: 0;
            font-size: 2.2em;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }

        h2 {
            color: #667eea;
            margin-bottom: 20px;
            font-size: 1.8em;
        }

        p {
            line-height: 1.6;
            font-size: 1.1em;
            color: #555;
        }

        .cta-button {
            display: inline-block;
            margin-top: 20px;
            padding: 12px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            border-radius: 25px;
            font-weight: bold;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }

        .cta-button:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
            background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
        }

        footer {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 15px;
            text-align: center;
            color: white;
            margin-top: 40px;
        }

        footer:hover {
            background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
            transition: all 0.3s ease;
        }
        footer > p {
          color : white;
        }
    </style>
</head>
<body>
    <header>
        <h1>Ayoub Bouagna Ansible Blog</h1>
        <p style="margin: 10px 0 0 0; opacity: 0.9;">Software Engineer & Automation Specialist</p>
    </header>

    <main>
        <section>
            <h2>Welcome to My Ansible Blog</h2>
            <div class="ansible-image">
                <img src="https://tse3.mm.bing.net/th/id/OIP.VegYoohBcWgKVZ5Q3A3WLQAAAA?w=347&h=347&rs=1&pid=ImgDetMain&o=7&rm=3" alt="Ansible Logo">
            </div>
            <p>
                Hello, I'm Ayoub Bouagna, a Software Engineer specializing in Automation. Welcome to my Ansible blog! Here, I'll be sharing insights, tips, and tutorials
                about Ansible and automation. Stay tuned for exciting content!
            </p>
            <a href="#" class="cta-button">Explore Tutorials</a>
            <!-- You can add more content, images, and styling as needed. -->
        </section>
    </main>

    <footer>
        <p>&copy; 2025 Ayoub Bouagna. All rights reserved.</p>
    </footer>
</body>
</html>
```

Save the file as `index.html` in the `/home/ubuntu/` directory on your Ansible master machine.

### Ansible Playbook for Web Content Deployment

Create an Ansible playbook (`deploy_static_page.yml`):

```yaml
---
- name: Deploy Beautiful Static Page on Server-3
  hosts: server3
  become: yes
  tasks:
    - name: Install Nginx
      apt:
        name: nginx
        state: latest
    
    - name: Start Nginx
      service:
        name: nginx
        state: started
        enabled: yes
    
    - name: Copy index.html
      copy:
        src: /home/ubuntu/index.html
        dest: /var/www/html
```

### Running the Ansible Playbook

```bash
ansible-playbook deploy_static_page.yml
```

This command will execute the playbook, and you should see output indicating the tasks being performed.

### Verifying the Deployment

Open a web browser and navigate to `http://<server3-public-ip>`. You should see your beautiful static page displayed.

Congratulations! You've successfully deployed a static page on Server-3 using Ansible, adding a touch of elegance to your Nginx-powered web server. This step not only showcases the power of Ansible in automating tasks but also sets the stage for more complex and sophisticated deployments in your infrastructure.

## Conclusion

In this comprehensive guide, we embarked on a journey to streamline the deployment of Nginx across multiple AWS EC2 instances using the powerful automation tool, Ansible. From the inception of creating AWS EC2 instances to the orchestration of Nginx installation and the deployment of a beautiful static page, we covered crucial steps in building a robust and automated web server infrastructure.

By adopting Ansible, we harnessed the ability to manage infrastructure as code, ensuring consistency, repeatability, and scalability. The provided Ansible playbook exemplifies the elegance of automation, simplifying complex tasks such as software installation, service management, and content deployment.

