# Terraform Configuration with Choices and Verbose Logging
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

# Input Variables for Choices
variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "intellicash-465015"
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "us-central1"
  validation {
    condition = contains([
      "us-central1", "us-east1", "us-west1", "us-west2", 
      "europe-west1", "europe-west2", "asia-southeast1"
    ], var.region)
    error_message = "Region must be one of: us-central1, us-east1, us-west1, us-west2, europe-west1, europe-west2, asia-southeast1."
  }
}

variable "zone" {
  description = "The GCP zone to deploy the VM instance"
  type        = string
  default     = ""
}

variable "machine_type" {
  description = "The machine type for the VM instance"
  type        = string
  default     = "f1-micro"
  validation {
    condition = contains([
      "f1-micro", "e2-micro", "e2-small", "e2-medium", 
      "n1-standard-1", "n1-standard-2", "n2-standard-2"
    ], var.machine_type)
    error_message = "Machine type must be one of: f1-micro, e2-micro, e2-small, e2-medium, n1-standard-1, n1-standard-2, n2-standard-2."
  }
}

variable "vm_name" {
  description = "Name for the VM instance"
  type        = string
  default     = "hello-world-vm"
}

variable "os_choice" {
  description = "Operating system choice for the VM"
  type        = string
  default     = "ubuntu"
  validation {
    condition = contains(["ubuntu", "debian", "centos", "rhel"], var.os_choice)
    error_message = "OS choice must be one of: ubuntu, debian, centos, rhel."
  }
}

variable "enable_http_server" {
  description = "Whether to install and configure HTTP server"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Whether to enable monitoring and logging"
  type        = bool
  default     = false
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 10
  validation {
    condition     = var.disk_size >= 10 && var.disk_size <= 100
    error_message = "Disk size must be between 10 and 100 GB."
  }
}

variable "instance_state" {
  description = "Desired state of the VM instance (RUNNING, TERMINATED)"
  type        = string
  default     = "RUNNING"
  validation {
    condition = contains(["RUNNING", "TERMINATED"], var.instance_state)
    error_message = "Instance state must be either RUNNING or TERMINATED."
  }
}

variable "auto_start" {
  description = "Whether to automatically start the instance if it's stopped"
  type        = bool
  default     = true
}

variable "auto_restart" {
  description = "Whether to automatically restart the instance if it crashes"
  type        = bool
  default     = true
}

variable "preemptible" {
  description = "Whether to make the instance preemptible (cheaper but can be stopped)"
  type        = bool
  default     = false
}

# Local values for computed configurations
locals {
  # Determine zone based on region if not specified
  computed_zone = var.zone != "" ? var.zone : "${var.region}-a"
  
  # OS image mapping
  os_images = {
    ubuntu = "projects/ubuntu-os-cloud/global/images/family/ubuntu-minimal-2404-lts"
    debian = "projects/debian-cloud/global/images/family/debian-12"
    centos = "projects/centos-cloud/global/images/family/centos-stream-9"
    rhel   = "projects/rhel-cloud/global/images/family/rhel-9"
  }
  
  # Tags based on configuration
  vm_tags = concat(
    var.enable_http_server ? ["http-server", "https-server"] : [],
    var.enable_monitoring ? ["monitoring"] : [],
    ["terraform-managed"]
  )
  
  # Startup script based on OS and options
  ubuntu_with_http = <<-EOT
      #!/bin/bash
      echo "=== Starting Ubuntu VM Setup ===" | tee -a /var/log/startup.log
      echo "Timestamp: $(date)" | tee -a /var/log/startup.log
      echo "Updating package lists..." | tee -a /var/log/startup.log
      apt-get update 2>&1 | tee -a /var/log/startup.log
      echo "Installing Apache2..." | tee -a /var/log/startup.log
      apt-get install -y apache2 2>&1 | tee -a /var/log/startup.log
      echo "Creating hello world page..." | tee -a /var/log/startup.log
      mkdir -p /var/www/html
      echo "<h1>Hello, World!</h1><p>VM: ${var.vm_name}</p><p>Zone: ${local.computed_zone}</p><p>Machine Type: ${var.machine_type}</p>" > /var/www/html/index.html
      echo "Starting Apache2..." | tee -a /var/log/startup.log
      systemctl start apache2 2>&1 | tee -a /var/log/startup.log
      systemctl enable apache2 2>&1 | tee -a /var/log/startup.log
      echo "=== Ubuntu VM Setup Complete ===" | tee -a /var/log/startup.log
    EOT
    
  ubuntu_without_http = <<-EOT
      #!/bin/bash
      echo "=== Starting Ubuntu VM Setup (No HTTP Server) ===" | tee -a /var/log/startup.log
      echo "Timestamp: $(date)" | tee -a /var/log/startup.log
      echo "Updating package lists..." | tee -a /var/log/startup.log
      apt-get update 2>&1 | tee -a /var/log/startup.log
      echo "=== Ubuntu VM Setup Complete ===" | tee -a /var/log/startup.log
    EOT
    
  debian_with_http = <<-EOT
      #!/bin/bash
      echo "=== Starting Debian VM Setup ===" | tee -a /var/log/startup.log
      echo "Timestamp: $(date)" | tee -a /var/log/startup.log
      apt-get update 2>&1 | tee -a /var/log/startup.log
      apt-get install -y nginx 2>&1 | tee -a /var/log/startup.log
      echo "<h1>Hello, World from Debian!</h1><p>VM: ${var.vm_name}</p>" > /var/www/html/index.html
      systemctl start nginx 2>&1 | tee -a /var/log/startup.log
      systemctl enable nginx 2>&1 | tee -a /var/log/startup.log
      echo "=== Debian VM Setup Complete ===" | tee -a /var/log/startup.log
    EOT
    
  debian_without_http = <<-EOT
      #!/bin/bash
      echo "=== Starting Debian VM Setup (No HTTP Server) ===" | tee -a /var/log/startup.log
      apt-get update 2>&1 | tee -a /var/log/startup.log
      echo "=== Debian VM Setup Complete ===" | tee -a /var/log/startup.log
    EOT
    
  # Startup scripts mapping
  startup_scripts = {
    ubuntu = var.enable_http_server ? local.ubuntu_with_http : local.ubuntu_without_http
    debian = var.enable_http_server ? local.debian_with_http : local.debian_without_http
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = local.computed_zone
}

# Firewall rules for HTTP/HTTPS traffic (conditional)
resource "google_compute_firewall" "allow_http" {
  count = var.enable_http_server ? 1 : 0
  
  name    = "${var.vm_name}-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
  
  description = "Allow HTTP and HTTPS traffic to VM instances with http-server tag"
}

# Main VM Instance with verbose configuration and lifecycle management
resource "google_compute_instance" "default" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = local.computed_zone
  
  # Instance lifecycle configuration
  desired_status = var.instance_state
  
  boot_disk {
    initialize_params {
      image = local.os_images[var.os_choice]
      size  = var.disk_size
      type  = "pd-standard"
    }
    auto_delete = true
  }

  # Preemptible instance configuration
  scheduling {
    preemptible                 = var.preemptible
    automatic_restart           = var.auto_restart && !var.preemptible
    on_host_maintenance        = var.preemptible ? "TERMINATE" : "MIGRATE"
    provisioning_model         = var.preemptible ? "SPOT" : "STANDARD"
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral external IP
    }
  }

  metadata_startup_script = lookup(local.startup_scripts, var.os_choice, local.startup_scripts["ubuntu"])

  tags = local.vm_tags

  # Enable monitoring if requested
  dynamic "service_account" {
    for_each = var.enable_monitoring ? [1] : []
    content {
      email  = "default"
      scopes = ["monitoring-write", "logging-write"]
    }
  }

  metadata = {
    startup-script-url = ""
    enable-oslogin     = "true"
  }

  labels = {
    environment = "development"
    created-by  = "terraform"
    os-type     = var.os_choice
    instance-state = lower(var.instance_state)
    preemptible = var.preemptible ? "true" : "false"
  }
  
  # Lifecycle management
  lifecycle {
    ignore_changes = [
      # Ignore changes to these attributes to prevent unnecessary recreation
      metadata["startup-script"],
      metadata_startup_script,
    ]
  }
}

# Verbose Outputs for Detailed Information
output "deployment_summary" {
  description = "Complete deployment summary"
  value = {
    vm_name           = google_compute_instance.default.name
    machine_type      = google_compute_instance.default.machine_type
    zone             = google_compute_instance.default.zone
    os_choice        = var.os_choice
    disk_size        = var.disk_size
    http_server      = var.enable_http_server
    monitoring       = var.enable_monitoring
    instance_state   = var.instance_state
    preemptible      = var.preemptible
    auto_restart     = var.auto_restart
    current_status   = google_compute_instance.default.current_status
    instance_id      = google_compute_instance.default.instance_id
  }
}

output "instance_details" {
  description = "Detailed instance information"
  value = {
    instance_id       = google_compute_instance.default.instance_id
    self_link        = google_compute_instance.default.self_link
    cpu_platform     = google_compute_instance.default.cpu_platform
    current_status   = google_compute_instance.default.current_status
    tags             = google_compute_instance.default.tags
    labels           = google_compute_instance.default.labels
  }
}

output "network_information" {
  description = "Network configuration details"
  value = {
    external_ip      = google_compute_instance.default.network_interface[0].access_config[0].nat_ip
    internal_ip      = google_compute_instance.default.network_interface[0].network_ip
    network_name     = google_compute_instance.default.network_interface[0].network
    subnetwork       = google_compute_instance.default.network_interface[0].subnetwork
  }
}

output "access_information" {
  description = "How to access your instance"
  value = var.enable_http_server ? {
    web_url = "http://${google_compute_instance.default.network_interface[0].access_config[0].nat_ip}"
    ssh_command = "gcloud compute ssh ${var.vm_name} --zone=${local.computed_zone} --project=${var.project_id}"
    web_accessible = true
  } : {
    ssh_command = "gcloud compute ssh ${var.vm_name} --zone=${local.computed_zone} --project=${var.project_id}"
    web_accessible = false
  }
}

output "firewall_rules" {
  description = "Applied firewall rules"
  value = var.enable_http_server ? {
    http_rule_name = google_compute_firewall.allow_http[0].name
    allowed_ports  = ["80", "443"]
    source_ranges  = google_compute_firewall.allow_http[0].source_ranges
  } : {
    message = "No HTTP firewall rules created"
  }
}

output "cost_estimation" {
  description = "Estimated monthly cost information"
  value = {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size
    estimated_note = "Visit Google Cloud Pricing Calculator for accurate cost estimates"
    pricing_url = "https://cloud.google.com/products/calculator"
  }
}

# Legacy output for backward compatibility
output "instance_ip" {
  description = "External IP address of the instance"
  value = google_compute_instance.default.network_interface[0].access_config[0].nat_ip
}
