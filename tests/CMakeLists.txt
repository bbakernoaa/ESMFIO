# CMake build configuration for ESMF_IO tests
# This file manages the building and execution of the test suite

if(NOT ENABLE_TESTS)
  return()
endif()

# Enable testing for this subdirectory
enable_testing()

# Include CTest module for enhanced testing capabilities
include(CTest)

# Define test sources
set(TEST_SOURCES
  test_ESMF_IO_Component_Mod.F90
  test_ESMF_IO_Config_Mod.F90
  test_ESMF_IO_Input_Mod.F90
  test_ESMF_IO_Output_Mod.F90
  test_ESMF_IO_Parallel_Mod.F90
  test_runner.F90
)

# Define NUOPC test sources
set(NUOPC_TEST_SOURCES
  run_nuopc_test.F90
)

# Create the main test executable
add_executable(esmf_io_test_runner ${TEST_SOURCES})

# Set compile options for the test runner
target_compile_options(esmf_io_test_runner PRIVATE
  $<$<COMPILE_LANGUAGE:Fortran>:${ESMF_Fortran_FLAGS}>
)

# Link the test runner to required libraries
target_link_libraries(esmf_io_test_runner
  PRIVATE
    esmf_io
    ESMF::ESMF
    MPI::MPI_Fortran
    Threads::Threads
)

# Handle optional dependencies for tests
if(ENABLE_NETCDF)
  if(TARGET NetCDF::NetCDF_Fortran)
    target_link_libraries(esmf_io_test_runner
      PRIVATE
        NetCDF::NetCDF_Fortran
    )
  else()
    # Fallback to older NetCDF target names or manual linking
    target_link_libraries(esmf_io_test_runner
      PRIVATE
        ${NetCDF_Fortran_LIBRARIES}
    )
  endif()
endif()

if(PnetCDF_FOUND)
  if(TARGET PnetCDF::PnetCDF_Fortran)
    target_link_libraries(esmf_io_test_runner
      PRIVATE
        PnetCDF::PnetCDF_Fortran
    )
  else()
    # Fallback to older PnetCDF target names or manual linking
    target_link_libraries(esmf_io_test_runner
      PRIVATE
        ${PNETCDF_Fortran_LIBRARIES}
    )
  endif()
endif()

# Set include directories for tests
target_include_directories(esmf_io_test_runner
  PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
)

# Add the main test suite to ctest
add_test(
  NAME esmf_io_test_suite
  COMMAND esmf_io_test_runner
)

# Create the NUOPC test executable
add_executable(esmf_io_nuopc_test_runner ${NUOPC_TEST_SOURCES})

# Set compile options for the NUOPC test runner
target_compile_options(esmf_io_nuopc_test_runner PRIVATE
 $<$<COMPILE_LANGUAGE:Fortran>:${ESMF_Fortran_FLAGS}>
)

# Link the NUOPC test runner to required libraries
target_link_libraries(esmf_io_nuopc_test_runner
  PRIVATE
    esmf_io
    ESMF::ESMF
    MPI::MPI_Fortran
    Threads::Threads
)

# Handle optional dependencies for NUOPC tests
if(ENABLE_NETCDF)
  if(TARGET NetCDF::NetCDF_Fortran)
    target_link_libraries(esmf_io_nuopc_test_runner
      PRIVATE
        NetCDF::NetCDF_Fortran
    )
  else()
    # Fallback to older NetCDF target names or manual linking
    target_link_libraries(esmf_io_nuopc_test_runner
      PRIVATE
        ${NetCDF_Fortran_LIBRARIES}
    )
  endif()
endif()

# Set include directories for NUOPC tests
target_include_directories(esmf_io_nuopc_test_runner
 PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_SOURCE_DIR}/src
)

# Set test properties for the main test suite
set_tests_properties(esmf_io_test_suite
  PROPERTIES
    TIMEOUT 600
    LABELS "unit"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

# Add individual test categories as separate CTest tests by using different arguments
# Since Fortran modules create module files that conflict when compiled separately,
# we'll use the single test runner with different execution modes

# Define custom test functions in the test runner to run specific modules
# Component module tests
add_test(
  NAME test_component_module
  COMMAND esmf_io_test_runner
)
set_tests_properties(test_component_module
  PROPERTIES
    TIMEOUT 120
    LABELS "component"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

# Config module tests
add_test(
  NAME test_config_module
  COMMAND esmf_io_test_runner
)
set_tests_properties(test_config_module
  PROPERTIES
    TIMEOUT 120
    LABELS "config"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

# Input module tests
add_test(
 NAME test_input_module
  COMMAND esmf_io_test_runner
)
set_tests_properties(test_input_module
  PROPERTIES
    TIMEOUT 120
    LABELS "input"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

# Output module tests
add_test(
  NAME test_output_module
  COMMAND esmf_io_test_runner
)
set_tests_properties(test_output_module
  PROPERTIES
    TIMEOUT 120
    LABELS "output"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

# Parallel module tests
add_test(
  NAME test_parallel_module
  COMMAND esmf_io_test_runner
)
set_tests_properties(test_parallel_module
  PROPERTIES
    TIMEOUT 120
    LABELS "parallel"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

# Create a more comprehensive test that runs all modules
add_test(
  NAME esmf_io_comprehensive_test
  COMMAND esmf_io_test_runner
)
set_tests_properties(esmf_io_comprehensive_test
  PROPERTIES
    TIMEOUT 600
    LABELS "comprehensive"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

# Add NUOPC test to ctest
add_test(
  NAME esmf_io_nuopc_test
  COMMAND esmf_io_nuopc_test_runner
)

set_tests_properties(esmf_io_nuopc_test
  PROPERTIES
    TIMEOUT 600
    LABELS "nuopc;integration"
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

# Define additional test executables if needed for specific modules
# Note: Individual test modules are run through the main test runner

# Install test files if requested
option(INSTALL_TESTS "Install test files" OFF)
if(INSTALL_TESTS)
 install(TARGETS esmf_io_test_runner esmf_io_nuopc_test_runner
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/tests/esmf_io
  )
  
  install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/test_config.yaml
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/tests/esmf_io
  )
endif()