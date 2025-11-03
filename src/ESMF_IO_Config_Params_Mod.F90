!> \file
!! \brief Configuration Parameters Module for ESMF_IO
!!
!! This module defines constants and default values for ESMF_IO configuration
!! to eliminate hardcoded values and improve maintainability.

module ESMF_IO_Config_Params_Mod

  use ESMF

  implicit none

  private

  !> Public interface
  public :: ESMF_IO_Config_Defaults
  public :: ESMF_IO_Config_Validation
  public :: ESMF_IO_Defaults

  !> Configuration defaults type
  type, public :: ESMF_IO_Config_Defaults
    ! Global defaults
    character(len=ESMF_MAXSTR) :: default_config_file = "esmf_io_config.rc"
    integer :: default_debug_level = 0
    character(len=ESMF_MAXSTR) :: default_io_mode = "PARALLEL"

    ! Input stream defaults
    character(len=ESMF_MAXSTR) :: default_input_filetype = "netcdf"
    character(len=ESMF_MAXSTR) :: default_input_mode = "read"
    integer :: default_calendar = 1  ! ESMF_CALKIND_GREGORIAN
    logical :: default_climatology = .false.
    integer :: default_regrid_method = 0
    character(len=ESMF_MAXSTR) :: default_regrid_file = ""

    ! Output collection defaults
    character(len=ESMF_MAXSTR) :: default_output_filetype = "netcdf"
    character(len=ESMF_MAXSTR) :: default_filename_base = "output"
    logical :: default_append_packed_files = .false.
    logical :: default_do_avg = .true.
    logical :: default_do_max = .false.
    logical :: default_do_min = .false.

    ! Field defaults
    integer :: default_field_levels = -1
    logical :: default_field_time_avg = .false.
  end type ESMF_IO_Config_Defaults

  !> Configuration validation type
  type, public :: ESMF_IO_Config_Validation
    ! Validation settings
    logical :: require_input_streams = .false.
    logical :: require_output_collections = .false.
    logical :: strict_field_validation = .false.
  end type ESMF_IO_Config_Validation

  !> Global configuration defaults instance
  type(ESMF_IO_Config_Defaults), parameter :: ESMF_IO_Defaults = ESMF_IO_Config_Defaults()

contains

  !> Get configuration defaults
  function ESMF_IO_GetConfigDefaults() result(defaults)
    type(ESMF_IO_Config_Defaults) :: defaults

    defaults = ESMF_IO_Defaults
  end function ESMF_IO_GetConfigDefaults

end module ESMF_IO_Config_Params_Mod
