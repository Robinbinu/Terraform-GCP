# Quick Reference: VM Management Options

## 🚀 **Deployment Commands**
```bash
# Initial setup
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your choices

# Deploy infrastructure
./deploy.sh deploy

# Validate configuration
./validate.sh
```

## 🎛️ **VM Management Commands**
```bash
# Check VM status
./manage.sh status

# Start VM (if stopped)
./manage.sh start

# Stop VM (to save costs)
./manage.sh stop

# Restart VM
./manage.sh restart

# Get SSH and web access info
./manage.sh info

# Sync Terraform state
./manage.sh sync
```

## ⚙️ **Configuration Choices**

### Instance States
- `instance_state = "RUNNING"` - VM is active
- `instance_state = "TERMINATED"` - VM is stopped (saves costs)

### Machine Types (Performance & Cost)
- `f1-micro` - Free tier, minimal workloads
- `e2-micro` - Burstable, light workloads  
- `e2-small` - Small web applications
- `e2-medium` - Medium workloads
- `n1-standard-1` - General purpose, 1 vCPU
- `n2-standard-2` - High performance, 2 vCPU

### Operating Systems
- `ubuntu` - Ubuntu minimal (recommended)
- `debian` - Debian 12
- `centos` - CentOS Stream 9
- `rhel` - Red Hat Enterprise Linux 9

### Cost Optimization
- `preemptible = true` - Up to 80% cost savings (can be stopped)
- `preemptible = false` - Standard instance (more reliable)
- `auto_restart = true` - Auto-restart on failure
- `auto_restart = false` - Manual restart required

### Features
- `enable_http_server = true` - Install Apache2/Nginx web server
- `enable_monitoring = true` - Enable Cloud Monitoring
- `disk_size = 20` - Boot disk size in GB (10-100)

## 💡 **Common Scenarios**

### Minimal Cost Setup
```hcl
machine_type = "f1-micro"
disk_size = 10
enable_http_server = false
preemptible = true
instance_state = "RUNNING"
```

### Web Development
```hcl
machine_type = "e2-small"
disk_size = 20
enable_http_server = true
enable_monitoring = true
preemptible = false
instance_state = "RUNNING"
```

### Cost-Conscious Web Server
```hcl
machine_type = "e2-micro"
disk_size = 15
enable_http_server = true
preemptible = true
auto_restart = true
instance_state = "RUNNING"
```

### Temporary Development (Stop when not needed)
```hcl
machine_type = "n1-standard-1"
disk_size = 30
enable_http_server = true
instance_state = "TERMINATED"  # Start with VM stopped
auto_start = false
```

## 🔧 **Quick Actions**

### Start Working
```bash
./manage.sh start    # Start VM
./manage.sh info     # Get access details
# SSH: gcloud compute ssh [vm-name] --zone=[zone] --project=[project]
```

### Save Costs
```bash
./manage.sh stop     # Stop VM when not needed
# Or set instance_state = "TERMINATED" in terraform.tfvars
```

### Monitor & Debug
```bash
./deploy.sh outputs  # View all outputs
./deploy.sh logs     # View deployment logs
./manage.sh status   # Check VM status
```

### Emergency Recovery
```bash
./manage.sh restart  # Hard restart VM
./manage.sh sync     # Sync Terraform state
```

## 📊 **Outputs & Information**

The deployment provides detailed information:
- **deployment_summary** - Complete configuration details
- **instance_details** - VM specifications and status
- **network_information** - IP addresses and network config
- **access_information** - SSH commands and web URLs
- **firewall_rules** - Security configuration
- **cost_estimation** - Cost information and calculator links
