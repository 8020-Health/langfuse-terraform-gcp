# Data sources for existing VPC resources
data "google_compute_network" "existing" {
  count = var.create_vpc ? 0 : 1
  name  = var.existing_network_name
}

data "google_compute_subnetwork" "existing" {
  count  = var.create_vpc ? 0 : 1
  name   = var.existing_subnetwork_name
  region = data.google_client_config.current.region
}

# Conditionally create VPC resources
resource "google_compute_network" "this" {
  count                   = var.create_vpc ? 1 : 0
  name                    = var.name
  auto_create_subnetworks = false # Only create subnet in configured region

  # labels = var.labels
}

# Create subnets in different zones
resource "google_compute_subnetwork" "this" {
  count         = var.create_vpc ? 1 : 0
  name          = var.name
  ip_cidr_range = var.subnetwork_cidr
  region        = data.google_client_config.current.region
  network       = google_compute_network.this[0].name

  # Enable private Google access
  private_ip_google_access = true

  # Enable flow logs
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  # labels = var.labels
}

# Cloud Router for NAT Gateway
resource "google_compute_router" "router" {
  count   = var.create_vpc ? 1 : 0
  name    = var.name
  region  = data.google_client_config.current.region
  network = google_compute_network.this[0].id
}

# Cloud NAT configuration
resource "google_compute_router_nat" "nat" {
  count                              = var.create_vpc ? 1 : 0
  name                               = var.name
  router                             = google_compute_router.router[0].name
  region                             = data.google_client_config.current.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall rules for internal communication
resource "google_compute_firewall" "internal" {
  count   = var.create_vpc ? 1 : 0
  name    = "${var.name}-internal"
  network = google_compute_network.this[0].name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnetwork_cidr]
}

# Allow all egress traffic (default behavior made explicit)
resource "google_compute_firewall" "allow_all_egress" {
  count     = var.create_vpc ? 1 : 0
  name      = "${var.name}-allow-all-egress"
  network   = google_compute_network.this[0].name
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}

# Private Service Connection
resource "google_compute_global_address" "this" {
  count         = var.create_vpc ? 1 : 0
  name          = var.name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.this[0].id
}

resource "google_service_networking_connection" "private_service_connection" {
  count                   = var.create_vpc ? 1 : 0
  network                 = google_compute_network.this[0].id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.this[0].name]
}

# Locals to reference either created or existing VPC resources
locals {
  network_name = var.create_vpc ? google_compute_network.this[0].name : data.google_compute_network.existing[0].name
  network_id   = var.create_vpc ? google_compute_network.this[0].id : data.google_compute_network.existing[0].id
  subnetwork_name = var.create_vpc ? google_compute_subnetwork.this[0].name : data.google_compute_subnetwork.existing[0].name
}
