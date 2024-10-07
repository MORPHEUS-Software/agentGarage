#!/bin/bash

# Step 1: Start Vault
docker run -d --name vault-dev -p 8200:8200 vault
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN="root"

# Step 2: Create Secrets in Vault
vault secrets enable -path=secret kv
vault kv put secret/gcp/k8s_ssh_keys private_key="$(cat ~/.ssh/id_rsa)" public_key="$(cat ~/.ssh/id_rsa.pub)"

# Step 3: Create Terraform Variables
cat > terraform.tfvars <<EOF
gcp_project_id = "$(gcloud config get-value project)"
gcp_region     = "us-central1"
gcp_zone       = "us-central1-a"
vault_address  = "$VAULT_ADDR"
vault_token    = "$VAULT_TOKEN"
EOF

echo "Vault server and Terraform variables are set up and ready to use."
