output "cluster_name" {
  description = "GKE Cluster Name to use for a Kubernetes terraform provider"
  value       = google_container_cluster.this.name
}

output "cluster_host" {
  description = "GKE Cluster host to use for a Kubernetes terraform provider"
  value       = "https://${google_container_cluster.this.endpoint}"
}

output "cluster_ca_certificate" {
  description = "GKE Cluster CA certificate to use for a Kubernetes terraform provider"
  value       = base64decode(google_container_cluster.this.master_auth[0].cluster_ca_certificate)
  sensitive   = true
}

output "cluster_token" {
  description = "GKE Cluster Token to use for a Kubernetes terraform provider"
  value       = data.google_client_config.current.access_token
  sensitive   = true
}

output "postgres_password" {
  description = "PostgreSQL password"
  value       = var.create_postgres_instance ? random_password.postgres_password[0].result : var.external_postgres_password
  sensitive   = true
}

output "network_id" {
  description = "VPC network ID for peering"
  value       = local.network_id
}

output "network_name" {
  description = "VPC network name"
  value       = local.network_name
}

output "network_self_link" {
  description = "VPC network self_link"
  value       = var.create_vpc ? google_compute_network.this[0].self_link : data.google_compute_network.existing[0].self_link
}

output "subnetwork_self_link" {
  description = "VPC subnetwork self_link"
  value       = var.create_vpc ? google_compute_subnetwork.this[0].self_link : data.google_compute_subnetwork.existing[0].self_link
}
