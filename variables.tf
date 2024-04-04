variable "project_id" {
  type        = string
  description = "SOCRA EPITA project id"
  default     = "c0ae6636-3663-4759-822c-adbf2387fd16"
}

variable "instance_zone" {
  type        = string
  description = "SOCRA EPITA instance zone"
  default     = "fr-par-1"
}

variable "instance_domain" {
  type        = string
  description = "SOCRA EPITA instance domain"
  default     = "socra-sigl.fr"
}

variable "ssh_authorized_keys_flo" {
  type    = string
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFY3RkuxU18orIhK3uECEZi8QASUpNsV5sPP6YmCEyaf florent.fauchille@floless.fr"
}

locals {
  students = csvdecode(file("${path.module}/students.csv"))
}
