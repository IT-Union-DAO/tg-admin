#!/bin/bash

# Validate GitHub Workflows Syntax
# This script checks workflow files for syntax errors

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

# Check if yamllint is available
check_yamllint() {
    if ! command -v yamllint &> /dev/null; then
        print_warning "yamllint is not installed. Installing..."
        if command -v pip3 &> /dev/null; then
            pip3 install yamllint
        elif command -v pip &> /dev/null; then
            pip install yamllint
        else
            print_error "pip not available. Please install yamllint manually:"
            echo "  pip install yamllint"
            return 1
        fi
    fi
    print_success "yamllint is available"
}

# Validate workflow files
validate_workflows() {
    local errors=0
    
    print_info "Validating workflow files..."
    
    for workflow in .github/workflows/*.yml; do
        if [ -f "$workflow" ]; then
            print_info "Checking $workflow"
            
            # Basic YAML syntax check
            if python3 -c "import yaml; yaml.safe_load(open('$workflow'))" 2>/dev/null; then
                print_success "✓ $workflow - YAML syntax is valid"
            else
                print_error "✗ $workflow - YAML syntax error"
                errors=$((errors + 1))
            fi
            
            # Check for common issues
            if grep -q "\${{ secrets\." "$workflow"; then
                print_warning "⚠ $workflow - Contains secret references (will need .env file for act)"
            fi
            
            if grep -q "\${{ github\.event\." "$workflow"; then
                print_info "ℹ $workflow - Contains GitHub event references"
            fi
        fi
    done
    
    return $errors
}

# Check environment file
check_env_file() {
    if [ -f ".env" ]; then
        print_success "✓ .env file exists"
        
        # Check for required variables
        local required_vars=("TELEGRAM_BOT_TOKEN" "GITHUB_TOKEN")
        local missing_vars=()
        
        for var in "${required_vars[@]}"; do
            if ! grep -q "^$var=" .env 2>/dev/null; then
                missing_vars+=("$var")
            fi
        done
        
        if [ ${#missing_vars[@]} -eq 0 ]; then
            print_success "✓ All required variables found in .env"
        else
            print_warning "⚠ Missing variables in .env: ${missing_vars[*]}"
        fi
    else
        print_warning "⚠ .env file not found"
        if [ -f ".env.example" ]; then
            print_info "You can copy .env.example to .env and fill in your values"
        fi
    fi
}

# Check act configuration
check_act_config() {
    if [ -f ".actrc" ]; then
        print_success "✓ .actrc configuration file exists"
    else
        print_warning "⚠ .actrc file not found"
    fi
    
    if [ -f ".github/workflows/deploy-inputs.json" ]; then
        print_success "✓ deploy-inputs.json exists for testing"
    fi
}

# Main function
main() {
    print_info "GitHub Workflows Validation"
    echo "================================"
    
    # Check tools
    check_yamllint
    
    # Validate workflows
    if validate_workflows; then
        print_success "All workflow files passed validation!"
    else
        print_error "Some workflow files have issues"
    fi
    
    echo
    print_info "Environment Setup Check"
    echo "============================"
    
    check_env_file
    check_act_config
    
    echo
    print_info "Next Steps:"
    echo "1. Install act: curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash"
    echo "2. Copy .env.example to .env and fill in your values"
    echo "3. Run: ./scripts/test-workflows.sh list"
    echo "4. Test workflows: ./scripts/test-workflows.sh build"
    echo "5. Note: Use --bind flag with act to avoid certbot permission issues"
}

# Run main function
main "$@"