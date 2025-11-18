resource "google_sql_database_instance" "this" {
  count = var.create_postgres_instance ? 1 : 0

  name             = var.name
  region           = data.google_client_config.current.region
  database_version = "POSTGRES_15"

  settings {
    tier                        = var.database_instance_tier
    edition                     = var.database_instance_edition
    availability_type           = var.database_instance_availability_type
    deletion_protection_enabled = var.deletion_protection # Applies setting on GCP level

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.create_vpc ? google_compute_network.this[0].self_link : data.google_compute_network.existing[0].self_link
      enable_private_path_for_google_cloud_services = true
      ssl_mode                                      = "ENCRYPTED_ONLY"
    }

    user_labels = var.labels
  }

  # note: when create_vpc=true, terraform will implicitly depend on the service connection
  # via the private_network reference. when create_vpc=false, we use the existing vpc's
  # service connection, so no explicit depends_on is needed.

  deletion_protection = var.deletion_protection # applies setting on terraform level
}

resource "google_sql_database" "langfuse" {
  count = var.create_postgres_instance ? 1 : 0

  name     = "langfuse"
  instance = google_sql_database_instance.this[0].name
}

resource "google_sql_user" "langfuse" {
  count = var.create_postgres_instance ? 1 : 0

  name     = "langfuse"
  instance = google_sql_database_instance.this[0].name
  password = random_password.postgres_password[0].result
}

# Random passwords for database credentials
resource "random_password" "postgres_password" {
  count = var.create_postgres_instance ? 1 : 0

  length      = 64
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}
