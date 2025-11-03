# Configuration Parameters

This document provides a comprehensive reference for all configuration parameters available in the ESMF_IO Unified Component.

## Overview

ESMF_IO uses ESMF's built-in configuration system with a hierarchical structure. Configuration parameters are organized into sections that control different aspects of the component's behavior. The system now uses configurable defaults to eliminate hardcoded values and improve maintainability.

## Global Settings

Global settings control the overall behavior of the ESMF_IO component.

| Parameter | Description | Default Value | Possible Values |
|-----------|-------------|---------------|------------------|
| DEBUG_LEVEL | Controls the verbosity of debug output | 0 | 0-3 |
| IO_MODE | Specifies the I/O mode | PARALLEL | SERIAL, PARALLEL |

## Configuration Defaults System

The ESMF_IO component now uses a configurable defaults system to eliminate hardcoded values. These can be customized by modifying the `ESMF_IO_Config_Params_Mod` module.

### Default Values

The following defaults are available:

- **Configuration File**: `esmf_io_config.rc`
- **Input Filetype**: `netcdf`
- **Input Mode**: `read`
- **Calendar**: `1` (ESMF_CALKIND_GREGORIAN)
- **Climatology**: `.false.`
- **Regrid Method**: `0`
- **Regrid File**: `""`
- **Output Filetype**: `netcdf`
- **Filename Base**: `output`
- **Append Packed Files**: `.false.`
- **Do Average**: `.true.`
- **Do Max**: `.false.`
- **Do Min**: `.false.`
- **Field Levels**: `-1`
- **Field Time Average**: `.false.`

## Input Stream Configuration

Input stream configuration controls the behavior of input data streams (equivalent to ExtData functionality).

### Required Parameters

| Parameter | Description | Example Value |
|-----------|-------------|---------------|
| NAME | Unique name for the input stream | `meteorology` |
| DATAFILE | Path to the input data file | `/path/to/data.nc` |

### Optional Parameters

| Parameter | Description | Default Value | Example Value |
|-----------|-------------|---------------|---------------|
| FILETYPE | Type of input file | `netcdf` | `netcdf`, `binary` |
| MODE | Read mode | `read` | `read`, `read_write` |
| START_TIME | Start time for data | Configurable | `2020-01-01_00:00:00` |
| END_TIME | End time for data | Configurable | `2020-12-31_23:59:59` |
| TIME_FREQUENCY | Time frequency for data | Configurable | `PT1H`, `P1D` |
| TIME_OFFSET | Time offset | Configurable | `PT0H` |
| CALENDAR | Calendar type | Configurable | `GREGORIAN`, `NO_LEAP` |
| CLIMATOLOGY | Climatology flag | Configurable | `true`, `false` |
| REGRID_METHOD | Regridding method | Configurable | `0`, `1`, `2` |
| REGRID_FILE | Regridding weights file | Configurable | `/path/to/weights.nc` |

### Field Configuration

Input streams can define multiple fields with the following parameters:

| Parameter | Description | Default Value | Example Value |
|-----------|-------------|---------------|---------------|
| FIELD_n_NAME | Name of field n | Required | `temperature` |
| FIELD_n_UNITS | Units of field n | Optional | `K`, `m/s` |
| FIELD_n_LONGNAME | Long name of field n | Optional | `Air Temperature` |
| FIELD_n_LEVELS | Number of vertical levels | Configurable | `1`, `32` |
| FIELD_n_TIME_AVG | Time averaging flag | Configurable | `true`, `false` |

## Output Collection Configuration

Output collection configuration controls the behavior of output data collections (equivalent to History functionality).

### Required Parameters

| Parameter | Description | Example Value |
|-----------|-------------|---------------|
| NAME | Unique name for the output collection | `hourly_data` |
| FILENAME_BASE | Base name for output files | `output` |

### Optional Parameters

| Parameter | Description | Default Value | Example Value |
|-----------|-------------|---------------|---------------|
| FILETYPE | Type of output file | `netcdf` | `netcdf`, `binary` |
| OUTPUT_FREQUENCY | Output frequency | Configurable | `PT1H`, `P6H` |
| TIME_AXIS_OFFSET | Time axis offset | Configurable | `PT0H`, `PT30M` |
| APPEND_PACKED_FILES | Append packed files flag | Configurable | `true`, `false` |
| DO_AVG | Perform averaging | Configurable | `true`, `false` |
| DO_MAX | Perform maximum calculation | Configurable | `true`, `false` |
| DO_MIN | Perform minimum calculation | Configurable | `true`, `false` |

### Field Configuration

Output collections can define multiple fields with the following parameters:

| Parameter | Description | Default Value | Example Value |
|-----------|-------------|---------------|---------------|
| FIELD_n_NAME | Name of field n | Required | `temperature` |
| FIELD_n_UNITS | Units of field n | Optional | `K`, `m/s` |
| FIELD_n_LONGNAME | Long name of field n | Optional | `Air Temperature` |
| FIELD_n_LEVELS | Number of vertical levels | Configurable | `1`, `32` |

## Configuration File Format

Configuration files use the ESMF configuration format with labeled sections:

```
! Global settings
::IO_Settings
  DEBUG_LEVEL: 1
 IO_MODE: PARALLEL
::END

! Input stream configuration
::InputStream: STREAM_NAME
  NAME: stream_name
 DATAFILE: /path/to/data.nc
  FILETYPE: netcdf
  ...
::END

! Output collection configuration
::OutputCollection: COLLECTION_NAME
 NAME: collection_name
  FILENAME_BASE: output
  ...
::END
```

## Error Handling

The configuration system implements comprehensive error handling:

1. **Missing Required Parameters**: The system will generate an error if required parameters are not provided.

2. **File Not Found**: The system checks for the existence of specified configuration and data files.

3. **Invalid Values**: The system validates parameter values and provides meaningful error messages.

4. **Validation**: The system can perform strict validation of configuration parameters if enabled.

## Best Practices

1. **Use Descriptive Names**: Use descriptive names for streams and collections to improve readability.

2. **Validate Configuration**: Always validate configuration files before using them in production runs.

3. **Document Non-Standard Values**: Document any non-standard parameter values or combinations.

4. **Use Default Values**: Leverage the configurable defaults system rather than hardcoding values.

5. **Test Configurations**: Test configurations with validation tools before deployment.

## Maintainability

1. **Modular Configuration**: Break complex configurations into logical sections
2. **Parameter Documentation**: Document non-obvious parameter choices
3. **Template Usage**: Use templates for common configuration patterns
4. **Validation Testing**: Test configurations with validation tools

This configuration parameters reference provides a comprehensive guide to all available configuration options in the ESMF_IO Unified Component. Proper configuration is essential for optimal performance and correct operation.