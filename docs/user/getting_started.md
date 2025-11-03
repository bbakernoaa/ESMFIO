# Getting Started with ESMF_IO

This guide provides step-by-step instructions for getting started with the ESMF_IO Unified Component, from installation to your first successful run.

## Overview

ESMF_IO is a unified component that combines the functionality of both input (ExtData equivalent) and output (History equivalent) operations within a single ESMF-compliant component. This guide will walk you through installing, configuring, and using ESMF_IO in your Earth system modeling applications.

## Prerequisites

Before installing ESMF_IO, ensure you have the following software installed:

1. **Fortran Compiler**: A modern Fortran compiler (e.g., `gfortran`, `ifort`, `nvfortran`)
2. **CMake**: Version 3.10 or higher
3. **MPI Implementation**: An MPI library (e.g., Open MPI, MPICH, Intel MPI)
4. **ESMF Library**: The Earth System Modeling Framework must be installed and configured
5. **NetCDF Libraries**: Required for NetCDF file format support
6. **PNetCDF Libraries**: Optional but recommended for parallel NetCDF I/O

## Installation

### Downloading ESMF_IO

Clone the ESMF_IO repository from GitHub:

```bash
git clone https://github.com/bbakernoaa/ESMFIO.git
cd ESMF_IO
```

### Setting Environment Variables

Before building, you need to set several environment variables:

```bash
export ESMFMKFILE=/path/to/esmf/lib/esmf.mk
export NETCDF_ROOT=/path/to/netcdf
export PNETCDF_ROOT=/path/to/pnetcdf  # Optional
```

### Building ESMF_IO

ESMF_IO uses CMake for its build system. Create a build directory and configure the build:

```bash
mkdir build
cd build
cmake .. \
  -DCMAKE_Fortran_COMPILER=gfortran \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_NETCDF=ON \
  -DENABLE_PARALLEL_IO=ON
make -j$(nproc)
```

### Installing ESMF_IO

After building, install ESMF_IO to your desired location:

```bash
make install
```

By default, ESMF_IO will be installed to `/usr/local`. To specify a different installation directory:

```bash
cmake .. \
  -DCMAKE_INSTALL_PREFIX=/path/to/install/location \
  -DCMAKE_Fortran_COMPILER=gfortran \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_NETCDF=ON \
  -DENABLE_PARALLEL_IO=ON
make -j$(nproc)
make install
```

## Basic Configuration

### Creating a Configuration File

ESMF_IO uses ESMF's configuration system. Create a basic configuration file named `basic_config.rc`:

```
! Basic ESMF_IO configuration example

::IO_Settings
 DEBUG_LEVEL: 1
 IO_MODE: PARALLEL
::

::InputStream: METEOROLOGY
 NAME: meteorology
 DATAFILE: /data/meteorology_%y4%m2%d2.nc
 FILETYPE: netcdf
 MODE: read
 START_TIME: 2020-01-01_00:00:00
 END_TIME: 2020-12-31_23:59:59
 TIME_FREQUENCY: PT1H
 REFRESH: 0
 FIELD_COUNT: 3
 FIELD_1_NAME: temperature
 FIELD_1_UNITS: K
 FIELD_1_LONGNAME: Air Temperature
 FIELD_2_NAME: humidity
 FIELD_2_UNITS: percent
 FIELD_2_LONGNAME: Relative Humidity
 FIELD_3_NAME: pressure
 FIELD_3_UNITS: Pa
 FIELD_3_LONGNAME: Surface Pressure
::

::OutputCollection: HOURLY_OUTPUT
 NAME: hourly_output
 FILENAME_BASE: hourly_output
 FILETYPE: netcdf
 OUTPUT_FREQUENCY: PT1H
 DO_AVG: false
 FIELD_COUNT: 2
 FIELD_1_NAME: temperature
 FIELD_1_UNITS: K
 FIELD_1_LONGNAME: Air Temperature
 FIELD_2_NAME: humidity
 FIELD_2_UNITS: percent
 FIELD_2_LONGNAME: Relative Humidity
::
```

## Simple Usage Example

### Creating a Basic Program

Create a simple Fortran program named `simple_example.F90`:

```fortran
program simple_example
  use ESMF
  use ESMF_IO_Component_Mod

  implicit none

  integer :: rc
  type(ESMF_GridComp) :: io_component
  type(ESMF_State) :: importState, exportState
  type(ESMF_Clock) :: clock
  type(ESMF_Time) :: startTime, stopTime
  type(ESMF_TimeInterval) :: timeStep

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
  startTime = ESMF_TimeCreate("2020-01-01_00:00:00", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  stopTime = ESMF_TimeCreate("2020-01-01_06:00:00", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  timeStep = ESMF_TimeIntervalCreate("PT1H", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  clock = ESMF_ClockCreate(startTime=startTime, stopTime=stopTime, &
                           timeStep=timeStep, name="SimpleExampleClock", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Add configuration file to import state
  call ESMF_StateSet(importState, "ESMF_IO_ConfigFile", "basic_config.rc", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Initialize the ESMF_IO component
  call ESMF_IO_Initialize(io_component, importState, exportState, clock, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Run the ESMF_IO component for several time steps
  do while (.not. ESMF_ClockIsStopTime(clock))
    ! Run the component
    call ESMF_IO_Run(io_component, importState, exportState, clock, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
      call ESMF_Finalize(endflag=ESMF_END_ABORT)

    ! Advance the clock
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

end program simple_example
```

### Compiling the Example

Compile the example program with:

```bash
mpif90 simple_example.F90 \
  -I/path/to/esmf/include \
  -L/path/to/esmf/lib \
  -lesmf \
  -I/path/to/esmf_io/include \
  -L/path/to/esmf_io/lib \
  -lesmf_io \
  -o simple_example
```

### Running the Example

Run the example with:

```bash
mpirun -np 4 ./simple_example
```

## NUOPC Integration

### Creating a NUOPC Driver

ESMF_IO can be integrated into NUOPC-based applications. Create a NUOPC driver named `nuopc_driver.F90`:

```fortran
program nuopc_driver
  use ESMF
  use NUOPC
  use NUOPC_Driver_ESMF_IO

  implicit none

  integer :: rc
  type(ESMF_VM) :: vm
  type(ESMF_GridComp) :: driver

  ! Initialize ESMF
  call ESMF_Initialize(logKindFlag=ESMF_LOGKIND_MULTI, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Get the VM for logging
  call ESMF_VMGetCurrent(vm, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Create the driver component
  driver = ESMF_GridCompCreate("NUOPC_ESMF_IO_Driver", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Set the services for the driver
  call ESMF_GridCompSetServices(driver, NUOPC_SetServices, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Call the NUOPC driver execution
  call NUOPC_CompDeriveSetServices(driver, ESMF_CLOCK_DEFAULT, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Execute the driver
  call ESMF_GridCompRun(driver, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Destroy the driver
  call ESMF_GridCompDestroy(driver, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Finalize ESMF
  call ESMF_Finalize(rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    stop

end program nuopc_driver
```

## Advanced Configuration

### Complex Input Configuration

Create a more complex configuration file named `advanced_config.rc`:

```
! Advanced ESMF_IO configuration example

::IO_Settings
 DEBUG_LEVEL: 2
 IO_MODE: PARALLEL
::

::InputStream: METEOROLOGY
 NAME: meteorology
 DATAFILE: /data/meteo_%y4.nc
 FILETYPE: netcdf
 MODE: read
 START_TIME: 2020-01-01_00:00:00
 END_TIME: 2020-12-31_23:59:59
 TIME_FREQUENCY: P1D
 REFRESH: 0
 CLIMATOLOGY: true
 VALID_YEARS: 1980-2014
 EXTRAPOLATE: true
 FIELD_COUNT: 3
 FIELD_1_NAME: temperature
 FIELD_1_UNITS: K
 FIELD_1_LONGNAME: Air Temperature
 FIELD_2_NAME: humidity
 FIELD_2_UNITS: percent
 FIELD_2_LONGNAME: Relative Humidity
 FIELD_3_NAME: pressure
 FIELD_3_UNITS: Pa
 FIELD_3_LONGNAME: Surface Pressure
::

::InputStream: EMISSIONS
 NAME: emissions
 DATAFILE: /data/emissions_%y4%m2.nc
 FILETYPE: netcdf
 MODE: read
 START_TIME: 2020-01-01_00:00:00
 END_TIME: 2020-12-31_23:59:59
 TIME_FREQUENCY: P1M
 REFRESH: 0
 CLIMATOLOGY: false
 FIELD_COUNT: 2
 FIELD_1_NAME: co2_emissions
 FIELD_1_UNITS: kg/m2/s
 FIELD_1_LONGNAME: CO2 Surface Emissions
 FIELD_2_NAME: nox_emissions
 FIELD_2_UNITS: kg/m2/s
 FIELD_2_LONGNAME: NOx Surface Emissions
::

::OutputCollection: HOURLY_SNAPSHOTS
 NAME: hourly_snapshots
 FILENAME_BASE: hourly_snapshots
 FILETYPE: netcdf
 OUTPUT_FREQUENCY: PT1H
 DO_AVG: false
 FIELD_COUNT: 4
 FIELD_1_NAME: temperature
 FIELD_1_UNITS: K
 FIELD_1_LONGNAME: Air Temperature
 FIELD_2_NAME: humidity
 FIELD_2_UNITS: percent
 FIELD_2_LONGNAME: Relative Humidity
 FIELD_3_NAME: wind_u
 FIELD_3_UNITS: m/s
 FIELD_3_LONGNAME: Eastward Wind
 FIELD_4_NAME: wind_v
 FIELD_4_UNITS: m/s
 FIELD_4_LONGNAME: Northward Wind
::

::OutputCollection: DAILY_AVERAGES
 NAME: daily_averages
 FILENAME_BASE: daily_averages
 FILETYPE: netcdf
 OUTPUT_FREQUENCY: P1D
 DO_AVG: true
 DO_MAX: true
 DO_MIN: true
 FIELD_COUNT: 2
 FIELD_1_NAME: precipitation
 FIELD_1_UNITS: mm/day
 FIELD_1_LONGNAME: Daily Precipitation
 FIELD_2_NAME: cloud_cover
 FIELD_2_UNITS: percent
 FIELD_2_LONGNAME: Cloud Cover
::

::OutputCollection: MONTHLY_MAXIMUMS
 NAME: monthly_maximums
 FILENAME_BASE: monthly_maximums
 FILETYPE: netcdf
 OUTPUT_FREQUENCY: P1M
 DO_AVG: false
 DO_MAX: true
 FIELD_COUNT: 1
 FIELD_1_NAME: temperature_max
 FIELD_1_UNITS: K
 FIELD_1_LONGNAME: Monthly Maximum Temperature
::
```

## Testing Your Installation

### Running the Test Suite

ESMF_IO includes a comprehensive test suite. To run the tests:

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

## Troubleshooting

### Common Issues

#### ESMF Not Found

If you encounter errors about ESMF not being found:

1. Verify that `ESMFMKFILE` environment variable is set correctly
2. Check that ESMF was built with the same compiler and MPI implementation
3. Ensure that ESMF libraries are in your library path

#### NetCDF Errors

If you encounter NetCDF-related errors:

1. Verify that NetCDF libraries are installed
2. Check that NetCDF was built with the same compiler
3. Ensure that NetCDF libraries are in your library path

#### MPI Issues

If you encounter MPI-related issues:

1. Verify that MPI is installed and in your PATH
2. Check that MPI was built with the same compiler
3. Ensure that MPI libraries are in your library path

#### Configuration Errors

If you encounter configuration-related errors:

1. Verify that your configuration file syntax is correct
2. Check that all required parameters are present
3. Ensure that file paths are correct and accessible

### Getting Help

If you need help with ESMF_IO:

1. **Documentation**: Check the official documentation at [ESMF_IO Documentation](https://esmf-io.readthedocs.io)
2. **GitHub Issues**: Report bugs or request features at [ESMF_IO GitHub Issues](https://github.com/bbakernoaa/ESMFIO/issues)
3. **Discussion Forum**: Join discussions at [ESMF_IO Discussion Forum](https://github.com/bbakernoaa/ESMFIO/discussions)
4. **Email Support**: Contact the development team at esmf-io-support@ucar.edu

## Next Steps

After successfully installing and running ESMF_IO:

1. **Explore Examples**: Review the examples in the `examples/` directory
2. **Read Documentation**: Dive deeper into the user and developer documentation
3. **Run Tests**: Execute the full test suite to verify your installation
4. **Customize Configuration**: Modify the configuration to suit your specific needs
5. **Integrate with Models**: Integrate ESMF_IO with your Earth system model

This getting started guide provides the foundation for using the ESMF_IO Unified Component in your Earth system modeling applications. With its unified approach to input and output operations, ESMF_IO simplifies data management while providing high performance and flexibility.
