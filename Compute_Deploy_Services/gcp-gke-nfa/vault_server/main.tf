provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

resource "google_compute_instance" "vault_server" {
  name         = "vault-server"
  machine_type = "n1-standard-1"
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = "default"

    access_config {
      # This assigns a public IP to the instance
    }
  }

  metadata_startup_script = file("${path.module}/vault-init.sh")

  tags = ["vault"]

  service_account {
    email  = google_service_account.vault_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_compute_firewall" "vault_firewall" {
  name    = "vault-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8200"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vault"]
}

resource "google_service_account" "vault_sa" {
  account_id   = "vault-service-account"
  display_name = "Vault Service Account"
}

output "vault_server_ip" {
  value = google_compute_instance.vault_server.network_interface[0].access_config[0].nat_ip
}
