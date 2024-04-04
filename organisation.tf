resource "scaleway_account_ssh_key" "main" {
  project_id = var.project_id
  name       = "main"
  public_key = var.ssh_authorized_keys_flo
}