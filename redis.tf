resource "google_redis_instance" "this" {
  name               = var.name
  tier               = var.cache_tier
  memory_size_gb     = var.cache_memory_size_gb
  region             = data.google_client_config.current.region
  authorized_network = local.network_id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  transit_encryption_mode = "SERVER_AUTHENTICATION"
  display_name = "${local.tag_name} Redis Instance"

  auth_enabled = true

  redis_configs = {
    "maxmemory-policy" = "noeviction"
  }

  labels = var.labels

  # note: when create_vpc=true, terraform will implicitly depend on the service connection
  # via the authorized_network reference. when create_vpc=false, we use the existing vpc's
  # service connection, so no explicit depends_on is needed.
}
