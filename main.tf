# Define provider
provider "google" {
  project = "myfirstapp-72240"
  region  = "northamerica-northeast2"
}

# Variables
variable "project_id" {
  default = "myfirstapp-72240"
}

variable "db_password" {
  description = "The password for the database user"
  type        = string
  default     = "mypassword" 
}

variable "postgres_password" {
  description = "The password for the PostgreSQL user"
  type        = string
  default     = "mypassword" 
}

# Create a network
resource "google_compute_network" "assignment_network" {
  name                    = "assignment-02-network"
  auto_create_subnetworks = false
}

# Create a subnet
resource "google_compute_subnetwork" "assignment_subnet" {
  name          = "assignment-02-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = "northamerica-northeast2"
  network       = google_compute_network.assignment_network.id
}

# Firewall rule for HTTP
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.assignment_network.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Firewall rule for PostgreSQL (port 5432)
resource "google_compute_firewall" "allow_postgres" {
  name    = "allow-postgres"
  network = google_compute_network.assignment_network.id

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = ["0.0.0.0/0"] # Allow all IPs
}

# Cloud SQL instance for PostgreSQL
resource "google_sql_database_instance" "postgres_instance" {
  name             = "assignment-02-database"
  region           = "northamerica-northeast2"
  database_version = "POSTGRES_14"
  deletion_protection = false
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = true
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
    }
  }
}

resource "google_sql_user" "postgres" {
  name     = "postgres"
  instance = google_sql_database_instance.postgres_instance.name
  password = var.postgres_password
}

# Create a user
resource "google_sql_user" "myuser" {
  name     = "myuser"
  instance = google_sql_database_instance.postgres_instance.name
  password = var.db_password
}

# Create a database
resource "google_sql_database" "myappdb" {
  name     = "myappdb"
  instance = google_sql_database_instance.postgres_instance.name
}

# Script to run SQL commands for granting privileges and schema access
resource "null_resource" "initialize_db" {
  depends_on = [
    google_sql_user.myuser,
    google_sql_database.myappdb
  ]

  provisioner "local-exec" {
    command = <<EOT
      PGPASSWORD="mypassword" psql -h ${google_sql_database_instance.postgres_instance.public_ip_address} -U postgres -d myappdb -c "GRANT ALL PRIVILEGES ON DATABASE myappdb TO myuser;" -c "\\c myappdb;" -c "GRANT USAGE ON SCHEMA public TO myuser;" -c "GRANT ALL PRIVILEGES ON SCHEMA public TO myuser;"
    EOT
  }
}


# Cloud SQL database
resource "google_sql_database" "default_db" {
  name     = "assignment-02-database"
  instance = google_sql_database_instance.postgres_instance.name
}

# GKE Cluster
resource "google_container_cluster" "gke_cluster" {
  name       = "assignment-02-cluster"
  location   = "northamerica-northeast2"
  network    = google_compute_network.assignment_network.id
  subnetwork = google_compute_subnetwork.assignment_subnet.id
  deletion_protection = false
  remove_default_node_pool = false

  # Node pool definition
  node_pool {
    name = "primary-node-pool"

    node_config {
      machine_type = "e2-medium"
      preemptible  = false
      disk_size_gb = 30
    }

    initial_node_count = 1
  }

  lifecycle {
    prevent_destroy = false # Disable Terraform protection
  }
}

# Outputs
output "network_name" {
  value = google_compute_network.assignment_network.name
}

output "database_ip" {
  value = google_sql_database_instance.postgres_instance.public_ip_address
}

output "cluster_endpoint" {
  value = google_container_cluster.gke_cluster.endpoint
}