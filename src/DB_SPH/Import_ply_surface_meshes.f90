!----------------------------------------------------------------------------------------------------------------------------------
! SPHERA (Smoothed Particle Hydrodynamics research software; mesh-less Computational Fluid Dynamics code).
! Copyright 2005-2015 (RSE SpA -formerly ERSE SpA, formerly CESI RICERCA, formerly CESI-) 
!      
!     
!   
!      
!  

! This file is part of SPHERA.
!  
!  
!  
!  
! SPHERA is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
!  
!  
!  
!----------------------------------------------------------------------------------------------------------------------------------

!----------------------------------------------------------------------------------------------------------------------------------
! Program unit: Import_ply_surface_meshes
! Description: To import the surface meshes (generated by SnappyHexMesh 
!              -OpenFOAM-), as converted by Paraview into .ply files.
!              This subroutine is mandatory and activated only for the DB-SPH 
!              boundary treatment scheme. In 3D, SPHERA (DBSPH) works with 
!              triangular faces, in 2D with quadrilateral faces. Input .ply 
!              files must be triangular/quadrilateral/pentagonal/hexagonal 
!              meshes in 3D or square meshes in 2D.    
!----------------------------------------------------------------------------------------------------------------------------------

subroutine Import_ply_surface_meshes
!------------------------
! Modules
!------------------------ 
use I_O_file_module
use Static_allocation_module
use Hybrid_allocation_module
use Dynamic_allocation_module
use I_O_diagnostic_module
!------------------------
! Declarations
!------------------------
implicit none
integer(4) :: file_stat,n_vertices,old_size_vert,old_size_face,new_size_vert
integer(4) :: new_size_face,dealloc_stat,alloc_stat,n_faces,face_vert_num,i,j,k
integer(4) :: surface_mesh_file_ID
integer(4) :: aux_face_vert(6)
character(80) :: file_name,aux_char_1,aux_char_2
type(vertex_der_type),dimension(:),allocatable :: aux_der_type_vert
type(face_der_type),dimension(:),allocatable :: aux_der_type_faces
!------------------------
! Explicit interfaces
!------------------------
interface
   subroutine area_triangle(P1,P2,P3,area,normal)
      implicit none
      double precision,intent(IN)    :: P1(3),P2(3),P3(3)
      double precision,intent(OUT)   :: area
      double precision,intent(OUT)   :: normal(3)
   end subroutine area_triangle
end interface
!------------------------
! Allocations
!------------------------
!------------------------
! Initializations
!------------------------
new_size_face = 0
surface_mesh_file_ID = 0
!------------------------
! Statements
!------------------------
! Open the file name list (surface_mesh_list.inp)
open(unit_file_list,file="surface_mesh_list.inp",IOSTAT=file_stat)
if (file_stat/=0) then
   write(*,*) 'Error in opening surface_mesh_list.inp in ',                    &
              'Import_pl_surface_meshes; the program terminates here'
   stop
endif
read(unit_file_list,*,IOSTAT=file_stat) 
if (file_stat/=0) then
   write(*,*) 'Error in reading surface_mesh_list.inp in ',                    &
              'Import_pl_surface_meshes; the program terminates here'
   stop
endif
do 
! To increment the file_number
   surface_mesh_file_ID = surface_mesh_file_ID + 1
! Read the file name    
   read (unit_file_list,'(a)',IOSTAT=file_stat) file_name
! Exit the cicle at the end of file
   if (file_stat/=0) exit 
   file_name = trim(file_name)
! Open the on-going mesh file
   open(unit_DBSPH_mesh,file=file_name,IOSTAT=file_stat)
   if (file_stat/=0) then
      write(*,*) 'Error in opening a surface mesh file in ',                   &
                 'Import_pl_surface_meshes; the program terminates here'
      stop
   endif   
   read(unit_DBSPH_mesh,"(3/)",IOSTAT=file_stat)
   if (file_stat/=0) then
      write(*,*) 'Error in reading a surface mesh file in ',                   &
                 'Import_pl_surface_meshes; the program terminates here'
      stop
   endif   
! Read the number of vertices in the file    
   read(unit_DBSPH_mesh,*,IOSTAT=file_stat) aux_char_1,aux_char_2,n_vertices
   if (file_stat/=0) then
      write(*,*) 'Error in reading a surface mesh file in ',                   &
                 'Import_pl_surface_meshes; the program terminates here'
      stop
   endif
   read(unit_DBSPH_mesh,"(2/)",IOSTAT=file_stat)
   if (file_stat/=0) then
      write(*,*) 'Error in reading a surface mesh file in ',                   &
                 'Import_pl_surface_meshes; the program terminates here'
      stop
   endif
! Read the number of faces in the file
   read(unit_DBSPH_mesh,*,IOSTAT=file_stat) aux_char_1,aux_char_2,n_faces
   if (file_stat/=0) then
      write(*,*) 'Error in reading a surface mesh file in ',                   &
                 'Import_pl_surface_meshes; the program terminates here'
      stop
   endif   
   read(unit_DBSPH_mesh,"(1/)",IOSTAT=file_stat)
   if (file_stat/=0) then
      write(*,*) 'Error in reading a surface mesh file in ',                   &
                 'Import_pl_surface_meshes; the program terminates here.'
      stop
   endif   
   if (.not.allocated(DBSPH%surf_mesh%vertices)) then
      allocate(DBSPH%surf_mesh%vertices(n_vertices),STAT=alloc_stat)
      if (alloc_stat/=0) then
         write(nout,*) 'Allocation of DBSPH%surf_mesh%vertices in ',           &
                       'Import_ply_surface_mesh failed; the program ',         &
                       'terminates here.'
! Stop the main program
         stop 
      endif
      if (.not.allocated(aux_der_type_vert)) then
          allocate(aux_der_type_vert(n_vertices),STAT=alloc_stat)
          if (alloc_stat/=0) then
             write(nout,*) 'Allocation of aux_der_type_vert in ',              &
                           'Import_ply_surface_mesh failed; the program ',     &
                           'terminates here.'
! Stop the main program
             stop 
          endif
      endif    
      old_size_vert = 0
      else
         old_size_vert = size(DBSPH%surf_mesh%vertices)
         new_size_vert = old_size_vert + n_vertices
         aux_der_type_vert(:) = DBSPH%surf_mesh%vertices(:)
         deallocate(DBSPH%surf_mesh%vertices,STAT=dealloc_stat)
         if (dealloc_stat/=0) then
            write(*,*) 'Deallocation of DBSPH%surf_mesh%vertices in ',         &
                       'Import_ply_surface_mesh failed; the program ',         &
                       'terminates here.'
! Stop the main program
            stop 
         endif          
         allocate(DBSPH%surf_mesh%vertices(new_size_vert),STAT=alloc_stat)
         if (alloc_stat/=0) then
            write(*,*) 'Allocation of DBSPH%surf_mesh%vertices in ',           &
                       'Import_ply_surface_mesh failed; the program ',         &
                       'terminates here'
! Stop the main program
            stop 
         endif         
         DBSPH%surf_mesh%vertices(1:old_size_vert) = aux_der_type_vert(:)
         if (allocated(aux_der_type_vert)) then
            deallocate(aux_der_type_vert,STAT=dealloc_stat)
            if (dealloc_stat/=0) then
               write(nout,*) 'Deallocation of aux_der_type_vert in ',          &
                             'Import_ply_surface_mesh failed; the program ',   &
                             'terminates here.'
! Stop the main program
               stop 
            endif   
         endif         
         allocate(aux_der_type_vert(new_size_vert),STAT=alloc_stat)
         if (alloc_stat/=0) then
            write(nout,*) 'Allocation of aux_der_type_vert in ',               &
                          'Import_ply_surface_mesh failed; the program ',      &
                          'terminates here.'
! Stop the main program
            stop 
         endif
   endif
! Read the vertex coordinates: start      
   do j=(old_size_vert+1),(old_size_vert+n_vertices)
      read (unit_DBSPH_mesh,*) DBSPH%surf_mesh%vertices(j)%pos(:)
   enddo
! Allocate or resize DBSPH%surf_mesh%faces on the maximum number of faces
! (worst case with all hexagonal faces)
   if (.not.allocated(DBSPH%surf_mesh%faces)) then
      if (ncord==3) then
         allocate(DBSPH%surf_mesh%faces((DBSPH%ply_n_face_vert-2)*n_faces),    &
            STAT=alloc_stat)
         else
            allocate(DBSPH%surf_mesh%faces(n_faces),STAT=alloc_stat)
      endif
      if (alloc_stat/=0) then
         write(nout,*) 'Allocation of DBSPH%surf_mesh%faces in ',              &
                       'Import_ply_surface_mesh failed; the program ',         &
                       'terminates here.'
! Stop the main program
         stop 
      endif
      if (.not.allocated(aux_der_type_faces)) then
         if (ncord==3) then
             allocate(aux_der_type_faces((DBSPH%ply_n_face_vert-2)*n_faces),   &
                STAT=alloc_stat)
            else
             allocate(aux_der_type_faces(n_faces),STAT=alloc_stat)
         endif
         if (alloc_stat/=0) then
            write(nout,*) 'Allocation of aux_der_type_faces in ',              &
                          'Import_ply_surface_mesh failed; the program ',      &
                          'terminates here.'
! Stop the main program
            stop 
         endif
      endif
      old_size_face = 0
      else
         old_size_face = size(DBSPH%surf_mesh%faces)
         if (ncord==3) then
            new_size_face = old_size_face + (DBSPH%ply_n_face_vert - 2) *      &
                            n_faces
            else
               new_size_face = old_size_face + n_faces
         endif
         aux_der_type_faces(:) = DBSPH%surf_mesh%faces(:)
         deallocate(DBSPH%surf_mesh%faces,STAT=dealloc_stat)
         if (dealloc_stat/=0) then
            write(*,*) 'Deallocation of DBSPH%surf_mesh%faces in ',            &
                       'Import_ply_surface_mesh failed; the program ',         &
                       'terminates here'
! Stop the main program
            stop 
         endif          
         allocate(DBSPH%surf_mesh%faces(new_size_face),STAT=alloc_stat)
         if (alloc_stat/=0) then
            write(*,*) 'Allocation of DBSPH%surf_mesh%faces in ',              &
                       'Import_ply_surface_mesh failed; the program ',         &
                       'terminates here'
! Stop the main program
            stop 
         endif         
         DBSPH%surf_mesh%faces(1:old_size_face) = aux_der_type_faces(:)
         if (allocated(aux_der_type_faces)) then
            deallocate(aux_der_type_faces,STAT=dealloc_stat)
            if (dealloc_stat/=0) then
               write(nout,*) 'Deallocation of aux_der_type_faces in ',         &
                             'Import_ply_surface_mesh failed; the program ',   &
                             'terminates here.'
! Stop the main program
               stop 
            endif   
         endif         
         allocate(aux_der_type_faces(new_size_face),STAT=alloc_stat)
         if (alloc_stat/=0) then
            write(nout,*) 'Allocation of aux_der_type_faces in ',              &
                          'Import_ply_surface_mesh failed; the program ',      &
                          'terminates here.'
! Stop the main program
            stop 
         endif
   endif 
! Read the face vertices: start
   k = old_size_face + 1
   do j=1,n_faces
      read(unit_DBSPH_mesh,*) face_vert_num,aux_face_vert(1:face_vert_num)
! Assignation of vertices with eventual conversion of any 4/5/6-side face  
! into 2/3/4 triangles; computation of area and normal 
      if (ncord==3) then
         select case (face_vert_num)
            case(3)
! To import vertices of the triangular face          
! Face 1: vertices 1,2,3
               DBSPH%surf_mesh%faces(k)%vert_list(1:3) = old_size_vert +       &
                                                         aux_face_vert(1:3) + 1
               DBSPH%surf_mesh%faces(k)%vert_list(4) = 0
               DBSPH%surf_mesh%surface_mesh_file_ID(k) = surface_mesh_file_ID
               k = k+1
! Computation of area and normal of the face
               call area_triangle(                                             &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(1))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(2))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(3))%pos,         &
                  DBSPH%surf_mesh%faces(k-1)%area,                             &
                  DBSPH%surf_mesh%faces(k-1)%normal)                         
            case(4)
! To import vertices of the quadrilateral face, split in 2 triangular faces
! Face 1: vertices 1,2,3 
            DBSPH%surf_mesh%faces(k)%vert_list(1:3) = old_size_vert +          &
                                                      aux_face_vert(1:3) + 1
            DBSPH%surf_mesh%faces(k)%vert_list(4) = 0
            DBSPH%surf_mesh%surface_mesh_file_ID(k) = surface_mesh_file_ID
! Face 2: vertices 1,3,4            
            DBSPH%surf_mesh%faces(k+1)%vert_list(1) = old_size_vert +          &
                                                      aux_face_vert(1) + 1
            DBSPH%surf_mesh%faces(k+1)%vert_list(2:3) = old_size_vert +        &
                                                       aux_face_vert(3:4) + 1
            DBSPH%surf_mesh%faces(k+1)%vert_list(4) = 0
            DBSPH%surf_mesh%surface_mesh_file_ID(k+1) = surface_mesh_file_ID
            k = k+2
! Computation of area and normal of the 2 faces
            call area_triangle(                                                &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-2)%vert_list(1))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-2)%vert_list(2))%pos,         & 
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-2)%vert_list(3))%pos,         &
               DBSPH%surf_mesh%faces(k-2)%area,                                &
               DBSPH%surf_mesh%faces(k-2)%normal)
            call area_triangle(                                                &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(1))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(2))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(3))%pos,         &
               DBSPH%surf_mesh%faces(k-1)%area,                                &
               DBSPH%surf_mesh%faces(k-1)%normal)            
            case(5)
! To import vertices of the pentagonal face, split in 3 triangular faces
! Face 1: vertices 1,2,5
            DBSPH%surf_mesh%faces(k)%vert_list(1:2) = old_size_vert +          &
                                                      aux_face_vert(1:2) + 1
            DBSPH%surf_mesh%faces(k)%vert_list(3) = old_size_vert +            &
                                                    aux_face_vert(5) + 1
            DBSPH%surf_mesh%faces(k)%vert_list(4) = 0
            DBSPH%surf_mesh%surface_mesh_file_ID(k) = surface_mesh_file_ID
! Face 2: vertices 2,3,5
            DBSPH%surf_mesh%faces(k+1)%vert_list(1:2) = old_size_vert +        &
                                                        aux_face_vert(2:3) + 1
            DBSPH%surf_mesh%faces(k+1)%vert_list(3)= old_size_vert +           &
                                                     aux_face_vert(5) + 1
            DBSPH%surf_mesh%faces(k+1)%vert_list(4) = 0
            DBSPH%surf_mesh%surface_mesh_file_ID(k+1) = surface_mesh_file_ID
! Face 3: vertices 3,4,5
            DBSPH%surf_mesh%faces(k+2)%vert_list(1:3) = old_size_vert +        &
                                                        aux_face_vert(3:5) + 1
            DBSPH%surf_mesh%faces(k+2)%vert_list(4) = 0
            DBSPH%surf_mesh%surface_mesh_file_ID(k+2) = surface_mesh_file_ID
            k = k+3
! Computation of area and normal of the 3 faces
            call area_triangle(                                                &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-3)%vert_list(1))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-3)%vert_list(2))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-3)%vert_list(3))%pos,         &
               DBSPH%surf_mesh%faces(k-3)%area,                                &
               DBSPH%surf_mesh%faces(k-3)%normal)   
            call area_triangle(                                                &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-2)%vert_list(1))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-2)%vert_list(2))%pos,         & 
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-2)%vert_list(3))%pos,         &
               DBSPH%surf_mesh%faces(k-2)%area,                                &
               DBSPH%surf_mesh%faces(k-2)%normal)
            call area_triangle(                                                &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(1))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(2))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(3))%pos,         &
               DBSPH%surf_mesh%faces(k-1)%area,                                &
               DBSPH%surf_mesh%faces(k-1)%normal)            
            case(6)
! To import vertices of the hexagonal face, split in 4 triangular faces
! Face 1: vertices 1,2,6
            DBSPH%surf_mesh%faces(k)%vert_list(1:2) = old_size_vert +          &
                                                      aux_face_vert(1:2) + 1
            DBSPH%surf_mesh%faces(k)%vert_list(3) = old_size_vert +            &
                                                    aux_face_vert(6) + 1
            DBSPH%surf_mesh%faces(k)%vert_list(4) = 0
            DBSPH%surf_mesh%surface_mesh_file_ID(k) = surface_mesh_file_ID
! Face 2: vertices 2,5,6
            DBSPH%surf_mesh%faces(k+1)%vert_list(1) = old_size_vert +          &
                                                      aux_face_vert(2) + 1
            DBSPH%surf_mesh%faces(k+1)%vert_list(2:3)= old_size_vert +         &
                                                       aux_face_vert(5:6) + 1
            DBSPH%surf_mesh%faces(k+1)%vert_list(4) = 0
            DBSPH%surf_mesh%surface_mesh_file_ID(k+1) = surface_mesh_file_ID
! Face 3: vertices 2,3,5
            DBSPH%surf_mesh%faces(k+2)%vert_list(1:2) = old_size_vert +        &
                                                        aux_face_vert(2:3) + 1
            DBSPH%surf_mesh%faces(k+2)%vert_list(3)= old_size_vert +           &
                                                     aux_face_vert(5) + 1
            DBSPH%surf_mesh%faces(k+2)%vert_list(4) = 0
            DBSPH%surf_mesh%surface_mesh_file_ID(k+2) = surface_mesh_file_ID
! Face 4: vertices 3,4,5 
            DBSPH%surf_mesh%faces(k+3)%vert_list(1:3) = old_size_vert +        &
                                                        aux_face_vert(3:5) + 1
            DBSPH%surf_mesh%faces(k+3)%vert_list(4) = 0
            DBSPH%surf_mesh%surface_mesh_file_ID(k+3) = surface_mesh_file_ID
            k = k+4
! Computation of area and normal of the 4 faces
            call area_triangle(                                                &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-4)%vert_list(1))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-4)%vert_list(2))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-4)%vert_list(3))%pos,         &
               DBSPH%surf_mesh%faces(k-4)%area,                                &
               DBSPH%surf_mesh%faces(k-4)%normal) 
            call area_triangle(                                                &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-3)%vert_list(1))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-3)%vert_list(2))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-3)%vert_list(3))%pos,         &
               DBSPH%surf_mesh%faces(k-3)%area,                                &
               DBSPH%surf_mesh%faces(k-3)%normal)   
            call area_triangle(                                                &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-2)%vert_list(1))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-2)%vert_list(2))%pos,         & 
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-2)%vert_list(3))%pos,         &
               DBSPH%surf_mesh%faces(k-2)%area,                                &
               DBSPH%surf_mesh%faces(k-2)%normal)
            call area_triangle(                                                &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(1))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(2))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(3))%pos,         &
               DBSPH%surf_mesh%faces(k-1)%area,                                &
               DBSPH%surf_mesh%faces(k-1)%normal)             
         endselect
         else
            DBSPH%surf_mesh%faces(k)%vert_list(1:4) = old_size_vert +          &
                                                      aux_face_vert(1:4) + 1
            k = k+1
! Computation of normal (area will be re-written)             
            call area_triangle(                                                &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(1))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(2))%pos,         &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(3))%pos,         &
               DBSPH%surf_mesh%faces(k-1)%area,                                &
               DBSPH%surf_mesh%faces(k-1)%normal)
! Computation of area in 2D (segment length)
            DBSPH%surf_mesh%faces(k-1)%area = dsqrt(dot_product(               &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(1))%pos          &
- DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(3))%pos,       &
DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(1))%pos          &
- DBSPH%surf_mesh%vertices(DBSPH%surf_mesh%faces(k-1)%vert_list(3))%pos)) /    &
                                              dsqrt(2.d0)
      endif
   enddo  
   close(unit_DBSPH_mesh,IOSTAT=file_stat)
   if (file_stat/=0) then
      write(*,*) 'Error in closing a surface mesh file in ',                   &
                 'Import_pl_surface_meshes; the program terminates here'
      stop
   endif
! Read the face vertices: end   
! Resize DBSPH%surf_mesh%faces on the actual number of faces 
! new_size_face = estimated_new_size_face - overestimation
   if (ncord==3) then
      new_size_face = size(DBSPH%surf_mesh%faces) - (k - old_size_face - 1 -   &
                      (DBSPH%ply_n_face_vert - 2) * n_faces) 
      else
         new_size_face = size(DBSPH%surf_mesh%faces) - (k - old_size_face - 1  &
                         - n_faces)     
   endif
   old_size_face = size(DBSPH%surf_mesh%faces)
   if (new_size_face>old_size_face) then
      aux_der_type_faces(:) = DBSPH%surf_mesh%faces(:)
      deallocate(DBSPH%surf_mesh%faces,STAT=dealloc_stat)
      if (dealloc_stat/=0) then
         write(*,*) 'Deallocation of DBSPH%surf_mesh%faces in ',               &
                    'Import_ply_surface_mesh failed; the program terminates ', &
                    'here.'
! Stop the main program
         stop 
      endif          
      allocate(DBSPH%surf_mesh%faces(new_size_face),STAT=alloc_stat)
      if (alloc_stat/=0) then
         write(*,*) 'Allocation of DBSPH%surf_mesh%faces in ',                 &
                    'Import_ply_surface_mesh failed; the program terminates ', &
                    'here.'
! Stop the main program
         stop 
      endif         
      DBSPH%surf_mesh%faces(:) = aux_der_type_faces(1:old_size_face)
      if (allocated(aux_der_type_faces)) then
         deallocate(aux_der_type_faces,STAT=dealloc_stat)
         if (dealloc_stat/=0) then
            write(nout,*) 'Deallocation of aux_der_type_faces in ',            &
                          'Import_ply_surface_mesh failed; the program ',      &
                          'terminates here.'
! Stop the main program
            stop 
         endif   
      endif         
      allocate(aux_der_type_faces(new_size_face),STAT=alloc_stat)
      if (alloc_stat/=0) then
         write(nout,*) 'Allocation of aux_der_type_faces in ',                 &
                       'Import_ply_surface_mesh failed; the program ',         &
                       'terminates here.'
! Stop the main program
         stop 
      endif
   endif
enddo   
close(unit_file_list,IOSTAT=file_stat)
if (file_stat/=0) then
   write(*,*) 'Error in closing surface_mesh_list.inp in ',                    &
              'Import_pl_surface_meshes; the program terminates here.'
   stop
endif
! Initializing the number of surface elements
DBSPH%n_w = new_size_face 
!------------------------
! Deallocations
!------------------------
if (allocated(aux_der_type_vert)) then
   deallocate(aux_der_type_vert,STAT=dealloc_stat)
   if (dealloc_stat/=0) then
      write(nout,*) 'Deallocation of aux_der_type_vert in ',                   &
                    'Import_ply_surface_mesh failed; the program terminates ', &
                    'here.'
! Stop the main program
      stop 
   endif   
endif 
if (allocated(aux_der_type_faces)) then
   deallocate(aux_der_type_faces,STAT=dealloc_stat)
   if (dealloc_stat/=0) then
      write(nout,*) 'Deallocation of aux_der_type_faces in ',                  &
                    'Import_ply_surface_mesh failed; the program terminates ', &
                    'here.'
! Stop the main program
      stop 
   endif   
endif
return
end subroutine Import_ply_surface_meshes

