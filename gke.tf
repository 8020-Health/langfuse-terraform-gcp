resource "google_container_cluster" "this" {
  name     = var.name
  location = data.google_client_config.current.region

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${data.google_client_config.current.project}.svc.id.goog"
  }

  enable_autopilot = true

  networking_mode = "VPC_NATIVE"
  network         = local.network_name
  subnetwork      = local.subnetwork_name

  deletion_protection = var.deletion_protection

  resource_labels = var.labels
}
