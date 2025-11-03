# Installation Guide

This guide provides detailed instructions for installing the ESMF_IO Unified Component on various platforms and configurations.

## Overview

ESMF_IO can be installed on a variety of systems ranging from personal computers to large-scale supercomputers. This guide covers the installation process for different environments and configurations.

## Prerequisites

Before installing ESMF_IO, ensure you have the following prerequisites installed:

1. **Fortran Compiler**: A modern Fortran compiler (e.g., `gfortran`, `ifort`, `nvfortran`)
2. **CMake**: Version 3.10 or higher
3. **MPI Implementation**: An MPI library (e.g., Open MPI, MPICH, Intel MPI)
4. **ESMF Library**: The Earth System Modeling Framework must be installed and configured
5. **NetCDF Libraries**: Required for NetCDF file format support
6. **PNetCDF Libraries**: Optional but recommended for parallel NetCDF I/O

## System-Specific Installation

### Linux Installation

#### Ubuntu/Debian

1. **Install System Dependencies**:
   ```bash
   sudo apt update
   sudo apt install build-essential cmake gfortran mpich libmpich-dev \
                    libnetcdf-dev libnetcdff-dev libpnetcdf-dev
   ```

2. **Install ESMF**:
   ```bash
   wget https://github.com/esmf-org/esmf/archive/refs/tags/ESMF_8_2_0.tar.gz
   tar -xzf ESMF_8_2_0.tar.gz
   cd esmf-ESMF_8_2_0
   export ESMF_DIR=$PWD
   export ESMF_COMM=mpich
   export ESMF_NETCDF=nc-config
   export ESMF_PNETCDF=pnetcdf-config
   make -j$(nproc)
   ```

3. **Install ESMF_IO**:
   ```bash
   git clone https://github.com/bbakernoaa/ESMFIO.git
   cd ESMF_IO
   mkdir build
   cd build
   cmake .. \
     -DCMAKE_Fortran_COMPILER=mpif90 \
     -DCMAKE_BUILD_TYPE=Release \
     -DENABLE_NETCDF=ON \
     -DENABLE_PARALLEL_IO=ON
   make -j$(nproc)
   sudo make install
   ```

#### CentOS/RHEL/Rocky Linux

1. **Install System Dependencies**:
   ```bash
   sudo yum install epel-release
   sudo yum install gcc gcc-gfortran cmake mpich mpich-devel \
                    netcdf-devel netcdf-fortran-devel pnetcdf-devel
   ```

2. **Install ESMF**:
   ```bash
   wget https://github.com/esmf-org/esmf/archive/refs/tags/ESMF_8_2_0.tar.gz
   tar -xzf ESMF_8_2_0.tar.gz
   cd esmf-ESMF_8_2_0
   export ESMF_DIR=$PWD
   export ESMF_COMM=mpich
   export ESMF_NETCDF=nc-config
   export ESMF_PNETCDF=pnetcdf-config
   make -j$(nproc)
   ```

3. **Install ESMF_IO**:
   ```bash
   git clone https://github.com/bbakernoaa/ESMFIO.git
   cd ESMF_IO
   mkdir build
   cd build
   cmake .. \
     -DCMAKE_Fortran_COMPILER=mpif90 \
     -DCMAKE_BUILD_TYPE=Release \
     -DENABLE_NETCDF=ON \
     -DENABLE_PARALLEL_IO=ON
   make -j$(nproc)
   sudo make install
   ```

### macOS Installation

#### Using Homebrew

1. **Install System Dependencies**:
   ```bash
   brew install cmake gcc mpich netcdf pnetcdf
   ```

2. **Install ESMF**:
   ```bash
   wget https://github.com/esmf-org/esmf/archive/refs/tags/ESMF_8_2_0.tar.gz
   tar -xzf ESMF_8_2_0.tar.gz
   cd esmf-ESMF_8_2_0
   export ESMF_DIR=$PWD
   export ESMF_COMM=mpich
   export ESMF_NETCDF=nc-config
   make -j$(sysctl -n hw.ncpu)
   ```

3. **Install ESMF_IO**:
   ```bash
   git clone https://github.com/bbakernoaa/ESMFIO.git
   cd ESMF_IO
   mkdir build
   cd build
   cmake .. \
     -DCMAKE_Fortran_COMPILER=mpif90 \
     -DCMAKE_BUILD_TYPE=Release \
     -DENABLE_NETCDF=ON \
     -DENABLE_PARALLEL_IO=ON
   make -j$(sysctl -n hw.ncpu)
   sudo make install
   ```

### HPC Cluster Installation

#### Generic HPC Installation

1. **Load Required Modules**:
   ```bash
   module load cmake
   module load intel/mpi
   module load netcdf
   module load pnetcdf
   module load esmf
   ```

2. **Set Environment Variables**:
   ```bash
   export ESMFMKFILE=$ESMF_ROOT/lib/esmf.mk
   export NETCDF_ROOT=$(dirname $(dirname $(which nc-config)))
   export PNETCDF_ROOT=$(dirname $(dirname $(which pnetcdf-config)))
   ```

3. **Install ESMF_IO**:
   ```bash
   git clone https://github.com/bbakernoaa/ESMFIO.git
   cd ESMF_IO
   mkdir build
   cd build
   cmake .. \
     -DCMAKE_Fortran_COMPILER=mpif90 \
     -DCMAKE_BUILD_TYPE=Release \
     -DENABLE_NETCDF=ON \
     -DENABLE_PARALLEL_IO=ON
   make -j$PBS_NUM_PPN
   make install
   ```

#### Specific Cluster Examples

##### NCAR Cheyenne

```bash
# Load modules
module load cmake/3.18.2
module load intel/19.0.5
module load mpt/2.22
module load netcdf/4.7.4
module load pnetcdf/1.12.1
module load esmf/8.2.0

# Set environment
export ESMFMKFILE=$ESMF_ROOT/lib/esmf.mk
export NETCDF_ROOT=$NETCDF
export PNETCDF_ROOT=$PNETCDF

# Build ESMF_IO
git clone https://github.com/bbakernoaa/ESMFIO.git
cd ESMF_IO
mkdir build
cd build
cmake .. \
  -DCMAKE_Fortran_COMPILER=mpif90 \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_NETCDF=ON \
  -DENABLE_PARALLEL_IO=ON
make -j 36
make install
```

##### NASA Pleiades

```bash
# Load modules
module load cmake/3.18.2
module load intel/2020
module load mpi-hpe/mpt.2.25
module load netcdf/4.7.4
module load pnetcdf/1.12.2
module load esmf/8.2.0

# Set environment
export ESMFMKFILE=$ESMF_ROOT/lib/esmf.mk
export NETCDF_ROOT=$NETCDF
export PNETCDF_ROOT=$PNETCDF

# Build ESMF_IO
git clone https://github.com/bbakernoaa/ESMFIO.git
cd ESMF_IO
mkdir build
cd build
cmake .. \
  -DCMAKE_Fortran_COMPILER=mpif90 \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_NETCDF=ON \
  -DENABLE_PARALLEL_IO=ON
make -j 24
make install
```

## Container Installation

### Docker Installation

1. **Create Dockerfile**:
   ```dockerfile
   FROM ubuntu:20.04
   
   # Install system dependencies
   RUN apt-get update && apt-get install -y \
       build-essential \
       cmake \
       gfortran \
       mpich \
       libmpich-dev \
       libnetcdf-dev \
       libnetcdff-dev \
       libpnetcdf-dev \
       wget \
       git \
       && rm -rf /var/lib/apt/lists/*
   
   # Install ESMF
   RUN wget https://github.com/esmf-org/esmf/archive/refs/tags/ESMF_8_2_0.tar.gz && \
       tar -xzf ESMF_8_2_0.tar.gz && \
       cd esmf-ESMF_8_2_0 && \
       export ESMF_DIR=$PWD && \
       export ESMF_COMM=mpich && \
       export ESMF_NETCDF=nc-config && \
       make -j$(nproc) && \
       cd ..
   
   # Clone and build ESMF_IO
   RUN git clone https://github.com/bbakernoaa/ESMFIO.git && \
       cd ESMF_IO && \
       mkdir build && \
       cd build && \
       cmake .. \
         -DCMAKE_Fortran_COMPILER=mpif90 \
         -DCMAKE_BUILD_TYPE=Release \
         -DENABLE_NETCDF=ON \
         -DENABLE_PARALLEL_IO=ON && \
       make -j$(nproc) && \
       make install
   
   WORKDIR /app
   ```

2. **Build Docker Image**:
   ```bash
   docker build -t esmf_io .
   ```

3. **Run Docker Container**:
   ```bash
   docker run -it esmf_io
   ```

### Singularity Installation

1. **Create Singularity Definition File**:
   ```singularity
   Bootstrap: docker
   From: ubuntu:20.04
   
   %post
       apt-get update && apt-get install -y \
           build-essential \
           cmake \
           gfortran \
           mpich \
           libmpich-dev \
           libnetcdf-dev \
           libnetcdff-dev \
           libpnetcdf-dev \
           wget \
           git \
           && rm -rf /var/lib/apt/lists/*
       
       # Install ESMF
       wget https://github.com/esmf-org/esmf/archive/refs/tags/ESMF_8_2_0.tar.gz
       tar -xzf ESMF_8_2_0.tar.gz
       cd esmf-ESMF_8_2_0
       export ESMF_DIR=$PWD
       export ESMF_COMM=mpich
       export ESMF_NETCDF=nc-config
       make -j$(nproc)
       cd ..
       
       # Clone and build ESMF_IO
       git clone https://github.com/bbakernoaa/ESMFIO.git
       cd ESMF_IO
       mkdir build
       cd build
       cmake .. \
         -DCMAKE_Fortran_COMPILER=mpif90 \
         -DCMAKE_BUILD_TYPE=Release \
         -DENABLE_NETCDF=ON \
         -DENABLE_PARALLEL_IO=ON
       make -j$(nproc)
       make install
       
       # Cleanup
       cd ../..
       rm -rf esmf-ESMF_8_2_0 ESMF_8_2_0.tar.gz ESMF_IO
   
   %environment
       export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
       
   %runscript
       echo "ESMF_IO Container"
       exec "$@"
   ```

2. **Build Singularity Image**:
   ```bash
   singularity build esmf_io.sif Singularity
   ```

3. **Run Singularity Container**:
   ```bash
   singularity run esmf_io.sif
   ```

## Cloud Installation

### Amazon Web Services (AWS)

#### Using AWS ParallelCluster

1. **Create Cluster Configuration**:
   ```yaml
   # cluster-config.yaml
   Region: us-west-2
   Image:
     Os: alinux2
   HeadNode:
     InstanceType: c5.xlarge
     Networking:
       SubnetId: subnet-12345678
     Ssh:
       KeyName: my-key-pair
   Scheduling:
     Scheduler: slurm
     SlurmQueues:
       - Name: queue1
         ComputeResources:
           - Name: compute-resource-1
             InstanceType: c5.xlarge
             MinCount: 0
             MaxCount: 10
   ```

2. **Deploy Cluster**:
   ```bash
   pcluster create-cluster --cluster-name esmf-io-cluster --cluster-configuration file://cluster-config.yaml
   ```

3. **Install ESMF_IO on Cluster**:
   ```bash
   # SSH to head node
   pcluster ssh --cluster-name esmf-io-cluster -i ~/.ssh/my-key-pair
   
   # Install dependencies
   sudo yum install -y cmake gcc gcc-gfortran mpich mpich-devel \
                       netcdf-devel netcdf-fortran-devel pnetcdf-devel
   
   # Install ESMF
   wget https://github.com/esmf-org/esmf/archive/refs/tags/ESMF_8_2_0.tar.gz
   tar -xzf ESMF_8_2_0.tar.gz
   cd esmf-ESMF_8_2_0
   export ESMF_DIR=$PWD
   export ESMF_COMM=mpich
   export ESMF_NETCDF=nc-config
   make -j$(nproc)
   cd ..
   
   # Install ESMF_IO
   git clone https://github.com/bbakernoaa/ESMFIO.git
   cd ESMF_IO
   mkdir build
   cd build
   cmake .. \
     -DCMAKE_Fortran_COMPILER=mpif90 \
     -DCMAKE_BUILD_TYPE=Release \
     -DENABLE_NETCDF=ON \
     -DENABLE_PARALLEL_IO=ON
   make -j$(nproc)
   sudo make install
   ```

### Google Cloud Platform (GCP)

#### Using Google Cloud Shell

1. **Create Compute Engine Instance**:
   ```bash
   gcloud compute instances create esmf-io-instance \
     --zone=us-central1-a \
     --machine-type=n1-standard-4 \
     --image-family=ubuntu-2004-lts \
     --image-project=ubuntu-os-cloud \
     --boot-disk-size=50GB
   ```

2. **SSH to Instance**:
   ```bash
   gcloud compute ssh esmf-io-instance --zone=us-central1-a
   ```

3. **Install Dependencies**:
   ```bash
   sudo apt update
   sudo apt install -y build-essential cmake gfortran mpich libmpich-dev \
                       libnetcdf-dev libnetcdff-dev libpnetcdf-dev
   
   # Install ESMF
   wget https://github.com/esmf-org/esmf/archive/refs/tags/ESMF_8_2_0.tar.gz
   tar -xzf ESMF_8_2_0.tar.gz
   cd esmf-ESMF_8_2_0
   export ESMF_DIR=$PWD
   export ESMF_COMM=mpich
   export ESMF_NETCDF=nc-config
   make -j$(nproc)
   cd ..
   
   # Install ESMF_IO
   git clone https://github.com/bbakernoaa/ESMFIO.git
   cd ESMF_IO
   mkdir build
   cd build
   cmake .. \
     -DCMAKE_Fortran_COMPILER=mpif90 \
     -DCMAKE_BUILD_TYPE=Release \
     -DENABLE_NETCDF=ON \
     -DENABLE_PARALLEL_IO=ON
   make -j$(nproc)
   sudo make install
   ```

## Advanced Installation Options

### Custom Installation Prefix

To install ESMF_IO to a custom location:

```bash
mkdir build
cd build
cmake .. \
  -DCMAKE_INSTALL_PREFIX=/path/to/custom/install/location \
  -DCMAKE_Fortran_COMPILER=mpif90 \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_NETCDF=ON \
  -DENABLE_PARALLEL_IO=ON
make -j$(nproc)
make install
```

### Debug Build

For development and debugging:

```bash
mkdir build_debug
cd build_debug
cmake .. \
  -DCMAKE_Fortran_COMPILER=mpif90 \
  -DCMAKE_BUILD_TYPE=Debug \
  -DENABLE_NETCDF=ON \
  -DENABLE_PARALLEL_IO=ON \
  -DENABLE_TESTS=ON
make -j$(nproc)
```

### Optimized Build

For production performance:

```bash
mkdir build_optimized
cd build_optimized
cmake .. \
  -DCMAKE_Fortran_COMPILER=mpif90 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_Fortran_FLAGS="-O3 -march=native -funroll-loops" \
  -DENABLE_NETCDF=ON \
  -DENABLE_PARALLEL_IO=ON \
  -DENABLE_TESTS=ON
make -j$(nproc)
```

### Cross-Compilation

For cross-compilation to different architectures:

```bash
mkdir build_cross
cd build_cross
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=/path/to/toolchain.cmake \
  -DCMAKE_Fortran_COMPILER=mpif90 \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_NETCDF=ON \
  -DENABLE_PARALLEL_IO=ON
make -j$(nproc)
```

## Verification

### Testing Installation

After installation, verify the installation by running the test suite:

```bash
cd build
make test
```

Or run the test executable directly:

```bash
./esmf_io_test_runner
```

### Expected Test Output

Successful test output should look similar to:

```
==================================================
ESMF_IO Unified Component Test Suite
==================================================

Running Unit Tests...
----------------------------------------
  Running test for: ESMF_IO_Component_Mod
  Running test for: ESMF_IO_Config_Mod
  Running test for: ESMF_IO_Input_Mod
  Running test for: ESMF_IO_Output_Mod
  Running test for: ESMF_IO_Parallel_Mod

Running Integration Tests...
----------------------------------------
...

==================================================
Test Summary
==================================================
Total Tests Run:      45
Tests Passed:        45
Tests Failed:        0
Tests Skipped:       0
Success Rate:        100.0 %
Total Time:          12.34 seconds

==================================================
ALL TESTS PASSED!
==================================================
```

### Simple Test Program

Create a simple test program to verify the installation:

```fortran
program test_installation
  use ESMF
  use ESMF_IO_Component_Mod

  implicit none

  integer :: rc

  ! Initialize ESMF
  call ESMF_Initialize(logKindFlag=ESMF_LOGKIND_MULTI, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  print *, "ESMF_IO installation verified successfully!"

  ! Finalize ESMF
  call ESMF_Finalize(rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    stop

end program test_installation
```

Compile and run the test program:

```bash
mpif90 test_installation.F90 \
  -I/usr/local/include \
  -L/usr/local/lib \
  -lesmf_io -lesmf \
  -o test_installation

mpirun -np 1 ./test_installation
```

## Troubleshooting

### Common Installation Issues

#### Missing Dependencies

If you encounter errors about missing dependencies:

1. **Verify Dependencies**: Ensure all required dependencies are installed
2. **Check Versions**: Verify that dependency versions meet minimum requirements
3. **Environment Variables**: Ensure environment variables are set correctly

#### Compiler Incompatibilities

If you encounter compiler-related issues:

1. **Consistent Compiler**: Ensure all dependencies are built with the same compiler
2. **MPI Compatibility**: Verify MPI implementation compatibility
3. **Fortran Standards**: Ensure compiler supports required Fortran standards

#### Linking Errors

If you encounter linking errors:

1. **Library Paths**: Verify that library paths are correctly specified
2. **Library Order**: Ensure libraries are linked in the correct order
3. **Missing Libraries**: Check for missing dependencies

#### Runtime Errors

If you encounter runtime errors:

1. **Shared Libraries**: Ensure shared libraries are in the library path
2. **Environment Variables**: Verify that environment variables are set correctly
3. **File Permissions**: Check file permissions for installed files

### Getting Help

If you need help with installation:

1. **Documentation**: Check the official documentation
2. **GitHub Issues**: Report bugs or request features at [ESMF_IO GitHub Issues](https://github.com/bbakernoaa/ESMFIO/issues)
3. **Discussion Forum**: Join discussions at [ESMF_IO Discussion Forum](https://github.com/bbakernoaa/ESMFIO/discussions)
4. **Email Support**: Contact the development team at esmf-io-support@ucar.edu

## Post-Installation Configuration

### Environment Setup

After installation, set up your environment:

```bash
# Add to your .bashrc or .bash_profile
export ESMF_IO_ROOT=/usr/local
export PATH=$ESMF_IO_ROOT/bin:$PATH
export LD_LIBRARY_PATH=$ESMF_IO_ROOT/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$ESMF_IO_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH
```

### Module Files (HPC Environments)

For HPC environments using environment modules:

```tcl
# ESMF_IO module file
#%Module1.0
##
## ESMF_IO Module
##
proc ModulesHelp { } {
    puts stderr "ESMF_IO - Unified I/O Component for Earth System Models"
}

module-whatis "ESMF_IO - Unified ISMF_IO Component for Earth System Models"

set root /usr/local

prepend-path PATH $root/bin
prepend-path LD_LIBRARY_PATH $root/lib
prepend-path PKG_CONFIG_PATH $root/lib/pkgconfig
prepend-path CMAKE_PREFIX_PATH $root

setenv ESMF_IO_ROOT $root
```

This installation guide provides comprehensive instructions for installing the ESMF_IO Unified Component on various platforms and configurations. Following these instructions will help ensure a successful installation and proper functioning of the component.