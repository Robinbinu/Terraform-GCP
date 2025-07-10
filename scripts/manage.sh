#!/bin/bash

# VM Instance Management Script
# This script provides easy start/stop/restart functionality for your Terraform-managed VM

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
LOGS_DIR="$PROJECT_ROOT/logs"

# Ensure logs directory exists
mkdir -p "$LOGS_DIR"

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Read configuration from terraform.tfvars
get_config_value() {
    local key=$1
    local default_value=$2
    if [ -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
        grep -E "^${key}" "$TERRAFORM_DIR/terraform.tfvars" | cut -d'"' -f2 2>/dev/null || echo "$default_value"
    else
        echo "$default_value"
    fi
}

# Get VM details
get_vm_info() {
    if [ ! -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
        print_error "Terraform state file not found. Please deploy first with './deploy.sh deploy'"
        exit 1
    fi
    
    VM_NAME=$(get_config_value "vm_name" "hello-world-vm")
    PROJECT_ID=$(get_config_value "project_id" "")
    REGION=$(get_config_value "region" "us-central1")
    ZONE="${REGION}-a"
    
    if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "your-gcp-project-id" ]; then
        print_error "Project ID not configured in terraform.tfvars"
        exit 1
    fi
    
    print_info "VM Configuration:"
    echo "  VM Name: $VM_NAME"
    echo "  Project: $PROJECT_ID"
    echo "  Zone: $ZONE"
}

# Check current VM status
check_vm_status() {
    get_vm_info
    print_info "Checking VM status..."
    
    STATUS=$(gcloud compute instances describe "$VM_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --format="value(status)" 2>/dev/null || echo "NOT_FOUND")
    
    case $STATUS in
        "RUNNING")
            print_success "VM is currently RUNNING"
            ;;
        "TERMINATED"|"STOPPED")
            print_warning "VM is currently STOPPED"
            ;;
        "STOPPING")
            print_warning "VM is currently STOPPING"
            ;;
        "STARTING")
            print_info "VM is currently STARTING"
            ;;
        "NOT_FOUND")
            print_error "VM not found. Please deploy first with './deploy.sh deploy'"
            exit 1
            ;;
        *)
            print_info "VM status: $STATUS"
            ;;
    esac
    
    echo "Current status: $STATUS"
    return 0
}

# Start VM instance
start_vm() {
    get_vm_info
    print_info "Starting VM instance..."
    
    # Check if already running
    STATUS=$(gcloud compute instances describe "$VM_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --format="value(status)" 2>/dev/null || echo "NOT_FOUND")
    
    if [ "$STATUS" = "RUNNING" ]; then
        print_warning "VM is already running"
        return 0
    fi
    
    if [ "$STATUS" = "NOT_FOUND" ]; then
        print_error "VM not found. Deploy first with './deploy.sh deploy'"
        exit 1
    fi
    
    # Start the instance
    gcloud compute instances start "$VM_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID"
    
    if [ $? -eq 0 ]; then
        print_success "VM started successfully!"
        
        # Update Terraform state to reflect the change
        print_info "Updating Terraform configuration..."
        sed -i.bak 's/instance_state.*=.*"TERMINATED"/instance_state = "RUNNING"/' "$TERRAFORM_DIR/terraform.tfvars" 2>/dev/null || true
        
        # Show access information
        sleep 5  # Wait for instance to fully start
        show_access_info
    else
        print_error "Failed to start VM"
        exit 1
    fi
}

# Stop VM instance
stop_vm() {
    get_vm_info
    print_info "Stopping VM instance..."
    
    # Check if already stopped
    STATUS=$(gcloud compute instances describe "$VM_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --format="value(status)" 2>/dev/null || echo "NOT_FOUND")
    
    if [ "$STATUS" = "TERMINATED" ] || [ "$STATUS" = "STOPPED" ]; then
        print_warning "VM is already stopped"
        return 0
    fi
    
    if [ "$STATUS" = "NOT_FOUND" ]; then
        print_error "VM not found. Deploy first with './deploy.sh deploy'"
        exit 1
    fi
    
    # Stop the instance
    gcloud compute instances stop "$VM_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID"
    
    if [ $? -eq 0 ]; then
        print_success "VM stopped successfully!"
        
        # Update Terraform state to reflect the change
        print_info "Updating Terraform configuration..."
        sed -i.bak 's/instance_state.*=.*"RUNNING"/instance_state = "TERMINATED"/' "$TERRAFORM_DIR/terraform.tfvars" 2>/dev/null || true
    else
        print_error "Failed to stop VM"
        exit 1
    fi
}

# Restart VM instance
restart_vm() {
    get_vm_info
    print_info "Restarting VM instance..."
    
    STATUS=$(gcloud compute instances describe "$VM_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --format="value(status)" 2>/dev/null || echo "NOT_FOUND")
    
    if [ "$STATUS" = "NOT_FOUND" ]; then
        print_error "VM not found. Deploy first with './deploy.sh deploy'"
        exit 1
    fi
    
    # Reset the instance
    gcloud compute instances reset "$VM_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID"
    
    if [ $? -eq 0 ]; then
        print_success "VM restarted successfully!"
        sleep 5
        show_access_info
    else
        print_error "Failed to restart VM"
        exit 1
    fi
}

# Show access information
show_access_info() {
    get_vm_info
    
    # Get external IP
    EXTERNAL_IP=$(gcloud compute instances describe "$VM_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" \
        --format="value(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "")
    
    print_info "=== Access Information ==="
    echo "SSH Command:"
    echo "  gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_ID"
    
    if [ -n "$EXTERNAL_IP" ]; then
        echo "External IP: $EXTERNAL_IP"
        
        # Check if HTTP server is enabled
        HTTP_ENABLED=$(get_config_value "enable_http_server" "true")
        if [ "$HTTP_ENABLED" = "true" ]; then
            echo "Web URL: http://$EXTERNAL_IP"
        fi
    fi
}

# Apply Terraform changes to sync state
sync_terraform() {
    print_info "Syncing Terraform state with actual VM state..."
    
    cd "$TERRAFORM_DIR"
    
    # Run terraform plan to see changes
    terraform plan -var-file="terraform.tfvars" -out=tfplan
    
    # Ask for confirmation
    echo ""
    read -p "Apply these changes to sync Terraform state? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply tfplan
        print_success "Terraform state synchronized!"
    else
        print_info "Sync cancelled."
        rm -f tfplan
    fi
}

# Show help
show_help() {
    echo "VM Instance Management Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start     - Start the VM instance"
    echo "  stop      - Stop the VM instance"
    echo "  restart   - Restart the VM instance"
    echo "  status    - Check current VM status"
    echo "  info      - Show VM access information"
    echo "  sync      - Sync Terraform state with actual VM state"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start     # Start the VM"
    echo "  $0 stop      # Stop the VM"
    echo "  $0 restart   # Restart the VM"
    echo "  $0 status    # Check if VM is running"
}

# Main script logic
case "${1:-help}" in
    "start")
        start_vm
        ;;
    "stop")
        stop_vm
        ;;
    "restart")
        restart_vm
        ;;
    "status")
        check_vm_status
        ;;
    "info")
        show_access_info
        ;;
    "sync")
        sync_terraform
        ;;
    "help"|*)
        show_help
        ;;
esac
