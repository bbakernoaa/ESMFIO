!-------------------------------------------------------------------------------
! ESMF_IO NUOPC Component Module.
!
! This module contains the NUOPC component implementation for ESMF_IO.
!-------------------------------------------------------------------------------

module ESMF_IO_NUOPC

  use ESMF
  use NUOPC
  use NUOPC_Model, &
    modelSetServices => SetServices
 use ESMF_IO_Config_Mod
 use ESMF_IO_Grid_Config_Mod
  use ESMF_IO_Component_Mod

  implicit none

  private

  public SetServices

  !-----------------------------------------------------------------------------
contains
  !-----------------------------------------------------------------------------

 subroutine SetServices(model, rc)
    type(ESMF_GridComp) :: model
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    character(len=ESMF_MAXSTR) :: error_msg

    rc = ESMF_SUCCESS

    ! Validate input component
    if (.not. ESMF_GridCompIsCreated(model)) then
      call ESMF_LogSetError(ESMF_RC_OBJ_NOT_CREATED, &
                            msg="Model grid component not properly created", &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! derive from NUOPC_Model
    call NUOPC_CompDerive(model, modelSetServices, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) return

    ! specialize model
    call NUOPC_CompSpecialize(model, specLabel="Advertise", &
                              specRoutine=Advertise, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) return
    call NUOPC_CompSpecialize(model, specLabel="Realize", &
                              specRoutine=Realize, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) return
    call NUOPC_CompSpecialize(model, specLabel="Run", &
                              specRoutine=Run, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) return
    call NUOPC_CompSpecialize(model, specLabel="Finalize", &
                              specRoutine=Finalize, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) return

    ! Log successful service setup
    call ESMF_LogWrite("NUOPC ESMF_IO component services set successfully", &
                       ESMF_LOGMSG_INFO, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

 end subroutine SetServices

  !-----------------------------------------------------------------------------

  subroutine Advertise(model, rc)
    type(ESMF_GridComp) :: model
    integer, intent(out) :: rc

    ! local variables
    type(ESMF_State) :: importState, exportState
    type(ESMF_Clock) :: clock
    type(ESMF_IO_Config) :: config
    integer :: i, j
    integer :: localrc
    character(len=ESMF_MAXSTR) :: error_msg

    rc = ESMF_SUCCESS

    ! query for importState and exportState
    call NUOPC_ModelGet(model, importState=importState, &
                        exportState=exportState, modelClock=clock, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) return

    ! Initialize configuration to get field information
    call ESMF_IO_ConfigInitialize(config, model, importState, clock, localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) return

    ! Advertise importable fields for input data based on configuration
    ! If no configuration is available, use defaults
    if (config%input_stream_count > 0 .and. config%input_streams(1)%field_count > 0) then
      ! Use configured fields
      do i = 1, config%input_streams(1)%field_count
        if (len_trim(config%input_streams(1)%field_names(i)) > 0) then
          call NUOPC_Advertise(importState, &
                               StandardName=trim(config%input_streams(1)%field_names(i)), &
                               name=trim(config%input_streams(1)%field_names(i)), rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, &
                                 file=__FILE__, rcToReturn=rc)) then
            call ESMF_IO_ConfigFinalize(config, localrc) ! Cleanup before returning
            return
          end if
        end if
      end do
    else
      ! Use default fields if no configuration
      call NUOPC_Advertise(importState, &
                           StandardName="air_temperature", name="air_temperature", rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, &
                             file=__FILE__, rcToReturn=rc)) return

      call NUOPC_Advertise(importState, &
                           StandardName="eastward_wind", name="eastward_wind", rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, &
                             file=__FILE__, rcToReturn=rc)) return

      call NUOPC_Advertise(importState, &
                           StandardName="northward_wind", name="northward_wind", rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, &
                             file=__FILE__, rcToReturn=rc)) return
    end if

    ! Advertise exportable fields for output data based on configuration
    if (config%output_collection_count > 0 .and. config%output_collections(1)%field_count > 0) then
      ! Use configured fields
      do i = 1, config%output_collections(1)%field_count
        if (len_trim(config%output_collections(1)%field_names(i)) > 0) then
          call NUOPC_Advertise(exportState, &
                               StandardName=trim(config%output_collections(1)%field_names(i)), &
                               name=trim(config%output_collections(1)%field_names(i)), rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, &
                                 file=__FILE__, rcToReturn=rc)) then
            call ESMF_IO_ConfigFinalize(config, localrc) ! Cleanup before returning
            return
          end if
        end if
      end do
    else
      ! Use default fields if no configuration
      call NUOPC_Advertise(exportState, &
                           StandardName="air_pressure_at_sea_level", name="pmsl", rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, &
                             file=__FILE__, rcToReturn=rc)) return

      call NUOPC_Advertise(exportState, &
                           StandardName="surface_net_downward_shortwave_flux", name="rsns", rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, &
                             file=__FILE__, rcToReturn=rc)) return
    end if

    ! Finalize configuration
    call ESMF_IO_ConfigFinalize(config, localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) return

    ! Log successful advertisement
    call ESMF_LogWrite("NUOPC ESMF_IO component fields advertised successfully", &
                       ESMF_LOGMSG_INFO, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

 end subroutine Advertise

  !-----------------------------------------------------------------------------

 !> Resource cleanup subroutine for the ESMF_IO NUOPC component
 subroutine ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, rc)
    type(ESMF_GridComp), intent(in) :: model
    type(ESMF_State), intent(inout) :: importState
    type(ESMF_State), intent(inout) :: exportState
    type(ESMF_Grid), intent(inout) :: grid
    type(ESMF_IO_GridConfig), intent(inout) :: grid_config
    integer, intent(out) :: rc

    integer :: localrc
    character(len=ESMF_MAXSTR) :: error_msg

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Log cleanup start
    call ESMF_LogWrite("Starting resource cleanup for ESMF_IO component", &
                       ESMF_LOGMSG_INFO, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Finalize grid configuration if it was initialized
    if (grid_config%is_initialized) then
      call ESMF_IO_GridConfigFinalize(grid_config, localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      ! Reset the flag after finalization
      grid_config%is_initialized = .false.
    end if

    ! Destroy the grid if it was created
    if (ESMF_GridIsCreated(grid)) then
      call ESMF_GridDestroy(grid, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

    ! Log successful cleanup
    call ESMF_LogWrite("Resource cleanup completed successfully for ESMF_IO component", &
                       ESMF_LOGMSG_INFO, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  end subroutine ESMF_IO_CleanupResources

 !-----------------------------------------------------------------------------

  subroutine Realize(model, rc)
    type(ESMF_GridComp) :: model
    integer, intent(out) :: rc

    ! local variables
    type(ESMF_State) :: importState, exportState
    type(ESMF_Field) :: field
    type(ESMF_Grid) :: grid
    type(ESMF_IO_GridConfig) :: grid_config
    type(ESMF_IO_Config) :: config
    type(ESMF_Clock) :: clock
    integer :: grid_dim_x, grid_dim_y
    real(ESMF_KIND_R8) :: min_corner_x, min_corner_y, max_corner_x, max_corner_y
    integer :: i, j
    integer :: localrc
    character(len=ESMF_MAXSTR) :: error_msg

    ! Initialize variables
    grid_config%is_initialized = .false.

    rc = ESMF_SUCCESS

    ! Validate input component
    if (.not. ESMF_GridCompIsCreated(model)) then
      call ESMF_LogSetError(ESMF_RC_OBJ_NOT_CREATED, &
                            msg="Model grid component not properly created", &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! query for importState and exportState
    call NUOPC_ModelGet(model, importState=importState, &
                        exportState=exportState, modelClock=clock, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) return

    ! Validate states
    if (.not. ESMF_StateIsCreated(importState)) then
      call ESMF_LogSetError(ESMF_RC_OBJ_NOT_CREATED, &
                            msg="Import state not properly created", &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    if (.not. ESMF_StateIsCreated(exportState)) then
      call ESMF_LogSetError(ESMF_RC_OBJ_NOT_CREATED, &
                            msg="Export state not properly created", &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Initialize configuration to get field information
    call ESMF_IO_ConfigInitialize(config, model, importState, clock, localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) return

    ! Initialize grid configuration
    call ESMF_IO_GridConfigInitialize(grid_config, model, importState, localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) then
      call ESMF_IO_ConfigFinalize(config, localrc) ! Cleanup config before returning
      call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
      return
    end if

    ! Get grid parameters from configuration
    call ESMF_IO_GridConfigGet(grid_config, &
                               grid_dim_x=grid_dim_x, &
                               grid_dim_y=grid_dim_y, &
                               min_corner_x=min_corner_x, &
                               min_corner_y=min_corner_y, &
                               max_corner_x=max_corner_x, &
                               max_corner_y=max_corner_y, &
                               rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) then
      call ESMF_IO_ConfigFinalize(config, localrc)  ! Cleanup config before returning
      call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
      return
    end if

    ! create a Grid object for Fields using configurable parameters
    grid = ESMF_GridCreateNoPeriDimUfrm(maxIndex=(/grid_dim_x, grid_dim_y/), &
                                        minCornerCoord=(/min_corner_x, min_corner_y/), &
                                        maxCornerCoord=(/max_corner_x, max_corner_y/), &
                                        coordSys=ESMF_COORDSYS_CART, staggerLocList=(/ESMF_STAGGERLOC_CENTER/), &
                                        rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) then
      call ESMF_IO_ConfigFinalize(config, localrc)  ! Cleanup config before returning
      call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
      return
    end if

    ! Create importable fields for input data based on configuration
    if (config%input_stream_count > 0 .and. config%input_streams(1)%field_count > 0) then
      ! Use configured fields
      do i = 1, config%input_streams(1)%field_count
        if (len_trim(config%input_streams(1)%field_names(i)) > 0) then
          field = ESMF_FieldCreate(name=trim(config%input_streams(1)%field_names(i)), grid=grid, &
                                   typekind=ESMF_TYPEKIND_R8, rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, &
                                 file=__FILE__, rcToReturn=rc)) then
            call ESMF_IO_ConfigFinalize(config, localrc)  ! Cleanup config before returning
            call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
            return
          end if
          call NUOPC_Realize(importState, field=field, rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, &
                                 file=__FILE__, rcToReturn=rc)) then
            call ESMF_IO_ConfigFinalize(config, localrc)  ! Cleanup config before returning
            call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
            return
          end if
        end if
      end do
    else
      ! Use default fields if no configuration
      field = ESMF_FieldCreate(name="air_temperature", grid=grid, &
                               typekind=ESMF_TYPEKIND_R8, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, &
                             file=__FILE__, rcToReturn=rc)) then
        call ESMF_IO_ConfigFinalize(config, localrc)  ! Cleanup config before returning
        call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
        return
      end if
      call NUOPC_Realize(importState, field=field, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, &
                             file=__FILE__, rcToReturn=rc)) then
        call ESMF_IO_ConfigFinalize(config, localrc)  ! Cleanup config before returning
        call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
        return
      end if

      field = ESMF_FieldCreate(name="eastward_wind", grid=grid, &
                               typekind=ESMF_TYPEKIND_R8, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, &
                             file=__FILE__, rcToReturn=rc)) then
        call ESMF_IO_ConfigFinalize(config, localrc)  ! Cleanup config before returning
        call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
        return
      end if
      call NUOPC_Realize(importState, field=field, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, &
                             file=__FILE__, rcToReturn=rc)) then
        call ESMF_IO_ConfigFinalize(config, localrc)  ! Cleanup config before returning
        call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
        return
      end if

      field = ESMF_FieldCreate(name="northward_wind", grid=grid, &
                               typekind=ESMF_TYPEKIND_R8, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, &
                             file=__FILE__, rcToReturn=rc)) then
        call ESMF_IO_ConfigFinalize(config, localrc)  ! Cleanup config before returning
        call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
        return
      end if
      call NUOPC_Realize(importState, field=field, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, &
                             file=__FILE__, rcToReturn=rc)) then
        call ESMF_IO_ConfigFinalize(config, localrc)  ! Cleanup config before returning
        call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
        return
      end if
    end if

    ! Create exportable fields for output data based on configuration
    if (config%output_collection_count > 0 .and. config%output_collections(1)%field_count > 0) then
      ! Use configured fields
      do i = 1, config%output_collections(1)%field_count
        if (len_trim(config%output_collections(1)%field_names(i)) > 0) then
          field = ESMF_FieldCreate(name=trim(config%output_collections(1)%field_names(i)), grid=grid, &
                                   typekind=ESMF_TYPEKIND_R8, rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, &
                                 file=__FILE__, rcToReturn=rc)) then
            call ESMF_IO_ConfigFinalize(config, localrc)  ! Cleanup config before returning
            call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
            return
          end if
          call NUOPC_Realize(exportState, field=field, rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, &
                                 file=__FILE__, rcToReturn=rc)) then
            call ESMF_IO_ConfigFinalize(config, localrc)  ! Cleanup config before returning
            call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
            return
          end if
        end if
      end do
    else
      ! Use default fields if no configuration
      field = ESMF_FieldCreate(name="pmsl", grid=grid, &
                               typekind=ESMF_TYPEKIND_R8, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, &
                             file=__FILE__, rcToReturn=rc)) then
        call ESMF_IO_ConfigFinalize(config, localrc) ! Cleanup config before returning
        call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
        return
      end if
      call NUOPC_Realize(exportState, field=field, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, &
                             file=__FILE__, rcToReturn=rc)) then
        call ESMF_IO_ConfigFinalize(config, localrc)  ! Cleanup config before returning
        call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
        return
      end if

      field = ESMF_FieldCreate(name="rsns", grid=grid, &
                               typekind=ESMF_TYPEKIND_R8, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, &
                             file=__FILE__, rcToReturn=rc)) then
        call ESMF_IO_ConfigFinalize(config, localrc) ! Cleanup config before returning
        call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
        return
      end if
      call NUOPC_Realize(exportState, field=field, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, &
                             file=__FILE__, rcToReturn=rc)) then
        call ESMF_IO_ConfigFinalize(config, localrc) ! Cleanup config before returning
        call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
        return
      end if
    end if

    ! Finalize grid configuration
    call ESMF_IO_GridConfigFinalize(grid_config, localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) then
      call ESMF_IO_ConfigFinalize(config, localrc)  ! Cleanup config before returning
      call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
      return
    end if

    ! Finalize configuration
    call ESMF_IO_ConfigFinalize(config, localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) then
      call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
      return
    end if

    ! Log successful realization
    call ESMF_LogWrite("NUOPC ESMF_IO component fields realized successfully", &
                       ESMF_LOGMSG_INFO, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  end subroutine Realize

 !-----------------------------------------------------------------------------

   subroutine Run(model, rc)
     type(ESMF_GridComp) :: model
     integer, intent(out) :: rc
 
     ! local variables
     type(ESMF_Clock) :: clock
     type(ESMF_State) :: importState, exportState
     character(len=160) :: msgString
     integer :: localrc
     type(ESMF_Time) :: startTime, stopTime
     type(ESMF_TimeInterval) :: timeStep
     character(len=ESMF_MAXSTR) :: error_msg
 
     rc = ESMF_SUCCESS
 
     ! Validate input component
     if (.not. ESMF_GridCompIsCreated(model)) then
       call ESMF_LogSetError(ESMF_RC_OBJ_NOT_CREATED, &
                             msg="Model grid component not properly created", &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     end if
 
     ! query for clock, importState and exportState
     call NUOPC_ModelGet(model, modelClock=clock, importState=importState, &
                         exportState=exportState, rc=localrc)
     if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                            line=__LINE__, &
                            file=__FILE__, rcToReturn=rc)) return
 
     ! Validate clock
     if (.not. ESMF_ClockIsCreated(clock)) then
       call ESMF_LogSetError(ESMF_RC_OBJ_NOT_CREATED, &
                             msg="Model clock not properly created", &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     end if
 
     ! Validate states
     if (.not. ESMF_StateIsCreated(importState)) then
       call ESMF_LogSetError(ESMF_RC_OBJ_NOT_CREATED, &
                             msg="Import state not properly created", &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     end if
 
     if (.not. ESMF_StateIsCreated(exportState)) then
       call ESMF_LogSetError(ESMF_RC_OBJ_NOT_CREATED, &
                             msg="Export state not properly created", &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     end if
 
     ! Get time information for logging
     call ESMF_ClockGet(clock, currTime=startTime, stopTime=stopTime, timeStep=timeStep, rc=localrc)
     if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                            line=__LINE__, &
                            file=__FILE__, rcToReturn=rc)) return
 
     ! Log the advancement with detailed timing information
     call ESMF_TimePrint(startTime, options="currTime", &
                         preString="------>Running ESMF_IO from: ", unit=msgString, rc=localrc)
     if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                            line=__LINE__, &
                            file=__FILE__, rcToReturn=rc)) return
     call ESMF_LogWrite(msgString, ESMF_LOGMSG_INFO, rc=localrc)
     if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                            line=__LINE__, &
                            file=__FILE__, rcToReturn=rc)) return
 
     call ESMF_TimePrint(stopTime, options="stopTime", &
                         preString="---------------------> to: ", unit=msgString, rc=localrc)
     if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                            line=__LINE__, &
                            file=__FILE__, rcToReturn=rc)) return
     call ESMF_LogWrite(msgString, ESMF_LOGMSG_INFO, rc=localrc)
     if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                            line=__LINE__, &
                            file=__FILE__, rcToReturn=rc)) return
 
     ! Call the ESMF_IO component to perform I/O operations
     ! This is where the actual I/O functionality is executed
     call ESMF_IO_Run(model, importState, exportState, clock, localrc)
     if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                            line=__LINE__, &
                            file=__FILE__, rcToReturn=rc)) return
 
     ! Log successful advancement
     write(error_msg, '(A)') "ESMF_IO component run completed successfully"
     call ESMF_LogWrite(trim(error_msg), ESMF_LOGMSG_INFO, rc=localrc)
     if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)) return
 
   end subroutine Run

  !-----------------------------------------------------------------------------

  subroutine Finalize(model, rc)
    type(ESMF_GridComp) :: model
    integer, intent(out) :: rc

    ! local variables
    type(ESMF_State) :: importState, exportState
    type(ESMF_Grid) :: grid
    type(ESMF_IO_GridConfig) :: grid_config
    integer :: localrc

    rc = ESMF_SUCCESS

    ! query for importState and exportState
    call NUOPC_ModelGet(model, importState=importState, &
                        exportState=exportState, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) return

    ! Initialize grid_config for cleanup
    grid_config%is_initialized = .false.

    ! Perform comprehensive cleanup of resources
    call ESMF_IO_CleanupResources(model, importState, exportState, grid, grid_config, localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, &
                           file=__FILE__, rcToReturn=rc)) return

    ! Log successful finalization
    call ESMF_LogWrite("NUOPC ESMF_IO component finalized successfully", &
                       ESMF_LOGMSG_INFO, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  end subroutine Finalize

  !-----------------------------------------------------------------------------

end module ESMF_IO_NUOPC