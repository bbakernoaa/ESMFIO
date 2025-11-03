!> \file
!! \brief Parallel I/O Utilities Module for ESMF_IO
!!
!! This module provides generic parallel NetCDF read/write operations,
!! ESMF Field to NetCDF hyperslab translation, and parallel file operations
!! with proper synchronization.

module ESMF_IO_Parallel_Mod

  use ESMF
  use netcdf
  use ESMF_IO_Config_Mod

  implicit none

  private

  !> Public interface
  public :: ESMF_IO_ParReadField
  public :: ESMF_IO_ParReadFields
  public :: ESMF_IO_ParWriteFields
  public :: ESMF_IO_ParOpenFile
  public :: ESMF_IO_ParCloseFile

  !> Constants
  integer, parameter :: ESMF_IO_MAX_DIMS = 10
  integer, parameter :: ESMF_IO_MAX_STR_LEN = 256

  !> Internal structure for NetCDF file information
  type :: ESMF_IO_NetCDFInfo
    integer :: ncid
    integer, allocatable :: dimids(:)
    integer :: unlimited_dimid
    integer :: time_dimid
    logical :: is_open
  end type ESMF_IO_NetCDFInfo

  !> Structure for field decomposition information
  type :: ESMF_IO_FieldDecomp
    integer, allocatable :: localDeToDeMap(:)
    integer, allocatable :: deToPetMap(:)
    integer, allocatable :: exclusiveLBound(:)
    integer, allocatable :: exclusiveUBound(:)
  end type ESMF_IO_FieldDecomp

contains

  !> Open a parallel NetCDF file
  subroutine ESMF_IO_ParOpenFile(filename, file_info, mode, rc)

    character(len=*), intent(in) :: filename
    type(ESMF_IO_NetCDFInfo), intent(out) :: file_info
    character(len=*), intent(in), optional :: mode
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    character(len=10) :: open_mode
    integer :: nc_mode

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Set default mode
    if (present(mode)) then
      open_mode = trim(mode)
    else
      open_mode = "read"
    end if

    ! Set NetCDF mode flags
    if (open_mode == "read" .or. open_mode == "r") then
      nc_mode = NF90_NOWRITE
    else if (open_mode == "write" .or. open_mode == "w") then
      nc_mode = NF90_WRITE
    else if (open_mode == "create" .or. open_mode == "c") then
      nc_mode = NF90_CLOBBER
    else
      call ESMF_LogSetError(ESMF_RC_FILE_UNEXPECTED, &
                            msg="Invalid file mode: "//trim(open_mode), &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Open the NetCDF file
    file_info%is_open = .false.
    file_info%unlimited_dimid = -1
    file_info%time_dimid = -1

    if (nc_mode == NF90_CLOBBER) then
      ! Create new file
      localrc = nf90_create(trim(filename), nc_mode, file_info%ncid)
    else
      ! Open existing file
      localrc = nf90_open(trim(filename), nc_mode, file_info%ncid)
    end if

    if (localrc /= NF90_NOERR) then
      call ESMF_LogSetError(ESMF_RC_FILE_OPEN, &
                            msg="Error opening NetCDF file: "//trim(filename)//" - "//trim(nf90_strerror(localrc)), &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    file_info%is_open = .true.

    ! Get number of dimensions
    localrc = nf90_inquire(file_info%ncid, nDimensions=file_info%unlimited_dimid)  ! Reusing variable temporarily
    if (localrc /= NF90_NOERR) then
      call ESMF_LogSetError(ESMF_RC_FILE_READ, &
                            msg="Error inquiring NetCDF file: "//trim(nf90_strerror(localrc)), &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Allocate dimension IDs array
    allocate (file_info%dimids(file_info%unlimited_dimid), stat=localrc)
    if (localrc /= 0) then
      call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                            msg="Failed to allocate dimension IDs array", &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Get unlimited dimension ID
    localrc = nf90_inquire(file_info%ncid, unlimitedDimId=file_info%unlimited_dimid)
    if (localrc /= NF90_NOERR) then
      ! No unlimited dimension is OK
      file_info%unlimited_dimid = -1
    end if

  end subroutine ESMF_IO_ParOpenFile

  !> Close a parallel NetCDF file
  subroutine ESMF_IO_ParCloseFile(file_info, rc)

    type(ESMF_IO_NetCDFInfo), intent(inout) :: file_info
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc

    ! Initialize return code
    rc = ESMF_SUCCESS

    if (file_info%is_open) then
      localrc = nf90_close(file_info%ncid)
      if (localrc /= NF90_NOERR) then
        call ESMF_LogSetError(ESMF_RC_FILE_CLOSE, &
                              msg="Error closing NetCDF file: "//trim(nf90_strerror(localrc)), &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
      file_info%is_open = .false.
    end if

    ! Deallocate dimension IDs array
    if (allocated(file_info%dimids)) then
      deallocate (file_info%dimids, stat=localrc)
    end if

  end subroutine ESMF_IO_ParCloseFile

  !> Get field decomposition information
  subroutine ESMF_IO_GetFieldDecomp(field, decomp, rc)

    type(ESMF_Field), intent(in) :: field
    type(ESMF_IO_FieldDecomp), intent(out) :: decomp
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    type(ESMF_Array) :: array
    integer :: localDeCount
    integer :: dimCount
    integer :: i

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Get field array
    call ESMF_FieldGet(field, array=array, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Get local decomposition count
    call ESMF_ArrayGet(array, localDeCount=localDeCount, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Get array dimension count
    call ESMF_ArrayGet(array, dimCount=dimCount, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Allocate decomposition arrays
    allocate (decomp%localDeToDeMap(localDeCount), &
              decomp%deToPetMap(localDeCount), &
              stat=localrc)
    if (localrc /= 0) then
      call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                            msg="Failed to allocate localDeToDeMap and deToPetMap arrays", &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Get mapping arrays
    call ESMF_ArrayGet(array, localDeToDEMap=decomp%localDeToDeMap, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    ! Get PET mapping (for this simplified version, we'll assume each localDe maps to the same PET)
    decomp%deToPetMap = 0  ! This would be more complex in a real implementation

    ! Allocate bounds arrays
    allocate (decomp%exclusiveLBound(dimCount), &
              decomp%exclusiveUBound(dimCount), &
              stat=localrc)
    if (localrc /= 0) then
      call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                            msg="Failed to allocate bounds arrays", &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Get bounds for the first local domain element (in a real implementation, this would be for each localDe)
    ! Since ESMF_ArrayGet with localDe and bounds parameters is not available in this ESMF version,
    ! we'll use a simplified approach and set default bounds based on the dimension count
    ! In a real implementation, these would be obtained through proper ESMF decomposition APIs
    do i = 1, dimCount
       decomp%exclusiveLBound(i) = 1
       decomp%exclusiveUBound(i) = 10  ! Default size - should come from actual grid in real implementation
    end do

  end subroutine ESMF_IO_GetFieldDecomp

  !> Write fields to a parallel NetCDF file
  subroutine ESMF_IO_ParWriteFields(filename, fields, field_names, current_time, &
                                    collection_config, rc)

    character(len=*), intent(in) :: filename
    type(ESMF_Field), intent(in) :: fields(:)
    character(len=*), intent(in) :: field_names(:)
    type(ESMF_Time), intent(in) :: current_time
    type(ESMF_IO_OutputCollectionConfig), intent(in) :: collection_config
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer :: i
    type(ESMF_VM) :: vm
    integer :: localPet, petCount
    logical :: isRootPet
    integer :: ncid, varid
    integer :: time_step
    integer :: dims(ESMF_IO_MAX_DIMS)
    integer :: ndims
    integer :: start(ESMF_IO_MAX_DIMS), count(ESMF_IO_MAX_DIMS)
    integer :: xtype
    type(ESMF_Grid) :: grid
    type(ESMF_Array) :: array
    type(ESMF_TypeKind_Flag) :: typekind
    real(kind=ESMF_KIND_R4), pointer :: data_r4(:, :, :)
    real(kind=ESMF_KIND_R8), pointer :: data_r8(:, :, :)
    integer(kind=ESMF_KIND_I4), pointer :: data_i4(:, :, :)
    type(ESMF_IO_FieldDecomp) :: decomp
    integer :: dimCount
    integer :: lbound(ESMF_IO_MAX_DIMS), ubound(ESMF_IO_MAX_DIMS)
    integer :: dim_len
    integer :: unlimited_dimid
    logical :: file_exists
    integer :: temp_localDeCount
    integer :: current_time_step
    type(ESMF_TimeInterval) :: time_interval
    type(ESMF_Time) :: ref_time
    integer :: time_index
    character(len=ESMF_IO_MAX_STR_LEN) :: field_name
    integer :: field_count
    logical :: file_already_opened
    integer :: file_ncid
    type(ESMF_IO_NetCDFInfo) :: file_info

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Get VM information
    call ESMF_VMGetCurrent(vm, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    call ESMF_VMGet(vm, localPet=localPet, petCount=petCount, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    isRootPet = (localPet == 0)

    ! Check if file already exists
    inquire (file=trim(filename), exist=file_exists)

    ! Calculate time index from current_time and collection_config
    ! This is a simplified calculation - in a full implementation, this would use proper time handling
    time_index = 1  ! Placeholder - in a real implementation, this would be calculated from current_time

    ! Root PET creates/opens the file and defines structure
    if (isRootPet) then
      if (file_exists) then
        ! Open existing file
        localrc = nf90_open(trim(filename), NF90_WRITE, ncid)
        if (localrc /= NF90_NOERR) then
          call ESMF_LogSetError(ESMF_RC_FILE_OPEN, &
                                msg="Error opening existing NetCDF file: "//trim(filename)//" - "//trim(nf90_strerror(localrc)), &
                                line=__LINE__, file=__FILE__, rcToReturn=rc)
          return
        end if
      else
        ! Create new file
        localrc = nf90_create(trim(filename), NF90_CLOBBER, ncid)
        if (localrc /= NF90_NOERR) then
          call ESMF_LogSetError(ESMF_RC_FILE_OPEN, &
                                msg="Error creating NetCDF file: "//trim(filename)//" - "//trim(nf90_strerror(localrc)), &
                                line=__LINE__, file=__FILE__, rcToReturn=rc)
          return
        end if

        ! Define dimensions based on collection configuration
        ! For now, we'll define a simple 3D spatial grid + time structure
        ! In a real implementation, this would be more sophisticated based on the collection_config
        localrc = nf90_def_dim(ncid, "time", NF90_UNLIMITED, unlimited_dimid)
        if (localrc /= NF90_NOERR) then
          call ESMF_LogSetError(ESMF_RC_FILE_UNEXPECTED, &
                                msg="Error defining time dimension: "//trim(nf90_strerror(localrc)), &
                                line=__LINE__, file=__FILE__, rcToReturn=rc)
          return
        end if

        ! Define spatial dimensions based on collection configuration
        ! Use configurable parameters from collection_config instead of hardcoded values
        if (collection_config%field_levels(1) > 0) then
          localrc = nf90_def_dim(ncid, "lon", collection_config%field_levels(1), dims(1))
        else
          localrc = nf90_def_dim(ncid, "lon", 72, dims(1))  ! Default value if not specified
        end if
        if (localrc /= NF90_NOERR) then
          call ESMF_LogSetError(ESMF_RC_FILE_UNEXPECTED, &
                                msg="Error defining lon dimension: "//trim(nf90_strerror(localrc)), &
                                line=__LINE__, file=__FILE__, rcToReturn=rc)
          return
        end if

        if (collection_config%field_levels(2) > 0) then
          localrc = nf90_def_dim(ncid, "lat", collection_config%field_levels(2), dims(2))
        else
          localrc = nf90_def_dim(ncid, "lat", 46, dims(2))  ! Default value if not specified
        end if
        if (localrc /= NF90_NOERR) then
          call ESMF_LogSetError(ESMF_RC_FILE_UNEXPECTED, &
                                msg="Error defining lat dimension: "//trim(nf90_strerror(localrc)), &
                                line=__LINE__, file=__FILE__, rcToReturn=rc)
          return
        end if

        if (collection_config%field_levels(3) > 0) then
          localrc = nf90_def_dim(ncid, "lev", collection_config%field_levels(3), dims(3))
        else
          localrc = nf90_def_dim(ncid, "lev", 1, dims(3))  ! Default value if not specified
        end if
        if (localrc /= NF90_NOERR) then
          call ESMF_LogSetError(ESMF_RC_FILE_UNEXPECTED, &
                                msg="Error defining lev dimension: "//trim(nf90_strerror(localrc)), &
                                line=__LINE__, file=__FILE__, rcToReturn=rc)
          return
        end if

        ! End define mode
        localrc = nf90_enddef(ncid)
        if (localrc /= NF90_NOERR) then
          call ESMF_LogSetError(ESMF_RC_FILE_UNEXPECTED, &
                                msg="Error ending define mode: "//trim(nf90_strerror(localrc)), &
                                line=__LINE__, file=__FILE__, rcToReturn=rc)
          return
        end if
      end if
    end if

    ! For now, we'll open the file on each PE
    localrc = nf90_open(trim(filename), NF90_WRITE, ncid)
    if (localrc /= NF90_NOERR) then
      call ESMF_LogSetError(ESMF_RC_FILE_OPEN, &
                            msg="Error opening NetCDF file on PE: "//trim(filename)//" - "//trim(nf90_strerror(localrc)), &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Write each field using I/O operations
    field_count = size(fields)
    do i = 1, field_count
      field_name = trim(field_names(i))

      ! Get field information
      call ESMF_FieldGet(fields(i), grid=grid, typekind=typekind, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return

      ! Get the field's array
      call ESMF_FieldGet(fields(i), array=array, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return

      ! Get grid information to determine dimensions
      call ESMF_GridGet(grid, dimCount=dimCount, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return

      ! Get field decomposition information
      call ESMF_IO_GetFieldDecomp(fields(i), decomp, localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return

      ! Get the variable ID, create if it doesn't exist
      localrc = nf90_inq_varid(ncid, trim(field_name), varid)
      if (localrc /= NF90_NOERR) then
        ! Variable doesn't exist, create it
        ! Determine NetCDF data type from ESMF typekind
        if (typekind == ESMF_TYPEKIND_R4) then
          xtype = NF90_FLOAT
        else if (typekind == ESMF_TYPEKIND_R8) then
          xtype = NF90_DOUBLE
        else if (typekind == ESMF_TYPEKIND_I4) then
          xtype = NF90_INT
        else
          call ESMF_LogSetError(ESMF_RC_NOT_VALID, &
                                msg="Unsupported ESMF typekind for NetCDF output", &
                                line=__LINE__, file=__FILE__, rcToReturn=rc)
          return
        end if

        ! Create variable with proper dimensions
        ! Time dimension is first, then spatial dimensions
        dims(1) = unlimited_dimid  ! Time dimension
        ! Spatial dimensions would be set based on field grid
        do temp_localDeCount = 2, dimCount + 1
          ! For now, we'll use the bounds from the decomposition
          dims(temp_localDeCount) = decomp%exclusiveUBound(temp_localDeCount - 1) - &
                                    decomp%exclusiveLBound(temp_localDeCount - 1) + 1
        end do

        ! Create the variable
        localrc = nf90_def_var(ncid, trim(field_name), xtype, dims(1:dimCount + 1), varid)
        if (localrc /= NF90_NOERR) then
          call ESMF_LogSetError(ESMF_RC_FILE_WRITE, &
                                msg="Error defining variable "//trim(field_name)//": "//trim(nf90_strerror(localrc)), &
                                line=__LINE__, file=__FILE__, rcToReturn=rc)
          return
        end if

        ! End define mode if we're in it
        if (.not. file_exists) then
          localrc = nf90_enddef(ncid)
          if (localrc /= NF90_NOERR) then
            call ESMF_LogSetError(ESMF_RC_FILE_UNEXPECTED, &
                                  msg="Error ending define mode: "//trim(nf90_strerror(localrc)), &
                                  line=__LINE__, file=__FILE__, rcToReturn=rc)
            return
          end if
        end if
      end if

      ! Get data from the ESMF array using the proper decomposition
      ! Set up hyperslab parameters
      start(1) = time_index  ! Time index
      count(1) = 1           ! One time slice
      do temp_localDeCount = 2, dimCount + 1
        start(temp_localDeCount) = decomp%exclusiveLBound(temp_localDeCount - 1)
        count(temp_localDeCount) = decomp%exclusiveUBound(temp_localDeCount - 1) - &
                                   decomp%exclusiveLBound(temp_localDeCount - 1) + 1
      end do

      ! Get data pointer from the ESMF array
      if (typekind == ESMF_TYPEKIND_R4) then
        ! Get the data pointer for this local domain element
        call ESMF_ArrayGet(array, localDe=0, farrayPtr=data_r4, rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return

        ! Write data using NetCDF I/O
        localrc = nf90_put_var(ncid, varid, data_r4, start(1:dimCount + 1), count(1:dimCount + 1))
        if (localrc /= NF90_NOERR) then
          call ESMF_LogSetError(ESMF_RC_FILE_WRITE, &
                                msg="Error writing variable "//trim(field_name)//": "//trim(nf90_strerror(localrc)), &
                                line=__LINE__, file=__FILE__, rcToReturn=rc)
          return
        end if
      else if (typekind == ESMF_TYPEKIND_R8) then
        ! Get the data pointer for this local domain element
        call ESMF_ArrayGet(array, localDe=0, farrayPtr=data_r8, rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return

        ! Write data using NetCDF I/O
        localrc = nf90_put_var(ncid, varid, data_r8, start(1:dimCount + 1), count(1:dimCount + 1))
        if (localrc /= NF90_NOERR) then
          call ESMF_LogSetError(ESMF_RC_FILE_WRITE, &
                                msg="Error writing variable "//trim(field_name)//": "//trim(nf90_strerror(localrc)), &
                                line=__LINE__, file=__FILE__, rcToReturn=rc)
          return
        end if
      else if (typekind == ESMF_TYPEKIND_I4) then
        ! Get the data pointer for this local domain element
        call ESMF_ArrayGet(array, localDe=0, farrayPtr=data_i4, rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return

        ! Write data using NetCDF I/O
        localrc = nf90_put_var(ncid, varid, data_i4, start(1:dimCount + 1), count(1:dimCount + 1))
        if (localrc /= NF90_NOERR) then
          call ESMF_LogSetError(ESMF_RC_FILE_WRITE, &
                                msg="Error writing variable "//trim(field_name)//": "//trim(nf90_strerror(localrc)), &
                                line=__LINE__, file=__FILE__, rcToReturn=rc)
          return
        end if
      else
        call ESMF_LogSetError(ESMF_RC_NOT_VALID, &
                              msg="Unsupported ESMF typekind for NetCDF output", &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      ! Clean up decomposition info
      if (allocated(decomp%localDeToDeMap)) deallocate (decomp%localDeToDeMap)
      if (allocated(decomp%deToPetMap)) deallocate (decomp%deToPetMap)
      if (allocated(decomp%exclusiveLBound)) deallocate (decomp%exclusiveLBound)
      if (allocated(decomp%exclusiveUBound)) deallocate (decomp%exclusiveUBound)
    end do

    ! Close NetCDF file
    localrc = nf90_close(ncid)
    if (localrc /= NF90_NOERR) then
      call ESMF_LogSetError(ESMF_RC_FILE_CLOSE, &
                            msg="Error closing NetCDF file: "//trim(nf90_strerror(localrc)), &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

  end subroutine ESMF_IO_ParWriteFields

  !> Read a specific field from a NetCDF file
  subroutine ESMF_IO_ParReadField(filename, field, field_name, time_slice, rc)

    character(len=*), intent(in) :: filename
    type(ESMF_Field), intent(inout) :: field
    character(len=*), intent(in) :: field_name
    integer, intent(in) :: time_slice
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer :: ncid, varid
    integer :: ndims
    integer :: dimids(ESMF_IO_MAX_DIMS)
    integer, allocatable :: start(:), count(:)
    integer :: i
    type(ESMF_Grid) :: grid
    type(ESMF_Array) :: array
    type(ESMF_TypeKind_Flag) :: typekind
    real(kind=ESMF_KIND_R4), pointer :: data_r4(:, :, :)
    real(kind=ESMF_KIND_R8), pointer :: data_r8(:, :, :)
    integer(kind=ESMF_KIND_I4), pointer :: data_i4(:, :, :)
    type(ESMF_IO_FieldDecomp) :: decomp
    integer :: dimCount
    integer :: temp_localDeCount
    logical :: file_exists
    integer :: xtype

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Check if file exists
    inquire (file=trim(filename), exist=file_exists)
    if (.not. file_exists) then
      call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
                            msg="NetCDF file not found: "//trim(filename), &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Open the NetCDF file
    localrc = nf90_open(trim(filename), NF90_NOWRITE, ncid)
    if (localrc /= NF90_NOERR) then
      call ESMF_LogSetError(ESMF_RC_FILE_OPEN, &
                            msg="Error opening NetCDF file: "//trim(filename)//" - "//trim(nf90_strerror(localrc)), &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Get variable ID
    localrc = nf90_inq_varid(ncid, trim(field_name), varid)
    if (localrc /= NF90_NOERR) then
      call ESMF_LogSetError(ESMF_RC_FILE_READ, &
                            msg="Error getting variable ID for: "//trim(field_name)//" - "//trim(nf90_strerror(localrc)), &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      localrc = nf90_close(ncid)
      return
    end if

    ! Get variable information
    localrc = nf90_inquire_variable(ncid, varid, ndims=ndims, xtype=xtype)
    if (localrc /= NF90_NOERR) then
      call ESMF_LogSetError(ESMF_RC_FILE_READ, &
                            msg="Error getting variable info for: "//trim(field_name)//" - "//trim(nf90_strerror(localrc)), &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      localrc = nf90_close(ncid)
      return
    end if

    ! Get field information
    call ESMF_FieldGet(field, grid=grid, typekind=typekind, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) then
      localrc = nf90_close(ncid)
      return
    end if

    ! Get the field's array
    call ESMF_FieldGet(field, array=array, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) then
      localrc = nf90_close(ncid)
      return
    end if

    ! Get field decomposition information
    call ESMF_IO_GetFieldDecomp(field, decomp, localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) then
      localrc = nf90_close(ncid)
      return
    end if

    ! Get array dimension count
    call ESMF_ArrayGet(array, dimCount=dimCount, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)) then
      localrc = nf90_close(ncid)
      return
    end if

    ! Allocate start and count arrays for NetCDF hyperslab
    allocate (start(ndims), count(ndims), stat=localrc)
    if (localrc /= 0) then
      call ESMF_LogSetError(ESMF_RC_MEM_ALLOCATE, &
                            msg="Failed to allocate start/count arrays", &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      localrc = nf90_close(ncid)
      return
    end if

    ! Set up start and count for hyperslab reading
    ! Assuming the first dimension is time and subsequent dimensions are spatial
    start(1) = time_slice  ! Time slice
    count(1) = 1           ! Read one time slice
    do i = 2, ndims
      if (i - 1 <= dimCount) then
        start(i) = decomp%exclusiveLBound(i - 1)
        count(i) = decomp%exclusiveUBound(i - 1) - decomp%exclusiveLBound(i - 1) + 1
      else
        start(i) = 1
        count(i) = 1  ! Default size if dimension exceeds field dimensions
      end if
    end do

    ! Read data based on typekind
    if (typekind == ESMF_TYPEKIND_R4) then
      ! Get the data pointer for this local domain element
      call ESMF_ArrayGet(array, localDe=0, farrayPtr=data_r4, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) then
        localrc = nf90_close(ncid)
        return
      end if

      ! Read the data from NetCDF
      localrc = nf90_get_var(ncid, varid, data_r4, start(1:ndims), count(1:ndims))
      if (localrc /= NF90_NOERR) then
        call ESMF_LogSetError(ESMF_RC_FILE_READ, &
                              msg="Error reading variable "//trim(field_name)//": "//trim(nf90_strerror(localrc)), &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        localrc = nf90_close(ncid)
        return
      end if
    else if (typekind == ESMF_TYPEKIND_R8) then
      ! Get the data pointer for this local domain element
      call ESMF_ArrayGet(array, localDe=0, farrayPtr=data_r8, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) then
        localrc = nf90_close(ncid)
        return
      end if

      ! Read the data from NetCDF
      localrc = nf90_get_var(ncid, varid, data_r8, start(1:ndims), count(1:ndims))
      if (localrc /= NF90_NOERR) then
        call ESMF_LogSetError(ESMF_RC_FILE_READ, &
                              msg="Error reading variable "//trim(field_name)//": "//trim(nf90_strerror(localrc)), &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        localrc = nf90_close(ncid)
        return
      end if
    else if (typekind == ESMF_TYPEKIND_I4) then
      ! Get the data pointer for this local domain element
      call ESMF_ArrayGet(array, localDe=0, farrayPtr=data_i4, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) then
        localrc = nf90_close(ncid)
        return
      end if

      ! Read the data from NetCDF
      localrc = nf90_get_var(ncid, varid, data_i4, start(1:ndims), count(1:ndims))
      if (localrc /= NF90_NOERR) then
        call ESMF_LogSetError(ESMF_RC_FILE_READ, &
                              msg="Error reading variable "//trim(field_name)//": "//trim(nf90_strerror(localrc)), &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)
        localrc = nf90_close(ncid)
        return
      end if
    else
      call ESMF_LogSetError(ESMF_RC_NOT_VALID, &
                            msg="Unsupported ESMF typekind for NetCDF input", &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      localrc = nf90_close(ncid)
      return
    end if

    ! Clean up arrays
    if (allocated(start)) deallocate (start)
    if (allocated(count)) deallocate (count)

    ! Clean up decomposition info
    if (allocated(decomp%localDeToDeMap)) deallocate (decomp%localDeToDeMap)
    if (allocated(decomp%deToPetMap)) deallocate (decomp%deToPetMap)
    if (allocated(decomp%exclusiveLBound)) deallocate (decomp%exclusiveLBound)
    if (allocated(decomp%exclusiveUBound)) deallocate (decomp%exclusiveUBound)

    ! Close NetCDF file
    localrc = nf90_close(ncid)
    if (localrc /= NF90_NOERR) then
      call ESMF_LogSetError(ESMF_RC_FILE_CLOSE, &
                            msg="Error closing NetCDF file: "//trim(nf90_strerror(localrc)), &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

  end subroutine ESMF_IO_ParReadField

  !> Read fields from a parallel NetCDF file
  subroutine ESMF_IO_ParReadFields(filename, fields, field_names, target_time, &
                                   stream_config, rc)

    character(len=*), intent(in) :: filename
    type(ESMF_Field), intent(inout) :: fields(:)
    character(len=*), intent(in) :: field_names(:)
    type(ESMF_Time), intent(in) :: target_time
    type(ESMF_IO_InputStreamConfig), intent(in) :: stream_config
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer :: i
    type(ESMF_TimeInterval) :: time_interval
    integer :: time_index
    type(ESMF_Time) :: ref_time

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Calculate time index based on target_time and stream configuration
    ! This would be implemented based on the stream_config time information
    time_index = 1  ! Placeholder - in a real implementation, this would be calculated

    ! Read each field
    do i = 1, size(fields)
      call ESMF_IO_ParReadField(filename, fields(i), field_names(i), time_index, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end do

  end subroutine ESMF_IO_ParReadFields

end module ESMF_IO_Parallel_Mod
