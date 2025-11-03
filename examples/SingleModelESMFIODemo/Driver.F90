!> NUOPC Single Model Driver for ESMF_IO Component
!! 
!! This driver creates and runs a single ESMF_IO component following NUOPC patterns.
!! It demonstrates proper component lifecycle management and configuration.

program SingleModelESMFIODriver
  use ESMF
  use ESMF_IO_NUOPC, only: SetServices

  implicit none

  integer :: rc
  type(ESMF_VM) :: vm
  type(ESMF_GridComp) :: singleModel
  type(ESMF_Clock) :: clock
  type(ESMF_Time) :: startTime, stopTime
  type(ESMF_TimeInterval) :: timeStep
  integer :: localPet, petCount
  character(len=ESMF_MAXSTR) :: error_msg

 ! Initialize ESMF
  call ESMF_Initialize(logKindFlag=ESMF_LOGKIND_MULTI, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("ESMF Initialization failed", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  ! Get the VM for logging and process information
  call ESMF_VMGetCurrent(vm, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to get current VM", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  ! Get process information
  call ESMF_VMGet(vm, localPet=localPet, petCount=petCount, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to get VM information", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  ! Log startup information
  write(error_msg, '(A,I0,A,I0,A)') "Single Model ESMF_IO NUOPC Driver starting on PE ", &
                                    localPet, " of ", petCount, " PEs"
  call ESMF_LogWrite(trim(error_msg), ESMF_LOGMSG_INFO, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to write startup log", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  ! Create the single model component
  singleModel = ESMF_GridCompCreate(name="ESMF_IO_SingleModel", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to create ESMF_IO single model component", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  ! Set the services for the single model
 call ESMF_GridCompSetServices(singleModel, SetServices, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to set services for ESMF_IO single model", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_GridCompDestroy(singleModel, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  ! Create a clock for the model
  call ESMF_TimeSet(startTime, yy=2020, mm=1, dd=1, h=0, m=0, s=0, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to set start time", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_GridCompDestroy(singleModel, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  call ESMF_TimeSet(stopTime, yy=2020, mm=1, dd=2, h=0, m=0, s=0, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to set stop time", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_GridCompDestroy(singleModel, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  call ESMF_TimeIntervalSet(timeStep, h=1, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to set time step", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_GridCompDestroy(singleModel, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  clock = ESMF_ClockCreate(startTime=startTime, stopTime=stopTime, &
                           timeStep=timeStep, name="ESMF_IO_Clock", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to create clock", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_GridCompDestroy(singleModel, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  ! Set the clock for the single model component
  call ESMF_GridCompSet(singleModel, clock=clock, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to set clock for single model", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_ClockDestroy(clock, rc=rc)
    call ESMF_GridCompDestroy(singleModel, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  ! Initialize the single model component
  call ESMF_GridCompInitialize(singleModel, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("ESMF_IO single model initialize failed", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_ClockDestroy(clock, rc=rc)
    call ESMF_GridCompDestroy(singleModel, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  ! Run the single model component
  call ESMF_GridCompRun(singleModel, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("ESMF_IO single model run failed", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_ClockDestroy(clock, rc=rc)
    call ESMF_GridCompDestroy(singleModel, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
 end if

  ! Finalize the single model component
  call ESMF_GridCompFinalize(singleModel, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("ESMF_IO single model finalize failed", ESMF_LOGMSG_ERROR, rc=rc)
    ! Continue with destruction despite the error
  end if

  ! Destroy the clock
  call ESMF_ClockDestroy(clock, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to destroy clock", ESMF_LOGMSG_ERROR, rc=rc)
  end if

  ! Destroy the single model
  call ESMF_GridCompDestroy(singleModel, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to destroy ESMF_IO single model component", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  ! Log completion information
  write(error_msg, '(A,I0,A,I0,A)') "Single Model ESMF_IO NUOPC Driver completed on PE ", &
                                    localPet, " of ", petCount, " PEs"
  call ESMF_LogWrite(trim(error_msg), ESMF_LOGMSG_INFO, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to write completion log", ESMF_LOGMSG_ERROR, rc=rc)
  end if

  ! Finalize ESMF
  call ESMF_Finalize(rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("ESMF Finalize failed", ESMF_LOGMSG_ERROR, rc=rc)
    stop
  end if

end program SingleModelESMFIODriver