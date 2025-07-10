# Terraform Deployment Guide

## Overview
This Terraform configuration provides a flexible and verbose setup for Google Cloud Platform VM instances with multiple configuration choices.

## Features
- **Multiple OS Choices**: Ubuntu, Debian, CentOS, RHEL
- **Machine Type Options**: From f1-micro to n2-standard-2
- **Optional HTTP Server**: Apache2 for Ubuntu, Nginx for Debian
- **Instance Lifecycle Management**: Start, stop, restart VMs easily
- **Preemptible Instances**: Cost-effective spot instances
- **Auto-restart Configuration**: Automatic restart on failure
- **Verbose Logging**: Detailed outputs and startup script logging
- **Conditional Resources**: Firewall rules created only when needed
- **Cost Awareness**: Estimated cost information in outputs

## Quick Start

### 1. Set up your variables
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your preferences
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Plan with verbose output
```bash
terraform plan -var-file="terraform.tfvars"
```

### 4. Apply with detailed logging
```bash
terraform apply -var-file="terraform.tfvars" -auto-approve
```

### 5. View verbose outputs
```bash
terraform output
terraform output deployment_summary
terraform output access_information
```

## VM Instance Management

After deploying your VM, you can easily manage its lifecycle using the management script:

### Start/Stop/Restart VM
```bash
# Check VM status
./manage.sh status

# Start the VM
./manage.sh start

# Stop the VM (to save costs)
./manage.sh stop

# Restart the VM
./manage.sh restart

# Get access information
./manage.sh info

# Sync Terraform state with actual VM state
./manage.sh sync
```

### Instance State Options
- **RUNNING**: VM is active and running
- **TERMINATED**: VM is stopped (saves compute costs, keeps disk)
- **Preemptible**: Cost-effective instances that can be stopped by Google

### Cost Optimization
- Set `instance_state = "TERMINATED"` to stop the VM
- Set `preemptible = true` for up to 80% cost savings
- Use `./manage.sh stop` for temporary shutdown

## Configuration Choices

### Machine Types and Use Cases
- **f1-micro**: Free tier, minimal workloads
- **e2-micro**: Burstable, light workloads
- **e2-small**: Small web applications
- **e2-medium**: Medium workloads
- **n1-standard-1**: General purpose, 1 vCPU
- **n1-standard-2**: General purpose, 2 vCPU
- **n2-standard-2**: High performance, 2 vCPU

### Operating Systems
- **ubuntu**: Latest Ubuntu minimal (recommended)
- **debian**: Debian 12
- **centos**: CentOS Stream 9
- **rhel**: Red Hat Enterprise Linux 9

### Regions and Zones
- **us-central1**: Iowa, USA
- **us-east1**: South Carolina, USA
- **us-west1**: Oregon, USA
- **us-west2**: Los Angeles, USA
- **europe-west1**: Belgium
- **europe-west2**: London
- **asia-southeast1**: Singapore

## Verbose Outputs Explained

### deployment_summary
Shows complete deployment configuration including VM name, type, zone, OS choice, and feature flags.

### instance_details
Provides detailed GCP instance information including instance ID, self-link, CPU platform, and current status.

### network_information
Shows all network-related details including external IP, internal IP, network, and subnetwork.

### access_information
Provides ready-to-use commands for SSH access and web URLs (if HTTP server is enabled).

### firewall_rules
Details about created firewall rules and allowed ports.

### cost_estimation
Basic cost information and links to pricing calculator.

## Startup Script Logging

The startup scripts log everything to `/var/log/startup.log` on the VM. You can view logs after VM creation:

```bash
# SSH into the VM
gcloud compute ssh [VM_NAME] --zone=[ZONE] --project=[PROJECT_ID]

# View startup logs
sudo cat /var/log/startup.log

# Follow real-time logs during startup
sudo tail -f /var/log/startup.log
```

## Example Scenarios

### Minimal Cost Setup
```hcl
machine_type = "f1-micro"
disk_size = 10
enable_http_server = false
enable_monitoring = false
```

### Web Server Setup
```hcl
machine_type = "e2-small"
disk_size = 20
enable_http_server = true
enable_monitoring = true
```

### Development Environment
```hcl
machine_type = "n1-standard-1"
disk_size = 30
enable_http_server = true
enable_monitoring = true
```

## Troubleshooting

### View Terraform Logs
```bash
export TF_LOG=DEBUG
terraform plan
terraform apply
```

### Check VM Status
```bash
gcloud compute instances describe [VM_NAME] --zone=[ZONE]
```

### View VM Serial Console Output
```bash
gcloud compute instances get-serial-port-output [VM_NAME] --zone=[ZONE]
```

## Cleanup
```bash
terraform destroy -var-file="terraform.tfvars"
```
