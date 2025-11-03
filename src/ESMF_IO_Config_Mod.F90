!> \file
!! \brief Configuration Management Module for ESMF_IO
!!
!! This module handles the unified configuration system for both input (ExtData)
!! and output (History) functionality using ESMF_Config.

module ESMF_IO_Config_Mod

  use ESMF
  use ESMF_IO_Config_Params_Mod, only: ESMF_IO_Config_Defaults, ESMF_IO_Defaults

  implicit none

  private

  !> Public interface
  public :: ESMF_IO_Config
  public :: ESMF_IO_ConfigInitialize
  public :: ESMF_IO_ConfigFinalize
  public :: ESMF_IO_InputStreamConfig
  public :: ESMF_IO_OutputCollectionConfig

  !> Input stream configuration
  type, public :: ESMF_IO_InputStreamConfig
    character(len=ESMF_MAXSTR) :: name
    character(len=ESMF_MAXSTR) :: datafile
    character(len=ESMF_MAXSTR) :: filetype
    character(len=ESMF_MAXSTR) :: mode
    type(ESMF_Time) :: start_time
    type(ESMF_Time) :: end_time
    type(ESMF_TimeInterval) :: time_frequency
    type(ESMF_TimeInterval) :: time_offset
    integer :: calendar
    logical :: climatology
    integer :: regrid_method
    character(len=ESMF_MAXSTR) :: regrid_file
    character(len=ESMF_MAXSTR), allocatable :: field_names(:)
    character(len=ESMF_MAXSTR), allocatable :: field_units(:)
    character(len=ESMF_MAXSTR), allocatable :: field_longnames(:)
    integer, allocatable :: field_levels(:)
    logical, allocatable :: field_time_avg(:)
    integer :: field_count
  end type ESMF_IO_InputStreamConfig

  !> Output collection configuration
  type, public :: ESMF_IO_OutputCollectionConfig
    character(len=ESMF_MAXSTR) :: name
    character(len=ESMF_MAXSTR) :: filename_base
    character(len=ESMF_MAXSTR) :: filetype
    type(ESMF_TimeInterval) :: output_frequency
    type(ESMF_TimeInterval) :: time_axis_offset
    logical :: append_packed_files
    logical :: do_avg
    logical :: do_max
    logical :: do_min
    character(len=ESMF_MAXSTR), allocatable :: field_names(:)
    character(len=ESMF_MAXSTR), allocatable :: field_units(:)
    character(len=ESMF_MAXSTR), allocatable :: field_longnames(:)
    integer, allocatable :: field_levels(:)
    integer :: field_count
  end type ESMF_IO_OutputCollectionConfig

  !> Main configuration type
  type, public :: ESMF_IO_Config
    type(ESMF_Config) :: esmf_config
    character(len=ESMF_MAXSTR) :: config_file
    type(ESMF_IO_InputStreamConfig), allocatable :: input_streams(:)
    type(ESMF_IO_OutputCollectionConfig), allocatable :: output_collections(:)
    integer :: input_stream_count
    integer :: output_collection_count
    logical :: is_initialized
  end type ESMF_IO_Config

contains

  !> Initialize the configuration system
  subroutine ESMF_IO_ConfigInitialize(config, gcomp, importState, clock, rc)

    type(ESMF_IO_Config), intent(inout) :: config
    type(ESMF_GridComp), intent(in) :: gcomp
    type(ESMF_State), intent(in) :: importState
    type(ESMF_Clock), intent(in) :: clock
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    character(len=ESMF_MAXSTR) :: config_filename
    logical :: found
    character(len=ESMF_MAXSTR) :: error_msg

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Initialize the configuration structure
    config%config_file = ""
    config%input_stream_count = 0
    config%output_collection_count = 0
    config%is_initialized = .false.

    ! Try to get configuration from importState first
    ! Use ESMF_AttributeGet instead of ESMF_StateGet for string values
    call ESMF_AttributeGet(importState, name="ESMF_IO_ConfigFile", &
                           value=config_filename, isPresent=found, rc=localrc)
    if (localrc /= ESMF_SUCCESS) then
      found = .false.
      localrc = ESMF_SUCCESS  ! Reset to success to continue execution
    end if
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! If not in importState, try to get from component attributes
    if (.not. found) then
      call ESMF_AttributeGet(gcomp, name="ESMF_IO_ConfigFile", &
                             value=config_filename, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

    ! If still not found, use default
    if (len_trim(config_filename) == 0) then
      config_filename = ESMF_IO_Defaults%default_config_file
    else
      ! Check if the specified config file exists
      inquire (file=trim(config_filename), exist=found)
      if (.not. found) then
        write (error_msg, '(A,A,A)') "Configuration file not found: ", trim(config_filename), &
          ". Please ensure the file exists and is accessible."
        call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                              msg=trim(error_msg), &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
    end if

    config%config_file = config_filename

    ! Create ESMF_Config object
    config%esmf_config = ESMF_ConfigCreate(rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Read the configuration file
    call ESMF_ConfigLoadFile(config%esmf_config, trim(config%config_file), rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Parse the configuration
    call ESMF_IO_ConfigParse(config, localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Mark as initialized
    config%is_initialized = .true.

    ! Log successful initialization
    call ESMF_LogWrite("ESMF_IO configuration initialized from: "//trim(config%config_file), &
                       ESMF_LOGMSG_INFO, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  end subroutine ESMF_IO_ConfigInitialize

  !> Parse the configuration file
  subroutine ESMF_IO_ConfigParse(config, rc)

    type(ESMF_IO_Config), intent(inout) :: config
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer :: i, j
    integer :: stream_count, collection_count
    character(len=ESMF_MAXSTR) :: current_line
    character(len=ESMF_MAXSTR) :: key
    logical :: found
    character(len=ESMF_MAXSTR) :: error_msg

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! First pass: count input streams and output collections
    call ESMF_ConfigFindLabel(config%esmf_config, label="ESMF_IO_STREAMS::", isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    if (found) then
      ! Count input streams
      stream_count = 0
      do
        write (current_line, '(A,I0,A)') "ESMF_IO_STREAMS::STREAM_", stream_count + 1, "_NAME:"
        call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
        if (.not. found) exit
        stream_count = stream_count + 1
      end do
      config%input_stream_count = stream_count
    end if

    call ESMF_ConfigFindLabel(config%esmf_config, label="ESMF_IO_COLLECTIONS::", isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    if (found) then
      ! Count output collections
      collection_count = 0
      do
        write (current_line, '(A,I0,A)') "ESMF_IO_COLLECTIONS::COLLECTION_", collection_count + 1, "_NAME:"
        call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
        if (.not. found) exit
        collection_count = collection_count + 1
      end do
      config%output_collection_count = collection_count
    end if

    ! Allocate arrays for streams and collections
    if (config%input_stream_count > 0) then
      allocate (config%input_streams(config%input_stream_count), stat=localrc)
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                              msg="Failed to allocate input streams array", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      ! Initialize each input stream
      do i = 1, config%input_stream_count
        call ESMF_IO_ConfigParseInputStream(config, i, config%input_streams(i), localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      end do
    end if

    if (config%output_collection_count > 0) then
      allocate (config%output_collections(config%output_collection_count), stat=localrc)
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                              msg="Failed to allocate output collections array", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      ! Initialize each output collection
      do i = 1, config%output_collection_count
        call ESMF_IO_ConfigParseOutputCollection(config, i, config%output_collections(i), localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      end do
    end if

  end subroutine ESMF_IO_ConfigParse

  !> Parse input stream configuration
  subroutine ESMF_IO_ConfigParseInputStream(config, stream_index, stream_config, rc)

    type(ESMF_IO_Config), intent(inout) :: config
    integer, intent(in) :: stream_index
    type(ESMF_IO_InputStreamConfig), intent(inout) :: stream_config
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    character(len=ESMF_MAXSTR) :: current_line, key, value
    character(len=ESMF_MAXSTR) :: label
    logical :: found
    integer :: field_count
    integer :: i
    character(len=ESMF_MAXSTR) :: error_msg

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Set default values using configuration defaults
    stream_config%name = ""
    stream_config%datafile = ""
    stream_config%filetype = ESMF_IO_Defaults%default_input_filetype
    stream_config%mode = ESMF_IO_Defaults%default_input_mode
    stream_config%calendar = ESMF_IO_Defaults%default_calendar
    stream_config%climatology = ESMF_IO_Defaults%default_climatology
    stream_config%regrid_method = ESMF_IO_Defaults%default_regrid_method
    stream_config%regrid_file = ESMF_IO_Defaults%default_regrid_file
    stream_config%field_count = 0

    ! Construct label for this stream
    write (label, '(A,I0,A)') "ESMF_IO_STREAMS::STREAM_", stream_index, "_"

    ! Get stream name
    write (current_line, '(A,A)') trim(label), "NAME:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, stream_config%name, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    else
      write (error_msg, '(A,I0,A)') "Required parameter missing: Input stream ", stream_index, " NAME"
      call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                            msg=trim(error_msg), &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Get datafile
    write (current_line, '(A,A)') trim(label), "DATAFILE:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, stream_config%datafile, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      ! Check if datafile exists if it's specified
      if (len_trim(stream_config%datafile) > 0) then
        inquire (file=trim(stream_config%datafile), exist=found)
        if (.not. found) then
          write (error_msg, '(A,A,A,I0,A)') "Input datafile not found: ", trim(stream_config%datafile), &
            " for stream ", stream_index, ". Check path and permissions."
          call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                                msg=trim(error_msg), &
                                line=__LINE__, file=__FILE__, rcToReturn=rc)
          return
        end if
      end if
    else
      write (error_msg, '(A,I0,A)') "Required parameter missing: Input stream ", stream_index, " DATAFILE"
      call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                            msg=trim(error_msg), &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Get filetype
    write (current_line, '(A,A)') trim(label), "FILETYPE:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, stream_config%filetype, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

    ! Get mode
    write (current_line, '(A,A)') trim(label), "MODE:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, stream_config%mode, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

    ! Get start time
    write (current_line, '(A,A)') trim(label), "START_TIME:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, current_line, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      ! Parse time string (format: YYYY-MM-DD-HH:mm:ss)
      call ESMF_IO_ParseTimeString(current_line, stream_config%start_time, localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

    ! Get end time
    write (current_line, '(A,A)') trim(label), "END_TIME:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, current_line, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      ! Parse time string
      call ESMF_IO_ParseTimeString(current_line, stream_config%end_time, localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

    ! Get time frequency
    write (current_line, '(A,A)') trim(label), "TIME_FREQUENCY:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, current_line, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      ! Parse time interval string (format: PTnH or PTnM)
      call ESMF_IO_ParseTimeIntervalString(current_line, stream_config%time_frequency, localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

    ! Get time offset
    write (current_line, '(A,A)') trim(label), "TIME_OFFSET:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, current_line, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      ! Parse time interval string
      call ESMF_IO_ParseTimeIntervalString(current_line, stream_config%time_offset, localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

    ! Get calendar
    write (current_line, '(A,A)') trim(label), "CALENDAR:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, current_line, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      ! Parse calendar string
      call ESMF_IO_ParseCalendarString(current_line, stream_config%calendar, localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

    ! Get climatology flag
    write (current_line, '(A,A)') trim(label), "CLIMATOLOGY:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, value, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      stream_config%climatology = (trim(value) == "true" .or. trim(value) == "TRUE" .or. &
                                   trim(value) == "yes" .or. trim(value) == "YES" .or. trim(value) == "1")
    end if

    ! Get regrid method
    write (current_line, '(A,A)') trim(label), "REGRID_METHOD:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, current_line, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      read (current_line, *, iostat=localrc) stream_config%regrid_method
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                              msg="Invalid regrid method value", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
    end if

    ! Get regrid file
    write (current_line, '(A,A)') trim(label), "REGRID_FILE:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, stream_config%regrid_file, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

    ! Count fields for this stream
    field_count = 0
    do
      write (current_line, '(A,I0,A)') trim(label), "FIELD_", field_count + 1, "_NAME:"
      call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      if (.not. found) exit
      field_count = field_count + 1
    end do
    stream_config%field_count = field_count

    ! Allocate field arrays if there are fields
    if (field_count > 0) then
      allocate (stream_config%field_names(field_count), stat=localrc)
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                              msg="Failed to allocate field names array", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      allocate (stream_config%field_units(field_count), stat=localrc)
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                              msg="Failed to allocate field units array", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      allocate (stream_config%field_longnames(field_count), stat=localrc)
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                              msg="Failed to allocate field longnames array", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      allocate (stream_config%field_levels(field_count), stat=localrc)
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                              msg="Failed to allocate field levels array", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      allocate (stream_config%field_time_avg(field_count), stat=localrc)
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                              msg="Failed to allocate field time_avg array", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      ! Initialize field arrays
      do i = 1, field_count
        ! Get field name
        write (current_line, '(A,I0,A)') trim(label), "FIELD_", i, "_NAME:"
        call ESMF_ConfigGetAttribute(config%esmf_config, stream_config%field_names(i), &
                                     label=trim(current_line), rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return

        ! Get field units
        write (current_line, '(A,I0,A)') trim(label), "FIELD_", i, "_UNITS:"
        call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
        if (found) then
          call ESMF_ConfigGetAttribute(config%esmf_config, stream_config%field_units(i), &
                                       label=trim(current_line), rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return
        else
          stream_config%field_units(i) = ""
        end if

        ! Get field longname
        write (current_line, '(A,I0,A)') trim(label), "FIELD_", i, "_LONGNAME:"
        call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
        if (found) then
          call ESMF_ConfigGetAttribute(config%esmf_config, stream_config%field_longnames(i), &
                                       label=trim(current_line), rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return
        else
          stream_config%field_longnames(i) = ""
        end if

        ! Get field levels
        write (current_line, '(A,I0,A)') trim(label), "FIELD_", i, "_LEVELS:"
        call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
        if (found) then
          call ESMF_ConfigGetAttribute(config%esmf_config, current_line, &
                                       label=trim(current_line), rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return
          read (current_line, *, iostat=localrc) stream_config%field_levels(i)
          if (localrc /= 0) then
            stream_config%field_levels(i) = ESMF_IO_Defaults%default_field_levels  ! Use default if not specified
          end if
        else
          stream_config%field_levels(i) = ESMF_IO_Defaults%default_field_levels
        end if

        ! Get field time_avg flag
        write (current_line, '(A,I0,A)') trim(label), "FIELD_", i, "_TIME_AVG:"
        call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
        if (found) then
          call ESMF_ConfigGetAttribute(config%esmf_config, value, &
                                       label=trim(current_line), rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return
          stream_config%field_time_avg(i) = (trim(value) == "true" .or. trim(value) == "TRUE" .or. &
                                             trim(value) == "yes" .or. trim(value) == "YES" .or. trim(value) == "1")
        else
          stream_config%field_time_avg(i) = ESMF_IO_Defaults%default_field_time_avg
        end if
      end do
    end if

  end subroutine ESMF_IO_ConfigParseInputStream

  !> Parse output collection configuration
  subroutine ESMF_IO_ConfigParseOutputCollection(config, collection_index, collection_config, rc)

    type(ESMF_IO_Config), intent(inout) :: config
    integer, intent(in) :: collection_index
    type(ESMF_IO_OutputCollectionConfig), intent(inout) :: collection_config
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    character(len=ESMF_MAXSTR) :: current_line, key, value
    character(len=ESMF_MAXSTR) :: label
    character(len=ESMF_MAXSTR) :: error_msg
    logical :: found
    integer :: field_count
    integer :: i

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Set default values using configuration defaults
    collection_config%name = ""
    collection_config%filename_base = ESMF_IO_Defaults%default_filename_base
    collection_config%filetype = ESMF_IO_Defaults%default_output_filetype
    collection_config%append_packed_files = ESMF_IO_Defaults%default_append_packed_files
    collection_config%do_avg = ESMF_IO_Defaults%default_do_avg
    collection_config%do_max = ESMF_IO_Defaults%default_do_max
    collection_config%do_min = ESMF_IO_Defaults%default_do_min
    collection_config%field_count = 0

    ! Construct label for this collection
    write (label, '(A,I0,A)') "ESMF_IO_COLLECTIONS::COLLECTION_", collection_index, "_"

    ! Get collection name
    write (current_line, '(A,A)') trim(label), "NAME:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, collection_config%name, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    else
      write (error_msg, '(A,I0,A)') "Required parameter missing: Output collection ", collection_index, " NAME"
      call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                            msg=trim(error_msg), &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Get filename base
    write (current_line, '(A,A)') trim(label), "FILENAME_BASE:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, collection_config%filename_base, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    else
      write (error_msg, '(A,I0,A)') "Required parameter missing: Output collection ", collection_index, " FILENAME_BASE"
      call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                            msg=trim(error_msg), &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Get filetype
    write (current_line, '(A,A)') trim(label), "FILETYPE:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, collection_config%filetype, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

    ! Get output frequency
    write (current_line, '(A,A)') trim(label), "OUTPUT_FREQUENCY:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, current_line, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      ! Parse time interval string
      call ESMF_IO_ParseTimeIntervalString(current_line, collection_config%output_frequency, localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

    ! Get time axis offset
    write (current_line, '(A,A)') trim(label), "TIME_AXIS_OFFSET:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, current_line, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      ! Parse time interval string
      call ESMF_IO_ParseTimeIntervalString(current_line, collection_config%time_axis_offset, localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

    ! Get append packed files flag
    write (current_line, '(A,A)') trim(label), "APPEND_PACKED_FILES:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, value, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      collection_config%append_packed_files = (trim(value) == "true" .or. trim(value) == "TRUE" .or. &
                                               trim(value) == "yes" .or. trim(value) == "YES" .or. trim(value) == "1")
    else
      collection_config%append_packed_files = .false.
    end if

    ! Get do_avg flag
    write (current_line, '(A,A)') trim(label), "DO_AVG:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, value, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      collection_config%do_avg = (trim(value) == "true" .or. trim(value) == "TRUE" .or. &
                                  trim(value) == "yes" .or. trim(value) == "YES" .or. trim(value) == "1")
    else
      collection_config%do_avg = .true.
    end if

    ! Get do_max flag
    write (current_line, '(A,A)') trim(label), "DO_MAX:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, value, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      collection_config%do_max = (trim(value) == "true" .or. trim(value) == "TRUE" .or. &
                                  trim(value) == "yes" .or. trim(value) == "YES" .or. trim(value) == "1")
    else
      collection_config%do_max = .false.
    end if

    ! Get do_min flag
    write (current_line, '(A,A)') trim(label), "DO_MIN:"
    call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    if (found) then
      call ESMF_ConfigGetAttribute(config%esmf_config, value, &
                                   label=trim(current_line), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      collection_config%do_min = (trim(value) == "true" .or. trim(value) == "TRUE" .or. &
                                  trim(value) == "yes" .or. trim(value) == "YES" .or. trim(value) == "1")
    else
      collection_config%do_min = .false.
    end if

    ! Count fields for this collection
    field_count = 0
    do
      write (current_line, '(A,I0,A)') trim(label), "FIELD_", field_count + 1, "_NAME:"
      call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      if (.not. found) exit
      field_count = field_count + 1
    end do
    collection_config%field_count = field_count

    ! Allocate field arrays if there are fields
    if (field_count > 0) then
      allocate (collection_config%field_names(field_count), stat=localrc)
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                              msg="Failed to allocate field names array", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      allocate (collection_config%field_units(field_count), stat=localrc)
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                              msg="Failed to allocate field units array", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      allocate (collection_config%field_longnames(field_count), stat=localrc)
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                              msg="Failed to allocate field longnames array", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      allocate (collection_config%field_levels(field_count), stat=localrc)
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                              msg="Failed to allocate field levels array", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      ! Initialize field arrays
      do i = 1, field_count
        ! Get field name
        write (current_line, '(A,I0,A)') trim(label), "FIELD_", i, "_NAME:"
        call ESMF_ConfigGetAttribute(config%esmf_config, collection_config%field_names(i), &
                                     label=trim(current_line), rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return

        ! Get field units
        write (current_line, '(A,I0,A)') trim(label), "FIELD_", i, "_UNITS:"
        call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
        if (found) then
          call ESMF_ConfigGetAttribute(config%esmf_config, collection_config%field_units(i), &
                                       label=trim(current_line), rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return
        else
          collection_config%field_units(i) = ""
        end if

        ! Get field longname
        write (current_line, '(A,I0,A)') trim(label), "FIELD_", i, "_LONGNAME:"
        call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
        if (found) then
          call ESMF_ConfigGetAttribute(config%esmf_config, collection_config%field_longnames(i), &
                                       label=trim(current_line), rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return
        else
          collection_config%field_longnames(i) = ""
        end if

        ! Get field levels
        write (current_line, '(A,I0,A)') trim(label), "FIELD_", i, "_LEVELS:"
        call ESMF_ConfigFindLabel(config%esmf_config, label=trim(current_line), isPresent=found, rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
        if (found) then
          call ESMF_ConfigGetAttribute(config%esmf_config, current_line, &
                                       label=trim(current_line), rc=localrc)
          if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return
          read (current_line, *, iostat=localrc) collection_config%field_levels(i)
          if (localrc /= 0) then
            collection_config%field_levels(i) = ESMF_IO_Defaults%default_field_levels  ! Use default if not specified
          end if
        else
          collection_config%field_levels(i) = ESMF_IO_Defaults%default_field_levels
        end if
      end do
    end if

  end subroutine ESMF_IO_ConfigParseOutputCollection

  !> Finalize the configuration system
  subroutine ESMF_IO_ConfigFinalize(config, rc)

    type(ESMF_IO_Config), intent(inout) :: config
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer :: i

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Deallocate input streams
    if (allocated(config%input_streams)) then
      do i = 1, size(config%input_streams)
        if (allocated(config%input_streams(i)%field_names)) then
          deallocate (config%input_streams(i)%field_names, stat=localrc)
        end if
        if (allocated(config%input_streams(i)%field_units)) then
          deallocate (config%input_streams(i)%field_units, stat=localrc)
        end if
        if (allocated(config%input_streams(i)%field_longnames)) then
          deallocate (config%input_streams(i)%field_longnames, stat=localrc)
        end if
        if (allocated(config%input_streams(i)%field_levels)) then
          deallocate (config%input_streams(i)%field_levels, stat=localrc)
        end if
        if (allocated(config%input_streams(i)%field_time_avg)) then
          deallocate (config%input_streams(i)%field_time_avg, stat=localrc)
        end if
      end do
      deallocate (config%input_streams, stat=localrc)
    end if

    ! Deallocate output collections
    if (allocated(config%output_collections)) then
      do i = 1, size(config%output_collections)
        if (allocated(config%output_collections(i)%field_names)) then
          deallocate (config%output_collections(i)%field_names, stat=localrc)
        end if
        if (allocated(config%output_collections(i)%field_units)) then
          deallocate (config%output_collections(i)%field_units, stat=localrc)
        end if
        if (allocated(config%output_collections(i)%field_longnames)) then
          deallocate (config%output_collections(i)%field_longnames, stat=localrc)
        end if
        if (allocated(config%output_collections(i)%field_levels)) then
          deallocate (config%output_collections(i)%field_levels, stat=localrc)
        end if
      end do
      deallocate (config%output_collections, stat=localrc)
    end if

    ! Destroy ESMF_Config object
    call ESMF_ConfigDestroy(config%esmf_config, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Reset initialization flag
    config%is_initialized = .false.

  end subroutine ESMF_IO_ConfigFinalize

  !> Parse time string to ESMF_Time
  subroutine ESMF_IO_ParseTimeString(time_string, parsed_esmf_time, rc)

    character(len=*), intent(in) :: time_string
    type(ESMF_Time), intent(out) :: parsed_esmf_time
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer :: year, month, day, hour, minute, second
    character(len=len(time_string)) :: temp_str
    integer :: ios
    integer :: i  ! Add missing variable declaration

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Parse the time string (format: YYYY-MM-DD-HH:mm:ss or YYYY-MM-DD HH:mm:ss)
    temp_str = time_string
    ! Try to read with hyphens first
    read (temp_str, *, iostat=ios) year, month, day, hour, minute, second
    if (ios /= 0) then
      ! Try alternative format with space separator
      temp_str = time_string
      ! Replace hyphens with spaces manually
      do i = 1, len_trim(temp_str)
        if (temp_str(i:i) == '-') temp_str(i:i) = ' '
      end do
      read (temp_str, *, iostat=ios) year, month, day, hour, minute, second
      if (ios /= 0) then
        call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                              msg="Invalid time string format: "//trim(time_string), &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
    end if

    ! Create ESMF_Time
    call ESMF_TimeSet(parsed_esmf_time, yy=year, mm=month, dd=day, &
                      h=hour, m=minute, s=second, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  end subroutine ESMF_IO_ParseTimeString

  !> Parse time interval string to ESMF_TimeInterval
  subroutine ESMF_IO_ParseTimeIntervalString(interval_string, parsed_esmf_interval, rc)

    character(len=*), intent(in) :: interval_string
    type(ESMF_TimeInterval), intent(out) :: parsed_esmf_interval
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer :: hours, minutes, seconds
    character(len=len(interval_string)) :: temp_str
    integer :: ios
    integer :: idx

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Parse the interval string (format: PTnH or PTnM or PTnS)
    temp_str = interval_string
    hours = 0
    minutes = 0
    seconds = 0

    ! Look for PTnH pattern
    idx = index(temp_str, 'H')
    if (idx > 0) then
      read (temp_str(3:idx - 1), *, iostat=ios) hours
      if (ios /= 0) then
        call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                              msg="Invalid time interval string format: "//trim(interval_string), &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
    end if

    ! Look for PTnM pattern
    idx = index(temp_str, 'M')
    if (idx > 0 .and. temp_str(idx - 1:idx - 1) /= 'T') then
      read (temp_str(3:idx - 1), *, iostat=ios) minutes
      if (ios /= 0) then
        call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                              msg="Invalid time interval string format: "//trim(interval_string), &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
    end if

    ! Look for PTnS pattern
    idx = index(temp_str, 'S')
    if (idx > 0) then
      read (temp_str(3:idx - 1), *, iostat=ios) seconds
      if (ios /= 0) then
        call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                              msg="Invalid time interval string format: "//trim(interval_string), &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
    end if

    ! Create ESMF_TimeInterval
    call ESMF_TimeIntervalSet(parsed_esmf_interval, h=hours, m=minutes, s=seconds, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  end subroutine ESMF_IO_ParseTimeIntervalString

  !> Parse calendar string to ESMF_CalKind_Flag
  subroutine ESMF_IO_ParseCalendarString(calendar_string, calendar_kind, rc)

    character(len=*), intent(in) :: calendar_string
    integer, intent(out) :: calendar_kind
    integer, intent(out) :: rc

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Set default
    calendar_kind = 1 ! ESMF_CALKIND_GREGORIAN

    ! Parse calendar string
    select case (trim(calendar_string))
    case ("GREGORIAN", "gregorian")
      calendar_kind = 1 ! ESMF_CALKIND_GREGORIAN
    case ("NO_LEAP", "no_leap", "NOLEAP")
      calendar_kind = 2 ! ESMF_CALKIND_NOLEAP
    case ("360_DAY", "360day")
      calendar_kind = 3 ! ESMF_CALKIND_360DAY
    case ("JULIAN", "julian")
      calendar_kind = 6 ! ESMF_CALKIND_JULIAN
    case ("PROLEPTIC_GREGORIAN", "proleptic_gregorian")
      calendar_kind = 4  ! ESMF_CALKIND_PROLEPTIC_GREGORIAN
    case ("THIRTY_DAY_MONTHS", "thirty_day_months")
      calendar_kind = 5  ! ESMF_CALKIND_THIRTY_DAY_MONTHS
    case default
      ! Keep default value
    end select
  end subroutine ESMF_IO_ParseCalendarString

end module ESMF_IO_Config_Mod
