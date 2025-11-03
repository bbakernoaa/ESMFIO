# Memory Management Documentation

This document provides a comprehensive overview of memory management in the ESMF_IO Unified Component, covering design principles, implementation strategies, and best practices.

## Overview

ESMF_IO implements a comprehensive memory management system that balances performance, resource utilization, and robustness. This document describes the memory management architecture, patterns, and mechanisms used throughout the component.

## Memory Management Architecture

### ESMF Memory Management Foundation

ESMF_IO builds upon ESMF's memory management mechanisms:

1. **ESMF Object Management**:
   - Automatic memory management for ESMF objects
   - Reference counting for shared objects
   - Proper object destruction and cleanup

2. **Fortran Memory Management**:
   - Fortran 2003+ allocatable arrays
   - Automatic deallocation on scope exit
   - Explicit deallocation for long-lived objects

3. **Hybrid Approach**:
   - ESMF-managed objects for ESMF integration
   - Manual management for performance-critical arrays
   - Pool allocation for frequently allocated objects

### ESMF_IO Memory Extensions

ESMF_IO extends ESMF's memory management with:

1. **Specialized Memory Pools**:
   - Field buffer pools for temporal processing
   - Accumulator field pools for time averaging
   - Configuration object pools for runtime efficiency

2. **Memory Tracking and Debugging**:
   - Allocation tracking for leak detection
   - Memory usage monitoring and reporting
   - Debugging aids for memory-related issues

3. **Advanced Memory Management**:
   - Memory-mapped files for large datasets
   - Zero-copy data sharing between components
   - Memory-efficient data structures for sparse data

## Memory Allocation Strategies

### Pre-allocation Pattern

ESMF_IO extensively uses pre-allocation to minimize runtime allocation overhead:

```fortran
type, private :: ESMF_IO_InternalState
  ! Pre-allocated field buffers for temporal interpolation
  type(ESMF_Field), allocatable :: field_buffer_t1(:)
  type(ESMF_Field), allocatable :: field_buffer_t2(:)
  type(ESMF_Time), allocatable :: time_buffer_t1(:)
  type(ESMF_Time), allocatable :: time_buffer_t2(:)
  
  ! Pre-allocated accumulator fields for time averaging
  type(ESMF_Field), allocatable :: accumulator_fields(:)
  type(ESMF_Field), allocatable :: accumulator_counts(:)
  type(ESMF_Field), allocatable :: max_fields(:)
  type(ESMF_Field), allocatable :: min_fields(:)
  
  ! Configuration-dependent allocations
  type(ESMF_IO_InputStreamConfig), allocatable :: input_streams(:)
  type(ESMF_IO_OutputCollectionConfig), allocatable :: output_collections(:)
  
  ! State tracking
  logical :: is_initialized = .false.
end type ESMF_IO_InternalState
```

### Dynamic Allocation Pattern

For situations where allocation size is unknown at compile time:

```fortran
subroutine ESMF_IO_AllocateBuffers(internal_state, config, rc)
  type(ESMF_IO_InternalState), intent(inout) :: internal_state
  type(ESMF_IO_Config), intent(in) :: config
  integer, intent(out) :: rc

  ! Local variables
  integer :: localrc
  integer :: total_field_count
  integer :: i, j

  ! Initialize return code
  rc = ESMF_SUCCESS

  ! Calculate total field count across all input streams
  total_field_count = 0
  do i = 1, config%input_stream_count
    total_field_count = total_field_count + config%input_streams(i)%field_count
  end do

  ! Allocate temporal buffers
  if (allocated(internal_state%field_buffer_t1)) then
    deallocate(internal_state%field_buffer_t1, stat=localrc)
    if (ESMF_LogFoundDeallocError(statusToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return
  end if

  if (allocated(internal_state%field_buffer_t2)) then
    deallocate(internal_state%field_buffer_t2, stat=localrc)
    if (ESMF_LogFoundDeallocError(statusToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return
  end if

  allocate(internal_state%field_buffer_t1(total_field_count), &
           internal_state%field_buffer_t2(total_field_count), &
           stat=localrc)
  if (ESMF_LogFoundAllocError(statusToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  ! Initialize buffers
  do i = 1, total_field_count
    internal_state%field_buffer_t1(i) = ESMF_FieldCreate(rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                          line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    internal_state%field_buffer_t2(i) = ESMF_FieldCreate(rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                          line=__LINE__, file=__FILE__, rcToReturn=rc)) return
  end do

end subroutine ESMF_IO_AllocateBuffers
```

### Pool Allocation Pattern

For frequently allocated/deallocated objects:

```fortran
module ESMF_IO_MemoryPool_Mod
  use ESMF
  implicit none

  private

  ! Memory pool for field buffers
  type, private :: ESMF_IO_FieldBufferPool
    type(ESMF_Field), allocatable :: available_buffers(:)
    integer :: pool_size = 0
    integer :: available_count = 0
  end type ESMF_IO_FieldBufferPool

  ! Global memory pools
  type(ESMF_IO_FieldBufferPool), save :: field_buffer_pool

contains

  function ESMF_IO_GetFieldBuffer() result(buffer)
    type(ESMF_Field) :: buffer
    integer :: localrc

    ! Check if there's an available buffer in the pool
    if (field_buffer_pool%available_count > 0) then
      ! Reuse an existing buffer
      buffer = field_buffer_pool%available_buffers(field_buffer_pool%available_count)
      field_buffer_pool%available_count = field_buffer_pool%available_count - 1
    else
      ! Create a new buffer
      buffer = ESMF_FieldCreate(rc=localrc)
      ! Note: Error handling omitted for brevity
    end if
  end function ESMF_IO_GetFieldBuffer

  subroutine ESMF_IO_ReturnFieldBuffer(buffer)
    type(ESMF_Field), intent(inout) :: buffer
    integer :: localrc

    ! Check if the pool has space for another buffer
    if (field_buffer_pool%available_count < field_buffer_pool%pool_size) then
      ! Return the buffer to the pool
      field_buffer_pool%available_count = field_buffer_pool%available_count + 1
      field_buffer_pool%available_buffers(field_buffer_pool%available_count) = buffer
      
      ! Reset the buffer for reuse
      call ESMF_FieldZero(buffer, rc=localrc)
      ! Note: Error handling omitted for brevity
    else
      ! Pool is full, destroy the buffer
      call ESMF_FieldDestroy(buffer, rc=localrc)
      ! Note: Error handling omitted for brevity
    end if
    
    ! Clear the buffer variable
    buffer = ESMF_FieldCreate(kindflag=ESMF_KIND_NONE, rc=localrc)
    ! Note: Error handling omitted for brevity
  end subroutine ESMF_IO_ReturnFieldBuffer

end module ESMF_IO_MemoryPool_Mod
```

## Memory Deallocation Strategies

### Automatic Cleanup

ESMF_IO leverages automatic cleanup mechanisms:

1. **Scope-Based Cleanup**:
   - Automatic deallocation of allocatable arrays at scope exit
   - Exception-safe resource management
   - RAII (Resource Acquisition Is Initialization) patterns

2. **ESMF Object Cleanup**:
   - Automatic destruction of ESMF objects
   - Proper reference counting
   - Cleanup of associated resources

### Explicit Cleanup

For long-lived objects and resources:

```fortran
subroutine ESMF_IO_Cleanup(internal_state, rc)
  type(ESMF_IO_InternalState), intent(inout) :: internal_state
  integer, intent(out) :: rc

  ! Local variables
  integer :: localrc
  integer :: i

  ! Initialize return code
  rc = ESMF_SUCCESS

  ! Destroy temporal buffers
  if (allocated(internal_state%field_buffer_t1)) then
    do i = 1, size(internal_state%field_buffer_t1)
      if (ESMF_FieldIsCreated(internal_state%field_buffer_t1(i))) then
        call ESMF_FieldDestroy(internal_state%field_buffer_t1(i), rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      end if
    end do
    deallocate(internal_state%field_buffer_t1, stat=localrc)
    if (ESMF_LogFoundDeallocError(statusToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return
  end if

  if (allocated(internal_state%field_buffer_t2)) then
    do i = 1, size(internal_state%field_buffer_t2)
      if (ESMF_FieldIsCreated(internal_state%field_buffer_t2(i))) then
        call ESMF_FieldDestroy(internal_state%field_buffer_t2(i), rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      end if
    end do
    deallocate(internal_state%field_buffer_t2, stat=localrc)
    if (ESMF_LogFoundDeallocError(statusToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return
  end if

  ! Destroy accumulator fields
  if (allocated(internal_state%accumulator_fields)) then
    do i = 1, size(internal_state%accumulator_fields)
      if (ESMF_FieldIsCreated(internal_state%accumulator_fields(i))) then
        call ESMF_FieldDestroy(internal_state%accumulator_fields(i), rc=localrc)
        if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                               line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      end if
    end do
    deallocate(internal_state%accumulator_fields, stat=localrc)
    if (ESMF_LogFoundDeallocError(statusToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return
  end if

  ! Destroy configuration objects
  if (allocated(internal_state%input_streams)) then
    deallocate(internal_state%input_streams, stat=localrc)
    if (ESMF_LogFoundDeallocError(statusToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return
  end if

  if (allocated(internal_state%output_collections)) then
    deallocate(internal_state%output_collections, stat=localrc)
    if (ESMF_LogFoundDeallocError(statusToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                                 line=__LINE__, file=__FILE__, rcToReturn=rc)) return
  end if

  ! Mark as uninitialized
  internal_state%is_initialized = .false.

end subroutine ESMF_IO_Cleanup
```

### Smart Pointer Pattern

For managing complex object lifetimes:

```fortran
module ESMF_IO_SmartPointer_Mod
  use ESMF
  implicit none

  private

  ! Smart pointer for ESMF_Field objects
  type, private :: ESMF_IO_SmartFieldPtr
    type(ESMF_Field), pointer :: ptr => null()
    integer :: ref_count = 0
  contains
    procedure :: assign => ESMF_IO_SmartFieldPtrAssign
    procedure :: release => ESMF_IO_SmartFieldPtrRelease
    procedure :: get => ESMF_IO_SmartFieldPtrGet
  end type ESMF_IO_SmartFieldPtr

contains

  subroutine ESMF_IO_SmartFieldPtrAssign(this, field)
    class(ESMF_IO_SmartFieldPtr), intent(inout) :: this
    type(ESMF_Field), intent(in) :: field

    ! Release any existing field
    call this%release()

    ! Assign new field and increment reference count
    this%ptr => field
    this%ref_count = 1
  end subroutine ESMF_IO_SmartFieldPtrAssign

  subroutine ESMF_IO_SmartFieldPtrRelease(this)
    class(ESMF_IO_SmartFieldPtr), intent(inout) :: this
    integer :: localrc

    if (associated(this%ptr)) then
      this%ref_count = this%ref_count - 1
      if (this%ref_count <= 0) then
        ! Last reference, destroy the field
        call ESMF_FieldDestroy(this%ptr, rc=localrc)
        ! Note: Error handling omitted for brevity
        nullify(this%ptr)
      end if
    end if
  end subroutine ESMF_IO_SmartFieldPtrRelease

  function ESMF_IO_SmartFieldPtrGet(this) result(field)
    class(ESMF_IO_SmartFieldPtr), intent(in) :: this
    type(ESMF_Field) :: field

    if (associated(this%ptr)) then
      field = this%ptr
    end if
  end function ESMF_IO_SmartFieldPtrGet

end module ESMF_IO_SmartPointer_Mod
```

## Memory Usage Optimization

### Buffer Management

ESMF_IO optimizes buffer usage for efficient memory utilization:

1. **Buffer Reuse**:
   - Reuse field buffers for temporal interpolation
   - Recycle accumulator fields for time averaging
   - Minimize buffer reallocation

2. **Buffer Sizing**:
   - Optimize buffer sizes for typical workloads
   - Support dynamic buffer resizing when needed
   - Balance memory usage with performance

3. **Buffer Pooling**:
   - Pool frequently used buffers
   - Reduce allocation/deallocation overhead
   - Improve cache locality

### Data Structure Optimization

ESMF_IO uses optimized data structures for memory efficiency:

1. **Compact Representations**:
   - Use appropriate data types (integers, reals, etc.)
   - Pack related data together
   - Eliminate unnecessary padding

2. **Sparse Data Handling**:
   - Efficient representation of sparse fields
   - Compression for constant or near-constant data
   - Special handling for missing data values

3. **Cache-Friendly Access Patterns**:
   - Organize data for sequential access
   - Minimize cache misses
   - Optimize for common access patterns

### Memory-Mapped Files

For very large datasets, ESMF_IO can use memory-mapped files:

```fortran
module ESMF_IO_MemMap_Mod
  use ESMF
  implicit none

  private

  ! Memory-mapped file descriptor
  type, private :: ESMF_IO_MemMappedFile
    character(len=ESMF_MAXPATHLEN) :: filename
    integer :: file_descriptor = -1
    integer(c_intptr_t) :: memory_address = 0
    integer(c_size_t) :: file_size = 0
    logical :: is_mapped = .false.
  contains
    procedure :: map => ESMF_IO_MemMappedFileMap
    procedure :: unmap => ESMF_IO_MemMappedFileUnmap
    procedure :: get_ptr => ESMF_IO_MemMappedFileGetPtr
  end type ESMF_IO_MemMappedFile

contains

  subroutine ESMF_IO_MemMappedFileMap(this, filename, rc)
    class(ESMF_IO_MemMappedFile), intent(inout) :: this
    character(len=*), intent(in) :: filename
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc
    integer(c_int) :: fd
    integer(c_intptr_t) :: addr
    integer(c_size_t) :: size

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Open the file
    fd = open(trim(filename)//c_null_char, O_RDONLY, S_IRUSR)
    if (fd == -1) then
      call ESMF_LogSetError(ESMF_RC_FILE_READ, &
                           msg="Failed to open file: "//trim(filename), &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if
    this%file_descriptor = fd

    ! Get file size
    size = lseek(fd, 0, SEEK_END)
    if (size == -1) then
      call ESMF_LogSetError(ESMF_RC_FILE_READ, &
                           msg="Failed to get file size: "//trim(filename), &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if
    this%file_size = size

    ! Reset file position
    lseek(fd, 0, SEEK_SET)

    ! Map the file into memory
    addr = mmap(C_NULL_PTR, size, PROT_READ, MAP_PRIVATE, fd, 0)
    if (addr == -1) then
      call ESMF_LogSetError(ESMF_RC_FILE_READ, &
                           msg="Failed to map file into memory: "//trim(filename), &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if
    this%memory_address = addr
    this%is_mapped = .true.
    this%filename = filename

  end subroutine ESMF_IO_MemMappedFileMap

  subroutine ESMF_IO_MemMappedFileUnmap(this, rc)
    class(ESMF_IO_MemMappedFile), intent(inout) :: this
    integer, intent(out) :: rc

    ! Local variables
    integer :: localrc

    ! Initialize return code
    rc = ESMF_SUCCESS

    if (this%is_mapped) then
      ! Unmap the file
      if (munmap(this%memory_address, this%file_size) /= 0) then
        call ESMF_LogSetError(ESMF_RC_FILE_READ, &
                             msg="Failed to unmap file: "//trim(this%filename), &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      ! Close the file
      if (close(this%file_descriptor) /= 0) then
        call ESMF_LogSetError(ESMF_RC_FILE_READ, &
                             msg="Failed to close file: "//trim(this%filename), &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if

      ! Reset state
      this%is_mapped = .false.
      this%memory_address = 0
      this%file_size = 0
      this%file_descriptor = -1
      this%filename = ""
    end if

  end subroutine ESMF_IO_MemMappedFileUnmap

  function ESMF_IO_MemMappedFileGetPtr(this) result(ptr)
    class(ESMF_IO_MemMappedFile), intent(in) :: this
    type(c_ptr) :: ptr

    if (this%is_mapped) then
      ptr = transfer(this%memory_address, ptr)
    else
      ptr = C_NULL_PTR
    end if

  end function ESMF_IO_MemMappedFileGetPtr

end module ESMF_IO_MemMap_Mod
```

## Memory Leak Prevention

### Allocation Tracking

ESMF_IO tracks all allocations to prevent memory leaks:

```fortran
module ESMF_IO_AllocTracker_Mod
  use ESMF
  implicit none

  private

  ! Allocation tracking record
  type, private :: ESMF_IO_AllocRecord
    type(c_ptr) :: ptr = C_NULL_PTR
    integer :: size = 0
    character(len=ESMF_MAXPATHLEN) :: file = ""
    integer :: line = 0
    logical :: is_allocated = .false.
  end type ESMF_IO_AllocRecord

  ! Global allocation tracker
  type(ESMF_IO_AllocRecord), allocatable, save :: alloc_tracker(:)
  integer, save :: alloc_count = 0
  integer, save :: max_allocs = 10000

contains

  subroutine ESMF_IO_TrackAllocation(ptr, size, file, line, rc)
    type(c_ptr), intent(in) :: ptr
    integer, intent(in) :: size
    character(len=*), intent(in) :: file
    integer, intent(in) :: line
    integer, intent(out) :: rc

    ! Local variables
    integer :: i

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Find a free slot or expand the tracker
    if (alloc_count >= size(alloc_tracker)) then
      ! Need to expand the tracker
      call ExpandTracker(rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

    ! Add the allocation record
    alloc_count = alloc_count + 1
    alloc_tracker(alloc_count)%ptr = ptr
    alloc_tracker(alloc_count)%size = size
    alloc_tracker(alloc_count)%file = file
    alloc_tracker(alloc_count)%line = line
    alloc_tracker(alloc_count)%is_allocated = .true.

  end subroutine ESMF_IO_TrackAllocation

  subroutine ESMF_IO_UntrackAllocation(ptr, rc)
    type(c_ptr), intent(in) :: ptr
    integer, intent(out) :: rc

    ! Local variables
    integer :: i

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Find the allocation record
    do i = 1, alloc_count
      if (alloc_tracker(i)%is_allocated .and. c_associated(alloc_tracker(i)%ptr, ptr)) then
        ! Mark as deallocated
        alloc_tracker(i)%is_allocated = .false.
        return
      end if
    end do

    ! Allocation not found - this might indicate a double-free or use-after-free
    call ESMF_LogSetError(ESMF_RC_ARG_WRONG, &
                         msg="Attempted to untrack unknown allocation", &
                         line=__LINE__, file=__FILE__, rcToReturn=rc)

  end subroutine ESMF_IO_UntrackAllocation

  subroutine ESMF_IO_CheckForLeaks(rc)
    integer, intent(out) :: rc

    ! Local variables
    integer :: i
    integer :: leak_count
    character(len=ESMF_MAXPATHLEN) :: leak_info

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Count and report leaks
    leak_count = 0
    do i = 1, alloc_count
      if (alloc_tracker(i)%is_allocated) then
        leak_count = leak_count + 1
        write(leak_info,'(A,I0,A,A,A,I0)') "Leaked allocation of size ", alloc_tracker(i)%size, &
                                          " at ", trim(alloc_tracker(i)%file), ":", alloc_tracker(i)%line
        call ESMF_LogWrite(trim(leak_info), ESMF_LOGMSG_WARNING, rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
                              line=__LINE__, file=__FILE__, rcToReturn=rc)) return
      end if
    end do

    if (leak_count > 0) then
      write(leak_info,'(A,I0,A)') "Total of ", leak_count, " leaked allocations detected"
      call ESMF_LogWrite(trim(leak_info), ESMF_LOGMSG_ERROR, rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

  end subroutine ESMF_IO_CheckForLeaks

  subroutine ExpandTracker(rc)
    integer, intent(out) :: rc

    ! Local variables
    type(ESMF_IO_AllocRecord), allocatable :: new_tracker(:)
    integer :: new_size
    integer :: localrc

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Calculate new size (25% growth or at least 100 slots)
    new_size = max(int(size(alloc_tracker) * 1.25), size(alloc_tracker) + 100)

    ! Allocate new tracker
    allocate(new_tracker(new_size), stat=localrc)
    if (localrc /= 0) then
      call ESMF_LogSetError(ESMF_RC_MEM_FAIL, &
                           msg="Failed to expand allocation tracker", &
                           line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    end if

    ! Copy existing records
    if (allocated(alloc_tracker)) then
      new_tracker(1:size(alloc_tracker)) = alloc_tracker
      deallocate(alloc_tracker, stat=localrc)
      if (localrc /= 0) then
        call ESMF_LogSetError(ESMF_RC_MEM_FAIL, &
                             msg="Failed to deallocate old allocation tracker", &
                             line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      end if
    end if

    ! Replace tracker
    call move_alloc(new_tracker, alloc_tracker)

  end subroutine ExpandTracker

end module ESMF_IO_AllocTracker_Mod
```

### Resource Management

ESMF_IO implements proper resource management:

1. **RAII (Resource Acquisition Is Initialization)**:
   - Acquire resources in constructors
   - Release resources in destructors
   - Exception-safe resource management

2. **Smart Pointers and Handles**:
   - Automatic cleanup of managed resources
   - Exception-safe resource management
   - Proper resource lifetime management

3. **Ownership Semantics**:
   - Clear ownership of resources
   - Transfer of ownership when appropriate
   - Shared ownership with reference counting

## Memory Usage Monitoring

### Memory Profiling

ESMF_IO includes memory profiling capabilities:

```fortran
module ESMF_IO_MemProfiler_Mod
  use ESMF
  implicit none

  private

  ! Memory usage statistics
  type, private :: ESMF_IO_MemStats
    integer(c_size_t) :: peak_memory = 0
    integer(c_size_t) :: current_memory = 0
    integer(c_size_t) :: total_allocated = 0
    integer(c_size_t) :: total_deallocated = 0
    integer :: allocation_count = 0
    integer :: deallocation_count = 0
  end type ESMF_IO_MemStats

  ! Global memory statistics
  type(ESMF_IO_MemStats), save :: mem_stats

contains

  subroutine ESMF_IO_MemAlloc(size, rc)
    integer(c_size_t), intent(in) :: size
    integer, intent(out) :: rc

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Update memory statistics
    mem_stats%current_memory = mem_stats%current_memory + size
    mem_stats%total_allocated = mem_stats%total_allocated + size
    mem_stats%allocation_count = mem_stats%allocation_count + 1

    ! Update peak memory usage
    if (mem_stats%current_memory > mem_stats%peak_memory) then
      mem_stats%peak_memory = mem_stats%current_memory
    end if

    ! Log allocation if requested
    if (ShouldLogAllocations()) then
      call LogAllocation(size, rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

  end subroutine ESMF_IO_MemAlloc

  subroutine ESMF_IO_MemDealloc(size, rc)
    integer(c_size_t), intent(in) :: size
    integer, intent(out) :: rc

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Update memory statistics
    mem_stats%current_memory = mem_stats%current_memory - size
    mem_stats%total_deallocated = mem_stats%total_deallocated + size
    mem_stats%deallocation_count = mem_stats%deallocation_count + 1

    ! Log deallocation if requested
    if (ShouldLogDeallocations()) then
      call LogDeallocation(size, rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
                            line=__LINE__, file=__FILE__, rcToReturn=rc)) return
    end if

  end subroutine ESMF_IO_MemDealloc

  subroutine ESMF_IO_ReportMemUsage(rc)
    integer, intent(out) :: rc

    ! Local variables
    character(len=ESMF_MAXPATHLEN) :: report

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Generate memory usage report
    write(report,'(A,Z0,A)') "Current memory usage: ", mem_stats%current_memory, " bytes"
    call ESMF_LogWrite(trim(report), ESMF_LOGMSG_INFO, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
                          line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    write(report,'(A,Z0,A)') "Peak memory usage: ", mem_stats%peak_memory, " bytes"
    call ESMF_LogWrite(trim(report), ESMF_LOGMSG_INFO, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
                          line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    write(report,'(A,Z0,A)') "Total allocated: ", mem_stats%total_allocated, " bytes"
    call ESMF_LogWrite(trim(report), ESMF_LOGMSG_INFO, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
                          line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    write(report,'(A,Z0,A)') "Total deallocated: ", mem_stats%total_deallocated, " bytes"
    call ESMF_LogWrite(trim(report), ESMF_LOGMSG_INFO, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
                          line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    write(report,'(A,I0)') "Total allocations: ", mem_stats%allocation_count
    call ESMF_LogWrite(trim(report), ESMF_LOGMSG_INFO, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
                          line=__LINE__, file=__FILE__, rcToReturn=rc)) return

    write(report,'(A,I0)') "Total deallocations: ", mem_stats%deallocation_count
    call ESMF_LogWrite(trim(report), ESMF_LOGMSG_INFO, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
                          line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  end subroutine ESMF_IO_ReportMemUsage

  function ShouldLogAllocations() result(should_log)
    logical :: should_log

    ! Log every 1000th allocation or allocations larger than 1MB
    should_log = (mod(mem_stats%allocation_count, 1000) == 0) .or. &
                 (mem_stats%current_memory > 1024*1024)

  end function ShouldLogAllocations

  function ShouldLogDeallocations() result(should_log)
    logical :: should_log

    ! Log every 1000th deallocation or deallocations larger than 1MB
    should_log = (mod(mem_stats%deallocation_count, 1000) == 0) .or. &
                 (mem_stats%current_memory > 1024*1024)

  end function ShouldLogDeallocations

  subroutine LogAllocation(size, rc)
    integer(c_size_t), intent(in) :: size
    integer, intent(out) :: rc

    ! Local variables
    character(len=ESMF_MAXPATHLEN) :: log_msg

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Log allocation
    write(log_msg,'(A,Z0,A,I0,A)') "Allocated ", size, " bytes (", mem_stats%allocation_count, ")"
    call ESMF_LogWrite(trim(log_msg), ESMF_LOGMSG_DEBUG, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
                          line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  end subroutine LogAllocation

  subroutine LogDeallocation(size, rc)
    integer(c_size_t), intent(in) :: size
    integer, intent(out) :: rc

    ! Local variables
    character(len=ESMF_MAXPATHLEN) :: log_msg

    ! Initialize return code
    rc = ESMF_SUCCESS

    ! Log deallocation
    write(log_msg,'(A,Z0,A,I0,A)') "Deallocated ", size, " bytes (", mem_stats%deallocation_count, ")"
    call ESMF_LogWrite(trim(log_msg), ESMF_LOGMSG_DEBUG, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
                          line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  end subroutine LogDeallocation

end module ESMF_IO_MemProfiler_Mod
```

### Memory Usage Reporting

ESMF_IO provides detailed memory usage reporting:

```fortran
subroutine ESMF_IO_ReportDetailedMemUsage(component, rc)
  type(ESMF_GridComp), intent(in) :: component
  integer, intent(out) :: rc

  ! Local variables
  integer :: localrc
  type(ESMF_IO_InternalState), pointer :: io_state
  character(len=ESMF_MAXPATHLEN) :: report
  integer :: i

  ! Initialize return code
  rc = ESMF_SUCCESS

  ! Get the internal state
  call ESMF_GridCompGetInternalState(component, io_state, localrc)
  if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                        line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  ! Report component-level memory usage
  call ESMF_LogWrite("=== ESMF_IO Memory Usage Report ===", ESMF_LOGMSG_INFO, rc=localrc)
  if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                        line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  ! Report configuration memory usage
  write(report,'(A,I0,A)') "Number of input streams: ", io_state%config%input_stream_count
  call ESMF_LogWrite(trim(report), ESMF_LOGMSG_INFO, rc=localrc)
  if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                        line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  write(report,'(A,I0,A)') "Number of output collections: ", io_state%config%output_collection_count
  call ESMF_LogWrite(trim(report), ESMF_LOGMSG_INFO, rc=localrc)
  if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                        line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  ! Report field buffer memory usage
  write(report,'(A,I0,A)') "Temporal buffer field count: ", size(io_state%field_buffer_t1)
  call ESMF_LogWrite(trim(report), ESMF_LOGMSG_INFO, rc=localrc)
  if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                        line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  ! Report accumulator field memory usage
  write(report,'(A,I0,A)') "Accumulator field count: ", size(io_state%accumulator_fields)
  call ESMF_LogWrite(trim(report), ESMF_LOGMSG_INFO, rc=localrc)
  if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                        line=__LINE__, file=__FILE__, rcToReturn=rc)) return

  ! Report per-stream memory usage
  do i = 1, io_state%config%input_stream_count
    write(report,'(A,I0,A,I0,A)') "Stream ", i, " field count: ", &
                                  io_state%config%input_streams(i)%field_count
    call ESMF_LogWrite(trim(report), ESMF_LOGMSG_INFO, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                          line=__LINE__, file=__FILE__, rcToReturn=rc)) return
  end do

  ! Report per-collection memory usage
  do i = 1, io_state%config%output_collection_count
    write(report,'(A,I0,A,I0,A)') "Collection ", i, " field count: ", &
                                  io_state%config%output_collections(i)%field_count
    call ESMF_LogWrite(trim(report), ESMF_LOGMSG_INFO, rc=localrc)
    if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                          line=__LINE__, file=__FILE__, rcToReturn=rc)) return
  end do

  call ESMF_LogWrite("===================================", ESMF_LOGMSG_INFO, rc=localrc)
  if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
                        line=__LINE__, file=__FILE__, rcToReturn=rc)) return

end subroutine ESMF_IO_ReportDetailedMemUsage
```

## Memory Management Best Practices

### Allocation Guidelines

1. **Minimize Allocations**:
   - Pre-allocate when possible
   - Reuse existing allocations
   - Pool frequently allocated objects

2. **Proper Error Handling**:
   - Check allocation status
   - Handle allocation failures gracefully
   - Provide meaningful error messages

3. **Memory Alignment**:
   - Align data structures for optimal performance
   - Use appropriate padding to prevent cache conflicts
   - Consider SIMD alignment requirements

### Deallocation Guidelines

1. **Explicit Deallocation**:
   - Always explicitly deallocate allocatable arrays
   - Use RAII patterns for automatic cleanup
   - Handle deallocation errors appropriately

2. **Deallocation Order**:
   - Deallocate in reverse order of allocation
   - Handle dependencies between allocations
   - Ensure proper cleanup of complex data structures

3. **Memory Leak Prevention**:
   - Track all allocations
   - Implement automatic leak detection
   - Use smart pointers for complex ownership scenarios

### Performance Considerations

1. **Cache Efficiency**:
   - Organize data for cache-friendly access patterns
   - Minimize cache misses
   - Use appropriate data structures for access patterns

2. **Memory Bandwidth**:
   - Minimize memory traffic
   - Use streaming stores when appropriate
   - Optimize data layout for memory bandwidth

3. **NUMA Awareness**:
   - Consider NUMA topology in allocation strategies
   - Use NUMA-aware allocation when available
   - Bind threads to appropriate NUMA nodes

## Memory Management Testing

### Unit Testing

Each module should have tests for memory management:

1. **Allocation Testing**:
   - Test successful allocation scenarios
   - Test allocation failure handling
   - Verify proper cleanup after allocation failures

2. **Deallocation Testing**:
   - Test proper deallocation of allocated memory
   - Test deallocation of null pointers
   - Verify no memory leaks after deallocation

3. **Memory Leak Testing**:
   - Test allocation and deallocation balance
   - Verify no memory leaks in normal operation
   - Test memory leak detection mechanisms

### Integration Testing

Integration tests should verify memory management between modules:

1. **Cross-Module Allocations**:
   - Test memory allocation and deallocation across module boundaries
   - Verify proper ownership transfer between modules
   - Test memory leak prevention in module interactions

2. **Configuration-Dependent Memory**:
   - Test memory usage with different configuration scenarios
   - Verify proper cleanup with complex configurations
   - Test memory scalability with large configurations

3. **Runtime Memory Management**:
   - Test memory usage during normal runtime
   - Verify proper cleanup after runtime errors
   - Test memory usage with frequent allocation/deallocation

### Performance Testing

Memory management should not significantly impact performance:

1. **Allocation Overhead**:
   - Measure allocation/deallocation overhead
   - Verify overhead is acceptable for typical workloads
   - Optimize allocation patterns for performance

2. **Memory Usage Scaling**:
   - Test memory usage scaling with problem size
   - Verify memory usage is predictable
   - Test memory usage with large datasets

3. **Cache Performance**:
   - Measure cache performance with different memory layouts
   - Optimize data structures for cache efficiency
   - Test cache performance with different access patterns

## Memory Management Documentation

### User Documentation

Provide clear documentation for users:

1. **Memory Requirements**:
   - Document typical memory usage patterns
   - Provide guidance on memory requirements
   - Include memory usage examples

2. **Configuration Impact**:
   - Document how configuration affects memory usage
   - Provide memory usage guidelines for different configurations
   - Include memory usage optimization tips

3. **Troubleshooting**:
   - Document memory-related error messages
   - Provide memory leak detection and prevention guidance
   - Include memory usage monitoring and reporting

### Developer Documentation

Provide detailed documentation for developers:

1. **Memory Management Patterns**:
   - Document standard memory management patterns
   - Provide code examples and best practices
   - Include memory management design guidelines

2. **Memory Profiling**:
   - Document memory profiling tools and techniques
   - Provide memory profiling examples
   - Include memory usage analysis guidelines

3. **Memory Leak Prevention**:
   - Document memory leak prevention techniques
   - Provide memory leak detection tools and techniques
   - Include memory leak prevention best practices

## Future Improvements

### Planned Enhancements

1. **Advanced Memory Management**:
   - Implement garbage collection for complex scenarios
   - Add support for memory-mapped files
   - Provide memory compression for large datasets

2. **Memory Optimization**:
   - Implement more sophisticated memory pools
   - Add support for compressed memory representations
   - Provide adaptive memory management strategies

3. **Memory Monitoring**:
   - Add support for real-time memory monitoring
   - Implement memory usage prediction
   - Provide memory usage anomaly detection

### Research Directions

1. **Machine Learning for Memory Management**:
   - Use ML to predict and optimize memory usage
   - Implement intelligent memory allocation strategies
   - Provide adaptive memory management based on usage patterns

2. **Quantum Memory Management**:
   - Explore quantum memory management techniques
   - Implement quantum memory allocation and deallocation
   - Provide hybrid classical-quantum memory management

3. **Cloud-Native Memory Management**:
   - Implement cloud-native memory management patterns
   - Add support for distributed memory management
   - Provide containerized memory management

This memory management documentation provides a comprehensive overview of how memory is managed in the ESMF_IO Unified Component. Following these guidelines will help ensure efficient, reliable, and maintainable memory management throughout the component.