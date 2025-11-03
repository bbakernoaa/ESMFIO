# Testing Guide

This guide explains how to test the ESMF_IO Unified Component, including unit tests, integration tests, and performance benchmarks.

## Overview

The ESMF_IO testing framework is designed to ensure the reliability, correctness, and performance of the component. It includes:

1. Unit tests for individual modules
2. Integration tests for module interactions
3. Performance benchmarks
4. Configuration validation tests
5. Error handling tests

## Test Organization

### Test Runner

The main test runner is located in `tests/test_runner.F90` and provides a comprehensive interface for executing all test suites.

### Test Modules

Individual test modules are organized as follows:

- `tests/test_ESMF_IO_Component_Mod.F90` - Tests for the main component module
- `tests/test_ESMF_IO_Config_Mod.F90` - Tests for the configuration module
- `tests/test_ESMF_IO_Input_Mod.F90` - Tests for the input module
- `tests/test_ESMF_IO_Output_Mod.F90` - Tests for the output module
- `tests/test_ESMF_IO_Parallel_Mod.F90` - Tests for the parallel I/O module
- `tests/test_integration.F90` - Integration tests
- `tests/test_performance.F90` - Performance benchmarks
- `tests/test_configuration_validation.F90` - Configuration validation tests
- `tests/test_error_handling.F90` - Error handling tests

## Running Tests

### Building the Test Suite

To build the test suite, use CMake with the ENABLE_TESTS option:

```bash
mkdir build
cd build
cmake .. -DENABLE_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
make
```

### Executing Tests

To run all tests:

```bash
ctest
```

Or run the test executable directly:

```bash
./esmf_io_test_runner
```

### Test Output

Test results are displayed in the terminal with a summary at the end:

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

## Unit Tests

### Component Module Tests

Tests for the main ESMF_IO component module verify:

1. Component initialization
2. Component run execution
3. Component finalization
4. Error handling in component methods

### Configuration Module Tests

Tests for the configuration module verify:

1. Configuration file parsing
2. Parameter validation
3. Default value assignment
4. Configuration access methods

### Input Module Tests

Tests for the input module verify:

1. Input stream initialization
2. Temporal interpolation
3. Spatial regridding
4. Climatology handling
5. Input data buffering

### Output Module Tests

Tests for the output module verify:

1. Output collection initialization
2. Time averaging
3. Statistical processing
4. File writing operations
5. Output data buffering

### Parallel I/O Module Tests

Tests for the parallel I/O module verify:

1. Parallel file reading
2. Parallel file writing
3. MPI communication
4. Data distribution
5. Collective operations

## Integration Tests

### Full Component Lifecycle

Tests the complete lifecycle of the ESMF_IO component:

1. Initialization with various configurations
2. Multiple time step execution
3. Proper resource cleanup

### Module Interactions

Tests interactions between different modules:

1. Configuration → Input data flow
2. Configuration → Output data flow
3. Input → Output data flow
4. Error propagation between modules

### Clock Integration

Tests clock integration and time management:

1. Time step advancement
2. Stop time detection
3. Time-based I/O triggering

### Configuration-Driven Behavior

Tests that behavior correctly responds to configuration:

1. Different I/O frequencies
2. Various regridding methods
3. Temporal processing options

## Performance Tests

### Parallel I/O Performance

Measures parallel I/O performance with different:

1. Grid sizes
2. Processor counts
3. File formats
4. I/O patterns

### Memory Usage Scalability

Tests memory usage scaling with:

1. Increasing grid sizes
2. Growing time series
3. Multiple concurrent streams

### Regridding Performance

Measures regridding performance with:

1. Different regridding methods
2. Various grid resolutions
3. Multiple fields

### Temporal Interpolation Efficiency

Tests temporal interpolation efficiency:

1. Linear interpolation
2. Nearest neighbor selection
3. Climatology handling

## Configuration Validation Tests

### Valid Configuration Formats

Tests handling of valid configuration files:

1. Standard parameter combinations
2. Edge case values
3. Default parameter handling

### Invalid Configuration Error Handling

Tests error handling for invalid configurations:

1. Missing required parameters
2. Invalid parameter values
3. Malformed configuration files

### Configuration Edge Cases

Tests edge cases in configuration:

1. Empty streams/collections
2. Single field configurations
3. Maximum field counts

### Parameter Validation

Tests parameter validation:

1. Range checking
2. Type validation
3. Dependency validation

## Error Handling Tests

### Robust Error Propagation

Tests that errors are properly propagated:

1. File I/O errors
2. Memory allocation failures
3. Configuration errors

### Graceful Failure Modes

Tests graceful degradation:

1. Continuing operation after non-critical errors
2. Fallback mechanisms
3. Recovery from transient errors

### Logging and Error Reporting

Tests error logging and reporting:

1. Consistent error messages
2. Appropriate log levels
3. Context-aware error reporting

### Recovery Mechanisms

Tests recovery from errors:

1. Retry mechanisms
2. State restoration
3. Resource cleanup after errors

## Writing New Tests

### Test Structure

New tests should follow this structure:

```fortran
subroutine test_new_feature()
  ! Local variables
  integer :: rc
  
  ! Test setup
  ! ...
  
  ! Test execution
  ! ...
  
  ! Verification
  if (condition) then
    print *, "PASS: New feature test"
  else
    print *, "FAIL: New feature test"
  end if
  
  ! Cleanup
  ! ...
end subroutine test_new_feature
```

### Adding Tests to the Test Runner

To add a new test to the test runner:

1. Create the test subroutine in the appropriate test module
2. Add the test to the module's public interface
3. Update the test runner to call the new test

### Test Data

For tests requiring data files:

1. Use small, synthetic datasets when possible
2. Include data files in the tests/data directory
3. Document data file formats and generation procedures

## Continuous Integration

### GitHub Actions

The ESMF_IO repository includes GitHub Actions workflows for continuous integration:

1. `.github/workflows/build-and-test.yml` - Builds and tests on multiple platforms
2. `.github/workflows/code-quality.yml` - Code quality checks
3. `.github/workflows/documentation.yml` - Documentation building

### Test Matrix

CI tests run on multiple configurations:

1. Operating systems: Linux, macOS
2. Compilers: GNU Fortran, Intel Fortran
3. ESMF versions: Latest stable releases
4. Build types: Debug, Release

## Best Practices

### Test Design

1. **Isolation**: Each test should be independent and not rely on state from other tests
2. **Repeatability**: Tests should produce the same results when run multiple times
3. **Speed**: Tests should execute quickly to encourage frequent running
4. **Clarity**: Test names and output should clearly indicate what is being tested

### Test Coverage

1. **Positive Cases**: Test expected behavior with valid inputs
2. **Negative Cases**: Test error handling with invalid inputs
3. **Boundary Cases**: Test edge conditions and limits
4. **Performance Cases**: Test performance characteristics

### Test Maintenance

1. **Regular Updates**: Keep tests updated with code changes
2. **Meaningful Names**: Use descriptive names for test functions
3. **Clear Failures**: Ensure test failures provide useful information
4. **Documentation**: Document complex test setups and expectations

## Debugging Test Failures

### Common Issues

1. **Environment Differences**: Differences between test and production environments
2. **Resource Limits**: Insufficient memory or disk space
3. **Timing Issues**: Race conditions in parallel tests
4. **Dependency Changes**: Updated dependencies affecting test behavior

### Debugging Strategies

1. **Verbose Output**: Enable verbose logging to trace execution
2. **Minimal Reproduction**: Create minimal test cases to isolate issues
3. **Step-by-Step Execution**: Use debugger to trace through failing tests
4. **Comparison Testing**: Compare behavior with known good versions

## Performance Benchmarking

### Benchmark Categories

1. **Throughput**: Data processing rate
2. **Latency**: Response time for operations
3. **Scalability**: Performance scaling with resources
4. **Efficiency**: Resource utilization

### Benchmark Reporting

Benchmark results should include:

1. **Absolute Values**: Raw performance measurements
2. **Relative Comparisons**: Comparison to baseline or previous versions
3. **Confidence Intervals**: Statistical uncertainty in measurements
4. **Environmental Details**: Hardware, software, and configuration details

### Regression Detection

Performance regression detection:

1. **Threshold-Based**: Alert when performance drops below thresholds
2. **Trend Analysis**: Detect negative performance trends over time
3. **Statistical Significance**: Only report significant performance changes

This testing guide provides a comprehensive overview of the ESMF_IO testing framework. Following these guidelines will help ensure the continued reliability and quality of the component.