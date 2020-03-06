# Required variables
variable "postgres_password" {
  description = "Postgres database password."
  type        = string
}
variable "letsencrypt_admin_email" {
  description = "Admin email for LetsEncrypt certificates requests."
  type        = string
}
variable "concourse_root_password" {
  description = "Concourse root password."
  type        = string
}
variable "vault_external_url" {
  description = "External URL for vault."
  type        = string
}
variable "concourse_external_url" {
  description = "External URL for concourse web service."
  type        = string
}
variable "ssh_keys" {
  type        = list(string)
  description = "List of SSH IDs or fingerprints to enable. They must already exist in your DO account. Provisioning will fail as \"remote-exec\" uses ssh to initalize the droplet."
}

# Optional variables
variable "postgres_user" {
  description = "Postrgres database user."
  type        = string
  default     = "concourse"
}
variable "postgres_database" {
  description = "Name of the postgres database. Default is \"concourse\"."
  type        = string
  default     = "concourse"
}
variable "do_token" {
  type        = string
  description = "DigitalOcean authentication token."
}
variable "domain" {
  type        = string
  description = "Domain to assign to the droplet."
  default     = ""
}
variable "records" {
  description = "DNS records to create. The key to the map is the \"name\" attribute. If \"value\"==\"droplet\" it will be assigned to the created droplet's ipv4_address."
  type = map(object({
    domain = string
    type   = string
    value  = string
    ttl    = number
  }))
  default = {}
}
variable "user" {
  description = "Username of user to be added to the droplet."
  type        = string
  default     = "ubuntu"
}

