# API Reference

This document provides a comprehensive reference for the ESMF_IO Unified Component API.

## ESMF_IO_Component_Mod

### Public Interfaces

#### ESMF_IO_SetServices
```fortran
subroutine ESMF_IO_SetServices(gcomp, rc)
```
Sets the services for the ESMF_IO component.

**Parameters:**
- `gcomp` (type(ESMF_GridComp)): The ESMF GridComp object
- `rc` (integer, intent(out)): Return code

#### ESMF_IO_Initialize
```fortran
subroutine ESMF_IO_Initialize(gcomp, importState, exportState, clock, rc)
```
Initializes the ESMF_IO component.

**Parameters:**
- `gcomp` (type(ESMF_GridComp)): The ESMF GridComp object
- `importState` (type(ESMF_State)): Import state containing configuration
- `exportState` (type(ESMF_State)): Export state for data exchange
- `clock` (type(ESMF_Clock)): ESMF Clock object
- `rc` (integer, intent(out)): Return code

#### ESMF_IO_Run
```fortran
subroutine ESMF_IO_Run(gcomp, importState, exportState, clock, rc)
```
Executes the ESMF_IO component for one time step.

**Parameters:**
- `gcomp` (type(ESMF_GridComp)): The ESMF GridComp object
- `importState` (type(ESMF_State)): Import state containing data for output
- `exportState` (type(ESMF_State)): Export state containing data for input
- `clock` (type(ESMF_Clock)): ESMF Clock object
- `rc` (integer, intent(out)): Return code

#### ESMF_IO_Finalize
```fortran
subroutine ESMF_IO_Finalize(gcomp, importState, exportState, clock, rc)
```
Finalizes the ESMF_IO component.

**Parameters:**
- `gcomp` (type(ESMF_GridComp)): The ESMF GridComp object
- `importState` (type(ESMF_State)): Import state
- `exportState` (type(ESMF_State)): Export state
- `clock` (type(ESMF_Clock)): ESMF Clock object
- `rc` (integer, intent(out)): Return code

## ESMF_IO_Config_Mod

### Public Interfaces

#### ESMF_IO_Config_Initialize
```fortran
subroutine ESMF_IO_Config_Initialize(config, gcomp, importState, clock, rc)
```
Initializes the configuration system.

**Parameters:**
- `config` (type(ESMF_IO_Config)): Configuration object
- `gcomp` (type(ESMF_GridComp)): ESMF GridComp object
- `importState` (type(ESMF_State)): Import state
- `clock` (type(ESMF_Clock)): ESMF Clock object
- `rc` (integer, intent(out)): Return code

#### ESMF_IO_Config_Finalize
```fortran
subroutine ESMF_IO_Config_Finalize(config, rc)
```
Finalizes the configuration system.

**Parameters:**
- `config` (type(ESMF_IO_Config)): Configuration object
- `rc` (integer, intent(out)): Return code

#### ESMF_IO_Config_GetInputStream
```fortran
function ESMF_IO_Config_GetInputStream(config, stream_index, rc) result(stream_config)
```
Retrieves an input stream configuration.

**Parameters:**
- `config` (type(ESMF_IO_Config)): Configuration object
- `stream_index` (integer): Index of the input stream
- `rc` (integer, intent(out)): Return code

**Returns:**
- `stream_config` (type(ESMF_IO_InputStreamConfig)): Input stream configuration

#### ESMF_IO_Config_GetOutputCollection
```fortran
function ESMF_IO_Config_GetOutputCollection(config, collection_index, rc) result(collection_config)
```
Retrieves an output collection configuration.

**Parameters:**
- `config` (type(ESMF_IO_Config)): Configuration object
- `collection_index` (integer): Index of the output collection
- `rc` (integer, intent(out)): Return code

**Returns:**
- `collection_config` (type(ESMF_IO_OutputCollectionConfig)): Output collection configuration

## ESMF_IO_Input_Mod

### Public Interfaces

#### ESMF_IO_Input_Initialize
```fortran
subroutine ESMF_IO_Input_Initialize(input_state, config, gcomp, importState, exportState, clock, rc)
```
Initializes the input module.

**Parameters:**
- `input_state` (type(ESMF_IO_InputState)): Input state object
- `config` (type(ESMF_IO_Config)): Configuration object
- `gcomp` (type(ESMF_GridComp)): ESMF GridComp object
- `importState` (type(ESMF_State)): Import state
- `exportState` (type(ESMF_State)): Export state
- `clock` (type(ESMF_Clock)): ESMF Clock object
- `rc` (integer, intent(out)): Return code

#### ESMF_IO_Input_Run
```fortran
subroutine ESMF_IO_Input_Run(input_state, config, gcomp, importState, exportState, clock, rc)
```
Executes the input module for one time step.

**Parameters:**
- `input_state` (type(ESMF_IO_InputState)): Input state object
- `config` (type(ESMF_IO_Config)): Configuration object
- `gcomp` (type(ESMF_GridComp)): ESMF GridComp object
- `importState` (type(ESMF_State)): Import state
- `exportState` (type(ESMF_State)): Export state
- `clock` (type(ESMF_Clock)): ESMF Clock object
- `rc` (integer, intent(out)): Return code

#### ESMF_IO_Input_Finalize
```fortran
subroutine ESMF_IO_Input_Finalize(input_state, config, gcomp, importState, exportState, clock, rc)
```
Finalizes the input module.

**Parameters:**
- `input_state` (type(ESMF_IO_InputState)): Input state object
- `config` (type(ESMF_IO_Config)): Configuration object
- `gcomp` (type(ESMF_GridComp)): ESMF GridComp object
- `importState` (type(ESMF_State)): Import state
- `exportState` (type(ESMF_State)): Export state
- `clock` (type(ESMF_Clock)): ESMF Clock object
- `rc` (integer, intent(out)): Return code

## ESMF_IO_Output_Mod

### Public Interfaces

#### ESMF_IO_Output_Initialize
```fortran
subroutine ESMF_IO_Output_Initialize(output_state, config, gcomp, importState, exportState, clock, rc)
```
Initializes the output module.

**Parameters:**
- `output_state` (type(ESMF_IO_OutputState)): Output state object
- `config` (type(ESMF_IO_Config)): Configuration object
- `gcomp` (type(ESMF_GridComp)): ESMF GridComp object
- `importState` (type(ESMF_State)): Import state
- `exportState` (type(ESMF_State)): Export state
- `clock` (type(ESMF_Clock)): ESMF Clock object
- `rc` (integer, intent(out)): Return code

#### ESMF_IO_Output_Run
```fortran
subroutine ESMF_IO_Output_Run(output_state, config, gcomp, importState, exportState, clock, rc)
```
Executes the output module for one time step.

**Parameters:**
- `output_state` (type(ESMF_IO_OutputState)): Output state object
- `config` (type(ESMF_IO_Config)): Configuration object
- `gcomp` (type(ESMF_GridComp)): ESMF GridComp object
- `importState` (type(ESMF_State)): Import state
- `exportState` (type(ESMF_State)): Export state
- `clock` (type(ESMF_Clock)): ESMF Clock object
- `rc` (integer, intent(out)): Return code

#### ESMF_IO_Output_Finalize
```fortran
subroutine ESMF_IO_Output_Finalize(output_state, config, gcomp, importState, exportState, clock, rc)
```
Finalizes the output module.

**Parameters:**
- `output_state` (type(ESMF_IO_OutputState)): Output state object
- `config` (type(ESMF_IO_Config)): Configuration object
- `gcomp` (type(ESMF_GridComp)): ESMF GridComp object
- `importState` (type(ESMF_State)): Import state
- `exportState` (type(ESMF_State)): Export state
- `clock` (type(ESMF_Clock)): ESMF Clock object
- `rc` (integer, intent(out)): Return code

## ESMF_IO_Parallel_Mod

### Public Interfaces

#### ESMF_IO_ParReadFields
```fortran
subroutine ESMF_IO_ParReadFields(filename, fields, field_names, target_time, stream_config, rc)
```
Reads fields from parallel NetCDF files.

**Parameters:**
- `filename` (character(len=*)): Name of the NetCDF file
- `fields` (type(ESMF_Field)): Array of ESMF Field objects
- `field_names` (character(len=*))): Array of field names
- `target_time` (type(ESMF_Time)): Target time for temporal interpolation
- `stream_config` (type(ESMF_IO_InputStreamConfig)): Input stream configuration
- `rc` (integer, intent(out)): Return code

#### ESMF_IO_ParWriteFields
```fortran
subroutine ESMF_IO_ParWriteFields(filename, fields, field_names, current_time, collection_config, rc)
```
Writes fields to parallel NetCDF files.

**Parameters:**
- `filename` (character(len=*)): Name of the NetCDF file
- `fields` (type(ESMF_Field)): Array of ESMF Field objects
- `field_names` (character(len=*))): Array of field names
- `current_time` (type(ESMF_Time)): Current time
- `collection_config` (type(ESMF_IO_OutputCollectionConfig)): Output collection configuration
- `rc` (integer, intent(out)): Return code

## Data Types

### ESMF_IO_Config
Main configuration type containing all input streams and output collections.

### ESMF_IO_InputStreamConfig
Configuration for a single input stream.

### ESMF_IO_OutputCollectionConfig
Configuration for a single output collection.

### ESMF_IO_InputState
State object for the input module containing temporal buffers.

### ESMF_IO_OutputState
State object for the output module containing accumulator fields.

## Error Codes

### ESMF_IO_RC_SUCCESS
Success return code (0).

### ESMF_IO_RC_ERROR
General error return code (1).

### ESMF_IO_RC_CONFIG_ERROR
Configuration error return code (2).

### ESMF_IO_RC_FILE_ERROR
File I/O error return code (3).

### ESMF_IO_RC_MEMORY_ERROR
Memory allocation error return code (4).

## Constants

### ESMF_IO_MAXSTR
Maximum string length for file paths and names (512).

### ESMF_IO_MAX_FIELDS
Maximum number of fields per stream/collection (100).

## Best Practices

1. **Always Check Return Codes**: All ESMF_IO functions return error codes that should be checked.

2. **Proper Initialization Order**: Follow the initialization order: Component → Config → Input → Output.

3. **Resource Cleanup**: Always call finalize functions to properly clean up resources.

4. **Thread Safety**: The ESMF_IO component is designed to be thread-safe when used with ESMF's parallel capabilities.

5. **Configuration Validation**: Validate configuration files before using them in production runs.