#!/bin/bash

# ESMF_IO Benchmark Script
# This script runs performance benchmarks for the ESMF_IO Unified Component

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

# Default benchmark settings
DEFAULT_BUILD_DIR="build"
DEFAULT_BENCHMARK_DIR="benchmarks"
DEFAULT_ENABLE_IO_BENCHMARKS="ON"
DEFAULT_ENABLE_MEMORY_BENCHMARKS="ON"
DEFAULT_ENABLE_SCALABILITY_BENCHMARKS="ON"
DEFAULT_ENABLE_REGRIDDING_BENCHMARKS="ON"
DEFAULT_ENABLE_TEMPORAL_BENCHMARKS="ON"
DEFAULT_ENABLE_PARALLEL_BENCHMARKS="ON"
DEFAULT_PROCESSOR_COUNTS="1 2 4 8 16"
DEFAULT_GRID_SIZES="100 500 1000 2000"
DEFAULT_ITERATION_COUNT=10

# Parse command line arguments
BUILD_DIR="$DEFAULT_BUILD_DIR"
BENCHMARK_DIR="$DEFAULT_BENCHMARK_DIR"
ENABLE_IO_BENCHMARKS="$DEFAULT_ENABLE_IO_BENCHMARKS"
ENABLE_MEMORY_BENCHMARKS="$DEFAULT_ENABLE_MEMORY_BENCHMARKS"
ENABLE_SCALABILITY_BENCHMARKS="$DEFAULT_ENABLE_SCALABILITY_BENCHMARKS"
ENABLE_REGRIDDING_BENCHMARKS="$DEFAULT_ENABLE_REGRIDDING_BENCHMARKS"
ENABLE_TEMPORAL_BENCHMARKS="$DEFAULT_ENABLE_TEMPORAL_BENCHMARKS"
ENABLE_PARALLEL_BENCHMARKS="$DEFAULT_ENABLE_PARALLEL_BENCHMARKS"
PROCESSOR_COUNTS="$DEFAULT_PROCESSOR_COUNTS"
GRID_SIZES="$DEFAULT_GRID_SIZES"
ITERATION_COUNT="$DEFAULT_ITERATION_COUNT"

while [[ $# -gt 0 ]]; do
    case $1 in
        --build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        --benchmark-dir)
            BENCHMARK_DIR="$2"
            shift 2
            ;;
        --enable-io-benchmarks)
            ENABLE_IO_BENCHMARKS="ON"
            shift
            ;;
        --disable-io-benchmarks)
            ENABLE_IO_BENCHMARKS="OFF"
            shift
            ;;
        --enable-memory-benchmarks)
            ENABLE_MEMORY_BENCHMARKS="ON"
            shift
            ;;
        --disable-memory-benchmarks)
            ENABLE_MEMORY_BENCHMARKS="OFF"
            shift
            ;;
        --enable-scalability-benchmarks)
            ENABLE_SCALABILITY_BENCHMARKS="ON"
            shift
            ;;
        --disable-scalability-benchmarks)
            ENABLE_SCALABILITY_BENCHMARKS="OFF"
            shift
            ;;
        --enable-regridding-benchmarks)
            ENABLE_REGRIDDING_BENCHMARKS="ON"
            shift
            ;;
        --disable-regridding-benchmarks)
            ENABLE_REGRIDDING_BENCHMARKS="OFF"
            shift
            ;;
        --enable-temporal-benchmarks)
            ENABLE_TEMPORAL_BENCHMARKS="ON"
            shift
            ;;
        --disable-temporal-benchmarks)
            ENABLE_TEMPORAL_BENCHMARKS="OFF"
            shift
            ;;
        --enable-parallel-benchmarks)
            ENABLE_PARALLEL_BENCHMARKS="ON"
            shift
            ;;
        --disable-parallel-benchmarks)
            ENABLE_PARALLEL_BENCHMARKS="OFF"
            shift
            ;;
        --processor-counts)
            PROCESSOR_COUNTS="$2"
            shift 2
            ;;
        --grid-sizes)
            GRID_SIZES="$2"
            shift 2
            ;;
        --iteration-count)
            ITERATION_COUNT="$2"
            shift 2
            ;;
        --help|-h)
            echo "ESMF_IO Benchmark Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --build-dir DIR           Build directory (default: $DEFAULT_BUILD_DIR)"
            echo "  --benchmark-dir DIR       Benchmark results directory (default: $DEFAULT_BENCHMARK_DIR)"
            echo "  --enable-io-benchmarks    Enable I/O benchmarks (default: $DEFAULT_ENABLE_IO_BENCHMARKS)"
            echo "  --disable-io-benchmarks   Disable I/O benchmarks"
            echo "  --enable-memory-benchmarks Enable memory benchmarks (default: $DEFAULT_ENABLE_MEMORY_BENCHMARKS)"
            echo "  --disable-memory-benchmarks Disable memory benchmarks"
            echo "  --enable-scalability-benchmarks Enable scalability benchmarks (default: $DEFAULT_ENABLE_SCALABILITY_BENCHMARKS)"
            echo "  --disable-scalability-benchmarks Disable scalability benchmarks"
            echo "  --enable-regridding-benchmarks Enable regridding benchmarks (default: $DEFAULT_ENABLE_REGRIDDING_BENCHMARKS)"
            echo "  --disable-regridding-benchmarks Disable regridding benchmarks"
            echo "  --enable-temporal-benchmarks Enable temporal benchmarks (default: $DEFAULT_ENABLE_TEMPORAL_BENCHMARKS)"
            echo "  --disable-temporal-benchmarks Disable temporal benchmarks"
            echo "  --enable-parallel-benchmarks Enable parallel benchmarks (default: $DEFAULT_ENABLE_PARALLEL_BENCHMARKS)"
            echo "  --disable-parallel-benchmarks Disable parallel benchmarks"
            echo "  --processor-counts COUNTS Processor counts to test (default: \"$DEFAULT_PROCESSOR_COUNTS\")"
            echo "  --grid-sizes SIZES        Grid sizes to test (default: \"$DEFAULT_GRID_SIZES\")"
            echo "  --iteration-count COUNT   Number of iterations per benchmark (default: $DEFAULT_ITERATION_COUNT)"
            echo "  --help, -h                Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --build-dir build --benchmark-dir benchmarks"
            echo "  $0 --enable-io-benchmarks --enable-memory-benchmarks"
            echo "  $0 --processor-counts \"1 2 4 8\" --grid-sizes \"100 500 1000\""
            echo "  $0 --iteration-count 20 --disable-parallel-benchmarks"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if build directory exists
check_build_dir() {
    print_status "Checking build directory..."

    if [ ! -d "$BUILD_DIR" ]; then
        print_error "Build directory ($BUILD_DIR) does not exist."
        print_error "Please run the build script first."
        exit 1
    fi

    if [ ! -f "$BUILD_DIR/esmf_io_benchmark_runner" ]; then
        print_error "Benchmark runner not found in build directory."
        print_error "Please run the build script with benchmarks enabled."
        exit 1
    fi

    print_success "Build directory is valid."
}

# Create benchmark directory
create_benchmark_dir() {
    print_status "Creating benchmark directory..."

    mkdir -p "$BENCHMARK_DIR"

    print_success "Benchmark directory created."
}

# Run I/O benchmarks
run_io_benchmarks() {
    if [ "$ENABLE_IO_BENCHMARKS" = "ON" ]; then
        print_status "Running I/O benchmarks..."

        # Run I/O benchmarks
        "$BUILD_DIR/esmf_io_benchmark_runner" --io-benchmarks \
            --benchmark-dir "$BENCHMARK_DIR" \
            --grid-sizes "$GRID_SIZES" \
            --iteration-count "$ITERATION_COUNT"

        if [ $? -ne 0 ]; then
            print_error "I/O benchmarks failed."
            exit 1
        fi

        print_success "I/O benchmarks completed."
    else
        print_status "I/O benchmarks are disabled. Skipping I/O benchmark execution."
    fi
}

# Run memory benchmarks
run_memory_benchmarks() {
    if [ "$ENABLE_MEMORY_BENCHMARKS" = "ON" ]; then
        print_status "Running memory benchmarks..."

        # Run memory benchmarks
        "$BUILD_DIR/esmf_io_benchmark_runner" --memory-benchmarks \
            --benchmark-dir "$BENCHMARK_DIR" \
            --grid-sizes "$GRID_SIZES" \
            --iteration-count "$ITERATION_COUNT"

        if [ $? -ne 0 ]; then
            print_error "Memory benchmarks failed."
            exit 1
        fi

        print_success "Memory benchmarks completed."
    else
        print_status "Memory benchmarks are disabled. Skipping memory benchmark execution."
    fi
}

# Run scalability benchmarks
run_scalability_benchmarks() {
    if [ "$ENABLE_SCALABILITY_BENCHMARKS" = "ON" ]; then
        print_status "Running scalability benchmarks..."

        # Run scalability benchmarks
        "$BUILD_DIR/esmf_io_benchmark_runner" --scalability-benchmarks \
            --benchmark-dir "$BENCHMARK_DIR" \
            --processor-counts "$PROCESSOR_COUNTS" \
            --grid-sizes "$GRID_SIZES" \
            --iteration-count "$ITERATION_COUNT"

        if [ $? -ne 0 ]; then
            print_error "Scalability benchmarks failed."
            exit 1
        fi

        print_success "Scalability benchmarks completed."
    else
        print_status "Scalability benchmarks are disabled. Skipping scalability benchmark execution."
    fi
}

# Run regridding benchmarks
run_regridding_benchmarks() {
    if [ "$ENABLE_REGRIDDING_BENCHMARKS" = "ON" ]; then
        print_status "Running regridding benchmarks..."

        # Run regridding benchmarks
        "$BUILD_DIR/esmf_io_benchmark_runner" --regridding-benchmarks \
            --benchmark-dir "$BENCHMARK_DIR" \
            --grid-sizes "$GRID_SIZES" \
            --iteration-count "$ITERATION_COUNT"

        if [ $? -ne 0 ]; then
            print_error "Regridding benchmarks failed."
            exit 1
        fi

        print_success "Regridding benchmarks completed."
    else
        print_status "Regridding benchmarks are disabled. Skipping regridding benchmark execution."
    fi
}

# Run temporal benchmarks
run_temporal_benchmarks() {
    if [ "$ENABLE_TEMPORAL_BENCHMARKS" = "ON" ]; then
        print_status "Running temporal benchmarks..."

        # Run temporal benchmarks
        "$BUILD_DIR/esmf_io_benchmark_runner" --temporal-benchmarks \
            --benchmark-dir "$BENCHMARK_DIR" \
            --grid-sizes "$GRID_SIZES" \
            --iteration-count "$ITERATION_COUNT"

        if [ $? -ne 0 ]; then
            print_error "Temporal benchmarks failed."
            exit 1
        fi

        print_success "Temporal benchmarks completed."
    else
        print_status "Temporal benchmarks are disabled. Skipping temporal benchmark execution."
    fi
}

# Run parallel benchmarks
run_parallel_benchmarks() {
    if [ "$ENABLE_PARALLEL_BENCHMARKS" = "ON" ]; then
        print_status "Running parallel benchmarks..."

        # Run parallel benchmarks
        "$BUILD_DIR/esmf_io_benchmark_runner" --parallel-benchmarks \
            --benchmark-dir "$BENCHMARK_DIR" \
            --processor-counts "$PROCESSOR_COUNTS" \
            --grid-sizes "$GRID_SIZES" \
            --iteration-count "$ITERATION_COUNT"

        if [ $? -ne 0 ]; then
            print_error "Parallel benchmarks failed."
            exit 1
        fi

        print_success "Parallel benchmarks completed."
    else
        print_status "Parallel benchmarks are disabled. Skipping parallel benchmark execution."
    fi
}

# Run all benchmarks
run_all_benchmarks() {
    print_status "Running all benchmarks..."

    # Run all benchmarks
    "$BUILD_DIR/esmf_io_benchmark_runner" --all-benchmarks \
        --benchmark-dir "$BENCHMARK_DIR" \
        --processor-counts "$PROCESSOR_COUNTS" \
        --grid-sizes "$GRID_SIZES" \
        --iteration-count "$ITERATION_COUNT"

    if [ $? -ne 0 ]; then
        print_error "Some benchmarks failed."
        exit 1
    fi

    print_success "All benchmarks completed."
}

# Generate benchmark reports
generate_reports() {
    print_status "Generating benchmark reports..."

    # Generate reports
    "$BUILD_DIR/esmf_io_benchmark_runner" --generate-reports \
        --benchmark-dir "$BENCHMARK_DIR"

    if [ $? -ne 0 ]; then
        print_error "Report generation failed."
        exit 1
    fi

    print_success "Benchmark reports generated."
}

# Print benchmark summary
print_benchmark_summary() {
    print_success "ESMF_IO benchmarks completed successfully!"
    echo ""
    echo "Benchmark Summary:"
    echo "  Build Directory: $BUILD_DIR"
    echo "  Benchmark Directory: $BENCHMARK_DIR"
    echo "  I/O Benchmarks Enabled: $ENABLE_IO_BENCHMARKS"
    echo "  Memory Benchmarks Enabled: $ENABLE_MEMORY_BENCHMARKS"
    echo "  Scalability Benchmarks Enabled: $ENABLE_SCALABILITY_BENCHMARKS"
    echo "  Regridding Benchmarks Enabled: $ENABLE_REGRIDDING_BENCHMARKS"
    echo "  Temporal Benchmarks Enabled: $ENABLE_TEMPORAL_BENCHMARKS"
    echo "  Parallel Benchmarks Enabled: $ENABLE_PARALLEL_BENCHMARKS"
    echo "  Processor Counts Tested: $PROCESSOR_COUNTS"
    echo "  Grid Sizes Tested: $GRID_SIZES"
    echo "  Iteration Count: $ITERATION_COUNT"
    echo ""
    echo "Benchmark results are available in: $BENCHMARK_DIR"
    echo ""
}

# Main benchmark function
main() {
    print_status "Starting ESMF_IO benchmarks..."

    # Check build directory
    check_build_dir

    # Create benchmark directory
    create_benchmark_dir

    # Run benchmarks based on enabled options
    if [ "$ENABLE_IO_BENCHMARKS" = "ON" ] || \
       [ "$ENABLE_MEMORY_BENCHMARKS" = "ON" ] || \
       [ "$ENABLE_SCALABILITY_BENCHMARKS" = "ON" ] || \
       [ "$ENABLE_REGRIDDING_BENCHMARKS" = "ON" ] || \
       [ "$ENABLE_TEMPORAL_BENCHMARKS" = "ON" ] || \
       [ "$ENABLE_PARALLEL_BENCHMARKS" = "ON" ]; then
       
        # Run individual benchmark categories
        run_io_benchmarks
        run_memory_benchmarks
        run_scalability_benchmarks
        run_regridding_benchmarks
        run_temporal_benchmarks
        run_parallel_benchmarks
    else
        # Run all benchmarks
        run_all_benchmarks
    fi

    # Generate reports
    generate_reports

    # Print benchmark summary
    print_benchmark_summary

    print_status "ESMF_IO benchmark script completed."
}

# Run main function
main "$@"