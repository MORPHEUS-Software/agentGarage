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
