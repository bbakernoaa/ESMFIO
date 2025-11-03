#!/bin/bash

# Modern build script for ESMF_IO following UFS Weather Model best practices
# This script demonstrates the usage of the new modular CMake build system

set -e  # Exit on any error

# Default configuration
BUILD_TYPE="Release"
BUILD_DIR="build"
INSTALL_PREFIX=""
CLEAN_BUILD=false
VERBOSE_BUILD=false
PARALLEL_JOBS=4 

# Parse command line arguments
while [[ $# -gt 0 ]]; do
 case $1 in
    -t|--type)
      BUILD_TYPE="$2"
      shift 2
      ;;
    -d|--dir)
      BUILD_DIR="$2"
      shift 2
      ;;
    -i|--install)
      INSTALL_PREFIX="$2"
      shift 2
      ;;
    -c|--clean)
      CLEAN_BUILD=true
      shift
      ;;
    -v|--verbose)
      VERBOSE_BUILD=true
      shift
      ;;
    -j|--jobs)
      PARALLEL_JOBS="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Build script for ESMF_IO using modern CMake practices"
      echo ""
      echo "Options:"
      echo "  -t, --type TYPE      Build type (Debug, Release, RelWithDebInfo, MinSizeRel) [default: Release]"
      echo "  -d, --dir DIR        Build directory [default: build]"
      echo "  -i, --install PREFIX Installation prefix"
      echo " -c, --clean          Clean previous build"
      echo "  -v, --verbose        Verbose build output"
      echo " -j, --jobs N          Number of parallel jobs [default: 4]"
      echo "  -h, --help           Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "==========================================="
echo "ESMF_IO Build Configuration"
echo "==========================================="
echo "Build Type: $BUILD_TYPE"
echo "Build Directory: $BUILD_DIR"
echo "Install Prefix: ${INSTALL_PREFIX:-Not set}"
echo "Clean Build: $CLEAN_BUILD"
echo "Parallel Jobs: $PARALLEL_JOBS"
echo "==========================================="

# Create build directory
if [ "$CLEAN_BUILD" = true ]; then
  echo "Cleaning previous build..."
  rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure the build with modern CMake practices
echo "Configuring build..."

cmake_args=(
  "-DCMAKE_BUILD_TYPE=$BUILD_TYPE"
  "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
)

if [ -n "$INSTALL_PREFIX" ]; then
  cmake_args+=("-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX")
fi

# Add common HPC environment detection
if [ -n "$ESMF_DIR" ]; then
  cmake_args+=("-DESMF_DIR=$ESMF_DIR")
fi

if [ -n "$NETCDF_ROOT" ]; then
  cmake_args+=("-DNetCDF_ROOT=$NETCDF_ROOT")
fi

if [ -n "$PNETCDF_ROOT" ]; then
  cmake_args+=("-DPnetCDF_ROOT=$PNETCDF_ROOT")
fi

# Add build options
cmake_args+=(
  "-DENABLE_NETCDF=ON"
  "-DENABLE_PARALLEL_IO=ON"
  "-DENABLE_TESTS=ON"
  "-DENABLE_EXAMPLES=ON"
  "-DENABLE_DOCUMENTATION=OFF"/
)

# Run cmake with all arguments
echo "cmake ${cmake_args[@]} .."
cmake "${cmake_args[@]}" ..

if [ "$VERBOSE_BUILD" = true ]; then
  make VERBOSE=1 -j "$PARALLEL_JOBS"
else
  make -j "$PARALLEL_JOBS"
fi