#!/bin/bash

# Comparison Demo Script - Terraform vs Python VM Management
# Shows both approaches side by side

set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
PYTHON_DIR="$PROJECT_ROOT/python"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}===================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}===================================================${NC}"
}

print_section() {
    echo -e "${PURPLE}--- $1 ---${NC}"
}

print_terraform() {
    echo -e "${BLUE}[TERRAFORM]${NC} $1"
}

print_python() {
    echo -e "${GREEN}[PYTHON]${NC} $1"
}

print_header "VM Management Solutions Comparison"

echo "This directory contains two equivalent solutions for managing GCP VMs:"
echo ""

print_section "1. TERRAFORM APPROACH"
print_terraform "Infrastructure as Code with HCL"
echo "Files:"
echo "  • terraform/main.tf - Terraform configuration"
echo "  • terraform.tfvars - Variable definitions"
echo "  • deploy.sh - Deployment script"
echo "  • manage.sh - VM lifecycle management"
echo "  • validate.sh - Configuration validation"
echo ""
echo "Usage:"
echo "  ./deploy.sh deploy    # Deploy infrastructure"
echo "  ./manage.sh start     # Start VM"
echo "  ./manage.sh stop      # Stop VM"
echo "  ./manage.sh status    # Check status"
echo ""

print_section "2. PYTHON APPROACH"
print_python "Direct API integration with Google Cloud SDK"
echo "Files:"
echo "  • python/vm_manager.py - Python VM management class"
echo "  • python_vm.sh - Convenient wrapper script"
echo "  • vm_config.json - Configuration file"
echo "  • requirements.txt - Python dependencies"
echo ""
echo "Usage:"
echo "  ./python_vm.sh setup   # Setup environment"
echo "  ./python_vm.sh config  # Interactive configuration"
echo "  ./python_vm.sh create  # Create VM"
echo "  ./python_vm.sh start   # Start VM"
echo "  ./python_vm.sh stop    # Stop VM"
echo ""

print_section "FEATURE COMPARISON"
echo ""
printf "%-25s %-20s %-20s\n" "Feature" "Terraform" "Python"
printf "%-25s %-20s %-20s\n" "-------" "---------" "------"
printf "%-25s %-20s %-20s\n" "Dependencies" "Terraform CLI" "Python + SDK"
printf "%-25s %-20s %-20s\n" "Configuration" "HCL (.tf files)" "JSON config"
printf "%-25s %-20s %-20s\n" "State Management" ".tfstate files" "JSON config"
printf "%-25s %-20s %-20s\n" "Interactive Setup" "Manual editing" "Built-in prompts"
printf "%-25s %-20s %-20s\n" "Real-time Logs" "Basic output" "Detailed logging"
printf "%-25s %-20s %-20s\n" "Learning Curve" "HCL syntax" "Python knowledge"
printf "%-25s %-20s %-20s\n" "Customization" "HCL limitations" "Full flexibility"
printf "%-25s %-20s %-20s\n" "Operation Tracking" "Plan/Apply" "Live monitoring"
echo ""

print_section "QUICK START RECOMMENDATIONS"
echo ""
echo "Choose TERRAFORM if:"
echo "  ✓ You want Infrastructure as Code (IaC)"
echo "  ✓ You need state management"
echo "  ✓ You're working with teams"
echo "  ✓ You want industry-standard tooling"
echo ""
echo "Choose PYTHON if:"
echo "  ✓ You want interactive setup"
echo "  ✓ You prefer direct API control"
echo "  ✓ You need custom integrations"
echo "  ✓ You want detailed real-time feedback"
echo ""

print_section "COST OPTIMIZATION (Both Approaches)"
echo ""
echo "1. Use preemptible instances (up to 80% savings):"
echo "   Terraform: preemptible = true"
echo "   Python: \"preemptible\": true"
echo ""
echo "2. Stop when not needed:"
echo "   Terraform: ./manage.sh stop"
echo "   Python: ./python_vm.sh stop"
echo ""
echo "3. Use minimal machine types:"
echo "   Both: f1-micro (free tier) or e2-micro"
echo ""

print_section "NEXT STEPS"
echo ""
echo "1. For Terraform approach:"
echo "   cp terraform.tfvars.example terraform.tfvars"
echo "   # Edit terraform.tfvars"
echo "   ./deploy.sh deploy"
echo ""
echo "2. For Python approach:"
echo "   ./python_vm.sh setup"
echo "   ./python_vm.sh config"
echo "   ./python_vm.sh create"
echo ""

print_header "Both solutions provide identical functionality!"
echo -e "${YELLOW}Choose the approach that best fits your workflow and preferences.${NC}"
