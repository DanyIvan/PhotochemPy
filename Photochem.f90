      module photochem
        implicit none
        ! Module variables (shared between subroutines)
        real*8, allocatable, dimension(:) :: Flux ! Solar flux photons/(cm2 s)
        real*8, allocatable, dimension(:,:) :: prates ! photolysis rates (1/s)
        integer :: nz ! number of vertical grid points
        integer :: nq ! number of long lived species
        integer :: np ! number of particles
        integer :: nw ! number of wavelengths
        integer :: nsp ! total number of species
        integer :: nsp2 ! total number of species, including HV and M
        integer :: nr ! number of reactions
        integer :: nmax ! max number of reactions a species can be involved in
        integer :: ks ! number of photo species
        integer :: kj ! number of photo reactions

        ! Defined in species.dat
        integer :: iSL ! number of sl species
        real*8 :: FCO2, FN2 ! mixing ratios of N2 and CO2 if inert
        character(len=8), allocatable, dimension(:) :: ISPEC
        integer, allocatable, dimension(:) :: LBOUND
        real*8, allocatable, dimension(:) :: VDEP0
        real*8, allocatable, dimension(:) :: FIXEDMR
        real*8, allocatable, dimension(:) :: distflux
        real*8, allocatable, dimension(:) :: SGFLUX
        real*8, allocatable, dimension(:) :: distheight
        integer, allocatable, dimension(:) :: MBOUND
        real*8, allocatable, dimension(:) :: SMFLUX
        real*8, allocatable, dimension(:) :: VEFF0
        integer, allocatable, dimension(:) :: atomsO
        integer, allocatable, dimension(:) :: atomsH
        integer, allocatable, dimension(:) :: atomsC
        integer, allocatable, dimension(:) :: atomsS
        integer, allocatable, dimension(:) :: atomsN
        integer, allocatable, dimension(:) :: atomsCL
        real*8, allocatable, dimension(:) :: mass
        ! make all these atoms things local

        ! Defined in reactions.rx
        Character(len=8), allocatable, dimension(:,:) :: chemj
        integer, allocatable, dimension(:,:) :: jchem
        Character(len=8), allocatable, dimension(:) :: reactype
        real*8, allocatable, dimension(:,:) :: rateparams ! a new one.
        ! I am going to need to calculate reaction rates each timestep with
        ! the data stored in rateparams. So I need a subroutine... lets call it
        ! rates, which does this. rates will take in T(z) and Density(z) and reactype
        ! and calculate all of the reaction rate coefficients.
        ! the reaction rates coefficients can be a module variable.
        integer, allocatable, dimension(:,:,:) :: iloss
        integer, allocatable, dimension(:,:) :: iprod
        integer, allocatable, dimension(:) :: photoreac
        integer, allocatable, dimension(:) :: photonums
        integer, allocatable, dimension(:) :: photospec

        ! needed in photogrid.f90
        real*8, allocatable, dimension(:) :: z
        real*8, allocatable, dimension(:) :: dz

        ! needed in read_atmosphere.f90
        real*8, allocatable, dimension(:,:) :: usol_init
        real*8, allocatable, dimension(:) :: den
        real*8, allocatable, dimension(:) :: T
        real*8, allocatable, dimension(:) :: EDD

        ! needed in rates.f90
        real*8, allocatable, dimension(:,:) :: A

        ! some planet parameters and constants
        real*8 :: g ! gravity cgs units
        real*8 :: k_boltz ! boltzman constant cgs units

      contains
        ! Module subroutines go here.
        ! include "fortran_subroutine_name.f90"
        ! e.g. include "Photo.f90"
        ! etc...

        include "read_species.f90" ! reads species.dat
        include "read_reactions.f90" ! reads reactions.rx
        include "read_atmosphere.f90" ! reads atmosphere.txt
        include "photogrid.f90" ! step up vertical grid
        include "rates.f90" ! calculates reaction rates
        ! include "xsections.f90" ! loads xsections
        ! dochem
        ! chempl
        ! ...

        subroutine allocate_memory(nnw, nnz, nnq, nnp, nnsp,&
           nnr, kks, kkj)
          implicit none
          integer :: nnw, nnz, nnq, nnp, nnsp, nnr, kks, kkj
          integer :: i,j
!f2py     intent(in) :: nnw, nnz, nnq, nnp, nnsp, nnr, kks, kkj

          ! The dimensions.
          nz = nnz
          nq  = nnq
          nw = nnw
          np = nnp
          nsp = nnsp
          nsp2 = nnsp+2
          ks = kks
          kj = kkj
          nr = nnr
          nmax = 300

          ! allocate memory
          ! safeguard against allocating twice
          if (allocated(Flux).neqv..True.) then
            allocate(Flux(nw))
            ! allocate(prates())

            ! Defined in species.dat
            allocate(ISPEC(nsp2)) ! issue with this one
            allocate(LBOUND(nq))
            allocate(vdep0(nq))
            allocate(fixedmr(nq))
            allocate(distflux(nq))
            allocate(sgflux(nq))
            allocate(distheight(nq))
            allocate(MBOUND(nq))
            allocate(SMFLUX(nq))
            allocate(VEFF0(nq))
            allocate(atomsO(nsp2))
            allocate(atomsH(nsp2))
            allocate(atomsC(nsp2))
            allocate(atomsS(nsp2))
            allocate(atomsN(nsp2))
            allocate(atomsCl(nsp2))
            allocate(mass(nsp2))

            ! definined in reactions.rx
            allocate(chemj(5,nr))
            allocate(jchem(5,nr))
            allocate(reactype(nr))
            allocate(rateparams(4,nr))
            allocate(iloss(2,nsp,nmax))
            allocate(iprod(nsp,nmax))
            allocate(photoreac(kj))
            allocate(photospec(ks))
            allocate(photonums(kj))

            ! needed in photogrid.f90
            allocate(z(nz))
            allocate(dz(nz))

            ! needed in atmosphere.txt
            allocate(usol_init(nq,nz))
            allocate(den(nz))
            allocate(T(nz))
            allocate(EDD(nz))

            ! needed in rates.f90
            allocate(A(NR,NZ))
            ! zero out
            do i =1,nr
              do j=1,nz
                A(i,j) = 0.0
              enddo
            enddo



          else
            print*, "Memory has already been allocated"
          endif

          ! Define planet parameters

          ! Define constants

        end subroutine allocate_memory

        subroutine right_hand_side(ttt, usol_flat, neq, rhs)
          implicit none
          integer :: i
          integer :: neq
          real*8, dimension(neq) :: usol_flat
          real*8, dimension(neq) :: rhs
          real*8 :: ttt
!f2py     intent(hide) :: neq
!f2py     intent(in), depend(neq) :: usol_flat
!f2py     intent(in) :: ttt
!f2py     intent(out), depend(neq) :: rhs

          ! ---INPUT---
          ! t (s)
          ! Time. Doesn't do anything. Required format for ODE integration.
          ! usol_flat (molecules/cm3)
          ! The first nq elements of usol_flat should be the ground level
          ! densities. The next nq elements are layer above the ground level
          ! densities etc.
          ! ---OUTPUT---
          ! rhs (molecules/cm3/s)
          ! right-hand-size of the ODEs. Same organization as usol_flat.

          ! Return error if essential module variables are not defined

          ! Define P and T structure. These will change as atmosphere is lost.
          ! For now follow what is done in the 0-D code. Do it in a subroutine
          ! so I can take it out easily and make it better.

          ! I need to figure how the PDE changes when volume change is
          ! accounted for caused by chemical reactions. This confuses me.

          ! calculate prates
          ! call photo(usol_flat)

          ! calculate reaction rates
          ! call rates

          ! calculate chemistry
          ! call dochem(usol_flat,rhs)

          ! calculate eddy and molecular diffusion and volume changes.

          ! return rhs

          do i=1,neq
            rhs(i) = usol_flat(i)
          enddo

        end subroutine right_hand_side


        subroutine jacobian(ttt, usol_flat, neq, lda, jacob)
          implicit none
          ! This subroutine APPROXIMATES the non-zero elements of the Jacobian
          ! of the system of ODEs.
          ! We will NOT calculate photolysis rates (prates) in the jacobian
          ! and assume the prates module varible, which is calculate everytime
          ! right_hand_side is called, is good enough.
          integer :: i, j
          integer :: neq
          integer :: lda ! "width" of the non-zero diagonal in jacobian. lda = nq*3 + 1
          real*8, dimension(neq) :: usol_flat
          real*8, dimension(lda,neq) :: jacob
          real*8 :: ttt
!f2py     intent(hide) :: neq
!f2py     intent(in), depend(neq) :: usol_flat
!f2py     intent(in) :: ttt
!f2py     intent(in) :: lda
!f2py     intent(out), depend(neq) :: jacob

          ! ---INPUT---
          ! t (seconds)
          ! Time. Doesn't do anything. don't worry about it.
          ! usol_flat(neq) (molecules/cm3)
          ! composition of the atmosphere, flattened into an array
          ! ---OUTPUT---
          ! jacob(lda,neq) (1/s)
          ! non-zero diagonal of the jacobian. The diagonal is lda = nq*3 + 1 wide
          ! because each layer in the atmosphere can only communicate with the
          ! layers above and below it

          ! Return error if essential module variables are not defined

          ! Return error if prates is not defined.
          ! another option is to call photo once to determine prates if
          ! prates is not defined.

          ! use finite difference approximation to the jacobian

          do i=1,lda
            do j=1,neq
              jacob(i,j) = usol_flat(i)
            enddo
          enddo

        end subroutine jacobian

      end module
