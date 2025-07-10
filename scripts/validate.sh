#!/bin/bash

# Terraform Configuration Validator
# This script validates your terraform.tfvars configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    print_error "terraform.tfvars not found!"
    print_info "Copy terraform.tfvars.example to terraform.tfvars and customize it."
    exit 1
fi

print_info "=== Terraform Configuration Validation ==="

# Read and validate configuration
print_info "Reading terraform.tfvars..."

# Extract values (basic parsing)
project_id=$(grep -E '^project_id' terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "")
region=$(grep -E '^region' terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "")
machine_type=$(grep -E '^machine_type' terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "")
os_choice=$(grep -E '^os_choice' terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "")
vm_name=$(grep -E '^vm_name' terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "")

echo ""
print_info "Current Configuration:"
echo "  Project ID: ${project_id:-'NOT SET'}"
echo "  Region: ${region:-'NOT SET'}"
echo "  VM Name: ${vm_name:-'NOT SET'}"
echo "  Machine Type: ${machine_type:-'NOT SET'}"
echo "  OS Choice: ${os_choice:-'NOT SET'}"

# Validation checks
errors=0

if [ -z "$project_id" ] || [ "$project_id" = "your-gcp-project-id" ]; then
    print_error "Project ID not properly configured!"
    ((errors++))
else
    print_success "Project ID configured"
fi

# Validate region
valid_regions=("us-central1" "us-east1" "us-west1" "us-west2" "europe-west1" "europe-west2" "asia-southeast1")
if [[ " ${valid_regions[@]} " =~ " ${region} " ]]; then
    print_success "Region is valid"
else
    print_error "Invalid region: $region"
    print_info "Valid regions: ${valid_regions[*]}"
    ((errors++))
fi

# Validate machine type
valid_machine_types=("f1-micro" "e2-micro" "e2-small" "e2-medium" "n1-standard-1" "n1-standard-2" "n2-standard-2")
if [[ " ${valid_machine_types[@]} " =~ " ${machine_type} " ]]; then
    print_success "Machine type is valid"
else
    print_error "Invalid machine type: $machine_type"
    print_info "Valid machine types: ${valid_machine_types[*]}"
    ((errors++))
fi

# Validate OS choice
valid_os=("ubuntu" "debian" "centos" "rhel")
if [[ " ${valid_os[@]} " =~ " ${os_choice} " ]]; then
    print_success "OS choice is valid"
else
    print_error "Invalid OS choice: $os_choice"
    print_info "Valid OS choices: ${valid_os[*]}"
    ((errors++))
fi

echo ""
if [ $errors -eq 0 ]; then
    print_success "Configuration validation passed!"
    print_info "You can now run: ./deploy.sh deploy"
else
    print_error "Configuration validation failed with $errors error(s)!"
    print_info "Please fix the errors in terraform.tfvars before deploying."
    exit 1
fi

# Run terraform validate if no errors
print_info "Running terraform validate..."
terraform init -backend=false > /dev/null 2>&1
terraform validate

print_success "Terraform configuration is valid!"
print_info "Ready for deployment!"
