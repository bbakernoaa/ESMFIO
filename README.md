# ESMF_IO Unified Component

[![Build Status](https://github.com/bbakernoaa/ESMFIO/workflows/Build/badge.svg)](https://github.com/bbakernoaa/ESMFIO/actions)
[![Documentation Status](https://readthedocs.org/projects/esmf-io/badge/?version=latest)](https://esmf-io.readthedocs.io/en/latest/?badge=latest)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Overview

ESMF_IO is a unified component that combines the functionality of both input (ExtData equivalent) and output (History equivalent) operations within a single ESMF-compliant component. It provides a modern, flexible, and high-performance solution for data I/O in Earth system models.

## Key Features

- **Unified Interface**: Combines both input and output functionality in a single component
- **Flexible Configuration**: ESMF-based configuration system for easy customization
- **Parallel I/O**: Built-in support for parallel NetCDF operations
- **Temporal Processing**: Advanced temporal interpolation and time-averaging capabilities
- **Spatial Regridding**: On-the-fly regridding between different grids
- **NUOPC Integration**: Seamless integration with NUOPC-based coupled systems
- **High Performance**: Optimized for large-scale parallel computing environments

## Documentation

Comprehensive documentation is available at [ESMF_IO Documentation](https://esmf-io.readthedocs.io).

### User Documentation

- [Getting Started](docs/user/getting_started.md): Introduction and basic usage
- [Configuration Guide](docs/user/configuration_guide.md): How to configure ESMF_IO
- [Usage Examples](docs/user/examples.md): Practical usage examples

### Developer Documentation

- [API Reference](docs/developer/api_reference.md): Detailed API documentation
- [Architecture Guide](docs/developer/architecture.md): System architecture overview
- [Implementation Guide](docs/developer/implementation.md): Implementation details
- [Testing Guide](docs/developer/testing.md): How to test ESMF_IO
- [Contributing Guidelines](docs/developer/contributing.md): How to contribute to ESMF_IO

### Technical Documentation

- [Data Flow Documentation](docs/technical/data_flow.md): Data flow diagrams and explanations
- [Performance Analysis](docs/technical/performance_analysis.md): Performance characteristics and optimization
- [Error Handling Documentation](docs/technical/error_handling.md): Error handling and recovery mechanisms
- [Memory Management](docs/technical/memory_management.md): Memory usage and management
- [Parallel I/O Implementation](docs/technical/parallel_io.md): Parallel I/O implementation details

### Reference Documentation

- [Configuration Parameters](docs/reference/configuration_parameters.md): Detailed configuration parameter reference
- [Module Dependencies](docs/reference/module_dependencies.md): Module dependency relationships
- [ESMF Integration](docs/reference/esmf_integration.md): Integration with ESMF
- [NUOPC Integration](docs/reference/nuopc_integration.md): Integration with NUOPC

### Release Documentation

- [Release Notes](docs/release/release_notes.md): Release history and changes
- [Installation Guide](docs/release/installation.md): How to install ESMF_IO
- [System Requirements](docs/release/system_requirements.md): Hardware and software requirements
- [License Information](docs/release/license.md): Licensing details

## Quick Start

### Prerequisites

Before installing ESMF_IO, ensure you have the following software installed:

1. **Fortran Compiler**: A modern Fortran compiler (e.g., `gfortran`, `ifort`, `nvfortran`)
2. **CMake**: Version 3.20 or higher (required for modern CMake practices)
3. **MPI Implementation**: An MPI library (e.g., Open MPI, MPICH, Intel MPI)
4. **ESMF Library**: The Earth System Modeling Framework must be installed and configured
5. **NetCDF Libraries**: Required for NetCDF file format support
6. **PNetCDF Libraries**: Optional but recommended for parallel NetCDF I/O

### Installation

ESMF_IO now uses a modular CMake build system following UFS Weather Model best practices. The build system is organized with separate CMakeLists.txt files for each component:

- Top-level: Handles project configuration and options
- src/: Contains the main library and driver executable
- tests/: Manages the testing framework
- examples/: Handles example programs

#### Quick Build

For a simple build, you can use the provided build script:

```bash
# Make sure you have environment variables set for dependencies
export ESMF_DIR=/path/to/esmf
export NETCDF_ROOT=/path/to/netcdf

# Run the modern build script
./build_modern.sh
```

#### Manual Build

Alternatively, build manually with CMake:

```bash
mkdir build_modern
cd build_modern
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_NETCDF=ON \
  -DENABLE_PARALLEL_IO=ON \
  -DENABLE_TESTS=ON \
  -DENABLE_EXAMPLES=ON
make -j$(nproc)
```

#### Advanced Configuration

For more control over the build process, you can use these CMake options:

```bash
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/path/to/install \
  -DENABLE_NETCDF=ON \
  -DENABLE_PARALLEL_IO=ON \
  -DENABLE_TESTS=ON \
  -DENABLE_EXAMPLES=ON \
  -DENABLE_DOCUMENTATION=OFF \
  -DBUILD_SHARED_LIBS=OFF \
  -DENABLE_WARNINGS=OFF
```

To install ESMF_IO:

```bash
# Clone the repository
git clone https://github.com/bbakernoaa/ESMFIO.git
cd ESMF_IO

# Set environment variables
export ESMFMKFILE=/path/to/esmf/lib/esmf.mk
export NETCDF_ROOT=/path/to/netcdf

# Create build directory
mkdir build
cd build

# Configure with CMake
cmake .. \
  -DCMAKE_Fortran_COMPILER=mpif90 \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_NETCDF=ON \
  -DENABLE_PARALLEL_IO=ON

# Build
make -j$(nproc)

# Install
make install
```

### Usage

To use ESMF_IO in your applications:

```fortran
program example
  use ESMF
  use ESMF_IO_Component_Mod

  implicit none

  integer :: rc
  type(ESMF_GridComp) :: io_component
  type(ESMF_State) :: importState, exportState
  type(ESMF_Clock) :: clock

  ! Initialize ESMF
  call ESMF_Initialize(logKindFlag=ESMF_LOGKIND_MULTI, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Create the ESMF_IO component
  io_component = ESMF_GridCompCreate("ESMF_IO_Component", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Set services for the ESMF_IO component
  call ESMF_GridCompSetServices(io_component, ESMF_IO_SetServices, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Create import and export states
  importState = ESMF_StateCreate(name="IO_ImportState", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  exportState = ESMF_StateCreate(name="IO_ExportState", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Create a simple clock
  ! ... (clock setup code) ...

  ! Add configuration file to import state
  call ESMF_StateSet(importState, "ESMF_IO_ConfigFile", "config.rc", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Initialize the ESMF_IO component
  call ESMF_IO_Initialize(io_component, importState, exportState, clock, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Run the ESMF_IO component for several time steps
  do while (.not. ESMF_ClockIsStopTime(clock))
    call ESMF_IO_Run(io_component, importState, exportState, clock, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
      call ESMF_Finalize(endflag=ESMF_END_ABORT)

    call ESMF_ClockAdvance(clock, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
      call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end do

  ! Finalize the ESMF_IO component
  call ESMF_IO_Finalize(io_component, importState, exportState, clock, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Destroy objects
  call ESMF_GridCompDestroy(io_component, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_StateDestroy(importState, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_StateDestroy(exportState, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_ClockDestroy(clock, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Finalize ESMF
  call ESMF_Finalize(rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    stop

end program example
```

### Compilation

To compile this example:

```bash
mpif90 example.F90 \
  -I/path/to/esmf/include \
  -L/path/to/esmf/lib \
  -lesmf \
  -I/path/to/esmf_io/include \
  -L/path/to/esmf_io/lib \
  -lesmf_io \
  -o example
```

## Testing

ESMF_IO includes a comprehensive test suite. To run the tests:

```bash
cd build
make test
```

Or run the test executable directly:

```bash
./esmf_io_test_runner
```

## Contributing

We welcome contributions to ESMF_IO! Please see our [Contributing Guidelines](docs/developer/contributing.md) for more information.

## Support

For support with ESMF_IO:

1. [GitHub Issues](https://github.com/bbakernoaa/ESMFIO/issues) - Report bugs or request features

## License

ESMF_IO is distributed under the Apache License, Version 2.0. See [LICENSE](docs/release/license.md) for more information.

## Acknowledgments

ESMF_IO builds upon the excellent work of the ESMF community and incorporates ideas from the MAPL ExtData and History components. We thank all contributors to these projects for their valuable work.