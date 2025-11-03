# System Requirements

This document outlines the system requirements for building and running the ESMF_IO Unified Component.

## Overview

ESMF_IO is designed to be portable across a wide range of computing platforms while maintaining high performance. The component has been tested on various systems from laptops to large-scale supercomputers.

## Hardware Requirements

### Minimum Hardware

For basic functionality and testing:

- **CPU**: Modern multi-core processor (x86-64 architecture recommended)
- **Memory**: 4 GB RAM minimum (8 GB recommended)
- **Storage**: 100 MB available disk space for installation
- **Network**: Ethernet connectivity (for parallel builds/tests)

### Recommended Hardware

For production use and development:

- **CPU**: Multi-core processor with AVX2 support or better
- **Memory**: 16 GB RAM or more (depending on grid size)
- **Storage**: SSD storage recommended for optimal I/O performance
- **Network**: High-speed interconnect (InfiniBand, Omni-Path) for parallel systems

### High-Performance Computing Systems

For large-scale applications:

- **Nodes**: 1 or more compute nodes with modern CPUs
- **Memory**: 64 GB RAM or more per node
- **Storage**: Parallel file system (Lustre, GPFS, BeeGFS)
- **Network**: High-bandwidth, low-latency interconnect

## Software Requirements

### Operating Systems

ESMF_IO supports the following operating systems:

#### Linux

- **Distributions**: CentOS/RHEL 7+, Ubuntu 18.04+, Debian 10+, SUSE Linux Enterprise 15+
- **Kernel**: Linux kernel 3.10 or newer
- **Architecture**: x86-64 (AMD64)

#### macOS

- **Versions**: macOS 10.14 (Mojave) or newer
- **Architecture**: x86-64 or Apple Silicon (ARM64)

#### Windows (Limited Support)

- **Versions**: Windows 10 with WSL2 or Windows Subsystem for Linux
- **Note**: Native Windows support is limited; WSL2 recommended

### Compilers

ESMF_IO requires a modern Fortran compiler with C interoperability support:

#### GNU Compiler Collection (GCC)

- **Minimum Version**: GCC 7.0
- **Recommended Version**: GCC 9.0 or newer
- **Required Components**: gfortran, gcc, g++

#### Intel Compilers

- **Minimum Version**: Intel Parallel Studio 2018
- **Recommended Version**: Intel oneAPI 2021 or newer
- **Required Components**: ifort, icc, icpc

#### NVIDIA HPC SDK

- **Minimum Version**: NVIDIA HPC SDK 20.7
- **Recommended Version**: NVIDIA HPC SDK 21.3 or newer
- **Required Components**: nvfortran, nvc, nvc++

#### Cray Compilers

- **Minimum Version**: Cray Compiler Environment 9.0
- **Recommended Version**: CCE 11.0 or newer
- **Required Components**: crayftn, cc, CC

### MPI Implementation

An MPI implementation is required for parallel execution:

#### Open MPI

- **Minimum Version**: Open MPI 3.0
- **Recommended Version**: Open MPI 4.0 or newer

#### MPICH

- **Minimum Version**: MPICH 3.2
- **Recommended Version**: MPICH 3.4 or newer

#### Intel MPI

- **Minimum Version**: Intel MPI 2018
- **Recommended Version**: Intel MPI 2021 or newer

#### Cray MPI

- **Minimum Version**: Cray MPI 7.0
- **Recommended Version**: Cray MPI 9.0 or newer

### ESMF Library

ESMF_IO requires the Earth System Modeling Framework library:

- **Minimum Version**: ESMF 8.0.0
- **Recommended Version**: ESMF 8.2.0 or newer
- **Build Requirements**: 
  - ESMF must be built with the same compiler and MPI implementation
  - ESMF must be built with NetCDF support
  - ESMF must be built with parallel I/O support (PNetCDF) for optimal performance

### NetCDF Library

NetCDF support is required for I/O operations:

#### NetCDF-C

- **Minimum Version**: NetCDF-C 4.6.0
- **Recommended Version**: NetCDF-C 4.7.4 or newer
- **Build Requirements**: 
  - Must be built with HDF5 support
  - Parallel I/O support recommended (built with MPI)

#### NetCDF-Fortran

- **Minimum Version**: NetCDF-Fortran 4.4.0
- **Recommended Version**: NetCDF-Fortran 4.5.3 or newer
- **Build Requirements**: 
  - Must be built with the same compiler as NetCDF-C
  - Must be linked against the same HDF5 library as NetCDF-C

### Parallel NetCDF (PNetCDF)

For optimal parallel I/O performance:

- **Minimum Version**: PNetCDF 1.12.0
- **Recommended Version**: PNetCDF 1.12.2 or newer
- **Build Requirements**: 
  - Must be built with the same MPI implementation as ESMF
  - Must be built with the same compiler as ESMF

### Optional Dependencies

#### UDUnits

For unit conversion and manipulation:

- **Minimum Version**: UDUnits 2.2.0
- **Recommended Version**: UDUnits 2.2.28 or newer

#### GPTL

For performance profiling:

- **Minimum Version**: GPTL 7.0.0
- **Recommended Version**: GPTL 8.0.2 or newer

#### YAML Parser

For future YAML configuration support:

- **Library**: libyaml-fortran or similar
- **Note**: Currently experimental; ESMF configuration format is the standard

## Build System Requirements

### CMake

ESMF_IO uses CMake as its build system:

- **Minimum Version**: CMake 3.10
- **Recommended Version**: CMake 3.18 or newer
- **Required Components**: 
  - Fortran support
  - MPI support
  - NetCDF support

### Make

Traditional make-based builds are supported:

- **GNU Make**: Version 3.81 or newer
- **Alternative**: Ninja build system (version 1.10 or newer)

### Build Environment

#### Environment Variables

Several environment variables may need to be set:

- **ESMFMKFILE**: Path to ESMF.mk file
- **NETCDF_ROOT**: Root directory of NetCDF installation
- **PNETCDF_ROOT**: Root directory of PNetCDF installation (if used)
- **MPI_ROOT**: Root directory of MPI installation (if needed)

#### Shell Requirements

- **Supported Shells**: bash, zsh, tcsh
- **Shell Features**: POSIX-compliant shell scripting support

## Runtime Requirements

### Shared Libraries

At runtime, the following shared libraries must be available:

- **ESMF**: ESMF shared libraries
- **NetCDF**: NetCDF-C and NetCDF-Fortran shared libraries
- **HDF5**: HDF5 shared libraries (used by NetCDF)
- **MPI**: MPI shared libraries
- **System Libraries**: Standard C library, math library

### Runtime Environment

#### Environment Variables

Several environment variables may need to be set at runtime:

- **LD_LIBRARY_PATH**: Path to shared libraries
- **NETCDF_ROOT**: Root directory of NetCDF installation
- **ESMF_RUNTIME_PROFILE**: Enable ESMF runtime profiling
- **MPIEXEC**: MPI execution command (for launching parallel jobs)

#### File System Access

- **Read Access**: Access to input data files
- **Write Access**: Access to output directory
- **Temporary Space**: Adequate temporary space for intermediate files

## Performance Considerations

### File System Requirements

For optimal performance:

- **Parallel File Systems**: Lustre, GPFS, BeeGFS recommended for large-scale runs
- **Local Storage**: SSD storage for small-scale testing
- **File Striping**: Appropriate file striping for parallel I/O
- **Metadata Performance**: High metadata performance for many-file operations

### Network Requirements

For parallel systems:

- **Bandwidth**: High network bandwidth for data movement
- **Latency**: Low network latency for synchronization
- **Congestion Control**: Proper congestion control for large jobs

## Container Support

### Docker

ESMF_IO can be containerized using Docker:

- **Base Images**: Ubuntu 20.04, CentOS 8, or Rocky Linux 8
- **Requirements**: Multi-stage builds for compilation/runtime
- **Size**: Approximately 2-4 GB for full installation

### Singularity

For HPC environments:

- **Images**: Singularity images built from Docker images
- **Security**: Unprivileged user namespaces
- **Mounts**: Proper mounting of filesystems for data access

## Cloud Computing Support

### Amazon Web Services (AWS)

- **Instances**: EC2 instances with EBS storage
- **File Systems**: Amazon FSx for Lustre recommended
- **Containers**: ECS/EKS for containerized deployments

### Microsoft Azure

- **Instances**: Virtual machines with premium storage
- **File Systems**: Azure HPC Cache or HPC File System
- **Containers**: Azure Container Instances or AKS

### Google Cloud Platform

- **Instances**: Compute Engine instances with persistent disks
- **File Systems**: Google Cloud Filestore or third-party solutions
- **Containers**: Google Kubernetes Engine

## Virtualization Support

### Virtual Machines

ESMF_IO runs in virtualized environments:

- **Hypervisors**: VMware ESXi, KVM, Hyper-V
- **Performance**: Paravirtualized drivers recommended
- **Limitations**: Potential I/O performance degradation

### Virtualization Platforms

- **VMware**: VMware Workstation/Fusion/ESXi
- **VirtualBox**: Oracle VM VirtualBox
- **Parallels**: Parallels Desktop (macOS)

## Testing Environment

### Continuous Integration

Supported CI platforms:

- **GitHub Actions**: Primary CI platform
- **GitLab CI**: Alternative CI platform
- **Jenkins**: On-premise CI solution

### Testing Matrix

CI testing covers:

- **Operating Systems**: Linux (Ubuntu, CentOS), macOS
- **Compilers**: GCC, Intel, NVIDIA HPC SDK
- **MPI Implementations**: Open MPI, MPICH
- **ESMF Versions**: Multiple ESMF releases
- **NetCDF Versions**: Multiple NetCDF releases

## Known Limitations

### Platform Limitations

- **Windows**: Limited native support
- **32-bit Systems**: Not supported
- **ARM Architecture**: Limited testing (except Apple Silicon)

### Performance Limitations

- **Serial I/O**: Performance limitations in serial mode
- **Small Grids**: Overhead may dominate for very small grids
- **Network Latency**: Performance sensitive to network latency

### Feature Limitations

- **File Formats**: Currently limited to NetCDF
- **Compression**: Limited compression options
- **Asynchronous I/O**: Not yet implemented

## Future Requirements

### Planned Enhancements

Future versions may require:

- **C++17**: For modern C++ features
- **Python 3.8+**: For enhanced scripting capabilities
- **WebAssembly**: For browser-based visualization
- **Quantum Computing**: Experimental quantum computing interfaces

This system requirements document provides a comprehensive overview of the hardware and software requirements for building and running the ESMF_IO Unified Component. Meeting these requirements ensures optimal performance and compatibility.