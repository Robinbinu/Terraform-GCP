terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = "intellicash-465015"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_instance" "default" {
  name         = "hello-world-vm"  # VM name
  machine_type = "f1-micro"  # Minimal instance type
  zone         = "us-central1-a"  # Change the zone if needed
  
  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2504-plucky-amd64-v20250624" # Ubuntu 20.04 LTS image
    }
  }

  network_interface {
    network = "default"
    access_config {}  # Allows external IP address
  }

  metadata_startup_script = <<-EOT
    #! /bin/bash
    echo "Hello, World!" > /var/www/html/index.html  # Write hello world to index.html
    apt-get update  # Update package lists
    apt-get install -y apache2  # Install Apache web server
    systemctl start apache2  # Start Apache server
    systemctl enable apache2  # Enable Apache to start on boot
  EOT

  tags = ["http-server"]  # Apply firewall rule to allow HTTP traffic
}

output "instance_ip" {
  value = google_compute_instance.default.network_interface[0].access_config[0].nat_ip  # Output the external IP
}
