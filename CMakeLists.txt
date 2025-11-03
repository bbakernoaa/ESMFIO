# ESMF_IO Unified Component CMake Build System
# Redesigned to mirror UFS Weather Model best practices
cmake_minimum_required(VERSION 3.20)

# Project declaration with explicit language standards
project(ESMF_IO
  VERSION 1.0.0
  LANGUAGES Fortran C
  DESCRIPTION "Unified I/O Component for Earth System Models"
)

# Set CMake policies for modern behavior
cmake_policy(SET CMP0074 NEW)  # Find modules use CMAKE_SIZEOF_*
cmake_policy(SET CMP0077 NEW)  # Option() honors normal variables
cmake_policy(SET CMP0148 NEW)  # Enable support for .cmake-format.json

# Establish project-wide variables
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

set(CMAKE_Fortran_STANDARD 2003)
set(CMAKE_Fortran_STANDARD_REQUIRED ON)
set(CMAKE_Fortran_EXTENSIONS OFF)

# Set default build type if not specified
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose build type" FORCE)
endif()

# Define project options with descriptions
option(ENABLE_NETCDF "Enable NetCDF support" ON)
option(ENABLE_PARALLEL_IO "Enable parallel I/O support" ON)
option(ENABLE_TESTS "Build test suite" ON)
option(ENABLE_EXAMPLES "Build example programs" ON)
option(ENABLE_DOCUMENTATION "Build documentation" OFF)
option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
option(ENABLE_WARNINGS "Enable compiler warnings" OFF)

# Validate compiler support
if(NOT CMAKE_Fortran_COMPILER_ID)
  message(FATAL_ERROR "A Fortran compiler is required but not found")
endif()

# Compiler-specific flags using target-based approach
include(CMakeDependentOption)
include(CheckFortranCompilerFlag)

# Set up output directories
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Add module path for custom CMake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/CMakeModules/Modules")

# Find required packages using modern CMake approaches
find_package(MPI REQUIRED)
find_package(Threads REQUIRED)

if(ENABLE_NETCDF)
  find_package(NetCDF REQUIRED COMPONENTS Fortran C)
endif()

if(ENABLE_PARALLEL_IO)
  find_package(PnetCDF QUIET)
  if(PnetCDF_FOUND)
    message(STATUS "PnetCDF support enabled")
  else()
    message(WARNING "PnetCDF not found, parallel NetCDF I/O will be limited")
  endif()
endif()

# Find ESMF using the provided FindESMF module
find_package(ESMF REQUIRED)

# Set up external dependencies with FetchContent if needed
include(FetchContent)

# Add subdirectories in dependency order
add_subdirectory(src)

# Add testing if enabled
if(ENABLE_TESTS)
  include(CTest)
  add_subdirectory(tests)
endif()

add_subdirectory(examples)

# Setup installation
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# Export targets for package configuration
install(EXPORT ESMF_IO_Targets
  FILE ESMF_IOConfig.cmake
  NAMESPACE ESMF_IO::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/ESMF_IO
)

# Create package configuration
configure_package_config_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake/ESMF_IOConfig.cmake.in"
  "${CMAKE_CURRENT_BINARY_DIR}/ESMF_IOConfig.cmake"
  INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/ESMF_IO
)

write_basic_package_version_file(
  "${CMAKE_CURRENT_BINARY_DIR}/ESMF_IOConfigVersion.cmake"
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY AnyNewerVersion
)

# Install configuration files
install(
 FILES
    "${CMAKE_CURRENT_BINARY_DIR}/ESMF_IOConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/ESMF_IOConfigVersion.cmake"
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/ESMF_IO
)

# Print build summary
message(STATUS "===========================================")
message(STATUS "ESMF_IO Build Configuration Summary:")
message(STATUS "  Project Version: ${PROJECT_VERSION}")
message(STATUS "  Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS " CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")
message(STATUS "  Fortran Compiler: ${CMAKE_Fortran_COMPILER_ID}")
message(STATUS "  C Compiler: ${CMAKE_C_COMPILER_ID}")
message(STATUS "  ESMF Directory: ${ESMF_DIR}")
message(STATUS "  NetCDF Support: ${ENABLE_NETCDF}")
message(STATUS "  Parallel I/O: ${ENABLE_PARALLEL_IO}")
message(STATUS "  Build Tests: ${ENABLE_TESTS}")
message(STATUS "  Build Examples: ${ENABLE_EXAMPLES}")
message(STATUS "  Build Documentation: ${ENABLE_DOCUMENTATION}")
message(STATUS "  Build Shared Libs: ${BUILD_SHARED_LIBS}")
message(STATUS "===========================================")