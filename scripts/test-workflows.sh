#!/bin/bash

# Test GitHub Workflows Locally with act
# This script helps test workflows using nektos/act

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if act is installed
check_act() {
    if ! command -v act &> /dev/null; then
        print_error "act is not installed. Please install it first:"
        echo "  macOS: brew install act"
        echo "  Linux: curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash"
        echo "  Windows: choco install act"
        exit 1
    fi
    print_success "act is installed: $(act --version)"
}

# Check if .env file exists
check_env() {
    if [ ! -f ".env" ]; then
        print_warning ".env file not found"
        if [ -f ".env.example" ]; then
            print_info "Copying .env.example to .env"
            cp .env.example .env
            print_warning "Please edit .env file with your actual values before running workflows"
        else
            print_error ".env.example not found"
            exit 1
        fi
    else
        print_success ".env file found"
    fi
}

# List available workflows
list_workflows() {
    print_info "Available workflows:"
    act -l
}

# Test specific workflow
test_workflow() {
    local workflow=$1
    local event=${2:-push}
    
    if [ ! -f ".github/workflows/$workflow" ]; then
        print_error "Workflow file not found: .github/workflows/$workflow"
        return 1
    fi
    
    print_info "Testing workflow: $workflow with event: $event"
    print_info "Using --bind flag to avoid permission issues with certbot directory"
    act --bind $event -W .github/workflows/$workflow
}

# Test all workflows
test_all() {
    print_info "Testing all workflows with push event"
    print_info "Using --bind flag to avoid permission issues with certbot directory"
    act --bind push
}

# Dry run
dry_run() {
    print_info "Dry run - showing what would happen"
    print_info "Using --bind flag to avoid permission issues with certbot directory"
    act --bind --dryrun
}

# Main function
main() {
    local command=${1:-help}
    
    case $command in
        "check")
            check_act
            check_env
            ;;
        "list")
            check_act
            list_workflows
            ;;
        "build")
            check_act
            test_workflow "build-and-publish.yml" "push"
            ;;
        "deploy")
            check_act
            test_workflow "deploy-to-vm.yml" "workflow_dispatch"
            ;;
        "test")
            check_act
            test_workflow "test-workflows.yml" "push"
            ;;
        "all")
            check_act
            test_all
            ;;
        "dryrun")
            check_act
            dry_run
            ;;
        "help"|"*")
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  check    - Check if act is installed and .env file exists"
            echo "  list     - List available workflows"
            echo "  build    - Test build and publish workflow"
            echo "  deploy   - Test deploy to VM workflow"
            echo "  test     - Test workflow validation"
            echo "  all      - Test all workflows"
            echo "  dryrun   - Dry run to see what would happen"
            echo "  help     - Show this help message"
            ;;
    esac
}

# Run main function
main "$@"