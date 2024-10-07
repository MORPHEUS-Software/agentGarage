variable "gcp_project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "gcp_region" {
  description = "The region in which to deploy resources."
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "The zone in which to deploy resources."
  type        = string
  default     = "us-central1-a"
}

variable "vault_address" {
  description = "The address of the Vault server."
  type        = string
  default     = "http://127.0.0.1:8200"
}

variable "vault_token" {
  description = "The token to authenticate with Vault."
  type        = string
}
