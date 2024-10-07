provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Create a GCP VPC
resource "google_compute_network" "vpc_network" {
  name = "k8s-vpc-network"
}

# Create a subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "k8s-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.gcp_region
  network       = google_compute_network.vpc_network.id
}

# Create firewall rules
resource "google_compute_firewall" "default-allow-ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["<Your IP Address/CIDR>"]  # Restrict access to your IP
}

resource "google_compute_firewall" "default-allow-k8s" {
  name    = "allow-k8s-api"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = ["<Your IP Address/CIDR>"]  # Restrict access to your IP
}

# Generate SSH keys using Terraform Vault provider
provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

resource "vault_generic_secret" "ssh_keys" {
  path = "secret/data/gcp/k8s_ssh_keys"

  data_json = jsonencode({
    private_key = tls_private_key.ssh_key.private_key_pem
    public_key  = tls_private_key.ssh_key.public_key_openssh
  })
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create GCP compute instances (VMs)
resource "google_compute_instance" "k8s_vm" {
  count        = 3
  name         = "k8s-vm-${count.index}"
  machine_type = "a2-ultragpu-1g"  # Machine type with GPU support
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      # Include this block to give the VM an external IP address
    }
  }

  metadata_startup_script = file("${path.module}/cloud-init.sh")

  service_account {
    email  = google_service_account.k8s_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["k8s-node"]

  metadata = {
    ssh-keys = "gcpuser:${vault_generic_secret.ssh_keys.data["data"]["public_key"]}"
  }
}

# Create a service account for the VMs
resource "google_service_account" "k8s_sa" {
  account_id   = "k8s-service-account"
  display_name = "K8s Service Account"
}

output "instance_ips" {
  value = google_compute_instance.k8s_vm.*.network_interface[0].access_config[0].nat_ip
}
