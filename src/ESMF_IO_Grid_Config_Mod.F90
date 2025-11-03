!> \file
!! \brief Grid Configuration Module for ESMF_IO
!!
!! This module defines grid-related configuration parameters to eliminate
!! hardcoded grid values and improve maintainability.

module ESMF_IO_Grid_Config_Mod

  use ESMF
  use ESMF_IO_Config_Params_Mod, only: ESMF_IO_Config_Defaults, ESMF_IO_Defaults

  implicit none

  private

  !> Public interface
  public :: ESMF_IO_GridConfig
  public :: ESMF_IO_GridConfigInitialize
 public :: ESMF_IO_GridConfigFinalize
  public :: ESMF_IO_GridConfigGet

  !> Grid configuration type
 type, public :: ESMF_IO_GridConfig
    ! Grid dimensions
    integer :: grid_dim_x = 100
    integer :: grid_dim_y = 100
    
    ! Grid coordinate bounds
    real(ESMF_KIND_R8) :: min_corner_x = 0.0_ESMF_KIND_R8
    real(ESMF_KIND_R8) :: min_corner_y = 0.0_ESMF_KIND_R8
    real(ESMF_KIND_R8) :: max_corner_x = 360.0_ESMF_KIND_R8
    real(ESMF_KIND_R8) :: max_corner_y = 180.0_ESMF_KIND_R8
    
    ! Grid coordinate system
    type(ESMF_CoordSys_Flag) :: coord_sys = ESMF_COORDSYS_CART
    
    ! Flag indicating if configuration is initialized
    logical :: is_initialized = .false.
  end type ESMF_IO_GridConfig

contains

  !> Initialize grid configuration from component attributes or defaults
  subroutine ESMF_IO_GridConfigInitialize(grid_config, gcomp, importState, rc)
    
    type(ESMF_IO_GridConfig), intent(inout) :: grid_config
    type(ESMF_GridComp), intent(in) :: gcomp
    type(ESMF_State), intent(in) :: importState
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    character(len=ESMF_MAXSTR) :: error_msg
    logical :: found
    character(len=ESMF_MAXSTR) :: temp_str

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Get grid dimensions from attributes if available
    call ESMF_AttributeGet(gcomp, name="GridDimX", value=temp_str, isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found .and. len_trim(temp_str) > 0) then
      read(temp_str, *, iostat=localrc) grid_config%grid_dim_x
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                              msg="Invalid GridDimX value: must be a valid integer", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
      ! Validate grid dimension
      if (grid_config%grid_dim_x <= 0) then
        call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                              msg="GridDimX must be positive", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
    end if

    call ESMF_AttributeGet(gcomp, name="GridDimY", value=temp_str, isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found .and. len_trim(temp_str) > 0) then
      read(temp_str, *, iostat=localrc) grid_config%grid_dim_y
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                              msg="Invalid GridDimY value: must be a valid integer", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
      ! Validate grid dimension
      if (grid_config%grid_dim_y <= 0) then
        call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                              msg="GridDimY must be positive", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
    end if

    ! Get grid coordinate bounds from attributes if available
    call ESMF_AttributeGet(gcomp, name="MinCornerX", value=temp_str, isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found .and. len_trim(temp_str) > 0) then
      read(temp_str, *, iostat=localrc) grid_config%min_corner_x
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                              msg="Invalid MinCornerX value: must be a valid real number", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
    end if

    call ESMF_AttributeGet(gcomp, name="MinCornerY", value=temp_str, isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found .and. len_trim(temp_str) > 0) then
      read(temp_str, *, iostat=localrc) grid_config%min_corner_y
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                              msg="Invalid MinCornerY value: must be a valid real number", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
    end if

    call ESMF_AttributeGet(gcomp, name="MaxCornerX", value=temp_str, isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found .and. len_trim(temp_str) > 0) then
      read(temp_str, *, iostat=localrc) grid_config%max_corner_x
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                              msg="Invalid MaxCornerX value: must be a valid real number", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
    end if

    call ESMF_AttributeGet(gcomp, name="MaxCornerY", value=temp_str, isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found .and. len_trim(temp_str) > 0) then
      read(temp_str, *, iostat=localrc) grid_config%max_corner_y
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                              msg="Invalid MaxCornerY value: must be a valid real number", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
    end if

    ! Validate coordinate bounds
    if (grid_config%min_corner_x >= grid_config%max_corner_x) then
      call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                            msg="MinCornerX must be less than MaxCornerX", &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if
    
    if (grid_config%min_corner_y >= grid_config%max_corner_y) then
      call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                            msg="MinCornerY must be less than MaxCornerY", &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Mark as initialized
    grid_config%is_initialized = .true.

    ! Log successful initialization
    write(error_msg, '(A,I0,A,I0,A,4F8.2,A)') &
      "Grid configuration initialized: dimensions(", grid_config%grid_dim_x, &
      ",", grid_config%grid_dim_y, "), bounds(", &
      grid_config%min_corner_x, ",", grid_config%min_corner_y, ",", &
      grid_config%max_corner_x, ",", grid_config%max_corner_y, ")"
    call ESMF_LogWrite(trim(error_msg), ESMF_LOGMSG_INFO, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  end subroutine ESMF_IO_GridConfigInitialize

 !> Finalize grid configuration
  subroutine ESMF_IO_GridConfigFinalize(grid_config, rc)
    
    type(ESMF_IO_GridConfig), intent(inout) :: grid_config
    integer, intent(out) :: rc

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Reset initialization flag
    grid_config%is_initialized = .false.

  end subroutine ESMF_IO_GridConfigFinalize

 !> Get grid configuration values
  subroutine ESMF_IO_GridConfigGet(grid_config, grid_dim_x, grid_dim_y, &
                                   min_corner_x, min_corner_y, max_corner_x, max_corner_y, rc)
    
    type(ESMF_IO_GridConfig), intent(in) :: grid_config
    integer, intent(out), optional :: grid_dim_x
    integer, intent(out), optional :: grid_dim_y
    real(ESMF_KIND_R8), intent(out), optional :: min_corner_x
    real(ESMF_KIND_R8), intent(out), optional :: min_corner_y
    real(ESMF_KIND_R8), intent(out), optional :: max_corner_x
    real(ESMF_KIND_R8), intent(out), optional :: max_corner_y
    integer, intent(out) :: rc

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Check if configuration is initialized
    if (.not. grid_config%is_initialized) then
      call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                            msg="Grid configuration not initialized", &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    if (present(grid_dim_x)) grid_dim_x = grid_config%grid_dim_x
    if (present(grid_dim_y)) grid_dim_y = grid_config%grid_dim_y
    if (present(min_corner_x)) min_corner_x = grid_config%min_corner_x
    if (present(min_corner_y)) min_corner_y = grid_config%min_corner_y
    if (present(max_corner_x)) max_corner_x = grid_config%max_corner_x
    if (present(max_corner_y)) max_corner_y = grid_config%max_corner_y

  end subroutine ESMF_IO_GridConfigGet

end module ESMF_IO_Grid_Config_Mod