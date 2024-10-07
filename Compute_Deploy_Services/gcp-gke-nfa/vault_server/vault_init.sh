#!/bin/bash

# Update the package list and install necessary dependencies
sudo apt-get update && sudo apt-get install -y unzip curl

# Download and install Vault
VAULT_VERSION="1.10.0"
curl -O https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip
unzip vault_${VAULT_VERSION}_linux_amd64.zip
sudo mv vault /usr/local/bin/

# Create Vault configuration directory
sudo mkdir -p /etc/vault.d
sudo mkdir -p /opt/vault/data

# Create Vault configuration file
cat <<EOF | sudo tee /etc/vault.d/vault.hcl
storage "file" {
  path = "/opt/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

ui = true
EOF

# Create systemd service file for Vault
cat <<EOF | sudo tee /etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP \$MAINPID
Restart=on-failure
Environment=VAULT_ADDR=http://0.0.0.0:8200
Environment=VAULT_DEV_ROOT_TOKEN_ID=root
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable, and start the Vault service
sudo systemctl daemon-reload
sudo systemctl enable vault
sudo systemctl start vault

# Wait for Vault to start
sleep 10

# Initialize and unseal Vault (for development mode)
export VAULT_ADDR='http://127.0.0.1:8200'
vault operator init -key-shares=1 -key-threshold=1 > /tmp/vault-init.txt
vault operator unseal $(grep 'Unseal Key 1:' /tmp/vault-init.txt | awk '{print $NF}')
vault login $(grep 'Initial Root Token:' /tmp/vault-init.txt | awk '{print $NF}')

# Print the Vault access information
echo "Vault is initialized and unsealed."
echo "Access the Vault UI at http://$(curl -s http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H 'Metadata-Flavor: Google'):8200"
