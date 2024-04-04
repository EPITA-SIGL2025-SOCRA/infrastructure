terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
    ovh = {
      source = "ovh/ovh"
    }
  }
  required_version = ">= 0.13"
}

provider "scaleway" {
  zone   = "fr-par-1"
  region = "fr-par"
}

provider "ovh" {
  endpoint           = "ovh-eu"
}