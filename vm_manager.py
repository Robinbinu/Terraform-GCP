#!/usr/bin/env python3
"""
Google Cloud VM Management Script with Choices and Verbose Logging
Alternative to Terraform for managing GCP VM instances with full lifecycle control
"""

import argparse
import json
import logging
import os
import sys
import time
from datetime import datetime
from typing import Any, Dict, List, Optional

try:
    import google.auth
    from google.cloud import compute_v1
    from google.oauth2 import service_account
except ImportError:
    print("Error: Google Cloud SDK not installed. Install with:")
    print("pip install google-cloud-compute google-auth")
    sys.exit(1)

# Configuration and logging setup
class Colors:
    """ANSI color codes for terminal output"""
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    WHITE = '\033[1;37m'
    RESET = '\033[0m'

class VMManager:
    """Google Cloud VM Instance Manager with verbose logging"""
    
    def __init__(self, config_file: str = "vm_config.json"):
        self.config_file = config_file
        self.config = self.load_config()
        self.setup_logging()
        self.setup_gcp_clients()
        
        # OS image mappings
        self.os_images = {
            'ubuntu': 'projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2504-plucky-amd64-v20250624',
            'debian': 'projects/debian-cloud/global/images/family/debian-12',
            'centos': 'projects/centos-cloud/global/images/family/centos-stream-9',
            'rhel': 'projects/rhel-cloud/global/images/family/rhel-9'
        }
        
        # Machine type choices
        self.machine_types = [
            'f1-micro', 'e2-micro', 'e2-small', 'e2-medium',
            'n1-standard-1', 'n1-standard-2', 'n2-standard-2'
        ]
        
        # Region choices
        self.regions = [
            'us-central1', 'us-east1', 'us-west1', 'us-west2',
            'europe-west1', 'europe-west2', 'asia-southeast1'
        ]

    def print_colored(self, message: str, color: str = Colors.WHITE) -> None:
        """Print colored message to terminal"""
        print(f"{color}{message}{Colors.RESET}")
        
    def log_info(self, message: str) -> None:
        """Log info message with color"""
        self.print_colored(f"[INFO] {message}", Colors.BLUE)
        self.logger.info(message)
        
    def log_success(self, message: str) -> None:
        """Log success message with color"""
        self.print_colored(f"[SUCCESS] {message}", Colors.GREEN)
        self.logger.info(f"SUCCESS: {message}")
        
    def log_warning(self, message: str) -> None:
        """Log warning message with color"""
        self.print_colored(f"[WARNING] {message}", Colors.YELLOW)
        self.logger.warning(message)
        
    def log_error(self, message: str) -> None:
        """Log error message with color"""
        self.print_colored(f"[ERROR] {message}", Colors.RED)
        self.logger.error(message)

    def setup_logging(self) -> None:
        """Setup verbose logging to file"""
        log_filename = f"vm_management_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_filename),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)
        self.log_info(f"Logging to: {log_filename}")

    def load_config(self) -> Dict[str, Any]:
        """Load configuration from JSON file"""
        default_config = {
            "project_id": "your-gcp-project-id",
            "region": "us-central1",
            "zone": "",
            "vm_name": "python-managed-vm",
            "machine_type": "e2-micro",
            "os_choice": "ubuntu",
            "disk_size": 20,
            "enable_http_server": True,
            "enable_monitoring": False,
            "instance_state": "RUNNING",
            "auto_start": True,
            "auto_restart": True,
            "preemptible": False,
            "tags": ["python-managed", "http-server"],
            "labels": {
                "created-by": "python-script",
                "environment": "development"
            }
        }
        
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'r') as f:
                    config = json.load(f)
                    # Merge with defaults
                    for key, value in default_config.items():
                        if key not in config:
                            config[key] = value
                    return config
            except Exception as e:
                self.log_error(f"Error loading config: {e}")
                return default_config
        else:
            # Create default config file
            with open(self.config_file, 'w') as f:
                json.dump(default_config, f, indent=2)
            self.log_info(f"Created default config file: {self.config_file}")
            return default_config

    def save_config(self) -> None:
        """Save current configuration to file"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
            self.log_success(f"Configuration saved to {self.config_file}")
        except Exception as e:
            self.log_error(f"Error saving config: {e}")

    def setup_gcp_clients(self) -> None:
        """Setup Google Cloud clients"""
        try:
            # Use default credentials or service account
            credentials, project = google.auth.default()
            
            if self.config["project_id"] == "your-gcp-project-id":
                if project:
                    self.config["project_id"] = project
                    self.log_info(f"Using detected project: {project}")
                else:
                    self.log_error("Please set project_id in config file")
                    sys.exit(1)
            
            self.instances_client = compute_v1.InstancesClient(credentials=credentials)
            self.disks_client = compute_v1.DisksClient(credentials=credentials)
            self.firewalls_client = compute_v1.FirewallsClient(credentials=credentials)
            self.operations_client = compute_v1.GlobalOperationsClient(credentials=credentials)
            self.zone_operations_client = compute_v1.ZoneOperationsClient(credentials=credentials)
            
            self.log_success("Google Cloud clients initialized")
            
        except Exception as e:
            self.log_error(f"Failed to setup GCP clients: {e}")
            self.log_error("Make sure you're authenticated: gcloud auth application-default login")
            sys.exit(1)

    def get_zone(self) -> str:
        """Get zone, auto-generate if not specified"""
        if self.config["zone"]:
            return self.config["zone"]
        return f"{self.config['region']}-a"

    def generate_startup_script(self) -> str:
        """Generate startup script based on configuration"""
        base_script = f"""#!/bin/bash
echo "=== Starting {self.config['os_choice'].title()} VM Setup ===" | tee -a /var/log/startup.log
echo "Timestamp: $(date)" | tee -a /var/log/startup.log
echo "VM Name: {self.config['vm_name']}" | tee -a /var/log/startup.log
echo "Machine Type: {self.config['machine_type']}" | tee -a /var/log/startup.log
echo "Zone: {self.get_zone()}" | tee -a /var/log/startup.log
"""
        
        if self.config["enable_http_server"]:
            if self.config["os_choice"] == "ubuntu":
                base_script += """
echo "Updating package lists..." | tee -a /var/log/startup.log
apt-get update 2>&1 | tee -a /var/log/startup.log
echo "Installing Apache2..." | tee -a /var/log/startup.log
apt-get install -y apache2 2>&1 | tee -a /var/log/startup.log
echo "Creating hello world page..." | tee -a /var/log/startup.log
mkdir -p /var/www/html
cat > /var/www/html/index.html << 'EOF'
<html>
<head><title>Python-Managed VM</title></head>
<body>
<h1>Hello, World!</h1>
<p>VM: {vm_name}</p>
<p>Zone: {zone}</p>
<p>Machine Type: {machine_type}</p>
<p>Managed by: Python Script</p>
<p>Timestamp: $(date)</p>
</body>
</html>
EOF
echo "Starting Apache2..." | tee -a /var/log/startup.log
systemctl start apache2 2>&1 | tee -a /var/log/startup.log
systemctl enable apache2 2>&1 | tee -a /var/log/startup.log
""".format(
                    vm_name=self.config['vm_name'],
                    zone=self.get_zone(),
                    machine_type=self.config['machine_type']
                )
            elif self.config["os_choice"] == "debian":
                base_script += """
echo "Installing Nginx..." | tee -a /var/log/startup.log
apt-get update 2>&1 | tee -a /var/log/startup.log
apt-get install -y nginx 2>&1 | tee -a /var/log/startup.log
echo "<h1>Hello from Debian!</h1><p>VM: {vm_name}</p>" > /var/www/html/index.html
systemctl start nginx 2>&1 | tee -a /var/log/startup.log
systemctl enable nginx 2>&1 | tee -a /var/log/startup.log
""".format(vm_name=self.config['vm_name'])
        
        base_script += f"""
echo "=== {self.config['os_choice'].title()} VM Setup Complete ===" | tee -a /var/log/startup.log
"""
        
        return base_script

    def wait_for_operation(self, operation, operation_type: str = "operation") -> bool:
        """Wait for GCP operation to complete with verbose logging"""
        self.log_info(f"Waiting for {operation_type} to complete...")
        
        while True:
            if hasattr(operation, 'name'):
                # Zone operation
                result = self.zone_operations_client.get(
                    project=self.config["project_id"],
                    zone=self.get_zone(),
                    operation=operation.name
                )
            else:
                # Global operation
                result = self.operations_client.get(
                    project=self.config["project_id"],
                    operation=operation.name
                )
            
            if result.status == compute_v1.Operation.Status.DONE:
                if result.error:
                    self.log_error(f"{operation_type} failed: {result.error}")
                    return False
                else:
                    self.log_success(f"{operation_type} completed successfully")
                    return True
            
            self.log_info(f"{operation_type} in progress... ({result.progress}%)")
            time.sleep(2)

    def create_firewall_rule(self) -> bool:
        """Create firewall rule for HTTP traffic"""
        if not self.config["enable_http_server"]:
            return True
            
        rule_name = f"{self.config['vm_name']}-allow-http"
        
        # Check if rule already exists
        try:
            existing_rule = self.firewalls_client.get(
                project=self.config["project_id"],
                firewall=rule_name
            )
            self.log_info(f"Firewall rule {rule_name} already exists")
            return True
        except:
            pass  # Rule doesn't exist, create it
        
        self.log_info(f"Creating firewall rule: {rule_name}")
        
        firewall_rule = compute_v1.Firewall()
        firewall_rule.name = rule_name
        firewall_rule.direction = "INGRESS"
        firewall_rule.priority = 1000
        firewall_rule.source_ranges = ["0.0.0.0/0"]
        firewall_rule.target_tags = ["http-server"]
        
        allowed = compute_v1.Allowed()
        allowed.I_p_protocol = "tcp"
        allowed.ports = ["80", "443"]
        firewall_rule.allowed = [allowed]
        
        try:
            operation = self.firewalls_client.insert(
                project=self.config["project_id"],
                firewall_resource=firewall_rule
            )
            
            if self.wait_for_operation(operation, "firewall rule creation"):
                self.log_success(f"Firewall rule {rule_name} created")
                return True
            else:
                return False
                
        except Exception as e:
            self.log_error(f"Failed to create firewall rule: {e}")
            return False

    def create_instance(self) -> bool:
        """Create VM instance with verbose logging"""
        instance_name = self.config["vm_name"]
        zone = self.get_zone()
        
        self.log_info(f"=== Creating VM Instance: {instance_name} ===")
        self.log_info(f"Project: {self.config['project_id']}")
        self.log_info(f"Zone: {zone}")
        self.log_info(f"Machine Type: {self.config['machine_type']}")
        self.log_info(f"OS: {self.config['os_choice']}")
        self.log_info(f"Disk Size: {self.config['disk_size']} GB")
        self.log_info(f"HTTP Server: {self.config['enable_http_server']}")
        self.log_info(f"Preemptible: {self.config['preemptible']}")
        
        # Check if instance already exists
        try:
            existing_instance = self.instances_client.get(
                project=self.config["project_id"],
                zone=zone,
                instance=instance_name
            )
            self.log_warning(f"Instance {instance_name} already exists")
            return True
        except:
            pass  # Instance doesn't exist, create it
        
        # Create firewall rule first
        if not self.create_firewall_rule():
            self.log_error("Failed to create firewall rule")
            return False
        
        # Create instance configuration
        instance = compute_v1.Instance()
        instance.name = instance_name
        instance.machine_type = f"zones/{zone}/machineTypes/{self.config['machine_type']}"
        
        # Boot disk configuration
        boot_disk = compute_v1.AttachedDisk()
        boot_disk.auto_delete = True
        boot_disk.boot = True
        boot_disk.device_name = "boot-disk"
        
        initialize_params = compute_v1.AttachedDiskInitializeParams()
        initialize_params.source_image = self.os_images[self.config["os_choice"]]
        initialize_params.disk_size_gb = int(self.config["disk_size"])
        initialize_params.disk_type = f"zones/{zone}/diskTypes/pd-standard"
        boot_disk.initialize_params = initialize_params
        instance.disks = [boot_disk]
        
        # Network configuration
        network_interface = compute_v1.NetworkInterface()
        network_interface.network = "projects/{}/global/networks/default".format(
            self.config["project_id"]
        )
        
        access_config = compute_v1.AccessConfig()
        access_config.type_ = "ONE_TO_ONE_NAT"
        access_config.name = "External NAT"
        network_interface.access_configs = [access_config]
        
        instance.network_interfaces = [network_interface]
        
        # Scheduling configuration
        scheduling = compute_v1.Scheduling()
        scheduling.preemptible = self.config["preemptible"]
        scheduling.automatic_restart = self.config["auto_restart"] and not self.config["preemptible"]
        scheduling.on_host_maintenance = "TERMINATE" if self.config["preemptible"] else "MIGRATE"
        instance.scheduling = scheduling
        
        # Service account for monitoring
        if self.config["enable_monitoring"]:
            service_account = compute_v1.ServiceAccount()
            service_account.email = "default"
            service_account.scopes = [
                "https://www.googleapis.com/auth/monitoring.write",
                "https://www.googleapis.com/auth/logging.write"
            ]
            instance.service_accounts = [service_account]
        
        # Metadata and startup script
        metadata = compute_v1.Metadata()
        startup_script_item = compute_v1.Items()
        startup_script_item.key = "startup-script"
        startup_script_item.value = self.generate_startup_script()
        
        enable_oslogin_item = compute_v1.Items()
        enable_oslogin_item.key = "enable-oslogin"
        enable_oslogin_item.value = "true"
        
        metadata.items = [startup_script_item, enable_oslogin_item]
        instance.metadata = metadata
        
        # Tags and labels
        tags = compute_v1.Tags()
        tags.items = self.config["tags"]
        if self.config["enable_http_server"] and "http-server" not in tags.items:
            tags.items.append("http-server")
        instance.tags = tags
        
        # Labels
        labels = self.config["labels"].copy()
        labels.update({
            "os-type": self.config["os_choice"],
            "managed-by": "python-script",
            "instance-state": self.config["instance_state"].lower(),
            "preemptible": str(self.config["preemptible"]).lower()
        })
        instance.labels = labels
        
        try:
            self.log_info("Submitting instance creation request...")
            operation = self.instances_client.insert(
                project=self.config["project_id"],
                zone=zone,
                instance_resource=instance
            )
            
            if self.wait_for_operation(operation, "instance creation"):
                self.log_success(f"VM instance {instance_name} created successfully!")
                
                # Set desired state
                if self.config["instance_state"] == "TERMINATED":
                    self.log_info("Stopping instance as per configuration...")
                    self.stop_instance()
                
                return True
            else:
                return False
                
        except Exception as e:
            self.log_error(f"Failed to create instance: {e}")
            return False

    def get_instance_status(self) -> Optional[str]:
        """Get current instance status"""
        try:
            instance = self.instances_client.get(
                project=self.config["project_id"],
                zone=self.get_zone(),
                instance=self.config["vm_name"]
            )
            return instance.status
        except Exception as e:
            self.log_error(f"Failed to get instance status: {e}")
            return None

    def start_instance(self) -> bool:
        """Start VM instance"""
        instance_name = self.config["vm_name"]
        zone = self.get_zone()
        
        status = self.get_instance_status()
        if status == "RUNNING":
            self.log_warning(f"Instance {instance_name} is already running")
            return True
        elif status is None:
            self.log_error(f"Instance {instance_name} not found")
            return False
        
        self.log_info(f"Starting instance {instance_name}...")
        
        try:
            operation = self.instances_client.start(
                project=self.config["project_id"],
                zone=zone,
                instance=instance_name
            )
            
            if self.wait_for_operation(operation, "instance start"):
                self.log_success(f"Instance {instance_name} started successfully!")
                self.config["instance_state"] = "RUNNING"
                self.save_config()
                time.sleep(5)  # Wait for instance to fully start
                self.show_access_info()
                return True
            else:
                return False
                
        except Exception as e:
            self.log_error(f"Failed to start instance: {e}")
            return False

    def stop_instance(self) -> bool:
        """Stop VM instance"""
        instance_name = self.config["vm_name"]
        zone = self.get_zone()
        
        status = self.get_instance_status()
        if status in ["TERMINATED", "STOPPED"]:
            self.log_warning(f"Instance {instance_name} is already stopped")
            return True
        elif status is None:
            self.log_error(f"Instance {instance_name} not found")
            return False
        
        self.log_info(f"Stopping instance {instance_name}...")
        
        try:
            operation = self.instances_client.stop(
                project=self.config["project_id"],
                zone=zone,
                instance=instance_name
            )
            
            if self.wait_for_operation(operation, "instance stop"):
                self.log_success(f"Instance {instance_name} stopped successfully!")
                self.config["instance_state"] = "TERMINATED"
                self.save_config()
                return True
            else:
                return False
                
        except Exception as e:
            self.log_error(f"Failed to stop instance: {e}")
            return False

    def restart_instance(self) -> bool:
        """Restart VM instance"""
        instance_name = self.config["vm_name"]
        zone = self.get_zone()
        
        self.log_info(f"Restarting instance {instance_name}...")
        
        try:
            operation = self.instances_client.reset(
                project=self.config["project_id"],
                zone=zone,
                instance=instance_name
            )
            
            if self.wait_for_operation(operation, "instance restart"):
                self.log_success(f"Instance {instance_name} restarted successfully!")
                time.sleep(5)
                self.show_access_info()
                return True
            else:
                return False
                
        except Exception as e:
            self.log_error(f"Failed to restart instance: {e}")
            return False

    def delete_instance(self) -> bool:
        """Delete VM instance"""
        instance_name = self.config["vm_name"]
        zone = self.get_zone()
        
        self.log_warning(f"Deleting instance {instance_name}...")
        
        try:
            operation = self.instances_client.delete(
                project=self.config["project_id"],
                zone=zone,
                instance=instance_name
            )
            
            if self.wait_for_operation(operation, "instance deletion"):
                self.log_success(f"Instance {instance_name} deleted successfully!")
                return True
            else:
                return False
                
        except Exception as e:
            self.log_error(f"Failed to delete instance: {e}")
            return False

    def show_status(self) -> None:
        """Show detailed instance status"""
        try:
            instance = self.instances_client.get(
                project=self.config["project_id"],
                zone=self.get_zone(),
                instance=self.config["vm_name"]
            )
            
            self.print_colored("=== Instance Status ===", Colors.CYAN)
            print(f"Name: {instance.name}")
            print(f"Status: {instance.status}")
            print(f"Machine Type: {instance.machine_type.split('/')[-1]}")
            print(f"Zone: {instance.zone.split('/')[-1]}")
            print(f"CPU Platform: {getattr(instance, 'cpu_platform', 'N/A')}")
            
            if instance.network_interfaces:
                ni = instance.network_interfaces[0]
                print(f"Internal IP: {ni.network_i_p}")
                if ni.access_configs:
                    print(f"External IP: {ni.access_configs[0].nat_i_p}")
            
            print(f"Preemptible: {instance.scheduling.preemptible}")
            print(f"Auto Restart: {instance.scheduling.automatic_restart}")
            
            if instance.labels:
                print("Labels:")
                for key, value in instance.labels.items():
                    print(f"  {key}: {value}")
            
        except Exception as e:
            self.log_error(f"Failed to get instance details: {e}")

    def show_access_info(self) -> None:
        """Show access information"""
        try:
            instance = self.instances_client.get(
                project=self.config["project_id"],
                zone=self.get_zone(),
                instance=self.config["vm_name"]
            )
            
            self.print_colored("=== Access Information ===", Colors.CYAN)
            
            if instance.network_interfaces and instance.network_interfaces[0].access_configs:
                external_ip = instance.network_interfaces[0].access_configs[0].nat_i_p
                
                print(f"SSH Command:")
                print(f"  gcloud compute ssh {self.config['vm_name']} --zone={self.get_zone()} --project={self.config['project_id']}")
                
                print(f"External IP: {external_ip}")
                
                if self.config["enable_http_server"]:
                    print(f"Web URL: http://{external_ip}")
                    
        except Exception as e:
            self.log_error(f"Failed to get access information: {e}")

    def show_deployment_summary(self) -> None:
        """Show comprehensive deployment summary"""
        self.print_colored("=== Deployment Summary ===", Colors.CYAN)
        print(f"VM Name: {self.config['vm_name']}")
        print(f"Project: {self.config['project_id']}")
        print(f"Zone: {self.get_zone()}")
        print(f"Machine Type: {self.config['machine_type']}")
        print(f"OS Choice: {self.config['os_choice']}")
        print(f"Disk Size: {self.config['disk_size']} GB")
        print(f"HTTP Server: {self.config['enable_http_server']}")
        print(f"Monitoring: {self.config['enable_monitoring']}")
        print(f"Instance State: {self.config['instance_state']}")
        print(f"Preemptible: {self.config['preemptible']}")
        print(f"Auto Restart: {self.config['auto_restart']}")
        
        # Show current status if instance exists
        status = self.get_instance_status()
        if status:
            print(f"Current Status: {status}")

    def interactive_config(self) -> None:
        """Interactive configuration setup"""
        self.print_colored("=== Interactive VM Configuration ===", Colors.CYAN)
        
        # Project ID
        current_project = self.config.get("project_id", "")
        project_id = input(f"Project ID [{current_project}]: ").strip()
        if project_id:
            self.config["project_id"] = project_id
        
        # VM Name
        current_vm = self.config.get("vm_name", "python-managed-vm")
        vm_name = input(f"VM Name [{current_vm}]: ").strip()
        if vm_name:
            self.config["vm_name"] = vm_name
        
        # Region
        print(f"Available regions: {', '.join(self.regions)}")
        current_region = self.config.get("region", "us-central1")
        region = input(f"Region [{current_region}]: ").strip()
        if region and region in self.regions:
            self.config["region"] = region
        elif region and region not in self.regions:
            self.log_warning(f"Invalid region. Using {current_region}")
        
        # Machine Type
        print(f"Available machine types: {', '.join(self.machine_types)}")
        current_machine = self.config.get("machine_type", "e2-micro")
        machine_type = input(f"Machine Type [{current_machine}]: ").strip()
        if machine_type and machine_type in self.machine_types:
            self.config["machine_type"] = machine_type
        elif machine_type and machine_type not in self.machine_types:
            self.log_warning(f"Invalid machine type. Using {current_machine}")
        
        # OS Choice
        os_choices = list(self.os_images.keys())
        print(f"Available OS: {', '.join(os_choices)}")
        current_os = self.config.get("os_choice", "ubuntu")
        os_choice = input(f"Operating System [{current_os}]: ").strip()
        if os_choice and os_choice in os_choices:
            self.config["os_choice"] = os_choice
        elif os_choice and os_choice not in os_choices:
            self.log_warning(f"Invalid OS choice. Using {current_os}")
        
        # Disk Size
        current_disk = self.config.get("disk_size", 20)
        disk_input = input(f"Disk Size GB (10-100) [{current_disk}]: ").strip()
        if disk_input:
            try:
                disk_size = int(disk_input)
                if 10 <= disk_size <= 100:
                    self.config["disk_size"] = disk_size
                else:
                    self.log_warning("Disk size must be between 10-100 GB")
            except ValueError:
                self.log_warning("Invalid disk size")
        
        # Boolean options
        current_http = self.config.get("enable_http_server", True)
        http_input = input(f"Enable HTTP Server (y/n) [{'y' if current_http else 'n'}]: ").strip().lower()
        if http_input in ['y', 'yes']:
            self.config["enable_http_server"] = True
        elif http_input in ['n', 'no']:
            self.config["enable_http_server"] = False
        
        current_monitoring = self.config.get("enable_monitoring", False)
        monitoring_input = input(f"Enable Monitoring (y/n) [{'y' if current_monitoring else 'n'}]: ").strip().lower()
        if monitoring_input in ['y', 'yes']:
            self.config["enable_monitoring"] = True
        elif monitoring_input in ['n', 'no']:
            self.config["enable_monitoring"] = False
        
        current_preemptible = self.config.get("preemptible", False)
        preemptible_input = input(f"Use Preemptible Instance (y/n) [{'y' if current_preemptible else 'n'}]: ").strip().lower()
        if preemptible_input in ['y', 'yes']:
            self.config["preemptible"] = True
        elif preemptible_input in ['n', 'no']:
            self.config["preemptible"] = False
        
        # Instance State
        states = ["RUNNING", "TERMINATED"]
        print(f"Available states: {', '.join(states)}")
        current_state = self.config.get("instance_state", "RUNNING")
        state_input = input(f"Instance State [{current_state}]: ").strip().upper()
        if state_input and state_input in states:
            self.config["instance_state"] = state_input
        
        # Save configuration
        self.save_config()
        self.log_success("Configuration saved!")
        
        # Show summary
        self.show_deployment_summary()

def main():
    """Main function with command line interface"""
    parser = argparse.ArgumentParser(
        description="Google Cloud VM Management with Choices and Verbose Logging"
    )
    parser.add_argument(
        'command',
        choices=['create', 'start', 'stop', 'restart', 'delete', 'status', 'info', 'summary', 'config'],
        help='Command to execute'
    )
    parser.add_argument(
        '--config',
        default='vm_config.json',
        help='Configuration file path (default: vm_config.json)'
    )
    parser.add_argument(
        '--interactive',
        action='store_true',
        help='Interactive configuration mode'
    )
    
    args = parser.parse_args()
    
    # Create VM manager
    vm_manager = VMManager(args.config)
    
    # Interactive configuration
    if args.interactive or args.command == 'config':
        vm_manager.interactive_config()
        return
    
    # Execute commands
    if args.command == 'create':
        success = vm_manager.create_instance()
        if success:
            vm_manager.show_deployment_summary()
            vm_manager.show_access_info()
    elif args.command == 'start':
        vm_manager.start_instance()
    elif args.command == 'stop':
        vm_manager.stop_instance()
    elif args.command == 'restart':
        vm_manager.restart_instance()
    elif args.command == 'delete':
        confirm = input("Are you sure you want to delete the instance? (yes/no): ")
        if confirm.lower() == 'yes':
            vm_manager.delete_instance()
        else:
            vm_manager.log_info("Deletion cancelled")
    elif args.command == 'status':
        vm_manager.show_status()
    elif args.command == 'info':
        vm_manager.show_access_info()
    elif args.command == 'summary':
        vm_manager.show_deployment_summary()

if __name__ == "__main__":
    main()
