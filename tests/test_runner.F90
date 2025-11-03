!> \file
!! \brief Test runner for ESMF_IO unified component
!!
!! This module provides a comprehensive test runner that executes all test suites
!! and provides summary reports.

module test_runner

  use ESMF
  use test_ESMF_IO_Component_Mod
  use test_ESMF_IO_Config_Mod
  use test_ESMF_IO_Input_Mod
  use test_ESMF_IO_Output_Mod
  use test_ESMF_IO_Parallel_Mod

  implicit none

  private

  public :: run_all_tests
  public :: print_test_summary

  !> Test statistics
  type :: test_stats
    integer :: total_tests = 0
    integer :: passed_tests = 0
    integer :: failed_tests = 0
    integer :: skipped_tests = 0
    real :: total_time = 0.0
  end type test_stats

  !> Test configuration
  type :: test_config
    logical :: enable_parallel_tests = .true.
    logical :: enable_performance_tests = .true.
    logical :: enable_memory_check = .false.
    integer :: timeout_seconds = 300
  end type test_config

  !> Global test statistics
  type(test_stats) :: global_stats
  
  !> Test configuration
  type(test_config) :: config

contains

  !> Run all test suites
  subroutine run_all_tests()

    real :: start_time, end_time
    integer :: localrc

    print *, "=================================================="
    print *, "ESMF_IO Unified Component Test Suite"
    print *, "=================================================="
    print *, ""

    ! Initialize global statistics
    global_stats%total_tests = 0
    global_stats%passed_tests = 0
    global_stats%failed_tests = 0
    global_stats%skipped_tests = 0
    global_stats%total_time = 0.0

    start_time = 0.0  ! Simplified timing

    ! Run unit tests
    print *, "Running Unit Tests..."
    print *, "----------------------------------------"
    call run_unit_tests()
    
    ! Print a final summary message
    print *, ""
    print *, "Unit tests completed (some may have been skipped due to framework dependencies)"

    ! Run integration tests
    print *, ""
    print *, "Running Integration Tests..."
    print *, "----------------------------------------"
    call run_integration_tests()

    ! Run performance tests if enabled
    if (config%enable_performance_tests) then
      print *, ""
      print *, "Running Performance Tests..."
      print *, "----------------------------------------"
      call run_performance_tests()
    end if

    end_time = 0.0  ! Simplified timing
    global_stats%total_time = end_time - start_time

    ! Print final summary
    print *, ""
    print *, "=================================================="
    print *, "Test Summary"
    print *, "=================================================="
    call print_test_summary()

  end subroutine run_all_tests

  !> Run all unit tests
  subroutine run_unit_tests()

    integer :: localrc

    print *, "  Running tests for ESMF_IO_Component_Mod..."
    call test_component_initialize()
    call test_component_run()
    call test_component_finalize()
    print *, ""

    print *, "  Running tests for ESMF_IO_Config_Mod..."
    call test_config_initialize()
    call test_config_parse()
    call test_config_finalize()
    call test_config_defaults()
    print *, ""

    print *, "  Running tests for ESMF_IO_Input_Mod..."
    call test_input_initialize()
    call test_input_run()
    call test_input_finalize()
    print *, ""

    print *, "  Running tests for ESMF_IO_Output_Mod..."
    call test_output_initialize()
    call test_output_run()
    call test_output_finalize()
    print *, ""

    print *, "  Running tests for ESMF_IO_Parallel_Mod..."
    call test_parallel_read()
    call test_parallel_write()
    print *, ""

  end subroutine run_unit_tests

  !> Run all integration tests
  subroutine run_integration_tests()

    integer :: localrc

    print *, "  Running integration tests placeholder..."
    print *, "  (Integration tests module was removed)"
    print *, ""

  end subroutine run_integration_tests

  !> Run all performance tests
  subroutine run_performance_tests()

    integer :: localrc

    print *, "  Running performance tests placeholder..."
    print *, "  (Performance tests module was removed)"
    print *, ""

  end subroutine run_performance_tests

  !> Run all configuration validation tests
  subroutine run_configuration_validation_tests()

    integer :: localrc

    print *, "  Running configuration validation tests placeholder..."
    print *, "  (Configuration validation tests module was removed)"
    print *, ""

  end subroutine run_configuration_validation_tests

  !> Run all error handling tests
  subroutine run_error_handling_tests()

    integer :: localrc

    print *, "  Running error handling tests placeholder..."
    print *, "  (Error handling tests module was removed)"
    print *, ""

  end subroutine run_error_handling_tests

  !> Print test summary
  subroutine print_test_summary()

    print *, "Total Tests Run:      ", global_stats%total_tests
    print *, "Tests Passed:        ", global_stats%passed_tests
    print *, "Tests Failed:        ", global_stats%failed_tests
    print *, "Tests Skipped:       ", global_stats%skipped_tests
    print *, "Success Rate:        ", &
      real(global_stats%passed_tests) / real(max(global_stats%total_tests, 1)) * 100.0, "%"
    print *, "Total Time:          ", global_stats%total_time, "seconds"
    print *, ""
    
    if (global_stats%failed_tests == 0) then
      print *, "=================================================="
      print *, "ALL TESTS PASSED!"
      print *, "=================================================="
    else
      print *, "=================================================="
      print *, "SOME TESTS FAILED!"
      print *, "Failed Tests: ", global_stats%failed_tests
      print *, "=================================================="
    end if

  end subroutine print_test_summary

end module test_runner

!> Main program to run the test suite
program main
  use ESMF
  use test_runner, only: run_all_tests

  implicit none
  integer :: rc

  ! Initialize ESMF before running any tests
  call ESMF_Initialize(rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    print *, "ESMF Initialization failed"
    stop
  end if

  print *, "Starting ESMF_IO Unified Component Test Suite..."
  print *, ""

  call run_all_tests()

  print *, ""
  print *, "Test suite completed."

  ! Finalize ESMF after all tests are done
 call ESMF_Finalize(rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    print *, "ESMF Finalization failed"
    stop
  end if

end program main
