!-------------------------------------------------------------------------------
! SPHERA v.9.0.0 (Smoothed Particle Hydrodynamics research software; mesh-less
! Computational Fluid Dynamics code).
! Copyright 2005-2021 (RSE SpA -formerly ERSE SpA, formerly CESI RICERCA,
! formerly CESI-Ricerca di Sistema)
!
! SPHERA authors and email contact are provided on SPHERA documentation.
!
! This file is part of SPHERA v.9.0.0
! SPHERA v.9.0.0 is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
! SPHERA is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
! GNU General Public License for more details.
! You should have received a copy of the GNU General Public License
! along with SPHERA. If not, see <http://www.gnu.org/licenses/>.
!-------------------------------------------------------------------------------
!-------------------------------------------------------------------------------
! Program unit: PreSourceParticles_3D
! Description: To generate new source particles at the inlet section (only in 3D
!              and quadrilateral inlet sections).  
!-------------------------------------------------------------------------------
#ifdef SPACE_3D
subroutine PreSourceParticles_3D
!------------------------
! Modules
!------------------------
use Static_allocation_module
use I_O_file_module
use Hybrid_allocation_module
use Dynamic_allocation_module
!------------------------
! Declarations
!------------------------
implicit none
integer(4) :: nt,isi,sd,ip,i_source,i,j,NumPartR,NumPartS,nodes
double precision :: deltapart,eps,deltaR,deltaS,LenR,LenS,distR,distS,csi
double precision :: etalocal
!------------------------
! Explicit interfaces
!------------------------
!------------------------
! Allocations
!------------------------
!------------------------
! Initializations
!------------------------
! searching the ID of the source side
SourceFace = 0
SpCount = 0
i_source=0
!------------------------
! Statements
!------------------------
do isi=1,NumFacce
   nt = BoundaryFace(isi)%stretch
   if (Tratto(nt)%tipo=="sour") then
      SourceFace = isi
      i_source = i_source + 1
      if (SourceFace>0) then
         nt = BoundaryFace(SourceFace)%stretch
         mat = Tratto(nt)%Medium
         izone = Tratto(nt)%zone
! Note: to insert a check in case of nodes=/4
         nodes = BoundaryFace(SourceFace)%nodes    
         deltapart = Domain%dx
! LenR and LenS are the length scales of the inlet section: they are computed
! as the distance between the first and the last inlet vertices and the third
! and the last inlet vertices, respectively. Particles are aligned with Plast-P1
! and Plast-P3, where P1 the first boundary vertex, ..., Plast being the last 
! boundary vertex. In case of a triangular inlet, we have particles aligned 
! with one direction: P3-P1. In case of a quadrilateral inlet, we have particles 
! distributed along two directions: P4-P1 and P4-P3.
         LenR = zero
         LenS = zero
         do sd=1,SPACEDIM
            LenR = LenR + (BoundaryFace(SourceFace)%Node(1)%GX(sd) -           &
                   BoundaryFace(SourceFace)%Node(nodes)%GX(sd)) ** 2
            LenS = LenS + (BoundaryFace(SourceFace)%Node(3)%GX(sd) -           &
                   BoundaryFace(SourceFace)%Node(nodes)%GX(sd)) ** 2
         enddo
         LenR = dsqrt(LenR)
         LenS = dsqrt(LenS)
         NumPartR = int(LenR / deltapart + 0.01d0)
         NumPartS = int(LenS / deltapart + 0.01d0)
         deltaR = LenR / NumPartR 
         deltaS = LenS / NumPartS 
         eps = -half
         zfila = eps * deltapart
         distR = -half * deltaR
         ip = 0
         do i=1,NumPartR
            distR = distR + deltaR
            csi = distR / LenR
            distS = -half * deltaS
            do j=1,NumPartS
               distS = distS + deltaS
               etalocal = distS / LenS
               ip = ip + 1
               do sd=1,SPACEDIM
                  P(sd) = BoundaryFace(SourceFace)%Node(4)%GX(sd) * (one -     &
                          csi) + BoundaryFace(SourceFace)%Node(1)%GX(sd) * csi
                  Q(sd) = BoundaryFace(SourceFace)%Node(3)%GX(sd) * (one -     &
                          csi) + BoundaryFace(SourceFace)%Node(2)%GX(sd) * csi
                  PartLine(i_source,ip,sd) = P(sd) * (one - etalocal) + Q(sd) *&
                                             etalocal
               enddo
            enddo
         enddo
         NumPartFace(i_source) = ip
         ParticleVolume = Domain%PVolume
         RowPeriod = ParticleVolume * NumPartFace(i_source) /                  &
                     Tratto(nt)%FlowRate 
         RowVelocity(i_source) = Domain%dx / RowPeriod
         Tratto(nt)%NormVelocity = RowVelocity(i_source)
         pinttimeratio = -1
      endif
   endif
enddo 
!------------------------
! Deallocations
!------------------------
return
end subroutine PreSourceParticles_3D
#endif
