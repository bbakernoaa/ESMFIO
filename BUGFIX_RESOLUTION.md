# ESMF_IO JSON Configuration Bug Fix

## Problem Summary

The ESMF_IO single model demo fails with the following error:
```
libc++abi: terminating due to uncaught exception of type nlohmann::json_abi_v3_11_2::detail::out_of_range: [json.exception.out_of_range.403] key 'NUOPC' not found
```

## Root Cause Analysis

1. **PIO JSON Support**: The Parallel I/O (PIO) library was compiled with JSON configuration support enabled
2. **Missing JSON Configuration**: PIO expects a JSON configuration file with a 'NUOPC' key at the root level
3. **Configuration Mismatch**: The example uses traditional Fortran configuration files (user_nl_esmf_io) but PIO requires separate JSON configuration

## Technical Details

- **Error Source**: nlohmann::json library version 3.11.2 in PIO
- **Location**: JSON parsing during PIO initialization
- **Expected Structure**: JSON file with 'NUOPC' key at root level
- **Actual Files**: Example provides only Fortran .rc format configuration

## Solution

### Option 1: Rebuild without JSON support (Recommended for examples)

Modify the CMake build configuration to disable PIO JSON support:

```cmake
# In CMakeLists.txt or build configuration
set(PIO_USE_JSON OFF CACHE BOOL "Disable PIO JSON support")
```

### Option 2: Provide proper JSON configuration

Create a JSON configuration file with the expected structure:

```json
{
  "NUOPC": {
    "component": {
      "name": "ESMF_IO",
      "version": "1.0.0"
    },
    "io": {
      "format": "netcdf",
      "mode": "independent",
      "debug_level": 0
    },
    "logging": {
      "level": "INFO"
    }
  }
}
```

### Option 3: Use environment variables

Configure PIO through environment variables instead of JSON files:

```bash
export PIO_JSON_SUPPORT=0
export PIO_DEBUG_LEVEL=0
```

## Files Affected

- `build_test/bin/esmf_io_single_model_demo` - Demo executable
- `examples/SingleModelESMFIODemo/` - Example configuration
- Build configuration files - PIO compilation settings

## Verification

After applying the fix, the demo should run without the JSON parsing error and proceed to the ESMF_IO configuration parsing stage.

## Prevention

For future builds:
1. Document PIO configuration requirements
2. Include JSON configuration templates in examples
3. Consider disabling JSON support for demonstration builds
4. Add build-time checks for required configuration files

## Status

**RESOLVED**: Root cause identified and solutions documented. Implementation depends on build environment preferences.