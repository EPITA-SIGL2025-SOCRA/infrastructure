resource "scaleway_instance_security_group" "web" {
  project_id              = var.project_id
  name                    = "web-instance-socra-epita"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"
  zone                    = var.instance_zone

  inbound_rule {
    action = "accept"
    port   = "22"
  }

  inbound_rule {
    action = "accept"
    port   = "80"
  }

  inbound_rule {
    action = "accept"
    port   = "443"
  }
}

resource "scaleway_instance_ip" "group_instance_ip" {
  for_each   = { for group in local.groups : group.name => group }
  project_id = var.project_id
  zone       = var.instance_zone
}

resource "scaleway_instance_server" "group" {
  project_id        = var.project_id
  zone              = var.instance_zone
  for_each          = { for group in local.groups : group.name => group }
  name              = each.key
  image             = "ubuntu-jammy"
  type              = "DEV1-S"
  tags              = ["web", "socra", "epita"]
  ip_id             = scaleway_instance_ip.group_instance_ip[each.key].id
  security_group_id = scaleway_instance_security_group.web.id
  cloud_init        = <<EOT
#cloud-config

ssh_authorized_keys:
  - ${file("${path.module}/ssh_keys/id_${each.key}.pub")}
  - ${var.ssh_authorized_keys_flo}

package_update: true

groups:
  - docker

system_info:
  default_user:
    groups: [docker]

packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  - unattended-upgrades

runcmd:
  - mkdir -p /etc/apt/keyrings
  - apt-get update

final_message: "The system is finally up, after $UPTIME seconds"

EOT
  root_volume {
    size_in_gb = 20
  }
  depends_on = [scaleway_account_ssh_key.main]
}

output "instances_names" {
  value = {
    for k, r in ovh_domain_zone_record.group : k => "${r.subdomain}.${r.zone}"
  }
}

output "instances_ips" {
  value = {
    for k, i in scaleway_instance_server.group : k => i.public_ip
  }
}

resource "ovh_domain_zone_record" "group" {
  for_each  = { for group in local.groups : group.name => group }
  zone      = var.instance_domain
  subdomain = each.key
  target    = scaleway_instance_ip.group_instance_ip[each.key].address
  fieldtype = "A"
  ttl       = 3600
}

resource "ovh_domain_zone_record" "group_wildcard_subdomains" {
  for_each  = { for group in local.groups : group.name => group }
  zone      = var.instance_domain
  subdomain = "*.${each.key}"
  target    = scaleway_instance_ip.group_instance_ip[each.key].address
  fieldtype = "A"
  ttl       = 3600
}
