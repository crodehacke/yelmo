module yelmo_timesteps

    use yelmo_defs, only : sp, dp, prec  

    implicit none 

    private
    public :: set_adaptive_timestep 

contains

    subroutine set_adaptive_timestep(dt,dt_adv,dt_diff,dt_adv3D,time_max,time, &
                        ux,uy,uz,ux_bar,uy_bar,D2D,H_ice,dHicedt,zeta_ac, &
                        dx,dtmin,dtmax,cfl_max,cfl_diff_max)
        ! Determine value of adaptive timestep to be consistent with 
        ! min/max timestep range and maximum allowed step of model 
        ! to line up with control time steps

        implicit none 

        real(prec), intent(OUT) :: dt             ! [a] Current timestep 
        real(prec), intent(OUT) :: dt_adv(:,:)     ! [a] Diagnosed maximum advective timestep (vertical ave)
        real(prec), intent(OUT) :: dt_diff(:,:)    ! [a] Diagnosed maximum diffusive timestep (vertical ave) 
        real(prec), intent(OUT) :: dt_adv3D(:,:,:) ! [a] Diagnosed maximum advective timestep (3D) 
        real(prec), intent(IN)  :: time_max        ! [a] Time the model can evolve to
        real(prec), intent(IN)  :: time            ! [a] Current model time  
        real(prec), intent(IN)  :: ux(:,:,:)       ! [m a-1]
        real(prec), intent(IN)  :: uy(:,:,:)       ! [m a-1]
        real(prec), intent(IN)  :: uz(:,:,:)       ! [m a-1]
        real(prec), intent(IN)  :: ux_bar(:,:)     ! [m a-1]
        real(prec), intent(IN)  :: uy_bar(:,:)     ! [m a-1]
        real(prec), intent(IN)  :: D2D(:,:)        ! [m2 a-1]
        real(prec), intent(IN)  :: H_ice(:,:)      ! [m]
        real(prec), intent(IN)  :: dHicedt(:,:)    ! [m a-1]
        real(prec), intent(IN)  :: zeta_ac(:)      ! [--] 
        real(prec), intent(IN)  :: dx, dtmin, dtmax ! [a]
        real(prec), intent(IN)  :: cfl_max
        real(prec), intent(IN)  :: cfl_diff_max
        
        ! Local variables 
        real(prec) :: dt_adv_min, dt_diff_min, dt_time_max 
        real(prec) :: x 
        logical    :: is_unstable
        real(prec), parameter :: dtmax_cfl   = 20.0_prec 
        real(prec), parameter :: exp_cfl     =  2.0_prec 
        real(prec), parameter :: n_decimal   = 2          ! Maximum decimals to treat for timestep
        real(prec), parameter :: rate_lim    = 10.0_prec  ! Reduction in timestep for instability 
        real(prec), parameter :: rate_scalar = 0.2_prec   ! Reduction in timestep for instability 
        real(prec), parameter :: dt_half_lim = 0.5_prec   ! Should be 0.5 or greater to make sense

        ! Timestep limits determined from CFL conditions for general advective
        ! velocity, as well as diagnosed diffusive magnitude
        ! (adapted from Bueler et al., 2007)

        dt_adv   = calc_adv2D_timestep1(ux_bar,uy_bar,dx,dx,cfl_max)
        dt_diff  = calc_diff2D_timestep(D2D,dx,dx,cfl_diff_max) 

!         dt_adv3D = calc_adv3D_timestep1(ux,uy,uz,dx,dx,H_ice,zeta_ac,cfl_max)
!         dt_adv3D = calc_adv3D_timestep(ux,uy,uz,H_ice,zeta_ac,dx,dx,cfl_max)
        dt_adv3D = 1000.0    ! Prescribe something just to avoid compiler warnings 

        ! Get minimum from adv and diffusive timesteps
        dt_adv_min  = minval(dt_adv)
        dt_diff_min = minval(dt_diff)
        
        ! Note: It's not clear whether dt_diff is working well, so for now
        ! it is not applied as a limit. Furthermore, although dt_adv should
        ! be consistent with the CFL limit, it does not guarantee that a 
        ! fully coupled thermodynamic model will remain stable. 

        ! Choose minimum timestep between advective and diffusive limits 
        !dt = min(dt_adv_min,dt_diff_min)
        dt = dt_adv_min 

        ! Apply additional reduction in timestep as it gets smaller
        if (.FALSE.) then 
            dt = max(dtmin,dt)          ! dt >= dtmin
            dt = min(dtmax_cfl,dt)      ! dt <= dtmax_cfl
            x = ((dt-dtmin)/(dtmax_cfl-dtmin))**exp_cfl
            dt = dtmin + (dtmax-dtmin)*x
        end if 

        ! Check if additional timestep reduction is necessary,
        ! due to checkerboard patterning related to mass conservation.
        ! Reduce if necessary 
        call check_checkerboard(is_unstable,dHicedt,rate_lim)
        if (is_unstable) dt = rate_scalar*dt

        ! Ensure timestep is also within parameter limits 
        dt = max(dtmin,dt)  ! dt >= dtmin
        dt = min(dtmax,dt)  ! dt <= dtmax

        ! Check to avoid lopsided timesteps (1 big, 1 tiny) to arrive at time_max 
        dt_time_max = time_max - time 
        if (dt_time_max .gt. 0.0) then 

            if (dt/dtmax .gt. dt_half_lim .and. dt .lt. dt_time_max) then 
                ! Current adaptive timestep is greater than ~0.5 of the total
                ! expected timestep, and another timestep will be needed to
                ! reach time_max. Therefore, set this timestep to a smaller
                ! value, ie, dt = dt_half_lim*dtmax. 

                dt = dt_half_lim*dtmax

                ! Round-off extra digits 
                dt = real( nint(dt*10.0_prec**n_decimal)*10.0_prec**(-n_decimal), prec)

            end if 

        end if 

        ! Round-off extra digits for neatness
        !dt = real( nint(dt*10.0_prec**n_decimal)*10.0_prec**(-n_decimal), prec)
        dt = real(floor(dt*10.0_prec**n_decimal)*10.0_prec**(-n_decimal), prec)

        ! Finally, make sure adaptive time step synchronizes with larger time step 
        if (time + dt .gt. time_max) then 
            dt = time_max - time 
        end if 
        
        return 

    end subroutine set_adaptive_timestep
    
    elemental function calc_diff2D_timestep(D,dx,dy,cfl_diff_max) result(dt)
        ! Calculate maximum diffusion time step based
        ! on Courant–Friedrichs–Lewy condition
        ! Equation obtained from Bueler et al. (2007), Eq. 25:
        ! dt/2 * (1/dx^2 + 1/dy^2)*max(D) <= cfl_diff_max = 0.12 
        ! dt = cfl_diff_max * 2.0 / ((1/dx^2+1/dy^2)*max(D))

        implicit none 
        
        real(prec), intent(IN) :: D, dx, dy
        real(prec), intent(IN) :: cfl_diff_max       ! Maximum Courant number, default cfl_diff_max=0.12
        real(prec) :: dt 

        dt = (2.0*cfl_diff_max) / ((1.0/(dx**2)+1.0/(dy**2))*max(abs(D),1e-5))
        
        return 

    end function calc_diff2D_timestep 
    
    function calc_adv2D_timestep1(ux,uy,dx,dy,cfl_max) result(dt)
        ! Calculate maximum advective time step based
        ! on Courant–Friedrichs–Lewy condition
        ! https://en.wikipedia.org/wiki/Courant%E2%80%93Friedrichs%E2%80%93Lewy_condition

        ! 1D condition: C = u*dt/dx <= cfl_max 
        ! 2D condition: C = u*dt/dx + v*dt/dy <= cfl_max 
        ! thus when C = cfl_max:
        ! dt = cfl_max * 1/(u/dx+v/dx)


        implicit none 
        
        real(prec), intent(IN) :: ux(:,:)           ! acx-nodes
        real(prec), intent(IN) :: uy(:,:)           ! acy-nodes 
        real(prec), intent(IN) :: dx, dy
        real(prec), intent(IN) :: cfl_max           ! Maximum Courant number, default cfl_max=1.0
        real(prec) :: dt(size(ux,1),size(ux,2))     ! aa-nodes 

        ! Local variables  
        integer :: i, j, nx, ny 
        real(prec) :: ux_now, uy_now 

        real(prec), parameter :: eps = 1e-1         ! [m/a] Small factor to avoid divide by zero 

        nx = size(ux,1)
        ny = size(ux,2)

        do j = 2, ny-1 
        do i = 2, nx-1 

!             ux_now = abs( 0.5*(ux(i-1,j)+ux(i,j)) )
!             uy_now = abs( 0.5*(uy(i,j-1)+uy(i,j)) )

            !ux_now = max(abs(ux(i-1,j)),abs(ux(i,j)))
            !uy_now = max(abs(uy(i,j-1)),abs(uy(i,j)))
            
            !dt(i,j) = cfl_max * 1.0 / max(ux_now/dx + uy_now/dy,1e-3)

            dt(i,j) = cfl_max * 1.0 / (abs(ux(i-1,j))/dx + abs(ux(i,j))/dx &
                                       + abs(uy(i,j-1))/dy + abs(uy(i,j))/dy + eps/(dx+dy))
            
        end do 
        end do 

        dt(1,:)  = dt(2,:)
        dt(nx,:) = dt(nx-1,:) 
        dt(:,1)  = dt(:,2)
        dt(:,ny) = dt(:,ny-1)

        return 

    end function calc_adv2D_timestep1 
    

    function calc_adv3D_timestep1(ux,uy,uz,dx,dy,H_ice,zeta_ac,cfl_max) result(dt)
        ! Calculate maximum advective time step based
        ! on Courant–Friedrichs–Lewy condition
        ! https://en.wikipedia.org/wiki/Courant%E2%80%93Friedrichs%E2%80%93Lewy_condition

        ! 1D condition: C = u*dt/dx <= cfl_max 
        ! 2D condition: C = u*dt/dx + v*dt/dy <= cfl_max 
        ! thus when C = cfl_max:
        ! dt = cfl_max * 1/(u/dx+v/dx)


        implicit none 
        
        real(prec), intent(IN) :: ux(:,:,:)        ! acx-nodes
        real(prec), intent(IN) :: uy(:,:,:)        ! acy-nodes
        real(prec), intent(IN) :: uz(:,:,:)        ! acz-nodes  
        real(prec), intent(IN) :: dx, dy
        real(prec), intent(IN) :: H_ice(:,:)       ! aa-nodes 
        real(prec), intent(IN) :: zeta_ac(:)       ! ac-nodes 
        real(prec), intent(IN) :: cfl_max          ! Maximum Courant number, default cfl_max=1.0
        real(prec) :: dt(size(ux,1),size(ux,2),size(ux,3))    ! aa-nodes 

        ! Local variables  
        integer :: i, j, k, nx, ny, nz_aa  
        real(prec) :: ux_now, uy_now 
        real(prec) :: dz 

        nx    = size(ux,1)
        ny    = size(ux,2)
        nz_aa = size(zeta_ac)+1  

        ! Set a high timestep to start 
        dt = cfl_max * 1.0 / (1e-3)

        do j = 2, ny-1 
        do i = 2, nx-1 

!             ux_now = abs( 0.5*(ux(i-1,j)+ux(i,j)) )
!             uy_now = abs( 0.5*(uy(i,j-1)+uy(i,j)) )

            !ux_now = max(abs(ux(i-1,j)),abs(ux(i,j)))
            !uy_now = max(abs(uy(i,j-1)),abs(uy(i,j)))
            
            !dt(i,j) = cfl_max * 1.0 / max(ux_now/dx + uy_now/dy,1e-3)

!             dt(i,j) = cfl_max * 1.0 / max(abs(ux(i-1,j))/dx + abs(ux(i,j))/dx &
!                                         + abs(uy(i,j-1))/dy + abs(uy(i,j))/dy,1e-3)
            
            do k = 2, nz_aa 

                dz = H_ice(i,j) * (zeta_ac(k)-zeta_ac(k-1))

                dt(i,j,k) = cfl_max * 1.0 / max(abs(ux(i-1,j,k))/(2.0*dx) + abs(ux(i,j,k))/(2.0*dx) &
                                        + abs(uy(i,j-1,k))/(2.0*dy) + abs(uy(i,j,k))/(2.0*dy), &
                                        + abs(uz(i,j,k))/(2.0*dz) + abs(uz(i,j,k-1))/(2.0*dz), 1e-3)
!                 dt(i,j,k) = cfl_max * 1.0 / max(abs(ux(i-1,j,k))/(2.0*dx) + abs(ux(i,j,k))/(2.0*dx) &
!                                         + abs(uy(i,j-1,k))/(2.0*dy) + abs(uy(i,j,k))/(2.0*dy), 1e-3)
            
            end do 

        end do 
        end do 

        return 

    end function calc_adv3D_timestep1 
    
    elemental function calc_adv2D_timestep(ux,uy,dx,dy,cfl_max) result(dt)
        ! Calculate maximum advective time step based
        ! on Courant–Friedrichs–Lewy condition
        ! https://en.wikipedia.org/wiki/Courant%E2%80%93Friedrichs%E2%80%93Lewy_condition

        ! 1D condition: C = u*dt/dx <= cfl_max 
        ! 2D condition: C = u*dt/dx + v*dt/dy <= cfl_max 
        ! thus when C = cfl_max:
        ! dt = cfl_max * 1/(u/dx+v/dx)


        implicit none 
        
        real(prec), intent(IN) :: ux
        real(prec), intent(IN) :: uy
        real(prec), intent(IN) :: dx, dy
        real(prec), intent(IN) :: cfl_max             ! Maximum Courant number, default cfl_max=1.0
        real(prec) :: dt 

        dt = cfl_max * 1.0 / max(abs(ux)/dx + abs(uy)/dy,1e-5)

        return 

    end function calc_adv2D_timestep 
    
    subroutine calc_adv2D_velocity(ux,uy,dx,dy,dt,cfl_max)
        ! Calculate maximum velocity given a known time step
        ! on Courant–Friedrichs–Lewy condition
        ! https://en.wikipedia.org/wiki/Courant%E2%80%93Friedrichs%E2%80%93Lewy_condition

        ! 1D condition: C = u*dt/dx <= cfl_max 
        ! 2D condition: C = u*dt/dx + v*dt/dy <= cfl_max 
        ! thus when C = cfl_max:
        ! dt = cfl_max * 1/(u/dx+v/dx)

        ! dt = cfl_max * dx/u 

        implicit none 
        
        real(prec), intent(INOUT) :: ux(:,:)
        real(prec), intent(INOUT) :: uy(:,:)
        real(prec), intent(IN)    :: dx, dy
        real(prec), intent(IN)    :: dt 
        real(prec), intent(IN)    :: cfl_max       ! Maximum Courant number, default cfl_max=1.0
        
        ! Local variables 
        integer    :: i, j, q, nx, ny 
        real(prec) :: uxy, dt_now 
        real(prec) :: X, X_max 
        real(prec) :: f_scale 

        nx = size(ux,1)
        ny = size(ux,2)

        X_max = cfl_max / dt 

        do j = 1, ny 
        do i = 1, nx 

            X = max(abs(ux(i,j))/dx + abs(uy(i,j))/dy,1e-5)

            if (X .gt. X_max) then 
                ! Reduce velocity of this point to below limit

                dt_now = cfl_max / X

                f_scale = X_max / X     ! Should be less than 1.0! 

                ux(i,j) = ux(i,j)*f_scale 
                uy(i,j) = uy(i,j)*f_scale 
                
            end if 

        end do 
        end do  


        return 

    end subroutine calc_adv2D_velocity 
    
    function calc_adv3D_timestep(ux,uy,uz,H_ice,zeta_ac,dx,dy,cfl_max) result(dt)
        ! Calculate maximum advective time step based
        ! on Courant–Friedrichs–Lewy condition
        ! https://en.wikipedia.org/wiki/Courant%E2%80%93Friedrichs%E2%80%93Lewy_condition

        ! 1D condition: C = u*dt/dx <= cfl_max 
        ! 2D condition: C = u*dt/dx + v*dt/dy <= cfl_max 
        ! thus when C = cfl_max:
        ! dt = cfl_max * 1/(u/dx+v/dx)

        ! Note: this is used by Bueler et al. (2007), but it seems 
        ! to impose a very, very small timestep, given the vertical
        ! velocity at the surface (ie, smb) essentially ends up being the
        ! limiting condition. 

        implicit none 
        
        real(prec), intent(IN) :: ux(:,:,:), uy(:,:,:), uz(:,:,:)
        real(prec), intent(IN) :: H_ice(:,:) 
        real(prec), intent(IN) :: zeta_ac(:) 
        real(prec), intent(IN) :: dx, dy
        real(prec), intent(IN) :: cfl_max             ! Maximum Courant number, default cfl_max=1.0
        real(prec) :: dt 

        ! Local variables 
        integer    :: i, j, k, nx, ny, nz_aa 
        real(prec) :: dt_check, dt_max 
        real(prec) :: dz, ux_aa, uy_aa, uz_aa  

        real(prec), parameter :: tol = 1e-5 

        nx    = size(ux,1)
        ny    = size(ux,2)
        nz_aa = size(ux,3)

        ! Start with a really high time step 
        dt_max = cfl_max * 1.0 / tol 
        dt     = dt_max

!         write(*,*) "cfl_max = ", cfl_max 
!         write(*,*) "dt_max  = ", dt_max 

!         write(*,*) "calc_adv3D_timestep:: Error: This routine is not working yet."
        
!         stop 

        ! Loop over horizontal grid points 
        do j = 2, ny 
        do i = 2, nx 

            if (H_ice(i,j) .gt. 0.0) then 

                ! Loop over the vertical layers
                do k = 1, nz_aa-1 
                    ux_aa = 0.5*(ux(i-1,j,k)+ux(i,j,k))
                    uy_aa = 0.5*(uy(i,j-1,k)+uy(i,j,k))

                    if (k .le. 1 .or. k .ge. nz_aa-1) then 
                        ! No interpolation of vertical velocity at the base or surface
                        uz_aa = uz(i,j,k) 
                    else
                        ! Interpolation to vertical aa-nodes
                        uz_aa = 0.5*(uz(i,j,k-1)+uz(i,j,k))
                    end if 

                    if (k .le. 1) then 
                        dz = 1e-5 
                    else 
                        dz = max(H_ice(i,j)*(zeta_ac(k)-zeta_ac(k-1)),1e-5)
                    end if 
                    
                    dt_check = cfl_max * 1.0 / max(abs(ux_aa)/dx + abs(uy_aa)/dy + abs(uz_aa)/dz,tol)

!                     write(*,*) i, j, k, dt_check, dt_max, ux_aa, ux_aa, uz_aa, &
!                                     abs(ux_aa)/dx + abs(ux_aa)/dy + abs(uz_aa)/dz

                    dt_max = min(dt_check,dt_max)
                end do 

            end if 

        end do 
        end do 

!         stop 

        return 

    end function calc_adv3D_timestep 
    
    subroutine check_checkerboard(is_unstable,dHdt,lim)

        implicit none 

        logical,    intent(OUT) :: is_unstable
        real(prec), intent(IN)  :: dHdt(:,:) 
        real(prec), intent(IN)  :: lim 

        ! Local variables 
        integer :: i, j, nx, ny 

        nx = size(dHdt,1)
        ny = size(dHdt,2) 

        ! First assume everything is stable 
        is_unstable = .FALSE. 

        do j = 2, ny-1
        do i = 2, nx-1 
 
            if (abs(dHdt(i,j)) .ge. lim) then
                ! Check for checkerboard pattern with dHdt > lim

                if ( (dHdt(i,j)*dHdt(i-1,j) .lt. 0.0 .and. & 
                      dHdt(i,j)*dHdt(i+1,j) .lt. 0.0) .or. & 
                     (dHdt(i,j)*dHdt(i,j-1) .lt. 0.0 .and. & 
                      dHdt(i,j)*dHdt(i,j+1) .lt. 0.0) ) then 
                    ! Point has two neighbors with dHdt of opposite sign 

                    is_unstable = .TRUE. 
                    exit

                end if 

            end if 

        end do 
        end do  

        return 

    end subroutine check_checkerboard

end module yelmo_timesteps 
