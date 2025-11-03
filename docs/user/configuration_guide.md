# Configuration Guide

This guide explains how to configure the ESMF_IO Unified Component for your Earth system modeling application.

## Overview

The ESMF_IO component uses a YAML-based configuration system that combines both input (ExtData equivalent) and output (History equivalent) functionality in a single configuration file.

## Configuration File Structure

A typical ESMF_IO configuration file has the following structure:

```yaml
# Global settings
IO_Settings:
  DEBUG_LEVEL: 0
  IO_MODE: PARALLEL

# Input stream configurations (ExtData equivalent)
InputStreams:
  - NAME: meteorology
    DATAFILE: /path/to/meteorology_data.nc
    FILETYPE: netcdf
    MODE: read
    START_TIME: 2020-01-01_00:00:00
    END_TIME: 2020-12-31_23:59:59
    TIME_FREQUENCY: PT1H
    REFRESH: 0
    CONSERVATIVE: false
    FIELD_COUNT: 3
    FIELDS:
      - NAME: temperature
        UNITS: K
        LONGNAME: Air Temperature
      - NAME: humidity
        UNITS: percent
        LONGNAME: Relative Humidity
      - NAME: pressure
        UNITS: Pa
        LONGNAME: Surface Pressure

# Output collection configurations (History equivalent)
OutputCollections:
  - NAME: hourly_data
    FILENAME_BASE: hourly_output
    FILETYPE: netcdf
    OUTPUT_FREQUENCY: PT1H
    DO_AVG: false
    FIELD_COUNT: 4
    FIELDS:
      - NAME: temperature
        UNITS: K
        LONGNAME: Air Temperature
      - NAME: humidity
        UNITS: percent
        LONGNAME: Relative Humidity
      - NAME: wind_u
        UNITS: m/s
        LONGNAME: Eastward Wind
      - NAME: wind_v
        UNITS: m/s
        LONGNAME: Northward Wind
```

## Global Settings

Global settings control the overall behavior of the ESMF_IO component:

| Parameter | Description | Default Value | Possible Values |
|-----------|-------------|---------------|------------------|
| DEBUG_LEVEL | Controls the verbosity of debug output | 0 | 0-3 |
| IO_MODE | Specifies the I/O mode | PARALLEL | SERIAL, PARALLEL |

## Input Stream Configuration

Input streams configure data ingestion functionality (equivalent to ExtData):

### Basic Parameters

| Parameter | Description | Required | Example |
|-----------|-------------|----------|---------|
| NAME | Unique identifier for the input stream | Yes | "meteorology" |
| DATAFILE | Path to the data file (can include time tokens) | Yes | "/data/met_%y4%m2%d2.nc" |
| FILETYPE | Type of data file | Yes | "netcdf" |
| MODE | I/O mode | Yes | "read" |
| START_TIME | Start time for the data stream | Yes | "2020-01-01_00:00:00" |
| END_TIME | End time for the data stream | Yes | "2020-12-31_23:59:59" |
| TIME_FREQUENCY | Time frequency of data in the file | Yes | "PT1H" |
| REFRESH | Temporal processing mode | No | 0 |
| CONSERVATIVE | Spatial regridding method | No | false |
| VALID_YEARS | Valid years for climatological data | No | "1980-2014" |
| EXTRAPOLATE | Enable extrapolation for out-of-range years | No | true |

### Field Configuration

Each input stream can contain multiple fields:

| Parameter | Description | Required | Example |
|-----------|-------------|----------|---------|
| NAME | Field name | Yes | "temperature" |
| UNITS | Physical units | No | "K" |
| LONGNAME | Descriptive name | No | "Air Temperature" |

## Output Collection Configuration

Output collections configure data output functionality (equivalent to History):

### Basic Parameters

| Parameter | Description | Required | Example |
|-----------|-------------|----------|---------|
| NAME | Unique identifier for the output collection | Yes | "hourly_data" |
| FILENAME_BASE | Base name for output files | Yes | "output" |
| FILETYPE | Type of output file | Yes | "netcdf" |
| OUTPUT_FREQUENCY | How often to write output | Yes | "PT1H" |
| DO_AVG | Enable time averaging | No | false |
| DO_MAX | Enable time maximum | No | false |
| DO_MIN | Enable time minimum | No | false |

### Field Configuration

Each output collection can contain multiple fields:

| Parameter | Description | Required | Example |
|-----------|-------------|----------|---------|
| NAME | Field name | Yes | "temperature" |
| UNITS | Physical units | No | "K" |
| LONGNAME | Descriptive name | No | "Air Temperature" |

## Time Tokens

ESMF_IO supports time tokens in file paths for dynamic file naming:

| Token | Description | Example |
|-------|-------------|---------|
| %y4 | 4-digit year | 2020 |
| %m2 | 2-digit month | 01 |
| %d2 | 2-digit day | 15 |
| %h2 | 2-digit hour | 12 |
| %n2 | 2-digit minute | 30 |
| %s2 | 2-digit second | 45 |

## Example Configurations

### Simple Input Configuration

```yaml
IO_Settings:
  DEBUG_LEVEL: 1
  IO_MODE: PARALLEL

InputStreams:
  - NAME: boundary_conditions
    DATAFILE: /data/bc_%y4%m2%d2.nc
    FILETYPE: netcdf
    MODE: read
    START_TIME: 2020-01-01_00:00:00
    END_TIME: 2020-12-31_23:59:59
    TIME_FREQUENCY: PT3H
    REFRESH: 0
    FIELD_COUNT: 2
    FIELDS:
      - NAME: u_wind
        UNITS: m/s
        LONGNAME: Zonal Wind
      - NAME: v_wind
        UNITS: m/s
        LONGNAME: Meridional Wind
```

### Time-Averaged Output Configuration

```yaml
IO_Settings:
  DEBUG_LEVEL: 0
  IO_MODE: PARALLEL

OutputCollections:
  - NAME: daily_averages
    FILENAME_BASE: daily_avg
    FILETYPE: netcdf
    OUTPUT_FREQUENCY: P1D
    DO_AVG: true
    FIELD_COUNT: 1
    FIELDS:
      - NAME: precipitation
        UNITS: mm/day
        LONGNAME: Daily Precipitation
```

## Best Practices

1. **Use Absolute Paths**: For production runs, use absolute paths for data files to avoid issues with working directory changes.

2. **Validate Configuration**: Always validate your configuration file before running simulations.

3. **Monitor Disk Space**: Output collections can generate large amounts of data; monitor disk space during long runs.

4. **Optimize Time Frequencies**: Balance output frequency with storage requirements and analysis needs.

5. **Use Appropriate Regridding**: Choose conservative regridding for flux variables and bilinear for state variables.