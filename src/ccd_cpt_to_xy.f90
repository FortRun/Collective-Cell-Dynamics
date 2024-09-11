! Help:Begin
! Usage: ccd_cpt_to_xy [-s | --snapshot]
! '-s' or '--snapshot' option outputs config.snapshot consumable by ccd_snapshot
! Help:End

program ccd_cpt_to_xy
    use files
    use utilities, only: help_handler, cmd_line_flag
    use gnuplot, only: gp_xy_dump
    implicit none
    integer :: pending_steps, current_step
    character(len=40) :: params_hash

    call help_handler()

    call cpt_read(timepoint, recnum, pending_steps, current_step, params_hash)
    if (cmd_line_flag('-s') .or. cmd_line_flag('--snapshot')) then
        call xy_dump('config.snapshot', box, x, y, 'checkpoint snapshot')
    else
        call gp_xy_dump('config.xy', box, x, y)
    end if
end program ccd_cpt_to_xy
