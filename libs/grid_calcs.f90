module grid_calcs

  ! Contains all the routines involved in the Arakawa grids, for mapping and
  ! calculating derivatives between all the different grids.

  use yelmo_defs, only : wp, dp, io_unit_err

  public 
  public :: ddx_a_to_a_2D 
  public :: ddy_a_to_a_2D 
  public :: ddxx_a_to_a_2D 
  public :: ddyy_a_to_a_2D 
  public :: ddxy_a_to_a_2D 
  public :: ddx_a_to_a_3D
  public :: ddy_a_to_a_3D
  public :: ddxx_a_to_a_3D
  public :: ddyy_a_to_a_3D
  public :: ddxy_a_to_a_3D
  public :: ddx_a_to_a_3D_upwind
  public :: ddy_a_to_a_3D_upwind
  public :: ddx_a_to_cx_2D 
  public :: ddy_a_to_cy_2D
  public :: ddx_a_to_cy_2D 
  public :: ddy_a_to_cx_2D 
  public :: ddx_a_to_cx_3D 
  public :: ddy_a_to_cy_3D

contains

! ======================
! ==== Derivatives =====
! ======================
  
    ! Aa to Aa
  
    ! 2D
    subroutine ddx_a_to_a_2D(dx_a,d_a,dx)
        ! Input:  scalar on the Aa grid
        ! Output: its x-derivative on the Aa grid
        
        implicit none
        
        ! In/output variables:
        
        real(wp), intent(OUT)   :: dx_a(:,:)
        real(wp), intent(IN)    :: d_a(:,:)
        real(wp), intent(IN)    :: dx 

        ! Local variables:
        integer :: i, j, nx, ny 
        
        nx = size(d_a,1)
        ny = size(d_a,2) 

        ! Central differencing in the interior
        do j = 1, ny
        do i = 2, nx-1
            dx_a(i,j) = (d_a(i+1,j) - d_a(i-1,j)) / (2.0*dx)
        end do
        end do
        
        
        ! One-sided differencing on the boundaries
        dx_a(1,:)  = (d_a(2,:) - d_a(1,:)) / dx
        dx_a(nx,:) = (d_a(nx,:) - d_a(nx-1,:)) / dx
        
        return 

    end subroutine ddx_a_to_a_2D

    subroutine ddy_a_to_a_2D(dy_a,d_a,dx)
        ! Input:  scalar on the Aa grid
        ! Output: its y-derivative on the Aa grid
        
        implicit none
        
        ! In/output variables:
        
        real(wp), intent(OUT)   :: dy_a(:,:)
        real(wp), intent(IN)    :: d_a(:,:)
        real(wp), intent(IN)    :: dx 

        ! Local variables:
        integer :: i, j, nx, ny 
        
        nx = size(d_a,1)
        ny = size(d_a,2) 

        ! Central differencing in the interior
        do j = 2, ny-1
        do i = 1, nx
            dy_a(i,j) = (d_a(i,j+1) - d_a(i,j-1)) / (2.0*dx)
        end do
        end do
        
        ! One-sided differencing on the boundaries
        dy_a(:,1)  = (d_a(:,2) - d_a(:,1)) / dx
        dy_a(:,ny) = (d_a(:,ny) - d_a(:,ny-1)) / dx
        
        return 

    end subroutine ddy_a_to_a_2D

    subroutine ddxx_a_to_a_2D(dxx_a, d_a, dx)
        ! Input:  scalar on the Aa grid
        ! Output: its xx-derivative on the Aa grid
        
        implicit none
        
        ! In/output variables:
        
        real(wp), intent(OUT)   :: dxx_a(:,:)
        real(wp), intent(IN)    :: d_a(:,:)
        real(wp), intent(IN)    :: dx 
        
        ! Local variables:
        integer :: i, j, nx, ny
        
        nx = size(d_a,1)
        ny = size(d_a,2) 

        ! Central differencing in the interior
        do j = 1, ny
        do i = 2, nx-1
            dxx_a(i,j) = (d_a(i+1,j) + d_a(i-1,j) - 2.0_wp*d_a(i,j)) / dx**2
        end do
        end do
        
        
        ! One-sided differencing on the boundaries
        dxx_a(1,:)  = (d_a(3,:) + d_a(1,:) - 2.0_wp*d_a(2,:)) / dx**2
        dxx_a(nx,:) = (d_a(nx,:) + d_a(nx-2,:) - 2.0_wp * d_a(nx-1,:)) / dx**2
        
        return
    
    end subroutine ddxx_a_to_a_2D

    subroutine ddyy_a_to_a_2D(dyy_a, d_a, dx)
        ! Input:  scalar on the Aa grid
        ! Output: its yy-derivative on the Aa grid
        
        implicit none
        
        ! In/output variables:
        
        real(wp), intent(OUT)   :: dyy_a(:,:)
        real(wp), intent(IN)    :: d_a(:,:)
        real(wp), intent(IN)    :: dx 

        ! Local variables:
        integer :: i, j, nx, ny
        
        nx = size(d_a,1)
        ny = size(d_a,2) 

        ! Central differencing in the interior
        do i = 1, nx
        do j = 2, ny-1
            dyy_a(i,j) = (d_a(i,j+1) + d_a(i,j-1) - 2.0_wp * d_a(i,j)) / dx**2
        end do
        end do
        
        ! One-sided differencing on the boundaries
        dyy_a(:,1)  = (d_a(:,3) + d_a(:,1) - 2.0_wp*d_a(:,2)) / dx**2
        dyy_a(:,ny) = (d_a(:,ny) + d_a(:,ny-2) - 2.0_wp*d_a(:,ny-1)) / dx**2
        
        return

    end subroutine ddyy_a_to_a_2D

    subroutine ddxy_a_to_a_2D(dxy_a, d_a, dx)
        ! Input:  scalar on the Aa grid
        ! Output: its xy-derivative on the Aa grid
    
        implicit none
        
        ! In/output variables:
        
        real(wp), intent(OUT)   :: dxy_a(:,:)
        real(wp), intent(IN)    :: d_a(:,:)
        real(wp), intent(IN)    :: dx 

        ! Local variables:
        integer :: i, j, nx, ny
        
        nx = size(d_a,1)
        ny = size(d_a,2) 

        ! Central differencing in the interior
        do j = 2, ny-1
        do i = 2, nx-1
            dxy_a(i,j) = (d_a(i+1,j+1) + d_a(i-1,j-1) - d_a(i-1,j+1) - d_a(i+1,j-1)) / (4.0_wp * dx * dx)
        end do
        end do
        
        ! One-sided differencing on the boundaries
        ! NO IDEA HOW TO do THIS...
        dxy_a(1,:)  = 0.0_wp
        dxy_a(nx,:) = 0.0_wp
        dxy_a(:,1)  = 0.0_wp
        dxy_a(:,ny) = 0.0_wp
    
        return 

    end subroutine ddxy_a_to_a_2D

    ! 3D
    subroutine ddx_a_to_a_3D( dx_a, d_a, dx )
        ! Input:  scalar on the Aa grid
        ! Output: its x-derivative on the Aa grid
        
        implicit none
        
        ! In/output variables:
        
        real(wp), intent(OUT)   :: dx_a(:,:,:)
        real(wp), intent(IN)    :: d_a(:,:,:)
        real(wp), intent(IN)    :: dx 

        ! Local variables:
        integer :: i, j, k, nx, ny, nz 
        
        nx = size(d_a,1)
        ny = size(d_a,2) 
        nz = size(d_a,3) 

        ! Loop over vertical layers and calculate horizontal derivatives 
        do k = 1, nz 
            call ddx_a_to_a_2D(dx_a(:,:,k),d_a(:,:,k),dx)
        end do 

        return 

    end subroutine ddx_a_to_a_3D

    subroutine ddy_a_to_a_3D( dy_a, d_a, dx )
        ! Input:  scalar on the Aa grid
        ! Output: its y-derivative on the Aa grid

        implicit none

        ! In/output variables:

        real(wp),  intent(OUT)   :: dy_a(:,:,:)
        real(wp),  intent(IN)    :: d_a(:,:,:)
        real(wp),  intent(IN)    :: dx 

        ! Local variables:
        integer :: i, j, k, nx, ny, nz 

        nx = size(d_a,1)
        ny = size(d_a,2) 
        nz = size(d_a,3) 

        ! Loop over vertical layers and calculate horizontal derivatives 
        do k = 1, nz 
            call ddy_a_to_a_2D(dy_a(:,:,k),d_a(:,:,k),dx)
        end do 

        return 

    end subroutine ddy_a_to_a_3D

    subroutine ddxx_a_to_a_3D( dxx_a, d_a, dx )
        ! Input:  scalar on the Aa grid
        ! Output: its xx-derivative on the Aa grid
        
        implicit none
        
        ! In/output variables:
        
        real(wp),  intent(OUT)   :: dxx_a(:,:,:)
        real(wp),  intent(IN)    :: d_a(:,:,:)
        real(wp),  intent(IN)    :: dx 

        ! Local variables:
        integer :: i, j, k, nx, ny, nz 

        nx = size(d_a,1)
        ny = size(d_a,2) 
        nz = size(d_a,3) 

        ! Loop over vertical layers and calculate horizontal derivatives 
        do k = 1, nz 
            call ddxx_a_to_a_2D(dxx_a(:,:,k),d_a(:,:,k),dx)
        end do 

        return 

    end subroutine ddxx_a_to_a_3D

    subroutine ddyy_a_to_a_3D( dyy_a, d_a, dx )
        ! Input:  scalar on the Aa grid
        ! Output: its yy-derivative on the Aa grid
        
        implicit none
        
        ! In/output variables:
        
        real(wp),  intent(OUT)   :: dyy_a(:,:,:)
        real(wp),  intent(IN)    :: d_a(:,:,:)
        real(wp),  intent(IN)    :: dx 

        ! Local variables:
        integer :: i, j, k, nx, ny, nz 

        nx = size(d_a,1)
        ny = size(d_a,2) 
        nz = size(d_a,3) 

        ! Loop over vertical layers and calculate horizontal derivatives 
        do k = 1, nz 
            call ddyy_a_to_a_2D(dyy_a(:,:,k),d_a(:,:,k),dx)
        end do 

        return 

    end subroutine ddyy_a_to_a_3D

    subroutine ddxy_a_to_a_3D( dxy_a, d_a, dx )
        ! Input:  scalar on the Aa grid
        ! Output: its xy-derivative on the Aa grid
        
        implicit none
        
        ! In/output variables:
        
        real(wp),  intent(OUT)   :: dxy_a(:,:,:)
        real(wp),  intent(IN)    :: d_a(:,:,:)
        real(wp),  intent(IN)    :: dx 

        ! Local variables:
        integer :: i, j, k, nx, ny, nz 

        nx = size(d_a,1)
        ny = size(d_a,2) 
        nz = size(d_a,3) 

        ! Loop over vertical layers and calculate horizontal derivatives 
        do k = 1, nz 
            call ddxy_a_to_a_2D(dxy_a(:,:,k),d_a(:,:,k),dx)
        end do 

        return 

    end subroutine ddxy_a_to_a_3D

    ! 3D upwind, for thermodynamics
    subroutine ddx_a_to_a_3D_upwind( dx_a, d_a, U_3D_a, dx )
        ! Input:  scalar on the Aa grid
        ! Output: its x-derivative on the Aa grid, using upwind one-sided differencing

        implicit none

        ! In/output variables:

        real(wp),  intent(OUT)   :: dx_a(:,:,:)
        real(wp),  intent(IN)    :: d_a(:,:,:)
        real(wp),  intent(IN)    :: U_3D_a(:,:,:)
        real(wp),  intent(IN)    :: dx 

        ! Local variables:
        integer :: i, j, k, nx, ny, nz 

        nx = size(d_a,1)
        ny = size(d_a,2) 
        nz = size(d_a,3) 

        ! Upwind one-sided differencing
        do k = 1, nz
        do j = 1, ny
        do i = 2, nx-1
        
          if (U_3D_a(i,j,k) > 0.0_wp) then
            dx_a(i,j,k) = (d_a(i,j,k) - d_a(i-1,j,k)) / dx
          else
            dx_a(i,j,k) = (d_a(i+1,j,k) - d_a(i,j,k)) / dx
          end if

        end do
        end do
        end do

        dx_a(1,:,:)  = 0.0_wp
        dx_a(nx,:,:) = 0.0_wp

        return 

    end subroutine ddx_a_to_a_3D_upwind

    subroutine ddy_a_to_a_3D_upwind( dy_a, d_a, V_3D_a, dx)
        ! Input:  scalar on the Aa grid
        ! Output: its y-derivative on the Aa grid, using upwind one-sided differencing

        implicit none

        ! In/output variables:

        real(wp),  intent(OUT)   :: dy_a(:,:,:)
        real(wp),  intent(IN)    :: d_a(:,:,:)
        real(wp),  intent(IN)    :: V_3D_a(:,:,:)
        real(wp),  intent(IN)    :: dx 

        ! Local variables:
        integer :: i, j, k, nx, ny, nz 

        nx = size(d_a,1)
        ny = size(d_a,2) 
        nz = size(d_a,3) 

        ! Upwind one-sided differencing
        do k = 1, nz
        do j = 2, ny-1
        do i = 1, nx
        
            if (V_3D_a(i,j,k) > 0.0_wp) then
                dy_a(i,j,k) = (d_a(i,j,k) - d_a(i,j-1,k)) / dx
            else
                dy_a(i,j,k) = (d_a(i,j+1,k) - d_a(i,j,k)) / dx
            end if

        end do
        end do
        end do

        dy_a(:,1,:)  = 0.0_wp
        dy_a(:,ny,:) = 0.0_wp

        return

    end subroutine ddy_a_to_a_3D_upwind
  
    ! Aa to Acx/Acy

    ! 2D
    subroutine ddx_a_to_cx_2D( dx_cx, d_a, dx )
        ! Input:  scalar on the Aa grid
        ! Output: its x-derivative on the Acx grid

        implicit none

        ! In/output variables:

        real(wp), intent(OUT)   :: dx_cx(:,:)
        real(wp), intent(IN)    :: d_a(:,:)
        real(wp), intent(IN)    :: dx 

        ! Local variables:
        integer :: i, j, nx, ny

        nx = size(d_a,1)
        ny = size(d_a,2) 
        
        dx_cx = 0.0_wp 

        do j = 1, ny
        do i = 1, nx-1
            dx_cx(i,j) = (d_a(i+1,j) - d_a(i,j)) / dx
        end do
        end do

        return 

    end subroutine ddx_a_to_cx_2D

    subroutine ddy_a_to_cy_2D( dy_cy, d_a, dx )
        ! Input:  scalar on the Aa grid
        ! Output: its y-derivative on the Acy grid

        implicit none

        ! In/output variables:

        real(wp), intent(OUT)   :: dy_cy(:,:)
        real(wp), intent(IN)    :: d_a(:,:)
        real(wp), intent(IN)    :: dx 

        ! Local variables:
        integer :: i, j, nx, ny

        nx = size(d_a,1)
        ny = size(d_a,2) 
        
        dy_cy = 0.0_wp 

        do j = 1, ny-1
        do i = 1, nx
          dy_cy(i,j) = (d_a(i,j+1) - d_a(i,j)) / dx
        end do
        end do

        return

    end subroutine ddy_a_to_cy_2D

    subroutine ddx_a_to_cy_2D( dx_cy, d_a, dx )
        ! Input:  scalar on the Aa grid
        ! Output: its x-derivative on the Acy grid

        implicit none

        ! In/output variables:

        real(wp),  intent(OUT)   :: dx_cy(:,:)
        real(wp),  intent(IN)    :: d_a(:,:)
        real(wp),  intent(IN)    :: dx 

        ! Local variables:
        integer :: i, j, nx, ny

        nx = size(d_a,1)
        ny = size(d_a,2) 
        
        dx_cy = 0.0_wp 

        ! Central differencing in the interior
        do j = 1, ny-1
        do i = 2, nx-1
          dx_cy(i,j) = (d_a(i+1,j) + d_a(i+1,j+1) - d_a(i-1,j) - d_a(i-1,j+1)) / (4.0_wp * dx)
        end do
        end do

        ! One-sided differencing on the boundary
        do j = 1, ny-1
          dx_cy(1,j) = (d_a(2,j) + d_a(2,j+1) - d_a(1,j) - d_a(1,j+1)) / (2.0_wp * dx)
          dx_cy(nx,j) = (d_a(nx,j) + d_a(nx,j+1) - d_a(nx-1,j) - d_a(nx-1,j+1)) / (2.0_wp * dx)
        end do

        return

    end subroutine ddx_a_to_cy_2D

    subroutine ddy_a_to_cx_2D( dy_cx, d_a, dx )
        ! Input:  scalar on the Aa grid
        ! Output: its y-derivative on the Acx grid

        implicit none

        ! In/output variables:

        real(wp),  intent(OUT)   :: dy_cx(:,:)
        real(wp),  intent(IN)    :: d_a(:,:)
        real(wp),  intent(IN)    :: dx 

        ! Local variables:
        integer :: i, j, nx, ny

        nx = size(d_a,1)
        ny = size(d_a,2) 
        
        dy_cx = 0.0_wp 

        ! Central differencing in the interior
        do j = 2, ny-1
        do i = 1, nx-1
            dy_cx(i,j) = (d_a(i,j+1) + d_a(i+1,j+1) - d_a(i,j-1) - d_a(i+1,j-1)) / (4.0_wp * dx)
        end do
        end do

        ! One-sided differencing on the boundary
        do i = 1, nx-1
            dy_cx(i,1)  = (d_a(i,2) + d_a(i+1,2) - d_a(i,1) - d_a(i+1,1)) / (2.0_wp * dx)
            dy_cx(i,ny) = (d_a(i,ny) + d_a(i+1,ny) - d_a(i,ny-1) - d_a(i+1,ny-1)) / (2.0_wp * dx)
        end do

        return

    end subroutine ddy_a_to_cx_2D

    ! 3D
    subroutine ddx_a_to_cx_3D( dx_cx, d_a, dx )
        ! Input:  scalar on the Aa grid
        ! Output: its x-derivative on the Acx grid

        implicit none

        ! In/output variables:

        real(wp),  intent(OUT)   :: dx_cx(:,:,:)
        real(wp),  intent(IN)    :: d_a(:,:,:)
        real(wp),  intent(IN)    :: dx 

        ! Local variables:
        integer :: k, nz 

        nz = size(d_a,3) 

        do k = 1, nz 
            call ddx_a_to_cx_2D(dx_cx(:,:,k),d_a(:,:,k),dx)
        end do

        return 

    end subroutine ddx_a_to_cx_3D

    subroutine ddy_a_to_cy_3D( dy_cy, d_a, dx )
        ! Input:  scalar on the Aa grid
        ! Output: its y-derivative on the Acy grid

        implicit none

        ! In/output variables:

        real(wp),  intent(OUT)   :: dy_cy(:,:,:)
        real(wp),  intent(IN)    :: d_a(:,:,:)
        real(wp),  intent(IN)    :: dx 

        ! Local variables:
        integer :: k, nz 

        nz = size(d_a,3) 

        do k = 1, nz 
            call ddy_a_to_cy_2D(dy_cy(:,:,k),d_a(:,:,k),dx)
        end do

        return 

    end subroutine ddy_a_to_cy_3D

    subroutine ddx_a_to_cy_3D( dx_cy, d_a, dx )
        ! Input:  scalar on the Aa grid
        ! Output: its x-derivative on the Acy grid

        implicit none

        ! In/output variables:

        real(wp),  intent(OUT)   :: dx_cy(:,:,:)
        real(wp),  intent(IN)    :: d_a(:,:,:)
        real(wp),  intent(IN)    :: dx 

        ! Local variables:
        integer :: k, nz 

        nz = size(d_a,3) 

        do k = 1, nz 
            call ddx_a_to_cy_2D(dx_cy(:,:,k),d_a(:,:,k),dx)
        end do

        return 

    end subroutine ddx_a_to_cy_3D

    subroutine ddy_a_to_cx_3D( dy_cx, d_a, dx )
        ! Input:  scalar on the Aa grid
        ! Output: its y-derivative on the Acx grid

        implicit none

        ! In/output variables:

        real(wp),  intent(OUT)   :: dy_cx(:,:,:)
        real(wp),  intent(IN)    :: d_a(:,:,:)
        real(wp),  intent(IN)    :: dx 

        ! Local variables:
        integer :: k, nz 

        nz = size(d_a,3) 

        do k = 1, nz 
            call ddy_a_to_cx_2D(dy_cx(:,:,k),d_a(:,:,k),dx)
        end do

        return 

    end subroutine ddy_a_to_cx_3D
    
!   ! Acx/Acy to Aa
  
!   ! 2D
!   subroutine ddx_cx_to_a_2D( d_cx, dx_a)
!     ! Input:  scalar on the Acx grid
!     ! Output: its x-derivative on the Aa grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cx
!     real(wp), intent(OUT)   :: dx_a
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     do i = 2, nx-1
!     do j = 1, ny
!       dx_a(i,j) = (d_cx(i,j) - d_cx(i-1,j)) / dx
!     end do
!     end do
    
    
!     dx_a(1,:) = dx_a( grid%j1:grid%j2,2        )
!     dx_a(nx,:) = dx_a( grid%j1:grid%j2,nx-1)
    
    
!   end subroutine ddx_cx_to_a_2D
!   subroutine ddy_cy_to_a_2D( d_cy, dy_a)
!     ! Input:  scalar on the Acy grid
!     ! Output: its y-derivative on the Aa grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cy
!     real(wp), intent(OUT)   :: dy_a
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     do i = 1, nx
!     do j = 2, ny-1
!       dy_a(i,j) = (d_cy(i,j) - d_cy(i,j-1)) / dx
!     end do
!     end do
    
    
!     dy_a(:,1) = dy_a( 2        ,grid%i1:grid%i2)
!     dy_a(:,ny) = dy_a( ny-1,grid%i1:grid%i2)
    
    
!   end subroutine ddy_cy_to_a_2D
!   subroutine ddy_cx_to_a_2D( d_cx, dy_a)
!     ! Input:  scalar on the Acx grid
!     ! Output: its y-derivative on the Aa grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cx
!     real(wp), intent(OUT)   :: dy_a
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Interior
!     do i = 2, nx-1
!     do j = 2, ny-1
!       dy_a(i,j) = (d_cx(i-1,j+1) + d_cx(i,j+1) - d_cx(i-1,j-1) - d_cx(i,j-1)) / (4.0_wp * dx)
!     end do
!     end do
    
    
!     do i = 2, nx-1
!       ! South ex. corners
!       j = 1
!       dy_a(i,j) = (d_cx(i-1,j+1) + d_cx(i,j+1) - d_cx( j  ,i-1) - d_cx( j  ,i)) / (4.0_wp * dx)
!       ! North ex. corners
!       j = ny
!       dy_a(i,j) = (d_cx( j  ,i-1) + d_cx( j  ,i) - d_cx(i-1,j-1) - d_cx(i,j-1)) / (4.0_wp * dx)
!     end do
    
    
!     do j = MAX(2,grid%j1), MIN(ny-1,grid%j2)
!       ! West ex. corners
!       i = 1
!       dy_a(i,j) = (d_cx( j+1,i  ) - d_cx( j-1,i  )) / (2.0_wp * dx)
!       ! East ex. corners
!       i = nx
!       dy_a(i,j) = (d_cx(i-1,j+1) - d_cx(i-1,j-1)) / (2.0_wp * dx)
!     end do
    
    
!     ! Corners
!     if (par%master) then
!     dy_a( 1      ,1      ) = (d_cx( 2      ,1        ) - d_cx( 1        ,1        )) / dx
!     dy_a( 1      ,nx) = (d_cx( 2      ,nx-1) - d_cx( 1        ,nx-1)) / dx
!     dy_a( ny,1      ) = (d_cx( ny,1        ) - d_cx( ny-1,1        )) / dx
!     dy_a( ny,nx) = (d_cx( ny,nx-1) - d_cx( ny-1,nx-1)) / dx
!     end if
    
    
!   end subroutine ddy_cx_to_a_2D
!   subroutine ddx_cy_to_a_2D( d_cy, dx_a)
!     ! Input:  scalar on the Acy grid
!     ! Output: its x-derivative on the Aa grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cy
!     real(wp), intent(OUT)   :: dx_a
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Interior
!     do i = 2, nx-1
!     do j = 2, ny-1
!       dx_a(i,j) = (d_cy(i+1,j-1) + d_cy(i+1,j) - d_cy(i-1,j-1) - d_cy(i-1,j)) / (4.0_wp * dx)
!     end do
!     end do
    
    
!     do j = MAX(2,grid%j1), MIN(ny-1,grid%j2)
!       ! West ex. corners
!       i = 1
!       dx_a(i,j) = (d_cy(i+1,j-1) + d_cy( j  ,i+1) - d_cy( j-1,i  ) - d_cy( j  ,i  )) / (4.0_wp * dx)
!       ! East ex. corners
!       i = nx
!       dx_a(i,j) = (d_cy( j-1,i  ) + d_cy( j  ,i  ) - d_cy(i-1,j-1) - d_cy( j  ,i-1)) / (4.0_wp * dx)
!     end do
    
    
!     do i = 2, nx-1
!       ! South ex. corners
!       j = 1
!       dx_a(i,j) = (d_cy( j  ,i+1) - d_cy( j  ,i-1)) / (2.0_wp * dx)
!       ! North ex. corners
!       j = ny
!       dx_a(i,j) = (d_cy(i+1,j-1) - d_cy(i-1,j-1)) / (2.0_wp * dx)
!     end do
    
    
!     ! Corners
!     if (par%master) then
!     dx_a( 1      ,      1) = (d_cy( 1        ,2      ) - d_cy( 1        ,1        )) / dx
!     dx_a( 1      ,nx) = (d_cy( 1        ,nx) - d_cy( 1        ,nx-1)) / dx
!     dx_a( ny,1      ) = (d_cy( ny-1,2      ) - d_cy( ny-1,1        )) / dx
!     dx_a( ny,nx) = (d_cy( ny-1,nx) - d_cy( ny-1,nx-1)) / dx
!     end if
    
    
!   end subroutine ddx_cy_to_a_2D
!   ! 3D
!   subroutine ddx_cx_to_a_3D( d_cx, dx_a)
!     ! Input:  scalar on the Acx grid
!     ! Output: its x-derivative on the Aa grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cx
!     real(wp),  intent(OUT)   :: dx_a
    
!     ! Local variables:
!     integer :: i, j, nx, ny,k
    
!     do i = 2, nx-1
!     do j = 1, ny
!     do k = 1, C%nZ
!       dx_a(i,j,k) = (d_cx(i,j,k) - d_cx(i-1,j,k)) / dx
!     end do
!     end do
!     end do
    
    
!   end subroutine ddx_cx_to_a_3D
!   subroutine ddy_cy_to_a_3D( d_cy, dy_a)
!     ! Input:  scalar on the Acy grid
!     ! Output: its y-derivative on the Aa grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cy
!     real(wp),  intent(OUT)   :: dy_a
    
!     ! Local variables:
!     integer :: i, j, nx, ny,k
    
!     do i = 1, nx
!     do j = 2, ny-1
!     do k = 1, C%nZ
!       dy_a(i,j,k) = (d_cy(i,j,k) - d_cy(i,j-1,k)) / dx
!     end do
!     end do
!     end do
    
    
!   end subroutine ddy_cy_to_a_3D
  
!   ! Acx/Acy to Acx/Acy
!   subroutine ddx_cx_to_cx_2D( d_cx, dx_cx)
!     ! Input:  scalar on the Acx grid
!     ! Output: its x-derivative on the Acx grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cx
!     real(wp),  intent(OUT)   :: dx_cx
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Central differencing in the interior
!     do i = 2, nx-2
!     do j = 1, ny
!       dx_cx(i,j) = (d_cx(i+1,j) - d_cx(i-1,j)) / (2 * dx)
!     end do
!     end do
    
    
!     ! One-sided differencing on the boundaries
!     dx_cx( grid%j1:grid%j2,1        ) = (d_cx( grid%j1:grid%j2,2        ) - d_cx( grid%j1:grid%j2,1        )) / dx
!     dx_cx( grid%j1:grid%j2,nx-1) = (d_cx( grid%j1:grid%j2,nx-1) - d_cx( grid%j1:grid%j2,nx-2)) / dx
    
    
!   end subroutine ddx_cx_to_cx_2D
!   subroutine ddy_cx_to_cx_2D( d_cx, dy_cx)
!     ! Input:  scalar on the Acx grid
!     ! Output: its y-derivative on the Acx grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cx
!     real(wp),  intent(OUT)   :: dy_cx
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Central differencing in the interior
!     do i = 1, nx-1
!     do j = 2, ny-1
!       dy_cx(i,j) = (d_cx(i,j+1) - d_cx(i,j-1)) / (2 * dx)
!     end do
!     end do
    
    
!     ! One-sided differencing on the boundaries
!     dy_cx(:,1) = (d_cx( 2      ,grid%i1:grid%i2) - d_cx( 1        ,grid%i1:grid%i2)) / dx
!     dy_cx(:,ny) = (d_cx(:,ny) - d_cx( ny-1,grid%i1:grid%i2)) / dx
    
    
!   end subroutine ddy_cx_to_cx_2D
!   subroutine ddx_cy_to_cy_2D( d_cy, dx_cy)
!     ! Input:  scalar on the Acy grid
!     ! Output: its x-derivative on the Acy grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cy
!     real(wp),  intent(OUT)   :: dx_cy
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Central differencing in the interior
!     do i = 2, nx-1
!     do j = 1, ny-1
!       dx_cy(i,j) = (d_cy(i+1,j) - d_cy(i-1,j)) / (2 * dx)
!     end do
!     end do
    
    
!     ! One-sided differencing on the boundaries
!     dx_cy( grid%j1:MIN(grid%j2,ny-1),1      ) = (d_cy( grid%j1:MIN(grid%j2,ny-1),2      ) - d_cy( grid%j1:MIN(grid%j2,ny-1),1        )) / dx
!     dx_cy( grid%j1:MIN(grid%j2,ny-1),nx) = (d_cy( grid%j1:MIN(grid%j2,ny-1),nx) - d_cy( grid%j1:MIN(grid%j2,ny-1),nx-1)) / dx
    
    
!   end subroutine ddx_cy_to_cy_2D
!   subroutine ddy_cy_to_cy_2D( d_cy, dy_cy)
!     ! Input:  scalar on the Acy grid
!     ! Output: its y-derivative on the Acy grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cy
!     real(wp),  intent(OUT)   :: dy_cy
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Central differencing in the interior
!     do i = 1, nx
!     do j = 2, ny-2
!       dy_cy(i,j) = (d_cy(i,j+1) - d_cy(i,j-1)) / (2 * dx)
!     end do
!     end do
    
    
!     ! One-sided differencing on the boundaries
!     dy_cy( 1        ,grid%i1:grid%i2) = (d_cy( 2        ,grid%i1:grid%i2) - d_cy( 1        ,grid%i1:grid%i2)) / dx
!     dy_cy( ny-1,grid%i1:grid%i2) = (d_cy( ny-1,grid%i1:grid%i2) - d_cy( ny-2,grid%i1:grid%i2)) / dx
    
    
!   end subroutine ddy_cy_to_cy_2D
!   subroutine ddx_cx_to_cy_2D( d_cx, dx_cy)
!     ! Input:  scalar on the Acx grid
!     ! Output: its x-derivative on the Acy grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cx
!     real(wp),  intent(OUT)   :: dx_cy
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Interior
!     do i = 2, nx-1
!     do j = 1, ny-1
!       dx_cy(i,j) = (d_cx( j,i  ) + d_cx( j+1,i  ) - d_cx(i-1,j) - d_cx(i-1,j+1)) / (2.0_wp * dx)
!     end do
!     end do
    
    
!     ! Boundaries
!     do j = 1, ny-1
!       ! West
!       dx_cy(1,j) = dx_cy( j,2        )
!       ! East
!       dx_cy(nx,j) = dx_cy(nx-1,j)
!     end do
    
    
!   end subroutine ddx_cx_to_cy_2D
!   subroutine ddy_cx_to_cy_2D( d_cx, dy_cy)
!     ! Input:  scalar on the Acx grid
!     ! Output: its y-derivative on the Acy grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cx
!     real(wp),  intent(OUT)   :: dy_cy
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Interior
!     do i = 2, nx-1
!     do j = 1, ny-1
!       dy_cy(i,j) = (d_cx(i-1,j+1) + d_cx( j+1,i  ) - d_cx( j  ,i-1) - d_cx( j  ,i  )) / (2.0_wp * dx)
!     end do
!     end do
    
    
!     ! Boundaries
!     do j = 1, ny-1
!       ! West
!       i = 1
!       dy_cy(i,j) = (d_cx( j,i  ) - d_cx( j,i  )) / dx
!       ! East
!       i = nx
!       dy_cy(i,j) = (d_cx(i-1,j) - d_cx(i-1,j)) / dx
!     end do
    
    
!   end subroutine ddy_cx_to_cy_2D
!   subroutine ddx_cy_to_cx_2D( d_cy, dx_cx)
!     ! Input:  scalar on the Acy grid
!     ! Output: its x-derivative on the Acx grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cy
!     real(wp),  intent(OUT)   :: dx_cx
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Interior
!     do i = 1, nx-1
!     do j = 2, ny-1
!       dx_cx(i,j) = (d_cy(i+1,j-1) + d_cy( j  ,i+1) - d_cy( j-1,i  ) - d_cy( j  ,i  )) / (2.0_wp * dx)
!     end do
!     end do
    
    
!     ! Boundaries
!     do i = 1, nx-1
!       ! South
!       j = 1
!       dx_cx(i,j) = (d_cy( j  ,i+1) - d_cy( j  ,i  )) / dx
!       ! North
!       j = ny
!       dx_cx(i,j) = (d_cy(i+1,j-1) - d_cy( j-1,i  )) / dx
!     end do
    
    
!   end subroutine ddx_cy_to_cx_2D
!   subroutine ddy_cy_to_cx_2D( d_cy, dy_cx)
!     ! Input:  scalar on the Acy grid
!     ! Output: its y-derivative on the Acx grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cy
!     real(wp),  intent(OUT)   :: dy_cx
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Interior
!     do i = 1, nx-1
!     do j = 2, ny-1
!       dy_cx(i,j) = (d_cy( j  ,i  ) + d_cy( j  ,i+1) - d_cy( j-1,i  ) - d_cy(i+1,j-1)) / (2.0_wp * dx)
!     end do
!     end do
    
    
!     ! Boundaries
!     do i = 1, nx-1
!       ! South
!       j = 1
!       dy_cx(i,j) = (d_cy( j+1,i  ) + d_cy(j+1,i+1) - d_cy( j  ,i  ) - d_cy( j  ,i+1)) / (2.0_wp * dx)
!       ! North
!       j = ny
!       dy_cx(i,j) = (d_cy( j-1,i  ) + d_cy(j-1,i+1) - d_cy( j-2,i  ) - d_cy( j-2,i+1)) / (2.0_wp * dx)
!     end do
    
    
!   end subroutine ddy_cy_to_cx_2D
  
!   ! Acx to Ab
!   subroutine ddx_cx_to_b_2D( d_cx, dx_b)
!     ! Input:  scalar on the Acx grid
!     ! Output: its x-derivative on the Ab grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cx
!     real(wp), DIMENSION(       ny-1, nx-1), intent(OUT)   :: dx_b
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Interior
!     do i = MAX(2,grid%i1), MIN(nx-2,grid%i2)
!     do j = 1, ny-1
!       dx_b(i,j) = (d_cx(i+1,j+1) + d_cx( j  ,i+1) - d_cx(i-1,j+1) - d_cx( j  ,i-1)) / (4.0_wp * dx)
!     end do
!     end do
    
    
!     ! Boundaries
!     do j = 1, ny-1
!       i = 1
!       dx_b(i,j) = (d_cx(i+1,j+1) + d_cx( j  ,i+1) - d_cx( j+1,i  ) - d_cx( j  ,i  )) / (2.0_wp * dx)
!       i = nx-1
!       dx_b(i,j) = (d_cx( j+1,i  ) + d_cx( j  ,i  ) - d_cx(i-1,j+1) - d_cx( j  ,i-1)) / (2.0_wp * dx)
!     end do
    
    
!   end subroutine ddx_cx_to_b_2D
!   subroutine ddy_cy_to_b_2D( d_cy, dy_b)
!     ! Input:  scalar on the Acy grid
!     ! Output: its y-derivative on the Ab grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cy
!     real(wp), DIMENSION(       ny-1, nx-1), intent(OUT)   :: dy_b
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Interior
!     do i = MAX(2,grid%i1), MIN(nx-2,grid%i2)
!     do j = 2, ny-2
!       dy_b(i,j) = (d_cy(i+1,j+1) + d_cy( j+1,i  ) - d_cy(i+1,j-1) - d_cy( j-1,i  )) / (4.0_wp * dx)
!     end do
!     end do
    
    
!     ! Boundaries
!     do i = 1, nx-1
!       j = 1
!       dy_b(i,j) = (d_cy(i+1,j+1) + d_cy( j+1,i  ) - d_cy( j  ,i+1) - d_cy( j  ,i  )) / (2.0_wp * dx)
!       j = ny-1
!       dy_b(i,j) = (d_cy( j  ,i+1) + d_cy( j  ,i  ) - d_cy(i+1,j-1) - d_cy( j-1,i  )) / (2.0_wp * dx)
!     end do
    
    
!   end subroutine ddy_cy_to_b_2D
!   subroutine ddx_cy_to_b_2D( d_cy, dx_b)
!     ! Input:  scalar on the Acy grid
!     ! Output: its x-derivative on the Ab grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cy
!     real(wp), DIMENSION(       ny-1, nx-1), intent(OUT)   :: dx_b
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Interior
!     do i = 1, nx-1
!     do j = 1, ny-1
!       dx_b(i,j) = (d_cy(i+1,j) - d_cy(i,j)) / dx
!     end do
!     end do
    
    
!   end subroutine ddx_cy_to_b_2D
!   subroutine ddy_cx_to_b_2D( d_cx, dy_b)
!     ! Input:  scalar on the Acx grid
!     ! Output: its y-derivative on the Ab grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cx
!     real(wp), DIMENSION(       ny-1, nx-1), intent(OUT)   :: dy_b
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Interior
!     do i = 1, nx-1
!     do j = 1, ny-1
!       dy_b(i,j) = (d_cx(i,j+1) - d_cx(i,j)) / dx
!     end do
!     end do
    
    
!   end subroutine ddy_cx_to_b_2D
  
! ! =============================================
! ! ===== Mapping between (staggered) grids =====
! ! =============================================

!   ! Aa to Acx/Acy
  
!   ! 2D
!   subroutine map_a_to_cx_2D( d_a, d_cx)
!     ! Input:  scalar on the Aa grid
!     ! Output: the same on the Acx grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp), intent(IN)    :: d_a
!     real(wp),  intent(OUT)   :: d_cx
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     do i = 1, nx-1
!     do j = 1, ny
!       d_cx(i,j) = (d_a(i,j) + d_a(i+1,j)) / 2.0_wp
!     end do
!     end do
    
    
!   end subroutine map_a_to_cx_2D
!   subroutine map_a_to_cy_2D( d_a, d_cy)
!     ! Input:  scalar on the Aa grid
!     ! Output: the same on the Acy grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp), intent(IN)    :: d_a
!     real(wp),  intent(OUT)   :: d_cy
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     do i = 1, nx
!     do j = 1, ny-1
!       d_cy(i,j) = (d_a(i,j) + d_a(i,j+1)) / 2.0_wp
!     end do
!     end do
    
    
!   end subroutine map_a_to_cy_2D
!   ! 3D
!   subroutine map_a_to_cx_3D( d_a, d_cx)
!     ! Input:  scalar on the Aa grid
!     ! Output: the same on the Acx grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_a
!     real(wp),  intent(OUT)   :: d_cx
    
!     ! Local variables:
!     integer :: i, j, nx, ny,k
    
!     do i = 1, nx-1
!     do j = 1, ny
!     do k = 1, C%nZ
!       d_cx(i,j,k) = (d_a(i,j,k) + d_a(i+1,j,k)) / 2.0_wp
!     end do
!     end do
!     end do
    
    
!   end subroutine map_a_to_cx_3D
!   subroutine map_a_to_cy_3D( d_a, d_cy)
!     ! Input:  scalar on the Aa grid
!     ! Output: the same on the Acy grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_a
!     real(wp),  intent(OUT)   :: d_cy
    
!     ! Local variables:
!     integer :: i, j, nx, ny,k
    
!     do i = 1, nx
!     do j = 1, ny-1
!     do k = 1, C%nZ
!       d_cy(i,j,k) = (d_a(i,j,k) + d_a(i,j+1,k)) / 2.0_wp
!     end do
!     end do
!     end do
    
    
!   end subroutine map_a_to_cy_3D
  
!   ! Acx/Acy to Aa
  
!   ! 2D
!   subroutine map_cx_to_a_2D( d_cx, d_a)
!     ! Input:  scalar on the Acx grid
!     ! Output: the same on the Aa grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cx
!     real(wp), intent(OUT)   :: d_a
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     do i = 2, nx-1
!     do j = 1, ny
!       d_a(i,j) = (d_cx(i-1,j) + d_cx(i,j)) / 2.0_wp
!     end do
!     end do
    
    
!     d_a(1,:) = d_cx( grid%j1:grid%j2,1        )
!     d_a(nx,:) = d_cx( grid%j1:grid%j2,nx-1)
    
    
!   end subroutine map_cx_to_a_2D
!   subroutine map_cy_to_a_2D( d_cy, d_a)
!     ! Input:  scalar on the Acy grid
!     ! Output: the same on the Aa grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cy
!     real(wp), intent(OUT)   :: d_a
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     do i = 1, nx
!     do j = 2, ny-1
!       d_a(i,j) = (d_cy(i,j-1) + d_cy(i,j)) / 2.0_wp
!     end do
!     end do
    
    
!     d_a(:,1) = d_cy( 1        ,grid%i1:grid%i2)
!     d_a(:,ny) = d_cy( ny-1,grid%i1:grid%i2)
    
    
!   end subroutine map_cy_to_a_2D
!   ! 3D
!   subroutine map_cx_to_a_3D( d_cx, d_a)
!     ! Input:  scalar on the Acx grid
!     ! Output: the same on the Aa grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cx
!     real(wp),  intent(OUT)   :: d_a
    
!     ! Local variables:
!     integer :: i, j, nx, ny,k
    
!     do i = 2, nx-1
!     do j = 1, ny
!     do k = 1, C%nZ
!       d_a(i,j,k) = (d_cx(i-1,j,k) + d_cx(i,j,k)) / 2.0_wp
!     end do
!     end do
!     end do
    
    
!     d_a(1,:,:) = d_cx( :,grid%j1:grid%j2,1        )
!     d_a(nx,:,:) = d_cx( :,grid%j1:grid%j2,nx-1)
    
    
!   end subroutine map_cx_to_a_3D
!   subroutine map_cy_to_a_3D( d_cy, d_a)
!     ! Input:  scalar on the Acy grid
!     ! Output: the same on the Aa grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cy
!     real(wp),  intent(OUT)   :: d_a
    
!     ! Local variables:
!     integer :: i, j, nx, ny,k
    
!     do i = 1, nx
!     do j = 2, ny-1
!     do k = 1, C%nZ
!       d_a(i,j,k) = (d_cy(i,j-1,k) + d_cy(i,j,k)) / 2.0_wp
!     end do
!     end do
!     end do
    
    
!     d_a(:,1,:) = d_cy( :,1        ,grid%i1:grid%i2)
!     d_a(:,ny,:) = d_cy( :,ny-1,grid%i1:grid%i2)
    
    
!   end subroutine map_cy_to_a_3D
  
!   ! Acx/Acy to Acy/Acx
!   subroutine map_cx_to_cy_2D( d_cx, d_cy)
!     ! Input:  scalar on the Acx grid
!     ! Output: the same on the Acy grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cx
!     real(wp),  intent(OUT)   :: d_cy
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Interior
!     do i = 2, nx-1
!     do j = 1, ny-1
!       d_cy(i,j) = (d_cx( j  ,i-1) + d_cx( j  ,i  ) + d_cx(i-1,j+1) + d_cx( j+1,i  )) / 4.0_wp
!     end do
!     end do
    
    
!     ! Boundaries
!     do j = 1, ny-1
!       i = 1
!       d_cy(i,j) = (d_cx( j  ,i  ) + d_cx( j+1,i  )) / 2.0_wp
!       i = nx
!       d_cy(i,j) = (d_cx( j  ,i-1) + d_cx(i-1,j+1)) / 2.0_wp
!     end do
    
    
!   end subroutine map_cx_to_cy_2D
!   subroutine map_cy_to_cx_2D( d_cy, d_cx)
!     ! Input:  scalar on the Acy grid
!     ! Output: the same on the Acx grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cy
!     real(wp),  intent(OUT)   :: d_cx
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     ! Interior
!     do i = 1, nx-1
!     do j = 2, ny-1
!       d_cx(i,j) = (d_cy( j-1,i  ) + d_cy(i+1,j-1) + d_cy( j  ,i  ) + d_cy( j  ,i+1)) / 4.0_wp
!     end do
!     end do
    
    
!     ! Boundaries
!     do i = 1, nx-1
!       j = 1
!       d_cx(i,j) = (d_cy( j  ,i  ) + d_cy( j  ,i+1)) / 2.0_wp
!       j = ny
!       d_cx(i,j) = (d_cy( j-1,i  ) + d_cy(i+1,j-1)) / 2.0_wp
!     end do
    
    
!   end subroutine map_cy_to_cx_2D
  
!   ! Aa to Ab
!   subroutine map_a_to_b_2D( d_a, d_b)
!     ! Input:  scalar on the Aa grid
!     ! Output: the same on the Ab grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp), intent(IN)    :: d_a
!     real(wp), DIMENSION(       ny-1, nx-1), intent(OUT)   :: d_b
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     do i = 1, nx-1
!     do j = 1, ny-1
!       d_b(i,j) = (d_a(i,j) + d_a(i+1,j) + d_a(i,j+1) + d_a(i+1,j+1)) / 4.0_wp
!     end do
!     end do
    
    
!   end subroutine map_a_to_b_2D
  
!   ! Acx/Acy to Ab
!   subroutine map_cx_to_b_2D( d_cx, d_b)
!     ! Input:  scalar on the Acx grid
!     ! Output: the same on the Ab grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cx
!     real(wp), DIMENSION(       ny-1, nx-1), intent(OUT)   :: d_b
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     do i = 1, nx-1
!     do j = 1, ny-1
!       d_b(i,j) = (d_cx(i,j) + d_cx(i,j+1)) / 2.0_wp
!     end do
!     end do
    
    
!   end subroutine map_cx_to_b_2D
!   subroutine map_cy_to_b_2D( d_cy, d_b)
!     ! Input:  scalar on the Acy grid
!     ! Output: the same on the Ab grid
    
!     implicit none
    
!     ! In/output variables:
    
!     real(wp),  intent(IN)    :: d_cy
!     real(wp), DIMENSION(       ny-1, nx-1), intent(OUT)   :: d_b
    
!     ! Local variables:
!     integer :: i, j, nx, ny
    
!     do i = 1, nx-1
!     do j = 1, ny-1
!       d_b(i,j) = (d_cy(i,j) + d_cy(i+1,j)) / 2.0_wp
!     end do
!     end do
    
    
!   end subroutine map_cy_to_b_2D
  
end module grid_calcs


