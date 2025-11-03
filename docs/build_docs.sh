#!/bin/bash

# Build Documentation Script
# This script builds the ESMF_IO documentation using MkDocs

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
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

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check if MkDocs is installed
    if ! command -v mkdocs &> /dev/null; then
        print_error "MkDocs is not installed. Please install it with: pip install mkdocs"
        exit 1
    fi
    
    # Check if required MkDocs plugins are installed
    python3 -c "import material" &> /dev/null || {
        print_warning "Material theme not found. Installing..."
        pip3 install mkdocs-material
    }
    
    python3 -c "import markdownextradata" &> /dev/null || {
        print_warning "Markdown Extra Data plugin not found. Installing..."
        pip3 install mkdocs-markdownextradata-plugin
    }
    
    print_success "All dependencies are satisfied."
}

# Validate documentation structure
validate_docs() {
    print_status "Validating documentation structure..."
    
    # Check if mkdocs.yml exists
    if [ ! -f "mkdocs.yml" ]; then
        print_error "mkdocs.yml not found. Please run this script from the project root directory."
        exit 1
    fi
    
    # Check if docs directory exists
    if [ ! -d "docs" ]; then
        print_error "docs directory not found. Please run this script from the project root directory."
        exit 1
    fi
    
    # Check if index.md exists
    if [ ! -f "docs/index.md" ]; then
        print_error "docs/index.md not found."
        exit 1
    fi
    
    print_success "Documentation structure is valid."
}

# Build documentation
build_docs() {
    print_status "Building documentation..."
    
    # Create site directory if it doesn't exist
    mkdir -p site
    
    # Build the documentation
    mkdocs build --clean
    
    print_success "Documentation built successfully."
}

# Serve documentation locally
serve_docs() {
    print_status "Serving documentation locally..."
    print_status "Open your browser to http://localhost:8000"
    
    # Serve the documentation
    mkdocs serve
}

# Deploy documentation to GitHub Pages
deploy_docs() {
    print_status "Deploying documentation to GitHub Pages..."
    
    # Deploy the documentation
    mkdocs gh-deploy --clean
    
    print_success "Documentation deployed to GitHub Pages."
}

# Show help
show_help() {
    echo "ESMF_IO Documentation Build Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  build     Build the documentation (default)"
    echo "  serve     Serve the documentation locally"
    echo "  deploy    Deploy the documentation to GitHub Pages"
    echo "  validate  Validate the documentation structure"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build    - Build the documentation"
    echo "  $0 serve    - Serve the documentation locally"
    echo "  $0 deploy   - Deploy the documentation to GitHub Pages"
}

# Main function
main() {
    # Check dependencies
    check_dependencies
    
    # Validate documentation structure
    validate_docs
    
    # Parse command line arguments
    case "${1:-build}" in
        build)
            build_docs
            ;;
        serve)
            serve_docs
            ;;
        deploy)
            deploy_docs
            ;;
        validate)
            validate_docs
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"