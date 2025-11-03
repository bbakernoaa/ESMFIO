# Single Model ESMF_IO NUOPC Example

This example demonstrates a complete single model NUOPC application that utilizes the ESMF_IO component. The example shows how to properly create and run an ESMF_IO component following NUOPC patterns.

## Overview

The Single Model ESMF_IO NUOPC Example implements a complete NUOPC application that:

- Creates a single ESMF_IO component
- Configures the component for both input (ExtData equivalent) and output (History equivalent) operations
- Demonstrates proper NUOPC component lifecycle management
- Shows how to integrate ESMF_IO with the NUOPC framework

## Files

- `Driver.F90`: Main driver program that creates and runs the ESMF_IO component
- `CMakeLists.txt`: Build system configuration for compiling the example
- `user_nl_esmf_io`: Configuration file for the ESMF_IO component
- `run.seq`: Run sequence file defining execution order
- `run_example.sh`: Script to build and run the example
- `README.md`: This documentation file

## Building the Example

To build the example:

```bash
mkdir build
cd build
cmake ../examples/SingleModelESMFIODemo
make
```

Alternatively, you can use the provided run script:

```bash
./run_example.sh build
```

## Running the Example

To run the example after building:

```bash
cd build
./esmf_io_single_model_demo
```

Or use the run script:

```bash
./run_example.sh run
```

## Configuration

The example uses the `user_nl_esmf_io` configuration file which defines:

### Input Stream Configuration
- **Stream Name**: METEOROLOGY_DATA
- **Fields**: air_temperature, eastward_wind, northward_wind
- **Data Source**: meteorology data files with hourly frequency
- **Time Range**: 2020-01-01 to 2020-01-02

### Output Collection Configuration
- **Collection Name**: HOURLY_OUTPUT
- **Fields**: pmsl (air pressure at sea level), rsns (surface net downward shortwave flux)
- **Output Frequency**: Hourly
- **File Format**: NetCDF

## NUOPC Patterns Demonstrated

This example demonstrates the following NUOPC patterns:

1. **Component Creation**: Creating a Grid Component and setting services
2. **Lifecycle Management**: Proper initialization, run, and finalization
3. **State Management**: Advertise and Realize import/export states
4. **Clock Integration**: Using ESMF Clock for time management
5. **Error Handling**: Proper ESMF error checking and reporting
6. **Grid Configuration**: Creating and managing grid objects for fields

## Expected Output

When running successfully, the example will:
1. Initialize the ESMF_IO component
2. Process input data according to configuration
3. Generate output files based on the output collection settings
4. Log execution progress and completion

## Troubleshooting

- Ensure ESMF and NUOPC libraries are properly installed and accessible
- Verify that the configuration file paths are correct
- Check that all required dependencies are available
- Review the log output for detailed error information

## Dependencies

- ESMF (Earth System Modeling Framework) library
- NUOPC (National Unified Operational Prediction Capability) layer
- ESMF_IO component library
- CMake build system
- Fortran compiler with ESMF support