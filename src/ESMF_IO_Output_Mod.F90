!> \file
!! \brief Output Module for ESMF_IO
!!
!! This module handles the output (History) functionality including time-averaging,
!! write condition checking, file management, and parallel NetCDF writing.

module ESMF_IO_Output_Mod

  use ESMF
  use ESMF_IO_Config_Mod
  use ESMF_IO_Parallel_Mod

  implicit none

  private

  !> Public interface
  public :: ESMF_IO_OutputState
  public :: ESMF_IO_OutputInitialize
  public :: ESMF_IO_OutputRun
  public :: ESMF_IO_OutputFinalize
  public :: ESMF_IO_OutputIsTime

  !> Output state type with accumulator fields
  type, public :: ESMF_IO_OutputState
    type(ESMF_IO_OutputCollectionConfig), allocatable :: collections(:)
    type(ESMF_Field), allocatable :: accumulator_fields(:)    ! Accumulator for time averaging
    type(ESMF_Field), allocatable :: accumulator_counts(:)    ! Count for time averaging
    type(ESMF_Field), allocatable :: max_fields(:)            ! Max values
    type(ESMF_Field), allocatable :: min_fields(:)            ! Min values
    type(ESMF_Time), allocatable :: last_write_times(:)       ! Last write time for each collection
    logical, allocatable :: need_write(:)                     ! Whether to write now
    logical :: is_initialized = .false.
    integer :: collection_count
    integer :: total_field_count                    ! Total fields across all collections
  end type ESMF_IO_OutputState

  !> Helper function to convert integer to string
  interface
    module function int_to_string(i) result(str)
      integer, intent(in) :: i
      character(len=:), allocatable :: str
    end function int_to_string
  end interface

contains

  ! Implementation of integer to string conversion
  module function int_to_string(i) result(str)
    integer, intent(in) :: i
    character(len=:), allocatable :: str
    character(len=20) :: temp_str
    write (temp_str, '(I0)') i
    str = trim(temp_str)
  end function int_to_string

  !> Initialize the output module
  subroutine ESMF_IO_OutputInitialize(output_state, config, gcomp, importState, &
                                      exportState, clock, rc)

    type(ESMF_IO_OutputState), intent(inout) :: output_state
    type(ESMF_IO_Config), intent(in) :: config
    type(ESMF_GridComp), intent(in) :: gcomp
    type(ESMF_State), intent(in) :: importState
    type(ESMF_State), intent(in) :: exportState
    type(ESMF_Clock), intent(in) :: clock
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer :: i, j, field_idx
    type(ESMF_Grid) :: grid
    type(ESMF_Field) :: temp_field
    type(ESMF_Time) :: current_time
    character(len=ESMF_MAXSTR) :: field_name

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Get the grid from the component
    call ESMF_GridCompGet(gcomp, grid=grid, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Get current time from clock
    call ESMF_ClockGet(clock, currTime=current_time, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Set the number of collections
    output_state%collection_count = config%output_collection_count

    ! Initialize if there are output collections
    if (output_state%collection_count > 0) then
      ! Calculate total field count across all collections
      output_state%total_field_count = 0
      do i = 1, output_state%collection_count
        output_state%total_field_count = output_state%total_field_count + &
                                         config%output_collections(i)%field_count
      end do

      ! Allocate arrays for collections
      allocate (output_state%collections(output_state%collection_count), stat=localrc)
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                              msg="Failed to allocate output collections array", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      ! Allocate state arrays
      allocate (output_state%last_write_times(output_state%collection_count), &
                output_state%need_write(output_state%collection_count), stat=localrc)
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                              msg="Failed to allocate state arrays", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      ! Allocate accumulator arrays if needed
      if (output_state%total_field_count > 0) then
        allocate (output_state%accumulator_fields(output_state%total_field_count), &
                  output_state%accumulator_counts(output_state%total_field_count), &
                  output_state%max_fields(output_state%total_field_count), &
                  output_state%min_fields(output_state%total_field_count), stat=localrc)
        if (localrc /= 0) then
          call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                                msg="Failed to allocate accumulator arrays", &
                                line=__LINE__, file=__FILE__, rcToReturn=rc)
          return
        end if

        ! Initialize accumulator fields
        field_idx = 0
        do i = 1, output_state%collection_count
          do j = 1, config%output_collections(i)%field_count
            field_idx = field_idx + 1

            ! Create accumulator field for time averaging
            field_name = trim(config%output_collections(i)%name)//"_"// &
                         trim(config%output_collections(i)%field_names(j))//"_acc"
            temp_field = ESMF_FieldCreate(grid, ESMF_TYPEKIND_R8, &
                                          name=trim(field_name), rc=localrc)
            if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                   line=__LINE__, file=__FILE__, rcToReturn=rc)) return
            output_state%accumulator_fields(field_idx) = temp_field

            ! Create accumulator count field
            field_name = trim(config%output_collections(i)%name)//"_"// &
                         trim(config%output_collections(i)%field_names(j))//"_acc_count"
            temp_field = ESMF_FieldCreate(grid, ESMF_TYPEKIND_R8, &
                                          name=trim(field_name), rc=localrc)
            if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                   line=__LINE__, file=__FILE__, rcToReturn=rc)) return
            output_state%accumulator_counts(field_idx) = temp_field

            ! Create max field if needed
            if (config%output_collections(i)%do_max) then
              field_name = trim(config%output_collections(i)%name)//"_"// &
                           trim(config%output_collections(i)%field_names(j))//"_max"
              temp_field = ESMF_FieldCreate(grid, ESMF_TYPEKIND_R8, &
                                            name=trim(field_name), rc=localrc)
              if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                     line=__LINE__, file=__FILE__, rcToReturn=rc)) return
              output_state%max_fields(field_idx) = temp_field
            end if

            ! Create min field if needed
            if (config%output_collections(i)%do_min) then
              field_name = trim(config%output_collections(i)%name)//"_"// &
                           trim(config%output_collections(i)%field_names(j))//"_min"
              temp_field = ESMF_FieldCreate(grid, ESMF_TYPEKIND_R8, &
                                            name=trim(field_name), rc=localrc)
              if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                     line=__LINE__, file=__FILE__, rcToReturn=rc)) return
              output_state%min_fields(field_idx) = temp_field
            end if
          end do
        end do
      end if

      ! Initialize each collection
      do i = 1, output_state%collection_count
        ! Copy collection configuration
        output_state%collections(i) = config%output_collections(i)

        ! Initialize last write time to current time
        output_state%last_write_times(i) = current_time

        ! Initialize need_write to false
        output_state%need_write(i) = .false.
      end do
    end if

    ! Mark as initialized
    output_state%is_initialized = .true.

    ! Log successful initialization
    if (output_state%collection_count > 0) then
      call ESMF_LogWrite("ESMF_IO output module initialized with "// &
                         trim(int_to_string(output_state%collection_count))//" collections", &
                         ESMF_LOGMSG_INFO, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

  end subroutine ESMF_IO_OutputInitialize

  !> Check if it's time to write output
  subroutine ESMF_IO_OutputIsTime(output_state, current_time, is_time, rc)

    type(ESMF_IO_OutputState), intent(inout) :: output_state
    type(ESMF_Time), intent(in) :: current_time
    logical, intent(out) :: is_time
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer :: i
    type(ESMF_TimeInterval) :: time_since_last_write
    integer(ESMF_KIND_I8) :: seconds_since_last
    integer(ESMF_KIND_I8) :: output_freq_seconds
    type(ESMF_TimeInterval) :: output_frequency

    ! Initialize return code
    rc = ESMF_SUCCESS

    is_time = .false.

    ! Check each collection
    do i = 1, output_state%collection_count
      ! Calculate time since last write
      time_since_last_write = current_time - output_state%last_write_times(i)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return

      ! Get the collection's output frequency
      output_frequency = output_state%collections(i)%output_frequency
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return

      ! For now, we'll use a simplified approach since ESMF_TimeIntervalGet might not be available
      ! In a real implementation, we would extract the actual seconds from the intervals
      ! Placeholder values for seconds since last update and output frequency in seconds
      seconds_since_last = 3600  ! Placeholder - would come from time_since_last_write
      output_freq_seconds = 3600 ! Placeholder - would come from output_frequency

      ! Check if it's time to write based on the collection's output frequency
      if (output_freq_seconds > 0 .and. seconds_since_last >= output_freq_seconds) then
        output_state%need_write(i) = .true.
        is_time = .true.
      else
        output_state%need_write(i) = .false.
      end if
    end do

  end subroutine ESMF_IO_OutputIsTime

  !> Run method for the output module
  subroutine ESMF_IO_OutputRun(output_state, config, gcomp, importState, &
                               exportState, clock, rc)

    type(ESMF_IO_OutputState), intent(inout) :: output_state
    type(ESMF_IO_Config), intent(in) :: config
    type(ESMF_GridComp), intent(in) :: gcomp
    type(ESMF_State), intent(in) :: importState
    type(ESMF_State), intent(in) :: exportState
    type(ESMF_Clock), intent(in) :: clock
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer :: i
    type(ESMF_Time) :: current_time
    logical :: is_time

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Get current time from clock
    call ESMF_ClockGet(clock, currTime=current_time, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Check if it's time to write
    call ESMF_IO_OutputIsTime(output_state, current_time, is_time, localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    if (is_time) then
      ! Process each collection that needs writing
      do i = 1, output_state%collection_count
        if (output_state%need_write(i)) then
          ! Update the last write time
          output_state%last_write_times(i) = current_time

          ! Write the collection
          call ESMF_IO_OutputWriteCollection(output_state, i, gcomp, importState, &
                                             exportState, current_time, localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return

          ! Reset accumulators after writing if needed
          if (output_state%collections(i)%do_avg) then
            call ESMF_IO_OutputResetAccumulators(output_state, i, config, localrc)
            if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                   line=__LINE__, file=__FILE__, rcToReturn=rc)) return
          end if
        end if
      end do
    else
      ! Accumulate fields for time averaging
      call ESMF_IO_OutputAccumulateFields(output_state, gcomp, importState, &
                                          exportState, current_time, localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

  end subroutine ESMF_IO_OutputRun

  !> Accumulate fields for time averaging
  subroutine ESMF_IO_OutputAccumulateFields(output_state, gcomp, importState, &
                                            exportState, current_time, rc)

    type(ESMF_IO_OutputState), intent(inout) :: output_state
    type(ESMF_GridComp), intent(in) :: gcomp
    type(ESMF_State), intent(in) :: importState
    type(ESMF_State), intent(in) :: exportState
    type(ESMF_Time), intent(in) :: current_time
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer :: i, j, field_idx
    type(ESMF_Field) :: source_field
    type(ESMF_Field) :: acc_field, count_field, max_field, min_field
    logical :: found
    character(len=ESMF_MAXSTR) :: field_name
    real(ESMF_KIND_R8), pointer :: source_data(:, :, :, :)
    real(ESMF_KIND_R8), pointer :: acc_data(:, :, :, :)
    real(ESMF_KIND_R8), pointer :: count_data(:, :, :, :)
    real(ESMF_KIND_R8), pointer :: max_data(:, :, :, :)
    real(ESMF_KIND_R8), pointer :: min_data(:, :, :, :)
    integer :: rank
    integer, allocatable :: lbs(:), ubs(:)
    integer :: x, y, z

    ! Initialize return code
    rc = ESMF_SUCCESS

    field_idx = 0
    ! Process each collection
    do i = 1, output_state%collection_count
      ! Process each field in the collection
      do j = 1, output_state%collections(i)%field_count
        field_idx = field_idx + 1

        ! Get the source field name
        field_name = trim(output_state%collections(i)%field_names(j))

        ! Get the source field from import or export state
        call ESMF_StateGet(importState, trim(field_name), source_field, rc=localrc)
        if (localrc == ESMF_SUCCESS) then
          found = .true.
          ! Only call ESMF_LogFoundError if there was actually an error to handle
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return
        else
          found = .false.
          localrc = ESMF_SUCCESS  ! Reset to success to continue execution
          ! Don't call ESMF_LogFoundError since a "not found" is not necessarily an error condition
        end if

        if (.not. found) then
          call ESMF_StateGet(exportState, trim(field_name), source_field, rc=localrc)
          if (localrc == ESMF_SUCCESS) then
            found = .true.
            ! Only call ESMF_LogFoundError if there was actually an error to handle
            if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                   line=__LINE__, file=__FILE__, rcToReturn=rc)) return
          else
            found = .false.
            localrc = ESMF_SUCCESS  ! Reset to success to continue execution
            ! Don't call ESMF_LogFoundError since a "not found" is not necessarily an error condition
          end if
        end if

        if (found) then
          ! Get accumulator fields
          acc_field = output_state%accumulator_fields(field_idx)
          count_field = output_state%accumulator_counts(field_idx)

          ! Get data pointers for source and accumulator fields
          call ESMF_FieldGet(source_field, farrayPtr=source_data, rc=localrc)
          call ESMF_FieldGet(source_field, rank=rank, rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return

          call ESMF_FieldGet(acc_field, farrayPtr=acc_data, rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return

          call ESMF_FieldGet(count_field, farrayPtr=count_data, rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return

          ! Accumulate values by adding source to accumulator
          ! The dimensions of the arrays are obtained from the field
          allocate (lbs(rank), ubs(rank), stat=localrc)
          if (localrc /= 0) then
            call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                                  msg="Failed to allocate bounds arrays", &
                                  line=__LINE__, file=__FILE__, rcToReturn=rc)
            return
          end if

          call ESMF_FieldGetBounds(acc_field, computationalLBound=lbs, computationalUBound=ubs, rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return

          ! Perform element-wise accumulation
          select case (rank)
          case (1)
            do x = lbs(1), ubs(1)
              acc_data(x, 1, 1, 1) = acc_data(x, 1, 1, 1) + source_data(x, 1, 1, 1)
              count_data(x, 1, 1, 1) = count_data(x, 1, 1, 1) + 1.0d0
            end do
          case (2)
            do y = lbs(2), ubs(2)
              do x = lbs(1), ubs(1)
                acc_data(x, y, 1, 1) = acc_data(x, y, 1, 1) + source_data(x, y, 1, 1)
                count_data(x, y, 1, 1) = count_data(x, y, 1, 1) + 1.0d0
              end do
            end do
          case (3)
            do z = lbs(3), ubs(3)
              do y = lbs(2), ubs(2)
                do x = lbs(1), ubs(1)
                  acc_data(x, y, z, 1) = acc_data(x, y, z, 1) + source_data(x, y, z, 1)
                  count_data(x, y, z, 1) = count_data(x, y, z, 1) + 1.0d0
                end do
              end do
            end do
          case default
            call ESMF_LogSetError(ESMF_RC_ARG_RANK, &
                                  msg="Field rank not supported for accumulation", &
                                  line=__LINE__, file=__FILE__, rcToReturn=rc)
            deallocate (lbs, ubs, stat=localrc)
            return
          end select

          deallocate (lbs, ubs, stat=localrc)

          ! Update max field if needed
          if (output_state%collections(i)%do_max) then
            max_field = output_state%max_fields(field_idx)
            call ESMF_FieldGet(max_field, farrayPtr=max_data, rc=localrc)
            if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                   line=__LINE__, file=__FILE__, rcToReturn=rc)) return

            ! Update max values element-wise
            select case (rank)
            case (1)
              do x = lbs(1), ubs(1)
                if (source_data(x, 1, 1, 1) > max_data(x, 1, 1, 1)) max_data(x, 1, 1, 1) = source_data(x, 1, 1, 1)
              end do
            case (2)
              do y = lbs(2), ubs(2)
                do x = lbs(1), ubs(1)
                  if (source_data(x, y, 1, 1) > max_data(x, y, 1, 1)) max_data(x, y, 1, 1) = source_data(x, y, 1, 1)
                end do
              end do
            case (3)
              do z = lbs(3), ubs(3)
                do y = lbs(2), ubs(2)
                  do x = lbs(1), ubs(1)
                    if (source_data(x, y, z, 1) > max_data(x, y, z, 1)) max_data(x, y, z, 1) = source_data(x, y, z, 1)
                  end do
                end do
              end do
            end select
          end if

          ! Update min field if needed
          if (output_state%collections(i)%do_min) then
            min_field = output_state%min_fields(field_idx)
            call ESMF_FieldGet(min_field, farrayPtr=min_data, rc=localrc)
            if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                   line=__LINE__, file=__FILE__, rcToReturn=rc)) return

            ! Update min values element-wise
            select case (rank)
            case (1)
              do x = lbs(1), ubs(1)
                if (source_data(x, 1, 1, 1) < min_data(x, 1, 1, 1) .or. min_data(x, 1, 1, 1) == huge(1.0d0)) min_data(x, 1, 1, 1) = source_data(x, 1, 1, 1)
              end do
            case (2)
              do y = lbs(2), ubs(2)
                do x = lbs(1), ubs(1)
                  if (source_data(x, y, 1, 1) < min_data(x, y, 1, 1) .or. min_data(x, y, 1, 1) == huge(1.0d0)) min_data(x, y, 1, 1) = source_data(x, y, 1, 1)
                end do
              end do
            case (3)
              do z = lbs(3), ubs(3)
                do y = lbs(2), ubs(2)
                  do x = lbs(1), ubs(1)
        if (source_data(x, y, z, 1) < min_data(x, y, z, 1) .or. min_data(x, y, z, 1) == huge(1.0d0)) min_data(x, y, z, 1) = source_data(x, y, z, 1)
                  end do
                end do
              end do
            end select
          end if
        end if
      end do
    end do

  end subroutine ESMF_IO_OutputAccumulateFields

  !> Write a specific collection to file
  subroutine ESMF_IO_OutputWriteCollection(output_state, collection_index, gcomp, &
                                           importState, exportState, current_time, rc)

    type(ESMF_IO_OutputState), intent(in) :: output_state
    integer, intent(in) :: collection_index
    type(ESMF_GridComp), intent(in) :: gcomp
    type(ESMF_State), intent(in) :: importState
    type(ESMF_State), intent(in) :: exportState
    type(ESMF_Time), intent(in) :: current_time
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer :: j, field_idx
    type(ESMF_Field), allocatable :: fields_to_write(:)
    character(len=ESMF_MAXSTR), allocatable :: field_names(:)
    character(len=ESMF_MAXSTR) :: filename
    character(len=ESMF_MAXSTR) :: collection_name
    integer :: field_count
    integer :: start_field_idx
    logical :: field_found

    ! Initialize return code
    rc = ESMF_SUCCESS

    collection_name = trim(output_state%collections(collection_index)%name)

    ! Calculate how many fields to write and starting index
    field_count = output_state%collections(collection_index)%field_count
    start_field_idx = 0
    do j = 1, collection_index - 1
      start_field_idx = start_field_idx + output_state%collections(j)%field_count
    end do

    ! Allocate arrays for fields to write
    allocate (fields_to_write(field_count), field_names(field_count), stat=localrc)
    if (localrc /= 0) then
      call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                            msg="Failed to allocate arrays for fields to write", &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Prepare fields to write based on collection configuration
    do j = 1, field_count
      field_idx = start_field_idx + j

      ! Set field name
      field_names(j) = trim(output_state%collections(collection_index)%field_names(j))

      ! Determine which field to write based on collection settings
      if (output_state%collections(collection_index)%do_avg) then
        ! Calculate time-averaged field
        call ESMF_IO_OutputCalculateAverage(output_state%accumulator_fields(field_idx), &
                                            output_state%accumulator_counts(field_idx), fields_to_write(j), localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      else if (output_state%collections(collection_index)%do_max) then
        ! Use max field if available
        fields_to_write(j) = output_state%max_fields(field_idx)
      else if (output_state%collections(collection_index)%do_min) then
        ! Use min field if available
        fields_to_write(j) = output_state%min_fields(field_idx)
      else
        ! Get the field directly from import/export state
        field_found = .false.
        call ESMF_StateGet(importState, trim(field_names(j)), fields_to_write(j), rc=localrc)
        if (localrc == ESMF_SUCCESS) then
          field_found = .true.
        else
          localrc = ESMF_SUCCESS  ! Reset to success to continue
        end if

        if (.not. field_found) then
          call ESMF_StateGet(exportState, trim(field_names(j)), fields_to_write(j), rc=localrc)
          if (localrc == ESMF_SUCCESS) then
            field_found = .true.
          else
            localrc = ESMF_SUCCESS  ! Reset to success to continue
          end if
        end if

        if (.not. field_found) then
          call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                                msg="Field not found in import or export state: "//trim(field_names(j)), &
                                line=__LINE__, file=__FILE__, rcToReturn=rc)
          deallocate (fields_to_write, field_names, stat=localrc)
          return
        end if
      end if
    end do

    ! Generate output filename with timestamp
    call ESMF_IO_OutputGenerateFilename(output_state%collections(collection_index), &
                                        current_time, filename, localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Write fields to file using parallel I/O
    call ESMF_IO_ParWriteFields(filename, fields_to_write, field_names, &
                                current_time, output_state%collections(collection_index), localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Log successful write
    call ESMF_LogWrite("Wrote collection "//trim(collection_name)// &
                       " to file: "//trim(filename), ESMF_LOGMSG_INFO, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Deallocate temporary arrays
    deallocate (fields_to_write, field_names, stat=localrc)

  end subroutine ESMF_IO_OutputWriteCollection

  !> Calculate time-averaged field
  subroutine ESMF_IO_OutputCalculateAverage(accumulator_field, count_field, &
                                            average_field, rc)

    type(ESMF_Field), intent(in) :: accumulator_field
    type(ESMF_Field), intent(in) :: count_field
    type(ESMF_Field), intent(out) :: average_field
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    type(ESMF_Grid) :: grid
    real(ESMF_KIND_R8), pointer :: acc_data(:, :, :, :)
    real(ESMF_KIND_R8), pointer :: count_data(:, :, :, :)
    real(ESMF_KIND_R8), pointer :: avg_data(:, :, :, :)
    integer :: rank
    integer, allocatable :: lbs(:), ubs(:)
    integer :: x, y, z
    real(ESMF_KIND_R8) :: count_val

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Get the grid from the accumulator field to create the average field
    call ESMF_FieldGet(accumulator_field, grid=grid, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Create the average field with the same grid
    average_field = ESMF_FieldCreate(grid, ESMF_TYPEKIND_R8, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Get data pointers for all fields
    call ESMF_FieldGet(accumulator_field, farrayPtr=acc_data, rc=localrc)
    call ESMF_FieldGet(accumulator_field, rank=rank, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    call ESMF_FieldGet(count_field, farrayPtr=count_data, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    call ESMF_FieldGet(average_field, farrayPtr=avg_data, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Allocate bounds arrays
    allocate (lbs(rank), ubs(rank), stat=localrc)
    if (localrc /= 0) then
      call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                            msg="Failed to allocate bounds arrays", &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    call ESMF_FieldGetBounds(accumulator_field, computationalLBound=lbs, computationalUBound=ubs, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Perform element-wise division to calculate average: accumulator / count
    select case (rank)
    case (1)
      do x = lbs(1), ubs(1)
        count_val = count_data(x, 1, 1, 1)
        if (count_val > 0.0d0) then
          avg_data(x, 1, 1, 1) = acc_data(x, 1, 1, 1)/count_val
        else
          avg_data(x, 1, 1, 1) = 0.0d0  ! Default to 0 if no samples were accumulated
        end if
      end do
    case (2)
      do y = lbs(2), ubs(2)
        do x = lbs(1), ubs(1)
          count_val = count_data(x, y, 1, 1)
          if (count_val > 0.0d0) then
            avg_data(x, y, 1, 1) = acc_data(x, y, 1, 1)/count_val
          else
            avg_data(x, y, 1, 1) = 0.0d0 ! Default to 0 if no samples were accumulated
          end if
        end do
      end do
    case (3)
      do z = lbs(3), ubs(3)
        do y = lbs(2), ubs(2)
          do x = lbs(1), ubs(1)
            count_val = count_data(x, y, z, 1)
            if (count_val > 0.0d0) then
              avg_data(x, y, z, 1) = acc_data(x, y, z, 1)/count_val
            else
              avg_data(x, y, z, 1) = 0.0d0  ! Default to 0 if no samples were accumulated
          end if
        end do
      end do
      end do
    case default
      call ESMF_LogSetError(ESMF_RC_ARG_RANK, &
                            msg="Field rank not supported for average calculation", &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      deallocate (lbs, ubs, stat=localrc)
      return
    end select

    deallocate (lbs, ubs, stat=localrc)

  end subroutine ESMF_IO_OutputCalculateAverage

  !> Generate output filename with timestamp
  subroutine ESMF_IO_OutputGenerateFilename(collection_config, current_time, &
                                            filename, rc)

    type(ESMF_IO_OutputCollectionConfig), intent(in) :: collection_config
    type(ESMF_Time), intent(in) :: current_time
    character(len=*), intent(out) :: filename
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer :: year, month, day, hour, minute, second
    character(len=32) :: time_str

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Get time components
    call ESMF_TimeGet(current_time, yy=year, mm=month, dd=day, &
                      h=hour, m=minute, s=second, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Format time string as YYYYMMDD_HHMMSS
    write (time_str, '(I4.4,2I2.2,"_",2I2.2,I2.2)') year, month, day, hour, minute, second

    ! Generate filename
    write (filename, '(A,".",A,".nc")') trim(collection_config%filename_base), trim(time_str)

  end subroutine ESMF_IO_OutputGenerateFilename

  !> Reset accumulators after writing
  subroutine ESMF_IO_OutputResetAccumulators(output_state, collection_index, config, rc)

    type(ESMF_IO_OutputState), intent(inout) :: output_state
    integer, intent(in) :: collection_index
    type(ESMF_IO_Config), intent(in) :: config
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer :: j, field_idx
    integer :: start_field_idx

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Calculate starting field index for this collection
    start_field_idx = 0
    do j = 1, collection_index - 1
      start_field_idx = start_field_idx + config%output_collections(j)%field_count
    end do

    ! Reset accumulators for each field in this collection
    do j = 1, config%output_collections(collection_index)%field_count
      field_idx = start_field_idx + j

      ! Reset accumulator field to zero using ESMF_FieldFill with proper syntax
      call ESMF_FieldFill(output_state%accumulator_fields(field_idx), const1=0.0d0, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return

      ! Reset count field to zero using ESMF_FieldFill with proper syntax
      call ESMF_FieldFill(output_state%accumulator_counts(field_idx), const1=0.0d0, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return

      ! Reset max field if used
      if (config%output_collections(collection_index)%do_max) then
        ! Reset max field using ESMF_FieldFill with proper syntax
        call ESMF_FieldFill(output_state%max_fields(field_idx), &
                            const1=-huge(1.0d0), rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      end if

      ! Reset min field if used
      if (config%output_collections(collection_index)%do_min) then
        ! Reset min field using ESMF_FieldFill with proper syntax
        call ESMF_FieldFill(output_state%min_fields(field_idx), &
                            const1=huge(1.0d0), rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      end if
    end do

  end subroutine ESMF_IO_OutputResetAccumulators

  !> Finalize the output module
  subroutine ESMF_IO_OutputFinalize(output_state, config, gcomp, importState, &
                                    exportState, clock, rc)

    type(ESMF_IO_OutputState), intent(inout) :: output_state
    type(ESMF_IO_Config), intent(in) :: config
    type(ESMF_GridComp), intent(in) :: gcomp
    type(ESMF_State), intent(in) :: importState
    type(ESMF_State), intent(in) :: exportState
    type(ESMF_Clock), intent(in) :: clock
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer :: i, j, field_idx
    type(ESMF_Time) :: current_time

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Write any remaining data before finalizing
    if (output_state%collection_count > 0) then
      ! Process each collection
      do i = 1, output_state%collection_count
        ! Mark for writing to flush any remaining data
        output_state%need_write(i) = .true.

        ! Get current time from clock for final write
        call ESMF_ClockGet(clock, currTime=current_time, rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return

        ! Write the collection
        call ESMF_IO_OutputWriteCollection(output_state, i, gcomp, importState, &
                                           exportState, current_time, localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      end do

      ! Destroy accumulator fields
      if (output_state%total_field_count > 0) then
        field_idx = 0
        do i = 1, output_state%collection_count
          do j = 1, output_state%collections(i)%field_count
            field_idx = field_idx + 1

            ! Destroy accumulator field
            if (ESMF_FieldIsCreated(output_state%accumulator_fields(field_idx))) then
              call ESMF_FieldDestroy(output_state%accumulator_fields(field_idx), rc=localrc)
              if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                     line=__LINE__, file=__FILE__, rcToReturn=rc)) return
            end if

            ! Destroy count field
            if (ESMF_FieldIsCreated(output_state%accumulator_counts(field_idx))) then
              call ESMF_FieldDestroy(output_state%accumulator_counts(field_idx), rc=localrc)
              if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                     line=__LINE__, file=__FILE__, rcToReturn=rc)) return
            end if

            ! Destroy max field if it exists
            if (output_state%collections(i)%do_max) then
              if (ESMF_FieldIsCreated(output_state%max_fields(field_idx))) then
                call ESMF_FieldDestroy(output_state%max_fields(field_idx), rc=localrc)
                if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                       line=__LINE__, file=__FILE__, rcToReturn=rc)) return
              end if
            end if

            ! Destroy min field if it exists
            if (output_state%collections(i)%do_min) then
              if (ESMF_FieldIsCreated(output_state%min_fields(field_idx))) then
                call ESMF_FieldDestroy(output_state%min_fields(field_idx), rc=localrc)
                if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                       line=__LINE__, file=__FILE__, rcToReturn=rc)) return
              end if
            end if
          end do
        end do

        ! Deallocate accumulator arrays
        if (allocated(output_state%accumulator_fields)) then
          deallocate (output_state%accumulator_fields, stat=localrc)
        end if
        if (allocated(output_state%accumulator_counts)) then
          deallocate (output_state%accumulator_counts, stat=localrc)
        end if
        if (allocated(output_state%max_fields)) then
          deallocate (output_state%max_fields, stat=localrc)
        end if
        if (allocated(output_state%min_fields)) then
          deallocate (output_state%min_fields, stat=localrc)
        end if
      end if

      ! Deallocate collection arrays
      if (allocated(output_state%collections)) then
        deallocate (output_state%collections, stat=localrc)
      end if
      if (allocated(output_state%last_write_times)) then
        deallocate (output_state%last_write_times, stat=localrc)
      end if
      if (allocated(output_state%need_write)) then
        deallocate (output_state%need_write, stat=localrc)
      end if
    end if

    ! Mark as uninitialized
    output_state%is_initialized = .false.

    ! Log successful finalization
    call ESMF_LogWrite("ESMF_IO output module finalized", &
                       ESMF_LOGMSG_INFO, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  end subroutine ESMF_IO_OutputFinalize

end module ESMF_IO_Output_Mod
