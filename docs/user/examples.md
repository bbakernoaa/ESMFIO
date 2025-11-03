# Usage Examples

This section provides practical examples of how to use the ESMF_IO Unified Component in various scenarios.

## Basic Usage Example

This example demonstrates the basic usage of ESMF_IO for simple input and output operations.

### Configuration File

First, create a configuration file named `basic_example_config.rc`:

```
! Basic ESMF_IO configuration example
! This demonstrates simple input and output operations

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

### Fortran Program

Next, create a Fortran program named `basic_example.F90`:

```fortran
program basic_example
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
                           timeStep=timeStep, name="BasicExampleClock", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Add configuration file to import state
  call ESMF_StateSet(importState, "ESMF_IO_ConfigFile", "basic_example_config.rc", rc=rc)
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

end program basic_example
```

### Compilation

To compile this example, use a command similar to:

```bash
mpif90 basic_example.F90 \
  -I/path/to/esmf/include \
  -L/path/to/esmf/lib \
  -lesmf \
  -I/path/to/esmf_io/include \
  -L/path/to/esmf_io/lib \
  -lesmf_io \
  -o basic_example
```

## NUOPC Integration Example

This example shows how to integrate ESMF_IO within a NUOPC driver.

### Configuration File

Create a configuration file named `nuopc_example_config.rc`:

```
! NUOPC Integration Example Configuration
! This demonstrates integration with NUOPC drivers

::IO_Settings
 DEBUG_LEVEL: 1
 IO_MODE: PARALLEL
::

::InputStream: BOUNDARY_CONDITIONS
 NAME: boundary_conditions
 DATAFILE: /data/bc_%y4%m2%d2.nc
 FILETYPE: netcdf
 MODE: read
 START_TIME: 2020-01-01_00:00:00
 END_TIME: 2020-12-31_23:59:59
 TIME_FREQUENCY: PT3H
 REFRESH: 0
 FIELD_COUNT: 2
 FIELD_1_NAME: u_wind
 FIELD_1_UNITS: m/s
 FIELD_1_LONGNAME: Zonal Wind
 FIELD_2_NAME: v_wind
 FIELD_2_UNITS: m/s
 FIELD_2_LONGNAME: Meridional Wind
::

::OutputCollection: MODEL_OUTPUT
 NAME: model_output
 FILENAME_BASE: model_output
 FILETYPE: netcdf
 OUTPUT_FREQUENCY: PT1H
 DO_AVG: true
 FIELD_COUNT: 2
 FIELD_1_NAME: temperature
 FIELD_1_UNITS: K
 FIELD_1_LONGNAME: Air Temperature
 FIELD_2_NAME: precipitation
 FIELD_2_UNITS: mm/hr
 FIELD_2_LONGNAME: Precipitation Rate
::
```

### NUOPC Driver Program

Create a NUOPC driver program named `nuopc_example.F90`:

```fortran
program nuopc_example
  use ESMF
  use NUOPC
  use NUOPC_Driver_ESMF_IO

  implicit none

  integer :: rc
  type(ESMF_GridComp) :: driver
  type(ESMF_Clock) :: clock
  type(ESMF_Time) :: startTime, stopTime
  type(ESMF_TimeInterval) :: timeStep

  ! Initialize ESMF
  call ESMF_Initialize(logKindFlag=ESMF_LOGKIND_MULTI, rc=rc)
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

  ! Create a simple clock for the example
  startTime = ESMF_TimeCreate("2020-01-01_00:00:00", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  stopTime = ESMF_TimeCreate("2020-01-02_00:00:00", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  timeStep = ESMF_TimeIntervalCreate("PT1H", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  clock = ESMF_ClockCreate(startTime=startTime, stopTime=stopTime, &
                           timeStep=timeStep, name="NUOPCExampleClock", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Set the clock for the driver
  call ESMF_GridCompSet(driver, clock=clock, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Call the NUOPC driver execution
  call NUOPC_CompDeriveSetServices(driver, clock, rc=rc)
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

  ! Destroy the clock
  call ESMF_ClockDestroy(clock, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Finalize ESMF
  call ESMF_Finalize(rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) &
    stop

end program nuopc_example
```

## Advanced Configuration Example

This example demonstrates a more complex configuration with multiple input streams and output collections.

### Configuration File

Create a configuration file named `advanced_example_config.rc`:

```
! Advanced ESMF_IO Configuration Example
! This demonstrates multiple input streams and output collections

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

## Best Practices

1. **Organize Configuration Files**: Keep configuration files organized and well-commented for maintainability.

2. **Use Relative Paths When Possible**: For portability, use relative paths when possible and document any absolute paths needed.

3. **Validate Before Production Runs**: Always validate your configuration files before running in production environments.

4. **Monitor Resource Usage**: Large output collections can consume significant disk space; monitor usage during long runs.

5. **Test with Small Datasets First**: Before scaling up, test with small datasets to ensure configuration is correct.

6. **Document Field Mappings**: Clearly document how fields in your configuration map to variables in your model.