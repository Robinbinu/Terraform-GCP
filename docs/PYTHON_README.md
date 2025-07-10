# Python VM Manager - Alternative to Terraform

## Overview
This Python-based VM management solution provides the same functionality as the Terraform configuration, using the Google Cloud Python SDK. It offers choices, verbose logging, and easy start/stop functionality without requiring Terraform.

## 🐍 **Features**

- **Direct Google Cloud API Integration**: No Terraform dependency
- **Interactive Configuration**: Easy setup with guided prompts
- **Verbose Logging**: Detailed logs saved to timestamped files
- **Instance Lifecycle Management**: Create, start, stop, restart, delete
- **Multiple OS Choices**: Ubuntu, Debian, CentOS, RHEL
- **Machine Type Options**: From f1-micro to n2-standard-2
- **Cost Optimization**: Preemptible instances and lifecycle management
- **Auto HTTP Server Setup**: Apache2/Nginx with custom pages
- **Firewall Management**: Automatic HTTP/HTTPS rule creation
- **Real-time Status Monitoring**: Live operation progress tracking

## 🚀 **Quick Start**

### 1. Setup Environment
```bash
# Setup dependencies and authentication
./python_vm.sh setup
```

### 2. Configure VM
```bash
# Interactive configuration
./python_vm.sh config

# Or edit vm_config.json directly
```

### 3. Create and Manage VM
```bash
# Create VM instance
./python_vm.sh create

# Start/stop VM
./python_vm.sh start
./python_vm.sh stop

# Check status
./python_vm.sh status

# Get access info
./python_vm.sh info
```

## 📁 **Files**

- **`vm_manager.py`** - Main Python VM management class
- **`python_vm.sh`** - Convenient wrapper script
- **`vm_config.json`** - Configuration file (JSON format)
- **`requirements.txt`** - Python dependencies

## ⚙️ **Configuration Options**

### Basic Settings
```json
{
  "project_id": "your-gcp-project",
  "region": "us-central1",
  "vm_name": "python-managed-vm",
  "machine_type": "e2-micro"
}
```

### OS and Storage
```json
{
  "os_choice": "ubuntu",
  "disk_size": 20
}
```

### Features
```json
{
  "enable_http_server": true,
  "enable_monitoring": false,
  "preemptible": false,
  "auto_restart": true
}
```

### Lifecycle
```json
{
  "instance_state": "RUNNING",
  "auto_start": true
}
```

## 🎛️ **Commands**

### Management Commands
```bash
./python_vm.sh create      # Create new VM
./python_vm.sh start       # Start VM
./python_vm.sh stop        # Stop VM
./python_vm.sh restart     # Restart VM
./python_vm.sh delete      # Delete VM
```

### Information Commands
```bash
./python_vm.sh status      # Show VM status
./python_vm.sh info        # Show access information
./python_vm.sh summary     # Show deployment summary
```

### Setup Commands
```bash
./python_vm.sh setup       # Setup environment
./python_vm.sh config      # Interactive configuration
```

## 🔧 **Direct Python Usage**

### Command Line Interface
```bash
# Direct Python execution
python3 vm_manager.py create
python3 vm_manager.py start
python3 vm_manager.py stop --config custom_config.json
python3 vm_manager.py config --interactive
```

### Python API Usage
```python
from vm_manager import VMManager

# Create manager instance
vm = VMManager('vm_config.json')

# Create and manage VM
vm.create_instance()
vm.start_instance()
vm.show_status()
vm.stop_instance()
```

## 💡 **Configuration Examples**

### Minimal Cost Setup
```json
{
  "machine_type": "f1-micro",
  "disk_size": 10,
  "enable_http_server": false,
  "enable_monitoring": false,
  "preemptible": true,
  "instance_state": "RUNNING"
}
```

### Web Development Server
```json
{
  "machine_type": "e2-small",
  "disk_size": 20,
  "enable_http_server": true,
  "enable_monitoring": true,
  "preemptible": false,
  "instance_state": "RUNNING"
}
```

### Cost-Conscious Spot Instance
```json
{
  "machine_type": "e2-medium",
  "disk_size": 30,
  "enable_http_server": true,
  "preemptible": true,
  "auto_restart": true,
  "instance_state": "RUNNING"
}
```

### Development Environment (Start Stopped)
```json
{
  "machine_type": "n1-standard-1",
  "disk_size": 30,
  "enable_http_server": true,
  "instance_state": "TERMINATED",
  "auto_start": false
}
```

## 📊 **Verbose Logging**

The Python script provides extensive logging:

### Log Files
- **Console Output**: Real-time colored status messages
- **Log Files**: Timestamped logs (`vm_management_YYYYMMDD_HHMMSS.log`)
- **Operation Tracking**: Detailed GCP API operation monitoring

### Log Levels
- **INFO**: General information and progress
- **SUCCESS**: Successful operations
- **WARNING**: Non-fatal issues
- **ERROR**: Failed operations with details

### Sample Log Output
```
[INFO] === Creating VM Instance: python-managed-vm ===
[INFO] Project: intellicash-465015
[INFO] Zone: us-central1-a
[INFO] Machine Type: e2-micro
[INFO] OS: ubuntu
[INFO] Disk Size: 20 GB
[SUCCESS] Firewall rule created
[INFO] Submitting instance creation request...
[INFO] Waiting for instance creation to complete...
[SUCCESS] Instance creation completed successfully
[SUCCESS] VM instance python-managed-vm created successfully!
```

## 🆚 **Python vs Terraform Comparison**

| Feature | Python Script | Terraform |
|---------|---------------|-----------|
| **Dependencies** | Python + Google Cloud SDK | Terraform + Provider |
| **State Management** | JSON config file | .tfstate files |
| **Learning Curve** | Python knowledge | HCL syntax |
| **API Integration** | Direct Google Cloud API | Provider abstraction |
| **Customization** | Full Python flexibility | HCL limitations |
| **Verbose Logging** | Built-in detailed logging | Basic output |
| **Interactive Setup** | Built-in prompts | Manual file editing |
| **Real-time Monitoring** | Live operation tracking | Plan/apply separation |

## 🔐 **Authentication**

### Setup Google Cloud Authentication
```bash
# Install Google Cloud SDK
# https://cloud.google.com/sdk/docs/install

# Authenticate
gcloud auth application-default login

# Set project (optional)
gcloud config set project YOUR_PROJECT_ID
```

### Service Account (Production)
```bash
# Create service account
gcloud iam service-accounts create vm-manager

# Grant permissions
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:vm-manager@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

# Download key
gcloud iam service-accounts keys create key.json \
  --iam-account=vm-manager@PROJECT_ID.iam.gserviceaccount.com

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="key.json"
```

## 🚨 **Troubleshooting**

### Common Issues

1. **Authentication Error**
   ```bash
   ./python_vm.sh setup  # Re-run setup
   gcloud auth application-default login
   ```

2. **Missing Dependencies**
   ```bash
   pip3 install -r requirements.txt
   ```

3. **Project Not Set**
   ```bash
   ./python_vm.sh config  # Set project_id
   ```

4. **Permission Denied**
   ```bash
   # Check IAM permissions
   gcloud projects get-iam-policy PROJECT_ID
   ```

### Debug Mode
```bash
# Enable detailed logging
export GOOGLE_CLOUD_DISABLE_GRPC=true
python3 vm_manager.py create
```

## 🎯 **Advantages of Python Approach**

1. **No Terraform Dependency**: Direct Google Cloud integration
2. **Interactive Configuration**: User-friendly setup process
3. **Real-time Feedback**: Live operation progress and status
4. **Flexible Customization**: Full Python programming capabilities
5. **Detailed Logging**: Comprehensive verbose output
6. **Error Handling**: Robust exception handling and recovery
7. **Cross-platform**: Works on any system with Python
8. **Extensible**: Easy to add new features and integrations

This Python solution provides all the functionality of the Terraform version while offering greater flexibility and user-friendliness!
