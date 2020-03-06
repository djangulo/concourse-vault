module "docker_compose_host" {
  source  = "djangulo/docker-compose-host/digitalocean"
  version = "0.2.3"

  do_token     = var.do_token
  droplet_name = "Concourse-CI"
  tags         = ["Concourse-CI"]
  image        = "ubuntu-18-04-x64"
  region       = "nyc3"
  size         = "s-2vcpu-2gb"

  ssh_keys    = var.ssh_keys
  init_script = "./scripts/gen_keys.sh"
  domain      = var.domain
  user        = var.user
  records     = var.records
}

resource "null_resource" "compose_up" {

  connection {
    type = "ssh"
    user = var.user
    host = module.docker_compose_host.ipv4_address
  }

  provisioner "file" {
    content = templatefile("${path.module}/vault/config/vault.hcl", {
      vault_external_url = var.vault_external_url
    })
    destination = "/home/${var.user}/traefik-concourse-vault/vault/config/vault.hcl"
  }

  provisioner "file" {
    source      = "./vault/config/concourse-policy.hcl"
    destination = "/home/${var.user}/traefik-concourse-vault/vault/config/concourse-policy.hcl"
  }

  provisioner "file" {
    source      = "./concourse/"
    destination = "/home/${var.user}/traefik-concourse-vault/concourse"
  }

  provisioner "file" {
    content = templatefile("${path.module}/docker-compose.yml", {
      host_user               = var.user,
      vault_external_url      = var.vault_external_url,
      concourse_external_url  = var.concourse_external_url,
      vault_host              = replace(var.vault_external_url, "/^.*\\:\\/\\//", ""),
      concourse_host          = replace(var.concourse_external_url, "/^.*\\:\\/\\//", ""),
      postgres_user           = var.postgres_user,
      postgres_password       = var.postgres_password,
      postgres_database       = var.postgres_database,
      concourse_root_password = var.concourse_root_password,
      letsencrypt_admin_email = var.letsencrypt_admin_email,
    })
    destination = "/home/${var.user}/traefik-concourse-vault/docker-compose.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/${var.user}/traefik-concourse-vault",
      "docker-compose down",
      "docker-compose up -d",
    ]
  }
}
