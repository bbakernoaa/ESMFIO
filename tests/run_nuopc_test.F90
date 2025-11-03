!> \file
!! \brief Automated test for single model NUOPC app with input data processing
!!
!! This test demonstrates a complete data pipeline: input -> processing (factor application) -> output validation.
program run_nuopc_test

  use ESMF
 use ESMF_IO_NUOPC

  implicit none

  integer :: rc
  type(ESMF_VM) :: vm
  type(ESMF_GridComp) :: model
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
 write(error_msg, '(A,I0,A,I0,A)') "NUOPC ESMF_IO test starting on PE ", &
                                    localPet, " of ", petCount, " PEs"
  call ESMF_LogWrite(trim(error_msg), ESMF_LOGMSG_INFO, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to write startup log", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
 end if

  ! Create the model component
  model = ESMF_GridCompCreate(name="ESMF_IO_NUOPC_Test", rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to create ESMF_IO model component", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  ! Set the services for the model
  call ESMF_GridCompSetServices(model, SetServices, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to set services for ESMF_IO model", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_GridCompDestroy(model, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  ! Execute the model
 call ESMF_GridCompRun(model, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("ESMF_IO model run failed", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_GridCompDestroy(model, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  end if

  ! Finalize the model component
  call ESMF_GridCompFinalize(model, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("ESMF_IO model finalize failed", ESMF_LOGMSG_ERROR, rc=rc)
    ! Continue with destruction despite the error
  end if

  ! Destroy the model
 call ESMF_GridCompDestroy(model, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU)) then
    call ESMF_LogWrite("Failed to destroy ESMF_IO model component", ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
 end if

  ! Log completion information
  write(error_msg, '(A,I0,A,I0,A)') "NUOPC ESMF_IO test completed on PE ", &
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

 ! If we got here, the test ran without errors
  write(*,'(A)') "NUOPC ESMF_IO test completed successfully!"
  write(*,'(A)') "Next step: Run verification script to check output data."

end program run_nuopc_test