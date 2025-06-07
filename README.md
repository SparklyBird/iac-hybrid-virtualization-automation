# IaC for Hybrid Virtualization Automation

> An Infrastructure as Code solution for deploying microservices in a hybrid virtualization infrastructure. This project was developed as part of a Master's Thesis at Riga Technical University.

This repository contains the code and configuration for an Infrastructure as Code (IaC) solution designed to automate the deployment of a microservices architecture within a hybrid virtualization environment. The project demonstrates the use of modern DevOps tools to manage the entire lifecycle of the infrastructure, from provisioning and configuration to application deployment.

## Architecture Overview

The architecture is composed of two main environments: a local **on-premises** environment (Windows 11 with WSL) used for management, and a **cloud** environment hosted on a **Proxmox VE** server. All components across both environments are connected via a secure, software-defined network using **ZeroTier**.

The core of the cloud environment consists of several **LXC containers** provisioned to host specific services:
* **GitLab:** For version control and CI/CD.
* **Docker:** To run the containerized microservices.
* **MySQL:** As the primary database for the application.

Finally, two **Docker containers** representing the microservices are deployed: a Python web application to display data and a Grafana instance for data visualization.

*You can include the architecture diagram from your thesis here for better visualization:*
`![Architecture Diagram](path/to/your/architecture-image.png)`

## Technologies Used

* **Infrastructure as Code:** Terraform
* **Configuration Management:** Ansible
* **Virtualization:** Proxmox VE, LXC (Linux Containers)
* **Containerization:** Docker
* **Version Control:** GitLab
* **Networking:** ZeroTier
* **Database:** MySQL
* **Monitoring & Visualization:** Grafana
* **Scripting:** Python, PowerShell

## Repository Structure

The code in this repository is organized into the following directories:

* **/terraform:** Contains all Terraform (`.tf`) files for provisioning the infrastructure, including LXC and Docker containers.
* **/ansible:** Contains Ansible Playbooks (`.yml`), inventory files, and configuration templates for installing and configuring software (GitLab, Docker, MySQL).
* **/scripts:** Includes auxiliary scripts, such as the Python script used to generate and populate the MySQL database with synthetic IoT data.

## Setup and Usage

To replicate this environment, follow the steps below.

### 1. Prerequisites

* Terraform and Ansible installed on your local management machine (or within WSL).
* Administrative access to a Proxmox VE server.
* A configured ZeroTier account and a virtual network ID.

### 2. Configuration

**IMPORTANT SECURITY NOTE:** Do not commit sensitive information like passwords or API tokens directly into your Git repository.

* **Terraform:** Create a `terraform.tfvars` file to store your sensitive variables (like the Proxmox API token and password). Add `*.tfvars` to your `.gitignore` file.
* **Ansible:** Update the `ansible/inventory.ini` file with the correct IP addresses of your target machines after they are created. Store sensitive data like SSH keys securely and reference them, or use a tool like Ansible Vault.

### 3. Execution Workflow

The deployment process follows a specific order:

1.  **Provision GitLab LXC:** Run the Terraform configuration (`lxc-gitlab.tf`) to create the initial GitLab container on Proxmox.
2.  **Configure GitLab:** Use the Ansible playbook (`gitlab.yml`) to install and configure GitLab inside its container.
3.  **Provision Core Infrastructure:** After setting up the GitLab repository with the remaining configurations, run the Terraform files (`lxc-docker-mysql.tf`) to create the Docker and MySQL LXC containers.
4.  **Configure Core Services:** Execute the Ansible playbooks for Docker and MySQL to install and configure the services in their respective containers.
5.  **Populate Database:** Run the Python script from the `/scripts` directory to populate the MySQL database with IoT data.
6.  **Deploy Microservices:** Finally, run the last Terraform configuration to build the Docker images and deploy the web application and Grafana containers.

### Example Commands:

```bash
# To provision infrastructure with Terraform
cd terraform/
terraform init
terraform apply -var-file="terraform.tfvars"

# To configure software with Ansible
cd ansible/
ansible-playbook -i inventory.ini playbook-name.yml
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
