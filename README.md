# Google Cloud VM Management Solution

A comprehensive solution for managing Google Cloud Platform VM instances with both Terraform and Python approaches, featuring lifecycle management, cost optimization, and verbose logging.

## 📁 Repository Structure

```
├── terraform/              # Terraform Infrastructure as Code
│   ├── main.tf             # Main Terraform configuration
│   ├── terraform.tfvars.example  # Example variables file
│   └── terraform.tfvars    # Your actual variables (gitignored)
├── python/                 # Python VM Management Alternative
│   ├── vm_manager.py       # Main Python VM manager script
│   ├── vm_config.json      # Python configuration file
│   └── requirements.txt    # Python dependencies
├── scripts/                # Utility Scripts
│   ├── deploy.sh          # Terraform deployment script
│   ├── manage.sh          # Terraform VM lifecycle management
│   ├── validate.sh        # Terraform validation script
│   ├── python_vm.sh       # Python wrapper script
│   └── compare.sh         # Compare both approaches
├── docs/                   # Documentation
│   ├── PYTHON_README.md   # Python approach documentation
│   └── QUICK_REFERENCE.md # Quick reference guide
├── logs/                   # Log Files (gitignored)
├── backup/                 # Backup Files
└── README.md              # This file
```

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

## 🚀 Quick Start

### Prerequisites
- Google Cloud SDK installed and configured
- Terraform installed (for Terraform approach)
- Python 3.7+ (for Python approach)
- Active GCP project with Compute Engine API enabled

### Option 1: Terraform Approach

1. **Setup Configuration:**
   ```bash
   cd terraform/
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your project details
   ```

2. **Deploy VM:**
   ```bash
   cd ../scripts/
   ./deploy.sh
   ```

3. **Manage VM:**
   ```bash
   ./manage.sh start    # Start VM
   ./manage.sh stop     # Stop VM
   ./manage.sh restart  # Restart VM
   ./manage.sh status   # Show status
   ```

### Option 2: Python Approach

1. **Setup Environment:**
   ```bash
   cd python/
   pip install -r requirements.txt
   ```

2. **Configure VM:**
   ```bash
   python vm_manager.py config  # Interactive configuration
   ```

3. **Manage VM:**
   ```bash
   python vm_manager.py create   # Create VM
   python vm_manager.py start    # Start VM
   python vm_manager.py stop     # Stop VM
   python vm_manager.py status   # Show status
   ```

### Option 3: Use Wrapper Scripts

```bash
cd scripts/
./python_vm.sh           # Python approach with dependency checks
./compare.sh            # Compare both approaches
```

## ✨ Features

### Common Features (Both Approaches)
- **Multiple OS Choices**: Ubuntu, Debian, CentOS, RHEL
- **Machine Type Selection**: From micro to standard instances
- **Region Flexibility**: Multiple GCP regions supported
- **HTTP Server Setup**: Optional Apache/Nginx installation
- **Lifecycle Management**: Start, stop, restart VM instances
- **Cost Optimization**: Preemptible instances, auto-restart options
- **Monitoring Integration**: Optional Stackdriver monitoring
- **Verbose Logging**: Comprehensive deployment and operation logs
- **State Management**: Desired instance state configuration

### Terraform Specific
- Infrastructure as Code with version control
- State management and drift detection
- Resource dependency management
- Plan before apply workflow

### Python Specific
- Interactive configuration setup
- Real-time colored output
- Direct GCP API integration
- Flexible configuration management

## 📖 Documentation

- **[Python Approach Guide](docs/PYTHON_README.md)** - Detailed Python documentation
- **[Quick Reference](docs/QUICK_REFERENCE.md)** - Command reference for both approaches

## 🔧 Configuration Options

Both approaches support the same configuration options:

| Option | Description | Values |
|--------|-------------|---------|
| `project_id` | GCP Project ID | Your GCP project |
| `region` | GCP Region | us-central1, us-east1, etc. |
| `vm_name` | VM Instance Name | Any valid name |
| `machine_type` | Machine Type | f1-micro, e2-micro, n1-standard-1, etc. |
| `os_choice` | Operating System | ubuntu, debian, centos, rhel |
| `disk_size` | Boot Disk Size (GB) | 10-100 |
| `enable_http_server` | Install HTTP Server | true/false |
| `enable_monitoring` | Enable Monitoring | true/false |
| `preemptible` | Use Preemptible Instance | true/false |
| `auto_restart` | Auto-restart on Failure | true/false |
| `instance_state` | Desired State | RUNNING/TERMINATED |

## 🔐 Authentication

### Option 1: Application Default Credentials (Recommended)
```bash
gcloud auth application-default login
```

### Option 2: Service Account Key
```bash
export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account-key.json"
```

## 📊 Monitoring and Logs

- **Terraform logs**: Available in `logs/` directory
- **Python logs**: Real-time colored output + file logging
- **VM startup logs**: Available in `/var/log/startup.log` on the VM
- **Access logs**: HTTP server logs (if enabled)

## 🛠️ Troubleshooting

### Common Issues

1. **Authentication Error**
   ```bash
   gcloud auth application-default login
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **API Not Enabled**
   ```bash
   gcloud services enable compute.googleapis.com
   ```

3. **Permission Denied**
   - Ensure your account has Compute Engine Admin role
   - Check project-level IAM permissions

4. **Large Files in Git**
   - The `.gitignore` file excludes large Terraform providers
   - Log files are also excluded from version control

## 🤝 Contributing

1. Follow the existing directory structure
2. Update documentation for any new features
3. Test both Terraform and Python approaches
4. Ensure sensitive files are properly gitignored

## 📜 License

This project is open source and available under the MIT License.

---

**Choose your preferred approach and start managing GCP VMs with ease!** 🚀

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
