#!/bin/bash

# Run script for Single Model ESMF_IO NUOPC Example
# This script provides an easy way to build and run the example

set -e # Exit on any error

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Go to the project root directory
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default build directory
BUILD_DIR="${PROJECT_ROOT}/build_example"
INSTALL_DIR="${PROJECT_ROOT}/install_example"

# Function to print usage
print_usage() {
    echo "Usage: $0 [build|run|clean|help]"
    echo "  build  - Build the example (default if no argument provided)"
    echo "  run    - Run the built example"
    echo "  clean  - Clean build and install directories"
    echo "  help   - Show this help message"
}

# Function to build the example
build_example() {
    echo "Building Single Model ESMF_IO NUOPC Example..."
    
    # Create build directory if it doesn't exist
    mkdir -p "$BUILD_DIR"
    
    # Change to build directory
    cd "$BUILD_DIR"
    
    # Run CMake to configure the build - build as part of the main project
    echo "Configuring build with CMake..."
    cmake "$PROJECT_ROOT" \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_TESTS=OFF \
        -DENABLE_EXAMPLES=ON \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"
    
    # Build the example
    echo "Building the example..."
    make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4) esmf_io_single_model_demo
    
    echo "Build completed successfully!"
}

# Function to run the example
run_example() {
    echo "Running Single Model ESMF_IO NUOPC Example..."
    
    # Check if build directory exists
    if [ ! -d "$BUILD_DIR" ]; then
        echo "Error: Build directory does not exist. Please build first."
        exit 1
    fi
    
    # Check if executable exists
    EXECUTABLE="$BUILD_DIR/bin/esmf_io_single_model_demo"
    if [ ! -f "$EXECUTABLE" ]; then
        echo "Error: Executable not found at $EXECUTABLE"
        exit 1
    fi
    
    # Change to build directory
    cd "$BUILD_DIR"
    
    # Copy configuration file to build directory
    if [ -f "$SCRIPT_DIR/user_nl_esmf_io" ]; then
        cp "$SCRIPT_DIR/user_nl_esmf_io" .
        echo "Configuration file copied to build directory."
    else
        echo "Warning: Configuration file not found at $SCRIPT_DIR/user_nl_esmf_io"
    fi
    
    # Run the executable
    echo "Starting execution..."
    echo "Note: The example may fail with configuration errors if required data files are not present."
    echo "This is expected behavior for a demonstration of the NUOPC component structure."
    ./"$(basename "$EXECUTABLE")"
    
    echo "Execution completed!"
}

# Function to clean build and install directories
clean_example() {
    echo "Cleaning build and install directories..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        echo "Removed $BUILD_DIR"
    fi
    
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        echo "Removed $INSTALL_DIR"
    fi
    
    echo "Clean completed!"
}

# Main script logic
case "${1:-build}" in
    build)
        build_example
        ;;
    run)
        run_example
        ;;
    clean)
        clean_example
        ;;
    help|--help|-h)
        print_usage
        ;;
    *)
        echo "Error: Unknown command '$1'"
        print_usage
        exit 1
        ;;
esac