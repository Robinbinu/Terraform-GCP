#!/bin/bash

# Python VM Manager Wrapper Script
# Convenient interface for the Python-based VM management

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
PYTHON_DIR="$PROJECT_ROOT/python"
LOGS_DIR="$PROJECT_ROOT/logs"

# File paths
VM_SCRIPT="$PYTHON_DIR/vm_manager.py"
CONFIG_FILE="$PYTHON_DIR/vm_config.json"
REQUIREMENTS_FILE="$PYTHON_DIR/requirements.txt"

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

# Check if Python is available
check_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed"
        exit 1
    fi
}

# Check if required packages are installed
check_dependencies() {
    print_info "Checking Python dependencies..."
    
    if ! python3 -c "import google.cloud.compute_v1" 2>/dev/null; then
        print_warning "Google Cloud SDK not installed. Installing..."
        pip3 install -r requirements.txt
        
        if [ $? -eq 0 ]; then
            print_success "Dependencies installed successfully"
        else
            print_error "Failed to install dependencies"
            print_info "Try: pip3 install -r requirements.txt"
            exit 1
        fi
    else
        print_success "Dependencies are installed"
    fi
}

# Check authentication
check_auth() {
    print_info "Checking Google Cloud authentication..."
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1 > /dev/null 2>&1; then
        print_error "Not authenticated with Google Cloud"
        print_info "Please run: gcloud auth application-default login"
        exit 1
    else
        print_success "Google Cloud authentication verified"
    fi
}

# Show help
show_help() {
    echo "Python VM Manager - Alternative to Terraform"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  config      - Interactive configuration setup"
    echo "  create      - Create new VM instance"
    echo "  start       - Start VM instance"
    echo "  stop        - Stop VM instance"
    echo "  restart     - Restart VM instance"
    echo "  delete      - Delete VM instance"
    echo "  status      - Show VM status"
    echo "  info        - Show access information"
    echo "  summary     - Show deployment summary"
    echo "  setup       - Setup dependencies and authentication"
    echo "  help        - Show this help message"
    echo ""
    echo "Options:"
    echo "  --interactive  - Use interactive mode"
    echo "  --config FILE  - Use specific config file"
    echo ""
    echo "Examples:"
    echo "  $0 setup           # Setup dependencies"
    echo "  $0 config          # Configure VM settings"
    echo "  $0 create          # Create VM with current config"
    echo "  $0 start           # Start the VM"
    echo "  $0 stop            # Stop the VM"
    echo "  $0 status          # Check VM status"
    echo ""
    echo "Configuration:"
    echo "  Edit vm_config.json or use '$0 config' for interactive setup"
}

# Setup dependencies and authentication
setup_environment() {
    print_info "=== Setting up Python VM Manager ==="
    
    check_python
    check_dependencies
    check_auth
    
    print_success "Setup complete! You can now use the VM manager."
    print_info "Next steps:"
    print_info "1. Configure your VM: $0 config"
    print_info "2. Create your VM: $0 create"
}

# Main script logic
case "${1:-help}" in
    "setup")
        setup_environment
        ;;
    "config")
        check_python
        check_dependencies
        cd "$PYTHON_DIR"
        python3 "$VM_SCRIPT" config --interactive
        ;;
    "create")
        check_python
        check_dependencies
        check_auth
        cd "$PYTHON_DIR"
        python3 "$VM_SCRIPT" create
        ;;
    "start")
        check_python
        check_dependencies
        check_auth
        cd "$PYTHON_DIR"
        python3 "$VM_SCRIPT" start
        ;;
    "stop")
        check_python
        check_dependencies
        check_auth
        cd "$PYTHON_DIR"
        python3 "$VM_SCRIPT" stop
        ;;
    "restart")
        check_python
        check_dependencies
        check_auth
        cd "$PYTHON_DIR"
        python3 "$VM_SCRIPT" restart
        ;;
    "delete")
        check_python
        check_dependencies
        check_auth
        cd "$PYTHON_DIR"
        python3 "$VM_SCRIPT" delete
        ;;
    "status")
        check_python
        check_dependencies
        check_auth
        cd "$PYTHON_DIR"
        python3 "$VM_SCRIPT" status
        ;;
    "info")
        check_python
        check_dependencies
        check_auth
        cd "$PYTHON_DIR"
        python3 "$VM_SCRIPT" info
        ;;
    "summary")
        check_python
        check_dependencies
        check_auth
        cd "$PYTHON_DIR"
        python3 "$VM_SCRIPT" summary
        ;;
    "help"|*)
        show_help
        ;;
esac
