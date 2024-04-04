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

resource "scaleway_instance_ip" "student_instance_ip" {
  for_each   = { for student in local.students : student.username => student }
  project_id = var.project_id
  zone       = var.instance_zone
}

resource "scaleway_instance_server" "student" {
  project_id        = var.project_id
  zone              = var.instance_zone
  for_each          = { for student in local.students : student.username => student }
  name              = each.key
  image             = "ubuntu-jammy"
  type              = "DEV1-S"
  tags              = ["web", "socra", "epita"]
  ip_id             = scaleway_instance_ip.student_instance_ip[each.key].id
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

write_files:
  - path: /data/compose/global.yml
    owner: root:root
    permissions: "0644"
    content: |
      version: "2"
      networks:
        web:
          name: web

  - path: /data/compose/traefik.yml
    owner: root:root
    permissions: "0644"
    content: |
      version: "2"
      services:
        traefik:
          image: traefik:v2.11
          container_name: traefik
          restart: unless-stopped
          networks:
            - web
          volumes:
            - /data/volumes/traefik/config/:/etc/traefik/:rw # Stores letsencrypt.json
            - /var/run/docker.sock:/var/run/docker.sock:ro
          ports:
            - 80:80/tcp
            - 443:443/tcp
          labels:
            - traefik.enable=true
            - traefik.http.routers.dashboard.rule=Host(`${each.key}.${var.instance_domain}`) && (PathPrefix(`/dashboard`) || PathPrefix(`/api`))
            - traefik.http.routers.dashboard.entrypoints=websecure
            - traefik.http.routers.dashboard.tls=true
            - traefik.http.routers.dashboard.tls.certresolver=letsencrypt
            - traefik.http.routers.dashboard.middlewares=dashboard-auth
            - traefik.http.routers.dashboard.service=api@internal
            - traefik.http.middlewares.dashboard-auth.basicauth.users=hetic:$$apr1$$0sTlc0o8$$GKB74SAsRB54MsX42oF.K0 # hetic:tactoe
          command:
            - --api.dashboard=true
            - --certificatesresolvers.letsencrypt.acme.email=${each.key}@${each.key}.socra-sigl.fr
            - --certificatesresolvers.letsencrypt.acme.storage=/etc/traefik/letsencrypt.json
            - --certificatesresolvers.letsencrypt.acme.tlsChallenge=true
            - --entrypoints.web.address=:80
            - --entrypoints.websecure.address=:443
            - --global.checkNewVersion=false
            - --global.sendAnonymousUsage=false
            - --log.level=DEBUG
            - --providers.docker.exposedByDefault=false
            - --providers.docker.network=web
            - --providers.file.fileName=/etc/traefik/dynamic-config.yml" # Optional but doesn't hurt even if the file doesn't exis
            - --providers.file.watch=true
          mem_limit: 300m

  - path: /etc/systemd/system/compose@.service
    owner: root:root
    permissions: "0644"
    encoding: b64
    content: ${filebase64("${path.module}/services/compose@.service")}

  - path: /data/volumes/traefik/config/letsencrypt.json
    owner: root:root
    permissions: "0600"
    content: {}

runcmd:
  - mkdir -p /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  - systemctl enable docker compose@traefik
  - systemctl start docker compose@traefik

final_message: "The system is finally up, after $UPTIME seconds"

EOT
  root_volume {
    size_in_gb = 20
  }
  depends_on = [scaleway_account_ssh_key.main]
}

output "instances_names" {
  value = {
    for k, r in ovh_domain_zone_record.student : k => "${r.subdomain}.${r.zone}"
  }
}

output "instances_ips" {
  value = {
    for k, i in scaleway_instance_server.student : k => i.public_ip
  }
}

resource "ovh_domain_zone_record" "student" {
  for_each  = { for student in local.students : student.username => student }
  zone      = var.instance_domain
  subdomain = each.key
  target    = scaleway_instance_ip.student_instance_ip[each.key].address
  fieldtype = "A"
  ttl       = 3600
}

resource "ovh_domain_zone_record" "student_api" {
  for_each  = { for student in local.students : student.username => student }
  zone      = var.instance_domain
  subdomain = "*.${each.key}"
  target    = scaleway_instance_ip.student_instance_ip[each.key].address
  fieldtype = "A"
  ttl       = 3600
}
