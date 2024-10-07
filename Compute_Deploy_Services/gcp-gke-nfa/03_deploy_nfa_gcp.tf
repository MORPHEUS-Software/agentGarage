provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Deploy NVIDIA device plugin on the cluster
resource "null_resource" "deploy_nvidia_plugin" {
  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.11.0/nvidia-device-plugin.yml"
    ]

    connection {
      type        = "ssh"
      user        = "gcpuser"
      private_key = file("${path.module}/id_rsa")
      host        = google_compute_instance.k8s_vm[0].network_interface[0].access_config[0].nat_ip
    }
  }

  depends_on = [null_resource.k8s_master_init]  # Ensure Kubernetes master is initialized
}

# Deploy AI agent on the cluster
resource "null_resource" "deploy_ai_agent" {
  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f /path/to/your/llm-ai-agent.yml"
    ]

    connection {
      type        = "ssh"
      user        = "gcpuser"
      private_key = file("${path.module}/id_rsa")
      host        = google_compute_instance.k8s_vm[0].network_interface[0].access_config[0].nat_ip
    }
  }

  depends_on = [null_resource.deploy_nvidia_plugin]  # Ensure NVIDIA plugin is deployed
}
