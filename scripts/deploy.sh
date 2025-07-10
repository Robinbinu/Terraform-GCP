#!/bin/bash

# Terraform Deployment Script with Verbose Logging
# This script provides an interactive way to deploy with choices and detailed logging

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
LOGS_DIR="$PROJECT_ROOT/logs"

# Ensure logs directory exists
mkdir -p "$LOGS_DIR"

# Function to print colored output
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

# Function to prompt for user choices
prompt_choices() {
    print_info "=== Terraform Deployment Configuration ==="
    
    # Change to terraform directory
    cd "$TERRAFORM_DIR"
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_info "Please edit terraform.tfvars with your configuration before continuing."
        print_info "Configuration file location: $TERRAFORM_DIR/terraform.tfvars"
        read -p "Press Enter after editing terraform.tfvars..."
    fi
    
    # Ask for deployment confirmation
    echo ""
    print_info "Current configuration will be read from $TERRAFORM_DIR/terraform.tfvars"
    print_info "Available machine types: f1-micro, e2-micro, e2-small, e2-medium, n1-standard-1, n1-standard-2, n2-standard-2"
    print_info "Available OS choices: ubuntu, debian, centos, rhel"
    print_info "Available regions: us-central1, us-east1, us-west1, us-west2, europe-west1, europe-west2, asia-southeast1"
    print_info "Instance states: RUNNING, TERMINATED"
    print_info "Lifecycle options: auto_start, auto_restart, preemptible"
    
    echo ""
    read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled."
        exit 0
    fi
}

# Function to run terraform with verbose logging
run_terraform() {
    local command=$1
    local description=$2
    local log_file="$LOGS_DIR/deployment.log"
    
    print_info "=== $description ==="
    
    # Change to terraform directory
    cd "$TERRAFORM_DIR"
    
    # Enable Terraform verbose logging
    export TF_LOG=INFO
    export TF_LOG_PATH="$LOGS_DIR/terraform-$(date +%Y%m%d-%H%M%S).log"
    
    print_info "Terraform logs will be saved to: $TF_LOG_PATH"
    
    case $command in
        "init")
            print_info "Initializing Terraform..."
            terraform init -no-color | tee -a "$log_file"
            ;;
        "plan")
            print_info "Creating Terraform plan..."
            terraform plan -var-file="terraform.tfvars" -no-color -out=tfplan | tee -a "$log_file"
            ;;
        "apply")
            print_info "Applying Terraform configuration..."
            terraform apply -no-color tfplan | tee -a "$log_file"
            ;;
        "output")
            print_info "Displaying Terraform outputs..."
            terraform output -no-color | tee -a "$log_file"
            ;;
        "destroy")
            print_info "Destroying Terraform resources..."
            terraform destroy -var-file="terraform.tfvars" -no-color | tee -a "$log_file"
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        print_success "$description completed successfully!"
    else
        print_error "$description failed! Check logs for details."
        exit 1
    fi
}

# Function to display verbose outputs
show_verbose_outputs() {
    print_info "=== Deployment Summary ==="
    terraform output deployment_summary
    
    echo ""
    print_info "=== Instance Details ==="
    terraform output instance_details
    
    echo ""
    print_info "=== Network Information ==="
    terraform output network_information
    
    echo ""
    print_info "=== Access Information ==="
    terraform output access_information
    
    echo ""
    print_info "=== Firewall Rules ==="
    terraform output firewall_rules
    
    echo ""
    print_info "=== Cost Estimation ==="
    terraform output cost_estimation
}

# Function to show help
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  deploy    - Full deployment with choices and verbose logging"
    echo "  plan      - Show deployment plan"
    echo "  apply     - Apply the plan"
    echo "  outputs   - Show verbose outputs"
    echo "  destroy   - Destroy all resources"
    echo "  logs      - Show recent deployment logs"
    echo "  help      - Show this help message"
    echo ""
    echo "VM Management (use manage.sh):"
    echo "  ./manage.sh start    - Start the VM instance"
    echo "  ./manage.sh stop     - Stop the VM instance"
    echo "  ./manage.sh restart  - Restart the VM instance"
    echo "  ./manage.sh status   - Check VM status"
    echo ""
    echo "Examples:"
    echo "  $0 deploy    # Interactive deployment"
    echo "  $0 plan      # Show what will be created"
    echo "  $0 outputs   # Show detailed information about created resources"
}

# Function to show recent logs
show_logs() {
    print_info "=== Recent Deployment Logs ==="
    if [ -f "deployment.log" ]; then
        tail -50 deployment.log
    else
        print_warning "No deployment logs found."
    fi
    
    print_info "=== Recent Terraform Logs ==="
    latest_tf_log=$(ls -t terraform-*.log 2>/dev/null | head -1)
    if [ -n "$latest_tf_log" ]; then
        print_info "Showing last 30 lines of $latest_tf_log"
        tail -30 "$latest_tf_log"
    else
        print_warning "No Terraform logs found."
    fi
}

# Main script logic
case "${1:-help}" in
    "deploy")
        print_info "Starting interactive Terraform deployment..."
        prompt_choices
        run_terraform "init" "Terraform Initialization"
        run_terraform "plan" "Terraform Planning"
        run_terraform "apply" "Terraform Application"
        show_verbose_outputs
        print_success "Deployment completed! Check the outputs above for access information."
        print_info "Use './manage.sh start|stop|restart|status' to manage the VM instance."
        ;;
    "plan")
        run_terraform "init" "Terraform Initialization"
        run_terraform "plan" "Terraform Planning"
        ;;
    "apply")
        run_terraform "apply" "Terraform Application"
        show_verbose_outputs
        ;;
    "outputs")
        show_verbose_outputs
        ;;
    "destroy")
        print_warning "This will destroy all resources!"
        read -p "Are you sure? Type 'yes' to confirm: " confirm
        if [ "$confirm" = "yes" ]; then
            run_terraform "destroy" "Terraform Destruction"
        else
            print_info "Destruction cancelled."
        fi
        ;;
    "logs")
        show_logs
        ;;
    "help"|*)
        show_help
        ;;
esac
