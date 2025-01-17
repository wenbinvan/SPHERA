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
! Program unit: ReadRestartFile
! Description: To read the restart file.                       
!-------------------------------------------------------------------------------
subroutine ReadRestartFile(option,ier,nrecords)
!------------------------
! Modules
!------------------------
use I_O_file_module
use Static_allocation_module
use Hybrid_allocation_module
use Dynamic_allocation_module
!------------------------
! Declarations
!------------------------
implicit none
character(7),intent(in) :: option
integer(4),intent(inout) :: ier,nrecords
integer(4) :: restartcode,save_istart,ioerr,i,alloc_stat,size_aux,i_zone
#ifdef SPACE_3D
integer(4) :: n_vertices_main_wall
#endif
double precision :: save_start
character(12) :: ainp = "Restart File"
character(len=8) :: versionerest
logical,external :: ReadCheck
character(100),external :: lcase
!------------------------
! Explicit interfaces
!------------------------
!------------------------
! Allocations
!------------------------
!------------------------
! Initializations
!------------------------
ier = 0
!------------------------
! Statements
!------------------------
! Restart heading 
if (trim(lcase(option))==trim(lcase("heading"))) then
   rewind(nsav)
   write(ulog,'(a)')    "-------------------"
   write(ulog,"(1x,a)") ">> Restart heading."
   write(ulog,'(a)')    "-------------------"
   read(nsav,iostat=ioerr) versionerest,nrecords
   if (.not.ReadCheck(ioerr,ier,it_start,ainp,"versionerest,nrecords",nsav,    &
      ulog)) return
! Check the program version
   if (trim(lcase(version))/=trim(lcase(versionerest))) then
      write(uerr,'(a)')                                                        &
         "---------------------------------------------------------------"
      write(uerr,"(1x,a)")                                                     &
         ">> ERROR! The Restart version is not equal the current version."
      write(uerr,"(1x,a)") ">>        The run is stopped."
      write(uerr,'(a)')                                                        &
         "---------------------------------------------------------------"
      flush(uerr)
      stop
   endif
   read(nsav,iostat=ioerr) nag,NPartZone,NumVertici,                           &
#ifdef SPACE_3D  
      NumFacce,NumTratti,NumBVertices,GCBFVecDim,Grid%nmax,npointst,NPoints,   &
#elif defined SPACE_2D
      NumTratti,NumBVertices,NumBSides,Grid%nmax,npointst,NPoints,             &
#endif
      NPointsl,NPointse,NLines,doubleh
   if (.not.ReadCheck(ioerr,ier,it_start,ainp,"nag, ...",nsav,ulog)) return
#ifdef SPACE_3D
! This quantity has to be read from the restart file (in case of restart):
   write(ulog,"(1x,a,1p,i12)")   "GCBFVecDim (from restart file): ",GCBFVecDim
! Allocation of the array "GCBFVector"
   if ((Domain%tipo=="semi").and.(GCBFVecDim>0).and.                           &
      (.not.allocated(GCBFVector))) then
      allocate(GCBFVector(GCBFVecDim),stat=ier)    
      if (ier/=0) then
         write(ulog,'(1x,2a)') "Allocation of GCBFVector in ",                 &
            "ReadRestartFile failed. "
         else
            write(ulog,'(1x,2a)') "Allocation of GCBFVector in ",              &
            "ReadRestartFile successully completed. "
      endif
   endif
#endif
   elseif (trim(lcase(option))=="reading") then
      write(ulog,'(a)')                                                        &
         "---------------------------------------------------------------------"
      write(ulog,"(1x,a)")                                                     &
         ">> Restart reading:  step         time      interval    num.particles"
      save_istart = Domain%istart
      save_start = Domain%start
! Since here, Domain%istart and Domain%start are zeroed, until next reading of 
! the main input file.
      read(nsav,iostat=ioerr) Domain
      if (.not.ReadCheck(ioerr,ier,it_start,ainp,"domain",nsav,ulog)) return
      read(nsav,iostat=ioerr) Grid
      if (.not.ReadCheck(ioerr,ier,it_start,ainp,"Grid",nsav,ulog)) return
! Allocating the 2D matrix to detect free surface
      if (.not.allocated(ind_interfaces)) then
         allocate(ind_interfaces(Grid%ncd(1),Grid%ncd(2),6),STAT=alloc_stat)
         if (alloc_stat/=0) then
            write(ulog,*)                                                      &
            'Allocation of ind_interfaces in ReadRestartFile failed;',         &
            ' the program terminates here.'
            stop
            else
               write(ulog,*)                                                   &
                  'Allocation of ind_interfaces in ReadRestartFile ',          &
                  'successfully completed.'
         endif
      endif
#ifdef SPACE_3D      
! Allocation of the array "GCBFPointers"
      if (Domain%tipo=="semi") then
         allocate(GCBFPointers(Grid%nmax,2),STAT=alloc_stat)
         if (alloc_stat/=0) then
            write(ulog,*) "Allocation of GCBFPointers in ReadRestartFile ",    &
               "failed; the program stops here."
            stop
            else
               write(ulog,*) "Allocation of GCBFPointers in ReadRestartFile ", &
                  "is successfully completed."
         endif
      endif
#endif
      if (NumVertici>0) then
         read(nsav,iostat=ioerr) Vertice(1:SPACEDIM,1:NumVertici)
         if (.not.ReadCheck(ioerr,ier,it_start,ainp,"Vertice",nsav,ulog)) return
      endif
#ifdef SPACE_3D
      if (NumFacce>0) then 
         read(nsav,iostat=ioerr) BoundaryFace(1:NumFacce)
         if (.not.ReadCheck(ioerr,ier,it_start,ainp,"BoundaryFace",nsav,ulog)) &
            return
         read(nsav,iostat=ioerr) BFaceList(1:NumFacce)
         if (.not.ReadCheck(ioerr,ier,it_start,ainp,"BFaceList",nsav,ulog))    &
            return
      endif
#endif
      if (NumTratti>0) then
         read(nsav,iostat=ioerr) Tratto(1:NumTratti)
         if (.not.ReadCheck(ioerr,ier,it_start,ainp,"Tratto",nsav,ulog)) return
      endif
      do i_zone=1,NPartZone
         read(nsav,iostat=ioerr) size_aux
         if (.not.ReadCheck(ioerr,ier,it_start,ainp,"Partz_1of5",nsav,ulog))   &
            return
         read(nsav,iostat=ioerr) Partz(i_zone)%DBSPH_fictitious_reservoir_flag,&
            Partz(i_zone)%ipool,Partz(i_zone)%icol,                            &
            Partz(i_zone)%Medium,Partz(i_zone)%npointv,                        &
            Partz(i_zone)%IC_source_type,Partz(i_zone)%Car_top_zone,           &
            Partz(i_zone)%slip_coefficient_mode,                               &
#ifdef SPACE_3D
Partz(i_zone)%plan_reservoir_points,Partz(i_zone)%ID_first_vertex_sel,         &
            Partz(i_zone)%ID_last_vertex_sel,Partz(i_zone)%dam_zone_ID,        &
            Partz(i_zone)%dam_zone_n_vertices,Partz(i_zone)%dx_CartTopog,      &
            Partz(i_zone)%H_res,                                               &
#endif
            Partz(i_zone)%BC_shear_stress_input,                               &
            Partz(i_zone)%avg_comp_slip_coeff,Partz(i_zone)%avg_ni_T_SASPH,    &
            Partz(i_zone)%avg_tau_wall_f,Partz(i_zone)%pool,Partz(i_zone)%valp,&
            Partz(i_zone)%limit(1:2),Partz(i_zone)%vel(1:3),                   &
            Partz(i_zone)%coordMM(1:3,1:2),                                    &
            Partz(i_zone)%plan_reservoir_pos(1:4,1:2)
         if (.not.ReadCheck(ioerr,ier,it_start,ainp,"Partz_2of5",nsav,ulog))   &
            return
#ifdef SPACE_3D
         read(nsav,iostat=ioerr) Partz(i_zone)%dam_zone_vertices(1:4,1:2)
         if (.not.ReadCheck(ioerr,ier,it_start,ainp,"Partz_3of5",nsav,ulog))   &
            return
         if (size_aux>0) then
            if (.not.allocated(Partz(i_zone)%BC_zmax_vertices)) then
               allocate(Partz(i_zone)%BC_zmax_vertices(size_aux,3),            &
                  STAT=alloc_stat)
               if (alloc_stat/=0) then
                  write(ulog,'(2a,i4,3a)') 'The allocation of the array ',     &
                     '"BC_zmax_vertices" for the zone ',i_zone,' in the ',     &
                     'program unit "ReadRestartFile" failed; the program ',    &
                     'stops here.'
                  stop
                  else
                     write(ulog,'(2a,i4,3a)') 'The allocation of the array ',  &
                        '"BC_zmax_vertices" for the zone ',i_zone,' in the ',  &
                        'program unit "ReadRestartFile" has successfully ',    &
                        'completed.'
               endif
            endif
            if (allocated(Partz(i_zone)%BC_zmax_vertices)) then
               read(nsav,iostat=ioerr)                                         &
                  Partz(i_zone)%BC_zmax_vertices(1:size_aux,1:3)
               if (.not.ReadCheck(ioerr,ier,it_start,ainp,"Partz_4of5",nsav,   &
                  ulog)) return
            endif
         endif
#endif
         read(nsav,iostat=ioerr) Partz(i_zone)%vlaw(0:3,MAXPOINTSVLAW),        &
            Partz(i_zone)%shape,Partz(i_zone)%bend,Partz(i_zone)%pressure,     &
            Partz(i_zone)%move,Partz(i_zone)%tipo,Partz(i_zone)%label
         if (.not.ReadCheck(ioerr,ier,it_start,ainp,"Partz_5of5",nsav,ulog))   &
            return
      enddo
      if (NumBVertices>0) then
        read(nsav,iostat=ioerr) BoundaryVertex(1:NumBVertices)
        if (.not.ReadCheck(ioerr,ier,it_start,ainp,"BoundaryVertex",nsav,ulog))&
           return
      endif
#ifdef SPACE_2D
      if (NumBSides>0) then
         read(nsav,iostat=ioerr) BoundarySide(1:NumBSides)     
         if (.not.ReadCheck(ioerr,ier,it_start,ainp,"BoundarySide",nsav,ulog)) &
            return
      endif
#endif
#ifdef SPACE_3D
      if (Domain%tipo=="semi") then
         if (GCBFVecDim>0) then
            read(nsav,iostat=ioerr) GCBFVector(1:GCBFVecDim)
            if (.not.ReadCheck(ioerr,ier,it_start,ainp,"GCBFVector",nsav,ulog))&
               return
         endif
         if (Grid%nmax>0) then
            read(nsav,iostat=ioerr) GCBFPointers(1:Grid%nmax,1:2)
            if (.not.ReadCheck(ioerr,ier,it_start,ainp,"GCBFPointers",nsav,    &
               ulog)) return
         endif
      endif
! Allocation of the array of the maximum water depth
      call main_wall_info(n_vertices_main_wall)
      write(ulog,'(a,i9)') 'The vertices of the main wall are ',               &
         n_vertices_main_wall     
      if (n_vertices_main_wall>0) then
         if (.not.allocated(Z_fluid_max)) then
            allocate(Z_fluid_max(Grid%ncd(1)*Grid%ncd(2),2),STAT=alloc_stat)
            if (alloc_stat/=0) then
               write(ulog,*)                                                   &
               'Allocation of Z_fluid_max in ReadRestartFile failed;',         &
               ' the program terminates here.'
               stop
               else
                  write(ulog,*)                                                &
                     'Allocation of Z_fluid_max in ReadRestartFile ',          &
                     'successfully completed.'
            endif
         endif
! Allocation of the array of the maximum specific flow rate
         if (.not.allocated(q_max)) then
            allocate(q_max(n_vertices_main_wall),STAT=alloc_stat)
            if (alloc_stat/=0) then
               write(ulog,*)                                                   &
               'Allocation of q_max in ReadRestartFile failed;',               &
               ' the program terminates here.'
               stop
               else
                  write(ulog,*)                                                &
                     'Allocation of q_max in ReadRestartFile successfully ',   &
                     'completed.'
            endif
         endif
      endif
#endif
! Allocation of the 2D array of the minimum saturation flag (bed-load transport)
      if ((Granular_flows_options%KTGF_config>0).and.                          &
         (.not.allocated(Granular_flows_options%minimum_saturation_flag))) then
         allocate(Granular_flows_options%minimum_saturation_flag(Grid%ncd(1),  &
            Grid%ncd(2)),STAT=alloc_stat)
         if (alloc_stat/=0) then
            write(ulog,*)                                                      &
            'Allocation of Granular_flows_options%minimum_saturation_flag ',   &
            ' in ReadRestartFile failed; the program stops here.'
            stop 
            else
               write(ulog,*)                                                   &
                  'Allocation of ',                                            &
                  'Granular_flows_options%minimum_saturation_flag in ',        &
                  'ReadRestartFile is successfully completed.'
         endif
      endif
! Allocation of the 2D array of the maximum saturation flag (bed-load transport)
      if ((Granular_flows_options%KTGF_config>0).and.                          &
         (.not.allocated(Granular_flows_options%maximum_saturation_flag))) then
         allocate(Granular_flows_options%maximum_saturation_flag(Grid%ncd(1),  &
            Grid%ncd(2)),STAT=alloc_stat)
         if (alloc_stat/=0) then
            write(ulog,*) "Allocation of ",                                    &
               "Granular_flows_options%maximum_saturation_flag in ",           &
               "ReadRestartFile failed; the program stops here."
            stop 
            else
               write(ulog,*) "Allocation of ",                                 &
                  "Granular_flows_options%maximum_saturation_flag in ",        &
                  "ReadRestartFile is successfully completed."
         endif
      endif
! Restart positions are based on the step number
      it_start = 0 
      if (save_istart>0) then
! It reads all the saved steps and overwrite the restart values until the
! restart time is reached.     
         do while (save_istart>it_start)
            read(nsav,iostat=ioerr) it_start,simulation_time,dt,nag,restartcode
            if (.not.ReadCheck(ioerr,ier,it_start,ainp,                        &
               "it_start,simulation_time,dt,nag,restartcode",nsav,ulog)) return
            write(ulog,"(16x,i10,2(2x,g12.5),7x,i10)") it_start,               &
               simulation_time,dt,nag
            flush(ulog)
            if (it_start<save_istart) then
               read(nsav,iostat=ioerr) 
               if (.not.ReadCheck(ioerr,ier,it_start,ainp,"...",nsav,ulog))    &
                  return  
               if (restartcode==1) then                 
                  if (allocated(pg_w)) then
                     read(nsav,iostat=ioerr) 
                     if (.not.ReadCheck(ioerr,ier,it_start,ainp,"pg_w",        &
                        nsav,ulog)) return
                  endif
                  if (n_bodies>0) then
                     do i=1,n_bodies
                        read(nsav,iostat=ioerr)
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,            &
                           "body_arr_1_of_2",nsav,ulog)) return
                        if (body_arr(i)%n_records>0) then
                           read(nsav,iostat=ioerr)
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,         &
                              "body_arr_2_of_2",nsav,ulog)) return
                        endif                  
                     enddo
                     read(nsav,iostat=ioerr) 
                     if (.not.ReadCheck(ioerr,ier,it_start,ainp,"bp_arr",      &
                              nsav,ulog)) return
                     read(nsav,iostat=ioerr) 
                     if (.not.ReadCheck(ioerr,ier,it_start,ainp,               &
                              "surf_body_part",nsav,ulog)) return
                  endif
#ifdef SPACE_3D
                     if (allocated(Z_fluid_max)) then
                        read(nsav,iostat=ioerr)
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,            &
                           "Z_fluid_max",nsav,ulog)) return
                     endif
                     if (allocated(q_max)) then
                        read(nsav,iostat=ioerr)
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,"q_max",    &
                           nsav,ulog)) return
                     endif
                  if (allocated(substations%sub)) then
                     read(nsav,iostat=ioerr)
                     if (.not.ReadCheck(ioerr,ier,it_start,ainp,               &
                        "POS_fsumq_max",nsav,ulog)) return
                     read(nsav,iostat=ioerr)
                     if (.not.ReadCheck(ioerr,ier,it_start,ainp,               &
                        "Ymax",nsav,ulog)) return
                     read(nsav,iostat=ioerr)
                     if (.not.ReadCheck(ioerr,ier,it_start,ainp,               &
                        "EOT",nsav,ulog)) return
                  endif
#endif
                  if (allocated(Granular_flows_options%minimum_saturation_flag)&
                     ) then
                     read(nsav,iostat=ioerr) 
                     if (.not.ReadCheck(ioerr,ier,it_start,ainp,               &
                        "minimum_saturation_flag",nsav,ulog)) return
                  endif
                  if (allocated(Granular_flows_options%maximum_saturation_flag)&
                     ) then
                     read(nsav,iostat=ioerr) 
                     if (.not.ReadCheck(ioerr,ier,it_start,ainp,               &
                        "maximum_saturation_flag",nsav,ulog)) return
                  endif  
               endif
               else
! Actual array reading for restart
                  if (restartcode==1) then
                     read(nsav,iostat=ioerr) pg(1:nag)
                     if (.not.ReadCheck(ioerr,ier,it_start,ainp,"pg",nsav,     &
                        ulog)) return
                     if (allocated(pg_w)) then
                        read(nsav,iostat=ioerr) pg_w(1:DBSPH%n_w+DBSPH%n_inlet+&
                           DBSPH%n_outlet)
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,"pg_w",nsav,&
                           ulog)) return
                     endif
                     if (n_bodies>0) then
                        do i=1,n_bodies
                           read(nsav,iostat=ioerr) body_arr(i)%npart,          &
                              body_arr(i)%Ic_imposed,                          &
                              body_arr(i)%imposed_kinematics,                  &
                              body_arr(i)%n_records,body_arr%mass,             &
                              body_arr(i)%umax,body_arr(i)%pmax,               &
                              body_arr(i)%x_CM(1:3),body_arr(i)%alfa(1:3),     &
                              body_arr(i)%u_CM(1:3),body_arr(i)%omega(1:3),    &
                              body_arr(i)%Force(1:3),body_arr(i)%Moment(1:3),  &
                              body_arr(i)%Ic(1:3,1:3),                         &
                              body_arr(i)%Ic_inv(1:3,1:3)
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,         &
                              "body_arr_1_of_2",nsav,ulog)) return                              
                           if (body_arr(i)%n_records>0) then
                              if (.not.allocated(body_arr(i)%body_kinematics)) &
allocate(body_arr(i)%body_kinematics(body_arr(i)%n_records,7))
                              read(nsav,iostat=ioerr)                          &
body_arr(i)%body_kinematics(1:body_arr(i)%n_records,1:7)
                              if (.not.ReadCheck(ioerr,ier,it_start,ainp,      &
                                 "body_arr_2_of_2",nsav,ulog)) return
                           endif
                        enddo
                        read(nsav,iostat=ioerr) bp_arr(1:n_body_part)
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,"bp_arr",   &
                           nsav,ulog)) return
                        read(nsav,iostat=ioerr) surf_body_part(1:              &
                           n_surf_body_part)
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,            &
                          "surf_body_part",nsav,ulog)) return
                     endif
#ifdef SPACE_3D
                        if (allocated(Z_fluid_max)) then
                           read(nsav,iostat=ioerr)                             &
                              Z_fluid_max(1:Grid%ncd(1)*Grid%ncd(2),1:2)
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,         &
                              "Z_fluid_max",nsav,ulog)) return
                        endif
                        if (allocated(q_max)) then
                           read(nsav,iostat=ioerr) q_max(1:size(q_max))
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,"q_max", &
                              nsav,ulog)) return
                        endif
                     if (allocated(substations%sub)) then
                        read(nsav,iostat=ioerr)                                &
                           substations%sub(1:substations%n_sub)%POS_fsum(1),   &
                           substations%sub(1:substations%n_sub)%POS_fsum(2)
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,            &
                           "POS_fsum_max",nsav,ulog)) return
                        read(nsav,iostat=ioerr)                                &
                           substations%sub(1:substations%n_sub)%Ymax(1),       &
                           substations%sub(1:substations%n_sub)%Ymax(2)
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,            &
                           "Ymax",nsav,ulog)) return
                        read(nsav,iostat=ioerr)                                &
                           substations%sub(1:substations%n_sub)%EOT(1),        &
                           substations%sub(1:substations%n_sub)%EOT(2)
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,            &
                           "EOT",nsav,ulog)) return
                     endif
#endif
                     if (allocated                                             &
                        (Granular_flows_options%minimum_saturation_flag)) then
                        read(nsav,iostat=ioerr)                                &
                           Granular_flows_options%minimum_saturation_flag(     &
                           1:Grid%ncd(1),1:Grid%ncd(2))
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,            &
                           "minimum_saturation_flag",nsav,ulog)) return
                     endif 
                     if (allocated                                             &
                        (Granular_flows_options%maximum_saturation_flag)) then
                        read(nsav,iostat=ioerr)                                &
                           Granular_flows_options%maximum_saturation_flag(     &
                           1:Grid%ncd(1),1:Grid%ncd(2))
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,            &
                           "maximum_saturation_flag",nsav,ulog)) return
                     endif                                           
                     write(ulog,'(a)') " "
                     write(ulog,'(a,i10,a,g12.5)') "   Located Restart Step :",&
                        it_start,"   Time :",simulation_time
                     flush(ulog)
! Reading for post-processing
                     elseif (restartcode==0) then
                        read(nsav,iostat=ioerr) pg(1:nag)%coord(1),            &
                           pg(1:nag)%coord(2),pg(1:nag)%coord(3),              &
                           pg(1:nag)%vel(1),pg(1:nag)%vel(2),pg(1:nag)%vel(3), &
                           pg(1:nag)%pres,pg(1:nag)%dens,pg(1:nag)%mass,       &
                           pg(1:nag)%kin_visc,pg(1:nag)%imed,pg(1:nag)%icol
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,"pg",nsav,  &
                           ulog)) return
                        write(uerr,'(a)') " "
                        write(uerr,'(a,i10,a,g12.5)')                          &
                           "   Located Result Step :",it_start,"   Time :",    &
                           simulation_time
                        flush(uerr)
                        write(uerr,'(a)')                                      &
"       But this step is not a restart step. Check the correct step for restart in the restart file."
                        flush(uerr)
                        write(uerr,'(a)') " The program is terminated."
                        flush(uerr)
                        stop
                  endif
                  return
            endif
         enddo
         write(uerr,'(a,i10,a)') "   Restart Step Number:",it_start,           &
            " has not been found"
         ier = 3
! Restart positions are based on time (s)
         elseif (save_start>zero) then
            simulation_time = zero
            do while (save_start>simulation_time)
               read(nsav,iostat=ioerr) it_start,simulation_time,dt,nag,        &
                  restartcode
               if (.not.ReadCheck(ioerr,ier,it_start,ainp,                     &
                  "it_start,simulation_time,dt,nag,restartcode",nsav,ulog))    &
                     return
               write(ulog,"(16x,i10,2(2x,g12.5),7x,i10)") it_start,            &
                  simulation_time,dt,nag
               flush(ulog)
               if (simulation_time<save_start) then
                  read(nsav,iostat=ioerr)
                  if (.not.ReadCheck(ioerr,ier,it_start,ainp,"...",nsav,ulog)) &
                     return
                  if (restartcode==1) then
                     if (allocated(pg_w)) then
                        read(nsav,iostat=ioerr) 
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,"pg_w",     &
                           nsav,ulog)) return
                     endif
                     if (n_bodies>0) then
                        do i=1,n_bodies
                           read(nsav,iostat=ioerr)
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,         &
                              "body_arr_1_of_2",nsav,ulog)) return
                           if (body_arr(i)%n_records>0) then   
                              read(nsav,iostat=ioerr)
                              if (.not.ReadCheck(ioerr,ier,it_start,ainp,      &
                                 "body_arr_2_of_2",nsav,ulog)) return
                           endif
                        enddo
                        read(nsav,iostat=ioerr) 
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,"bp_arr",   &
                                 nsav,ulog)) return
                        read(nsav,iostat=ioerr)
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,            &
                                 "surf_body_part",nsav,ulog)) return
                     endif
#ifdef SPACE_3D
                        if (allocated(Z_fluid_max)) then
                           read(nsav,iostat=ioerr)
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,         &
                              "Z_fluid_max",nsav,ulog)) return
                        endif
                        if (allocated(q_max)) then
                           read(nsav,iostat=ioerr) 
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,"q_max", &
                              nsav,ulog)) return
                        endif
                     if (allocated(substations%sub)) then
                        read(nsav,iostat=ioerr)
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,            &
                           "POS_fsum_max",nsav,ulog)) return
                        read(nsav,iostat=ioerr)
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,            &
                           "Ymax",nsav,ulog)) return
                        read(nsav,iostat=ioerr)
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,            &
                           "EOT",nsav,ulog)) return
                     endif
#endif
                     if (allocated                                             &
                        (Granular_flows_options%minimum_saturation_flag)) then
                        read(nsav,iostat=ioerr) 
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,            &
                        "minimum_saturation_flag",nsav,ulog)) return
                     endif
                     if (allocated                                             &
                        (Granular_flows_options%maximum_saturation_flag)) then
                        read(nsav,iostat=ioerr) 
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,            &
                        "maximum_saturation_flag",nsav,ulog)) return
                     endif
                  endif 
                  else
! Actual array reading for restart
                     if (restartcode==1) then
                        read(nsav,iostat=ioerr) pg(1:nag)
                        if (.not.ReadCheck(ioerr,ier,it_start,ainp,"pg",nsav,  &
                           ulog)) return
                        if (allocated(pg_w)) then
                           read(nsav,iostat=ioerr) pg_w(1:                     &
                              DBSPH%n_w+DBSPH%n_inlet+DBSPH%n_outlet)
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,"pg_w",  &
                              nsav,ulog)) return
                        endif
                        if (n_bodies>0) then
                           do i=1,n_bodies
                              read(nsav,iostat=ioerr) body_arr(i)%npart,       &
                                 body_arr(i)%Ic_imposed,                       &
                                 body_arr(i)%imposed_kinematics,               &
                                 body_arr(i)%n_records,body_arr%mass,          &
                                 body_arr(i)%umax,body_arr(i)%pmax,            &
                                 body_arr(i)%x_CM(1:3),body_arr(i)%alfa(1:3),  &
                                 body_arr(i)%u_CM(1:3),body_arr(i)%omega(1:3), &
                                 body_arr(i)%Force(1:3),                       &
                                 body_arr(i)%Moment(1:3),                      &
                                 body_arr(i)%Ic(1:3,1:3),                      &
                                 body_arr(i)%Ic_inv(1:3,1:3)
                              if (.not.ReadCheck(ioerr,ier,it_start,ainp,      &
                                 "body_arr_1_of_2",nsav,ulog)) return
                              if (body_arr(i)%n_records>0) then
                               if (.not.allocated(body_arr(i)%body_kinematics))&
allocate(body_arr(i)%body_kinematics(body_arr(i)%n_records,7))
                                 read(nsav,iostat=ioerr)                       &
body_arr(i)%body_kinematics(1:body_arr(i)%n_records,1:7)
                                 if (.not.ReadCheck(ioerr,ier,it_start,ainp,   &
                                 "body_arr_2_of_2",nsav,ulog)) return
                              endif
                           enddo
                           read(nsav,iostat=ioerr) bp_arr(1:n_body_part)
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,"bp_arr",&
                              nsav,ulog)) return
                           read(nsav,iostat=ioerr) surf_body_part(1:           &
                              n_surf_body_part)
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,         &
                              "surf_body_part",nsav,ulog)) return
                        endif
#ifdef SPACE_3D
                           if (allocated(Z_fluid_max)) then
                              read(nsav,iostat=ioerr)                          &
                                 Z_fluid_max(1:Grid%ncd(1)*Grid%ncd(2),1:2)
                              if (.not.ReadCheck(ioerr,ier,it_start,ainp,      &
                                 "Z_fluid_max",nsav,ulog)) return
                           endif
                           if (allocated(q_max)) then
                              read(nsav,iostat=ioerr) q_max(1:size(q_max))
                              if (.not.ReadCheck(ioerr,ier,it_start,ainp,      &
                                 "q_max",nsav,ulog)) return
                           endif
                        if (allocated(substations%sub)) then
                           read(nsav,iostat=ioerr)                             &
                              substations%sub(1:substations%n_sub)%POS_fsum(1),&
                              substations%sub(1:substations%n_sub)%POS_fsum(2) 
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,         &
                              "POS_fsum_max",nsav,ulog)) return              
                           read(nsav,iostat=ioerr)                             &
                              substations%sub(1:substations%n_sub)%Ymax(1),    &
                              substations%sub(1:substations%n_sub)%Ymax(2)
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,         &
                              "Ymax",nsav,ulog)) return       
                           read(nsav,iostat=ioerr)                             &
                              substations%sub(1:substations%n_sub)%EOT(1),     &
                              substations%sub(1:substations%n_sub)%EOT(2)     
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,         &
                              "EOT",nsav,ulog)) return
                        endif
#endif
if (allocated(Granular_flows_options%minimum_saturation_flag)) then
                           read(nsav,iostat=ioerr)                             &
                              Granular_flows_options%minimum_saturation_flag(  &
                              1:Grid%ncd(1),1:Grid%ncd(2))
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,         &
                              "minimum_saturation_flag",nsav,ulog)) return
                        endif
                        if (allocated                                          &
                           (Granular_flows_options%maximum_saturation_flag)) &
                           then
                           read(nsav,iostat=ioerr)                             &
                              Granular_flows_options%maximum_saturation_flag(  &
                              1:Grid%ncd(1),1:Grid%ncd(2))
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,         &
                              "maximum_saturation_flag",nsav,ulog)) return
                        endif
                        write(ulog,'(a)') 
                        write(ulog,'(a,i10,a,g12.5)')                          &
                           "   Located Restart Step :",it_start,"   Time :",   &
                           simulation_time
                        flush(ulog)
! Reading for post-processing
                        elseif (restartcode==0) then
                           read(nsav,iostat=ioerr) pg(1:nag)%coord(1),         &
                              pg(1:nag)%coord(2),pg(1:nag)%coord(3),           &
                              pg(1:nag)%vel(1),pg(1:nag)%vel(2),               &
                              pg(1:nag)%vel(3),pg(1:nag)%pres,pg(1:nag)%dens,  &
                              pg(1:nag)%mass,pg(1:nag)%kin_visc,               &
                              pg(1:nag)%imed,pg(1:nag)%icol
                           if (.not.ReadCheck(ioerr,ier,it_start,ainp,"pg",    &
                              nsav,ulog)) return
                           write(ulog,'(a)') 
                           write(ulog,'(a,i10,a,g12.5)')                       &
                              "   Located Result Time :",it_start,"   Time :", &
                              simulation_time
                           flush(ulog)
                           write(uerr,'(a)')                                   &
"       But this time is not a restart time. Check the correct time for restart in the restart file."
                           flush(uerr)
                           write(uerr,'(a)') " The program is terminated."
                           flush(uerr)
                           stop
                  endif 
                  return
               endif
            enddo
            write(uerr,'(a,i10,a)') "   Restart Time Step:",save_start,        &
               " has not been found"
            ier = 3
            else
               write(uerr,'(a)') "  > Restart cannot be read at step:",        &
                  it_start,"  time:",simulation_time
               ier = 4
      endif
      write(ulog,'(a)') "  > Restart read successfully at step:",it_start,     &
         "  time:",simulation_time
      else
         ier = 5
endif
!------------------------
! Deallocations
!------------------------
return
end subroutine ReadRestartFile
