# GCP GKE Cluster Setup for NFA Operations

This directory contains scripts for provisioning a Google Kubernetes Engine (GKE) cluster with GPU support for running NFA's. It leverages Google Cloud Platform (GCP), Terraform, and Vault to securely store SSH keys and deploy infrastructure.

## Directory Structure
- `00_setup_vault_tfvars.sh`: Sets up Vault and stores GCP-related secrets.
- `01_provision_infrastructure_gcp.tf`: Provisions the necessary infrastructure on GCP.
- `02_configure_kubernetes_gcp.tf`: Configures a Kubernetes cluster in GCP.
- `03_deploy_ai_agents_gcp.tf`: Deploys NVIDIA plugins and AI agents on the Kubernetes cluster.
- `variables.tf`: Defines the variables used across the Terraform scripts.

---

## 00_setup_vault_tfvars.sh

**Functionality**:
- Sets up a Vault server using Docker.
- Stores GCP-related SSH keys (private and public) in Vault as secrets.
- Creates a `terraform.tfvars` file with the necessary GCP and Vault configurations.

This script streamlines the integration of Vault with Terraform and GCP services.

---

## 01_provision_infrastructure_gcp.tf

**Functionality**:
1. **Provider Configuration**: Specifies the GCP project and region using variables (`var.gcp_project_id`, `var.gcp_region`).
2. **VPC Creation**: Creates a Virtual Private Cloud (VPC) named `k8s-vpc-network`.
3. **Subnet Creation**: Configures a subnet (`k8s-subnet`) within the VPC with an IP range of `10.0.0.0/24`.
4. **Firewall Rules**:
   - SSH access (port 22) and Kubernetes API access (port 6443) are allowed, restricted by IP.
5. **Vault Integration for SSH Keys**: SSH keys are securely stored in Vault and injected into the VMs' metadata.
6. **VM Creation**:
   - Creates three VMs with GPU support (`a2-ultragpu-1g` machine type) running Ubuntu 18.04.
   - Configures the VMs via a startup script (`cloud-init.sh`) to install necessary components.
   - Attaches a service account to the VMs for access to GCP services.
7. **Service Account**: A service account is created for the VMs.
8. **Outputs**: Outputs the external IP addresses of the created VMs.

---

## 02_configure_kubernetes_gcp.tf

**Functionality**:
1. **Provider Configuration**: The GCP provider is configured with the project ID and region.
2. **Kubernetes Master Initialization**:
   - The master node is initialized using `kubeadm` and Flannel networking is set up.
   - Admin configuration (`admin.conf`) is set up with proper permissions.
3. **Kubernetes Worker Nodes Join**:
   - Two worker nodes join the cluster via SSH, using `kubeadm join`.
   - The worker nodes wait for the master node to successfully initialize before joining.

This configuration sets up one Kubernetes master and two worker nodes with networking provided by Flannel.

---

## 03_deploy_nfa_gcp.tf

**Functionality**:
1. **Provider Configuration**: GCP provider is set up using project and region variables.
2. **NVIDIA Device Plugin Deployment**:
   - Deploys the NVIDIA device plugin on the Kubernetes cluster using `kubectl`.
   - The plugin allows GPU support for AI workloads.
3. **AI Agent Deployment**:
   - Deploys an NFA on the cluster using a predefined YAML configuration.
   - Both deployments use remote SSH commands to manage resources on the GCP VMs.

*NOTE*: Modify this file to integrate paths to preconfigured NFA YAML files here in step #3

---

## variables.tf

**Defined Variables**:

1. **`gcp_project_id`**  
   - **Description**: The GCP project ID where resources will be deployed.
   - **Type**: `string`  
   - **Required**: Yes

2. **`gcp_region`**  
   - **Description**: The region for GCP resource deployment.  
   - **Type**: `string`  
   - **Default**: `"us-central1"`

3. **`gcp_zone`**  
   - **Description**: The zone for GCP resource deployment.  
   - **Type**: `string`  
   - **Default**: `"us-central1-a"`

4. **`vault_address`**  
   - **Description**: The address of the Vault server.  
   - **Type**: `string`  
   - **Default**: `"http://127.0.0.1:8200"`

5. **`vault_token`**  
   - **Description**: The authentication token for Vault.  
   - **Type**: `string`  
   - **Required**: Yes
