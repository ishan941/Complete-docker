#!/bin/bash

# =============================================================================
# DOCKER BUILD AND TEST SCRIPT
# =============================================================================
# This script helps you test the optimized Docker setup locally
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show image sizes
show_image_sizes() {
    echo ""
    log_info "Docker Image Sizes:"
    echo "===================="
    docker images | grep "react-app" | awk '{print $1":"$2" - "$7$8}' || echo "No react-app images found"
    echo ""
    log_info "Docker System Usage:"
    docker system df
    echo ""
}

# Build production image
build_production() {
    log_info "Building production image..."
    docker build --target production -t react-app-prod:latest .
    log_success "Production image built successfully!"
}

# Build development image
build_development() {
    log_info "Building development image..."
    docker build --target development -t react-app-dev:latest .
    log_success "Development image built successfully!"
}

# Test production image
test_production() {
    log_info "Testing production image..."
    
    # Stop any existing container
    docker stop react-app-prod-test 2>/dev/null || true
    docker rm react-app-prod-test 2>/dev/null || true
    
    # Start production container
    docker run -d --name react-app-prod-test -p 8080:80 react-app-prod:latest
    
    # Wait for startup
    sleep 5
    
    # Test if responding
    if curl -f http://localhost:8080 >/dev/null 2>&1; then
        log_success "Production app is running! Visit: http://localhost:8080"
    else
        log_warning "Production app may still be starting up. Check: http://localhost:8080"
    fi
    
    # Show container info
    docker ps | grep react-app-prod-test
}

# Test development image
test_development() {
    log_info "Testing development image..."
    
    # Stop any existing container
    docker stop react-app-dev-test 2>/dev/null || true
    docker rm react-app-dev-test 2>/dev/null || true
    
    # Start development container
    docker run -d --name react-app-dev-test -p 5173:5173 -v $(pwd):/app react-app-dev:latest
    
    # Wait for startup
    sleep 10
    
    log_info "Development server starting... This may take a moment."
    log_info "Visit: http://localhost:5173"
    
    # Show container info
    docker ps | grep react-app-dev-test
}

# Clean up test containers
cleanup() {
    log_info "Cleaning up test containers..."
    docker stop react-app-prod-test react-app-dev-test 2>/dev/null || true
    docker rm react-app-prod-test react-app-dev-test 2>/dev/null || true
    log_success "Cleanup completed!"
}

# Show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  prod         Build and test production image"
    echo "  dev          Build and test development image"
    echo "  both         Build and test both images"
    echo "  sizes        Show current image sizes"
    echo "  cleanup      Stop and remove test containers"
    echo "  compose-dev  Run development with docker-compose"
    echo "  compose-prod Run production with docker-compose"
    echo "  help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 prod      # Build and test production image"
    echo "  $0 both      # Build and test both images"
    echo "  $0 sizes     # Show image sizes"
}

# Main script logic
case "${1:-help}" in
    "prod")
        build_production
        test_production
        show_image_sizes
        log_info "Production container running. Use '$0 cleanup' to stop when done."
        ;;
    "dev")
        build_development
        test_development
        show_image_sizes
        log_info "Development container running. Use '$0 cleanup' to stop when done."
        ;;
    "both")
        build_production
        build_development
        test_production
        test_development
        show_image_sizes
        log_info "Both containers running. Use '$0 cleanup' to stop when done."
        ;;
    "sizes")
        show_image_sizes
        ;;
    "cleanup")
        cleanup
        ;;
    "compose-dev")
        log_info "Starting development environment with docker-compose..."
        docker-compose up -d react-app-dev
        log_success "Development environment started! Visit: http://localhost:5173"
        ;;
    "compose-prod")
        log_info "Starting production environment with docker-compose..."
        docker-compose up -d react-app-prod
        log_success "Production environment started! Visit: http://localhost:80"
        ;;
    "help"|*)
        show_help
        ;;
esac
