provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

resource "null_resource" "k8s_master_init" {
  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm init --pod-network-cidr=10.244.0.0/16",
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
    ]

    connection {
      type        = "ssh"
      user        = "gcpuser"
      private_key = file("${path.module}/id_rsa")
      host        = google_compute_instance.k8s_vm[0].network_interface[0].access_config[0].nat_ip
    }
  }
}

resource "null_resource" "k8s_workers_join" {
  count = 2

  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm join ${google_compute_instance.k8s_vm[0].network_interface[0].access_config[0].nat_ip}:6443 --token <your-token> --discovery-token-ca-cert-hash sha256:<your-hash>"
    ]

    connection {
      type        = "ssh"
      user        = "gcpuser"
      private_key = file("${path.module}/id_rsa")
      host        = google_compute_instance.k8s_vm[count.index + 1].network_interface[0].access_config[0].nat_ip
    }
  }

  depends_on = [null_resource.k8s_master_init]
}
