#
#  Makefile for "CitcomCU" allowing considerable variations
#

#
#  NOTES:
#  1) Macro substitution is different for different version of make, for SGI,
#     CRAY, HP, etc. It seems necessary to go through and replace the
#     CEXT ... FOBJFLAG macros manually.
#
#  2) Put FLAGS=$(YOUR_MACHINE_FLAGS) chosen from the list that follows, add
#     machines, where necessary, try and find a better way than just defining
#     "const" to be null. 
#
##############################################################################
#	Individual Machine Variations
##############################################################################

#COMPRESS=/usr/bin/compress
COMPRESS=/bin/gzip
LIB_PATH= -L/usr/local/cuda-12.0/lib64 -lcudart -lcurand -lcublas -lstdc++
#LIB_LIST= -lmpi
LIB_LIST=
LIB= $(LIB_PATH) $(LIB_LIST) -lm


###################################################################
#	Operating System Variables
###################################################################

#CC=/usr/local/mpich/bin/mpicc
#CC=/opt/mpich/bin/mpicc
#CC=/usr/lib/cmplrs/cc/gemc_cc
#CC=$(HOME)/usr/local/mpich/bin/mpicc
CC=mpicc
NVCC=nvcc
F77=f77
CPP=

CEXT=c
FEXT=F   # which implies further action of cpp
OBJEXT=o
FOBJEXT=o
OBJFLAG=-c
FOBJFLAG=-c


###################################
# Choose your machine from here.
###################################

####################################
# Dec Alpha, OSF 1
AXPFLAGS= -unsigned  -non_shared  \
	-math_library=fast -prefix=all -reentrancy=none -assume=noaccuracy_sensitive \
	-unsigned_char -extern=strict_refdef -trapuv #  -D_INTRINSICS 
AXPLDFLAGS= -unsigned -assume=noaccuracy_sensitive -non_shared -D_INTRINSICS 
AXPOPTIM= -O -Ublas -float -Olimit 1000 # -cord  -feedback citcom.feedback
####################################

####################################
# CRAY Unicos systems
CRAYFLAGS=
CRAYLDFLAGS=
CRAYOPTIM=
####################################

####################################
#IBM AIX systems
AIXFLAGS= -D__aix__
AIXLDFLAGS=
AIXOPTIM= -O2 -qarch=pwr -qopt=pwr -Ublas
####################################

####################################
# SUNOS systems
SUNFLAGS= -D__sunos__ -Dconst=""
SUNLDFLAGS=
SUNOPTIM=-O -fsingle
####################################

####################################
# Solaris systems
SOLARISFLAGS= -D__solaris -Dconst="" -I/opt/mpi/include
SOLARISLDFLAGS=-fast -lsocket -lnsl -lthread
SOLARISOPTIM=-fast -xO4 -dalign -xtarget=ultra -xarch=v8plus -fsingle
####################################

####################################
#HP running HPUX
HPUXFLAGS=-Dconst=""
HPUXLDFLAGS=
HPUXOPTIM=+O3 +Onolimit +Odataprefetch
#HPUXOPTIM=+O4 +Onolimit +Odataprefetch +Ofastaccess
#HPUXOPTIM3=+O3 +Onolimit +Odataprefetch
####################################

####################################
# SGI with IRIX 
SGIFLAGS=
SGILDFLAGS=
SGIOPTIM=-O -fsingle
####################################

#LinuxFLAGS=-I/usr/local/mpi/include
#LinuxFLAGS=-I/opt/mpi/include
#LinuxFLAGS=-I$(HOME)/usr/include
LinuxFLAGS=
LinuxLDFLAGS=
#LinuxOPTIM=-g
#LinuxOPTIM=-O2
LinuxOPTIM=-O2 -Wall -Wextra -pedantic -std=c99 -Wunused-function -D_GNU_SOURCE

####################################
#PARAGON 
PARAGONFLAGS=-nx
PARAGONLDFLAGS=
PARAGONOPTIM=-O4
####################################

####################################################################
#	Choose the actual flags for your machine here ...
####################################################################

FLAGS= $(LinuxFLAGS) -DCOMPRESS_BINARY=\"$(COMPRESS)\"
LDFLAGS= $(LinuxLDFLAGS)
OPTIM= $(LinuxOPTIM)

#FLAGS= $(SOLARISFLAGS) -DCOMPRESS_BINARY=\"$(COMPRESS)\"
#LDFLAGS= $(SOLARISLDFLAGS)
#OPTIM= $(SOLARISOPTIM)

####################################################################
#	CitcomCU's files .....
####################################################################

CFILES= Advection_diffusion.c\
	Boundary_conditions.c\
	Citcom.c\
	Composition_adv.c\
	Construct_arrays.c\
	Convection.c\
	Drive_solvers.c\
	Element_calculations.c\
	Geometry_cartesian.c\
	General_matrix_functions.c\
	Global_operations.c\
	Stokes_flow_Incomp.c\
	Instructions.c\
	Nodal_mesh.c\
	Output.c\
	Pan_problem_misc_functions.c\
	Parallel_related.c\
	Parsing.c\
	Phase_change.c\
	Process_velocity.c\
	Profiling.c\
	Shape_functions.c\
	Size_does_matter.c\
	Solver_multigrid.c\
	Solver_conj_grad.c\
	Sphere_harmonics.c\
	Topo_gravity.c\
	Viscosity_structures.c

CUFILES= Process_buoyancy.cu


HEADER = element_definitions.h \
	 global_defs.h \
	 viscosity_descriptions.h \
	 advection.h prototypes.h


FFILES=#Blas_lapack_interfaces.F

OBJFILES=$(CFILES:.c=.o) $(FFILES:.f=.o) $(CUFILES:.cu=.o)


####################################################################
# Makefile rules follow
####################################################################

default: citcom.mpi

citcom.mpi: $(OBJFILES) $(HEADER) Makefile
#	$(CC) $(OPTIM) $(FLAGS) $(LDFLAGS) -o citcom.mpi $(OBJFILES)  $(FFTLIB)  $(LIB)
	$(CC) $(OPTIM) $(FLAGS) $(LDFLAGS) -c  $(CFILES)
	$(NVCC) -D_Bool=bool -c $(CUFILES)
	$(CC) $(OBJFILES) $(OPTIM) $(FLAGS) $(LDFLAGS) $(LIB) -w -o citcom.mpi $(FFTLIB)  

pg: $(OBJFILES) $(HEADER) Makefile
#	$(CC) $(OPTIM) $(FLAGS) $(LDFLAGS) -o citcom.mpi $(OBJFILES)  $(FFTLIB)  $(LIB)
	$(CC) $(OPTIM) $(FLAGS) $(LDFLAGS) -pg -c  $(CFILES)
	$(NVCC) -D_Bool=bool -pg -c $(CUFILES)
	$(CC) $(OBJFILES) $(OPTIM) $(FLAGS) $(LDFLAGS) $(LIB) -pg -w -o citcom.mpi $(FFTLIB) 

clean:
	rm -f *.o

clean-all:
	rm -f *.o citcom.mpi

smaller: 
	compress $(CFILES)

larger:
	uncompress $(CFILES)


####################################################################
# File dependencies follow
####################################################################

global_defs.h: viscosity_descriptions.h advection.h Convection_variables.h
		
# The following entries can probably be automated from $CFILES etc

Advection_diffusion.o: $(HEADER) Advection_diffusion.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Advection_diffusion.c
#
Boundary_conditions.o: $(HEADER) Boundary_conditions.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Boundary_conditions.c
#	
Citcom.o: $(HEADER) Citcom.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Citcom.c
#	
Composition_adv.o: $(HEADER) Composition_adv.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Composition_adv.c
#	
Construct_arrays.o: $(HEADER) Construct_arrays.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Construct_arrays.c
#	
Convection.o: $(HEADER) Convection.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Convection.c
#	
Drive_solvers.o: $(HEADER) Drive_solvers.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Drive_solvers.c
#	
Element_calculations.o: $(HEADER) Element_calculations.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Element_calculations.c

General_matrix_functions.o: $(HEADER) General_matrix_functions.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  General_matrix_functions.c
		
Geometry_cartesian.o: $(HEADER) Geometry_cartesian.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Geometry_cartesian.c
	
Global_operations.o: $(HEADER) Global_operations.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Global_operations.c
	
Instructions.o: $(HEADER) Instructions.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Instructions.c
	
io.o: $(HEADER) io.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  io.c

Nodal_mesh.o: $(HEADER) Nodal_mesh.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Nodal_mesh.c

output_ascii.o: $(HEADER) output_ascii.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  output_ascii.c
	
output_vtk.o: $(HEADER) output_vtk.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  output_vtk.c
	
Output.o: $(HEADER) Output.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Output.c
	
Pan_problem_misc_functions.o: $(HEADER)  Pan_problem_misc_functions.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Pan_problem_misc_functions.c
		
Parallel_related.o: $(HEADER) Parallel_related.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Parallel_related.c

Parsing.o: $(HEADER) Parsing.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Parsing.c

Phase_change.o: $(HEADER) Phase_change.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Phase_change.c

Process_velocity.o: $(HEADER) Process_velocity.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Process_velocity.c

Process_buoyancy.o: $(HEADER) Process_buoyancy.cu
	$(NVCC) -D_Bool=bool $(OBJFLAG)  Process_buoyancy.cu
			
Profiling.o: $(HEADER) Profiling.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Profiling.c
	
Shape_functions.o: $(HEADER) Shape_functions.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Shape_functions.c
	
Size_does_matter.o: $(HEADER) Size_does_matter.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Size_does_matter.c
	
Solver_conj_grad.o: $(HEADER) Solver_conj_grad.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Solver_conj_grad.c
	
Solver_multigrid.o: $(HEADER) Solver_multigrid.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Solver_multigrid.c

Sphere_harmonics.o: $(HEADER) Sphere_harmonics.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Sphere_harmonics.c

Stokes_flow_Incomp.o: $(HEADER) Stokes_flow_Incomp.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Stokes_flow_Incomp.c
	
Topo_gravity.o: $(HEADER) Topo_gravity.c 
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Topo_gravity.c

Viscosity_structures.o: $(HEADER) Viscosity_structures.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Viscosity_structures.c

Blas_lapack_interfaces.f: Blas_lapack_interfaces.F
	$(CPP) $(OPTIM) -P Blas_lapack_interfaces.F Blas_lapack_interfaces.f
	$(F77) $(OPTIM) $(FOPTIM) -c Blas_lapack_interfaces.f

Output_gzdir.o: $(HEADER) Output_gzdir.c
	$(CC) $(OPTIM) $(FLAGS)  $(OBJFLAG)  Output_gzdir.c


