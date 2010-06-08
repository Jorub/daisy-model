# Makefile --- For maintaining the Daisy project.
#
# Automatic creation of daisy on multiple platforms.
#
# You need GNU Make for using this file.
#
# The following envirnoment variables are used:
#
# HOSTTYPE
#	sun4		Create code for Solaris-2 / UltraSPARC.
#	i386-linux	Create code for ia32 / Linux.
#	hp		Create code for HP/UX / HP-PA.
#	win32		Create code for Win32 / Pentium.
#	cygwin		Create code for Cygwin / Pentium.
#	mingw		Create code for Mingw / Pentium.

# All makefiles should have these.
#
SHELL = /bin/sh
MAKEFLAGS =

# HOSTTYPE is not defined in the native win32 Emacs.
#
ifeq ($(OS),Windows_NT)
#	HOSTTYPE = cygwin
	HOSTTYPE = mingw
#	HOSTTYPE = win32
else
	HOSTTYPE = x86_64
endif

# HOSTTYPE .
#
# Some non-local files and directories.

ifeq ($(HOSTTYPE),x86_64)
SRCDIR = $(HOME)/daisy
OBJHOME =  $(SRCDIR)/obj
NATIVEHOME = $(OBJHOME)
NATIVEEXE = daisy
USE_GUI = none
BOOSTINC = #-isystem $(HOME)/boost/include/boost-1_35/
else
SRCDIR = ..
OBJHOME = obj
NATIVEHOME = $(OBJHOME)
NATIVEEXE = daisy.exe daisyw.exe
USE_GUI = Q4
BOOSTINC = -isystem $(CYGHOME)/usr/include/boost-1_33_1
#BOOSTINC = -isystem /cygdrive/c/boostcvs
#BOOSTINC = -isystem /cygdrive/c/boostsvn/boost-sandbox
SETUPDIR = /home/abraham/daisy/install
MAKENSIS = "/cygdrive/c/Program Files/NSIS/makensis.exe"
MINGWHOME = /cygdrive/c/MinGW
endif

TARGETTYPE = i586-mingw32msvc
SVNROOT = https://daisy-model.googlecode.com/svn

# Set USE_GUI to Q4 or none, depending on what GUI you want.
#

# Set USE_OPTIMIZE to `true' if you want a fast executable.
#
USE_OPTIMIZE = true
#USE_OPTIMIZE = false

# Set USE_PROFILE if you want to profile the executable
#
USE_PROFILE = true
#USE_PROFILE = false

# Set COMPILER according to which compiler you use.
#	sun		Use the unbundled sun compiler.
#	gcc		Use the GNU compiler.
#	borland		Use the Borland compiler.
#
ifeq ($(HOSTTYPE),sun4)
	COMPILER = gcc
#	COMPILER = sun	
endif
ifeq ($(HOSTTYPE),i386-linux)
	COMPILER = gcc
endif
ifeq ($(HOSTTYPE),x86_64)
	COMPILER = gcc
endif
ifeq ($(HOSTTYPE),hp)
	COMPILER = gcc
endif
ifeq ($(HOSTTYPE),win32)
	COMPILER = borland
endif
ifeq ($(HOSTTYPE),mingw)
	COMPILER = gcc
endif

# On SPARC platforms we trap mathematical exception with some assembler code.
#
SPARCSRC = set_exceptions.S
SPARCOBJ = set_exceptions.o

# Microsoft lacks some common Unix functions.
#
#MSSRC = win32_unistd.c
MSSRC =

WINSRC = w32reg.c
WINOBJ = w32reg.o
WINHDR = w32reg.h

ifeq ($(HOSTTYPE),sun4) 
SYSSOURCES = $(SPARCSRC)
SYSOBJECTS = $(SPARCOBJ)
endif

ifeq ($(COMPILER),ms)
SYSSOURCES = $(MSSRC)
endif

ifeq ($(HOSTTYPE),mingw)
SYSSOURCES = $(WINSRC)
SYSOBJECTS = $(WINOBJ)
SYSHEADERS = $(WINHDR)
endif

ALLSYSSRC = $(SPARCSRC) $(MSSRC) $(WINSRC)
ALLSYSHDR = $(WINHDR)

# Find the profile flags.
#
ifeq ($(USE_PROFILE),true)
	ifneq ($(COMPILER),borland)
		PROFILE = -pg
	endif
endif

# Find the optimize flags.
#
ifeq ($(USE_OPTIMIZE),true)
	ifeq ($(COMPILER),gcc)
		OPTIMIZE = -O3 -ffast-math -fno-finite-math-only 
		ifeq ($(HOSTTYPE),sun4)
		  OPTIMIZE = -O3 -ffast-math -fno-finite-math-only -mcpu=v8 -mtune=ultrasparc
#`-mcpu=ultrasparc' breaks `IM::IM ()' with gcc 2.95.1.
		endif
		ifeq ($(HOSTTYPE),i386-linux)
		  OPTIMIZE = -O3 -ffast-math -fno-finite-math-only -mtune=generic -march=pentium
	        endif
		ifeq ($(HOSTTYPE),x86_64)
		  OPTIMIZE = -O3 -ffast-math -fno-finite-math-only -mtune=native  -march=native
	        endif
		ifeq ($(HOSTTYPE),cygwin)
		  OPTIMIZE = -O3 -ffast-math -fno-finite-math-only -mtune=pentium-m -march=pentium
		endif
		ifeq ($(HOSTTYPE),mingw)
		  OPTIMIZE = -O3 -ffast-math -fno-finite-math-only -mtune=pentium-m -march=pentium
		endif
	endif
	ifeq ($(COMPILER),icc)
		OPTIMIZE = -O2
	endif
else
	ifeq ($(COMPILER),icc)
		OPTIMIZE = -O0
	endif
endif

# Do we want to create a dynamic library?
#
ifeq ($(HOSTTYPE),i386-linux)
	USE_DYNLIB = false
endif
ifeq ($(HOSTTYPE),x86_64)
	USE_DYNLIB = false
endif
ifeq ($(HOSTTYPE),sun4)
	USE_DYNLIB = false
endif
ifeq ($(HOSTTYPE),hp)
	USE_DYNLIB = true
endif
ifeq ($(HOSTTYPE),win32)
	USE_DYNLIB = false
endif
ifeq ($(HOSTTYPE),cygwin)
	USE_DYNLIB = false
endif
ifeq ($(HOSTTYPE),mingw)
	USE_DYNLIB = false
endif

# Create the right compile command.
#
ifeq ($(USE_DYNLIB),true)
	DYNSEARCH = -R`pwd`
endif

GCC = gcc
CROSSGCC = $(GCC) # "$(TARGETTYPE)-gcc"

STRIP = strip
CROSSSTRIP = "$(TARGETTYPE)-strip"

ifeq ($(COMPILER),gcc)
#	New warning flags in GCC 4.4
	WAR4    = -Wlogical-op -Wstrict-null-sentinel -Wvariadic-macros -Wvla \
		  -Wmissing-declarations -Wfloat-equal -Wcast-qual 
#	GCC 3 had gave uninitialized warnings during initialization.
	WAR3	= -Wno-uninitialized -Wno-unknown-pragmas 

	ifeq ($(HOSTTYPE),sun4)
		OSFLAGS = 
		DEBUG = -g
	endif
	ifeq ($(HOSTTYPE),i386-linux)
		OSFLAGS = 
		DEBUG = -g
	endif
	ifeq ($(HOSTTYPE),x86_64)
		WAREXTRA = $(WAR4)
		OSFLAGS = 
		DEBUG = -g
	endif
	ifeq ($(HOSTTYPE),cygwin)
		OSFLAGS =
		DEBUG = -g
	endif
	ifeq ($(HOSTTYPE),mingw)
		WAREXTRA = $(WAR3)
		OSFLAGS = -DMINGW -mno-cygwin
#		          -I/home/mingw/include -L/home/mingw/lib
		DEBUG = -g
	endif

	WARNING = -Wall -Wextra $(WAREXTRA) \
		  -Woverloaded-virtual -Wundef -Wpointer-arith -Wwrite-strings \
		  -Wcast-align -Wmissing-format-attribute \
		  -Wold-style-cast -Wformat=2 -Winit-self \
		  -Wsign-promo -Wredundant-decls \
		  -Wno-unused-parameter -Wno-sign-compare 


# I use these a lot:
#   -Wconversion -Wsign-compare -Wno-unused-parameter
#   -Wmissing-noreturn
# This one doesn't work (gcc 4.4 linux/amd64):
#   -Wunreachable-code: triggered by constructors?

	COMPILE = $(GCC) -ansi -pedantic $(WARNING) $(DEBUG) $(OSFLAGS) $(BOOSTINC) $(GTESTINC) $(GUIINCLUDE) 
	CCOMPILE = $(COMPILE)
	CPPLIB = -lstdc++
endif
ifeq ($(COMPILER),sun)
	COMPILE = /pack/devpro/SUNWspro/bin/CC
	CCOMPILE = gcc -I/pack/f2c/include -g -Wall
endif
ifeq ($(COMPILER),borland)
	WARNFLAGS = -w-csu -wdef -wnod -wamb -w-par -w-hid
	COMPILE = $(BORLAND)Bin/bcc32 -P -v $(WARNFLAGS)
	CCOMPILE = $(BORLAND)Bin/bcc32 -P- -v $(WARNFLAGS)
endif
ifeq ($(COMPILER),icc)
	COMPILE = /opt/intel/compiler70/ia32/bin/icc -Xc -x c++ -g -w1
	CCOMPILE = /opt/intel/compiler70/ia32/bin/icc -Xc -x c -g -w1
endif

CSHARP = /cygdrive/C/WINDOWS/Microsoft.NET/Framework/v2.0.50727/csc.exe

csdaisy.exe:	csmain.cs csdaisy.netmodule
	$(CSHARP) /out:csdaisy.exe /addmodule:csdaisy.netmodule csmain.cs

#csdaisydll.exe:	csmain.cs csdaisy.dll
#	$(CSHARP) /out:csdaisy.exe /r:csdaisy.dll csmain.cs 

#csdaisy.dll: csdaisy.cs
#	$(CSHARP) /target:library csdaisy.cs

.cs.netmodule:
	$(CSHARP) /target:module $<

# Construct the compile command.
#
CC = $(COMPILE) $(OPTIMIZE) $(PROFILE)

# Find the rigth math library.
#
ifeq ($(HOSTTYPE),sun4)
	MATHLIB = -lm
endif
ifeq ($(HOSTTYPE),hp)
	MATHLIB = -lM
endif
ifeq ($(HOSTTYPE),i386-linux)
	MATHLIB =
endif
ifeq ($(HOSTTYPE),x86_64)
	MATHLIB =
endif
ifeq ($(HOSTTYPE),win32)
	MATHLIB =
endif
ifeq ($(HOSTTYPE),cygwin)
	MATHLIB =
endif
ifeq ($(HOSTTYPE),mingw)
	MATHLIB =
endif

# Locate the CSSparse lib
CXSPARSELIB = -L../libdeps -lcxsparse
CXSPARSEHEAD = ublas_cxsparse.h cs.h UFconfig.h

# Locate the tk library.
#
TKINCLUDE	= -I/pack/tcl+tk-8/include -I/usr/openwin/include
TKLIB	  	= -L/pack/tcl+tk-8/lib -L/usr/openwin/lib \
		  -ltix4.1.8.0 -ltk8.0 -ltcl8.0 -lX11 -lsocket -lnsl -ldl

# Locate the Gtk-- library.
#
GTKMMINCLUDE	= -I$(HOME)/gtk/lib/Gtk--/include \
		  -I$(HOME)/gtk/lib/glib/include \
		  -I$(HOME)/gtk/include -I/usr/openwin/include
GTKMMLIB	= -L$(HOME)/gtk/lib -lgtkmm \
		  -L/usr/openwin/lib -R/usr/openwin/lib \
		  -lgtk -lgdk -lglib -lXext -lX11 -lsocket -lnsl -lm
GTKMMDRAWINCLUDE = -I$(HOME)/gtk/include/gtk--draw \
		   $(GTKMMINCLUDE)
GTKMMDRAWLIB	= -L$(HOME)/gtk/lib -lgtkmmdraw ${GTKMMLIB}

# Locate the Qt library.
#
ifeq ($(HOSTTYPE),i386-linux)
# Locate the Qt library.
#
QTINCLUDE	= -I/usr/include/qt
QTLIB		= -lqt -L/usr/X11R6/lib -lX11 -lm
QTMOC		= moc
else
QTINCLUDE	= -I/pack/qt/include -I/usr/openwin/include
QTLIB		= -L/pack/qt/lib -R/pack/qt/lib -lqt \
		  -L/usr/openwin/lib -R/usr/openwin/lib \
		  -lXext -lX11 -lsocket -lnsl -lm
QTMOC		= /pack/qt/bin/moc
endif

ifeq ($(HOSTTYPE),mingw)
Q4HOME = /cygdrive/c/Qt/4.5.2
Q4INCLUDE	= -isystem $(Q4HOME)/include
ifeq (false,true)
Q4SYS		= -lGDI32 -lole32 -lOleaut32 -luuid -lImm32 -lwinmm \
		  -lWinspool -lWs2_32 -lcomdlg32
Q4LIB		= -L$(Q4HOME)/lib -lQtGui -lQtCore $(Q4SYS) 
else
Q4LIB		= -L$(Q4HOME)/lib -lQtGui4 -lQtCore4
endif
Q4MOC		= $(Q4HOME)/bin/moc
endif

# Find the right file extension.
#
ifeq ($(HOSTTYPE),win32)
	OBJ = .obj
	EXE = .exe
else
	OBJ = .o
	ifeq ($(HOSTTYPE),cygwin)
		EXE = .exe
	else
		ifeq ($(HOSTTYPE),mingw)
			EXE = .exe
		else
			EXE =
		endif
	endif
endif

ifeq ($(HOSTTYPE),mingw)
	DAISYEXE = daisy.exe
else
	DAISYEXE = /usr/local/daisy/$(HOSTTYPE)/daisy
endif

# Figure out how to link.
#
ifeq ($(COMPILER),borland)
	LINK = $(BORLAND)Bin/BCC32 -lw-dup -e
	DLLLINK = $(BORLAND)Bin/BCC32 -WD -lTpd -lw-dup -e
endif
ifeq ($(COMPILER),gcc)
	LINK = $(CC) $(DYNSEARCH) $(DEBUG) -o
endif
ifeq ($(COMPILER),icc)
	LINK = /opt/intel/compiler70/ia32/bin/icc -g -o
endif
NOLINK = -c

# Select the C files that doesn't have a corresponding header file.
# These are all models of some component.
# 

LATER = tertiary_instant.C
MODELS = xysource_xycombine.C xysource_flux.C \
	gnuplot_soil.C reaction_sorption.C hydraulic_B_C_inverse.C \
	program_osvaldo.C vegetation_permanent.C  litter.C drain_lateral.C \
	hydraulic_MACRO.C program_cpedata.C \
	reaction_boundrel.C log_regress.C reaction_Morgan98.C \
	reaction_Styczen88.C program_GP2D.C svat_ssoc.C reaction_Jarvis99.C \
	reaction_filter.C seed_LAI.C seed_release.C \
	stomatacon_SHA.C \
	tertiary_old.C \
	biopore_drain.C tertiary_biopores.C \
	biopore_matrix.C transport_Mollerup.C transport_Hansen.C \
	movement_1D.C groundwater_aquitard.C \
	heatrect_Mollerup.C heatrect_linear.C heatrect_none.C \
	transport_convection.C \
	ABAprod_uptake.C ABAprod_soil.C ABAprod_root.C \
	solver_ublas.C solver_cxsparse.C solver_none.C \
	movement_rect.C chemistry_multi.C \
	equil_goal.C equil_linear.C equil_langmuir.C transform_equil.C \
	reaction_nit.C reaction_denit.C \
	reaction_adsorption.C reaction_equil.C rootdens_GP2D.C \
	rootdens_GP1D.C number_plf.C rubiscoNdist_forced.C action_extern.C \
	rubiscoNdist_expr.C uzrect_const.C photo_FCC3.C photo_FCC4.C \
	reaction_std.C chemistry_std.C \
	groundwater_extern.C \
	transport_none.C uzrect_Mollerup.C groundwater_flux.C \
	rubiscoNdist_uniform.C \
	uzrect_2x1.C select_flow.C \
	select_volume.C uz1d_none.C condition_walltime.C uz1d_richard.C \
	rubiscoNdist_DPF.C raddist_DPF.C raddist_std.C difrad_DPF.C \
        difrad_weather.C number_lisp.C condition_extern.C condition_boolean.C \
	boolean_number.C boolean_string.C \
	number_soil.C organic_none.C \
	organic_std.C integer_arit.C \
	source_merge.C number_source.C program_file.C action_table.C \
	xysource_merge.C xysource_inline.C xysource_loop.C \
	xysource_combine.C gnuplot_xy.C xysource_expr.C gnuplot_multi.C \
	gnuplot_time.C source_combine.C number_arit.C source_expr.C \
	source_std.C action_markvand.C  photo_GL.C \
	program_gnuplot.C \
	program_document.C program_batch.C summary_balance.C \
	rootdens_AP.C number_const.C \
	domsorp_std.C \
	horizon_numeric.C horizon_system.C pet_FAO_PM.C \
	pet_Hargreaves.C hydraulic_M_vGp.C summary_simple.C \
	phenology_TSum.C phenology_std.C hydraulic_hypres.C clayom_biomod.C \
        clayom_old.C hydraulic_Cosby.C \
	condition_weather.C \
	rootdens_PLF.C rootdens_G_P.C groundwater_file.C action_fertilize.C \
	action_repeat.C \
	vegetation_crops.C crop_simple.C action_ridge.C groundwater_fixed.C \
	groundwater_deep.C action_heat.C hydraulic_M_vG_compact.C \
	action_crop.C groundwater_lysimeter.C action_message.C weather_std.C \
	groundwater_pipe.C \
	select_index.C select_content.C \
	select_number.C select_array.C log_table.C \
	log_harvest.C action_while.C action_wait.C action_activity.C \
	mactrans_std.C macro_std.C macro_none.C \
	column_std.C  weather_simple.C uzrichard.C \
	hydraulic_yolo.C hydraulic_M_vG.C hydraulic_B_vG.C hydraulic_M_C.C \
	hydraulic_B_C.C hydraulic_M_BaC.C hydraulic_B_BaC.C \
	groundwater_static.C horizon_std.C \
	crop_std.C action_sow.C action_stop.C condition_time.C \
	condition_logic.C action_irrigate.C action_lisp.C \
	weather_none.C action_tillage.C \
	action_harvest.C \
	action_with.C nitrification_soil.C \
	nitrification_solute.C hydraulic_mod_C.C uzlr.C adsorption_vS_S.C \
	tortuosity_M_Q.C tortuosity_linear.C \
	adsorption_freundlich.C adsorption_linear.C adsorption_langmuir.C \
	bioclimate_std.C condition_crop.C \
	condition_soil.C log_checkpoint.C \
	uznone.C condition_daisy.C chemical_std.C \
	hydraulic_M_BaC_Bimodal.C hydraulic_B_BaC_Bimodal.C \
	pet_makkink.C pet_weather.C svat_none.C action_spray.C pet_PM.C \
	svat_pmsw.C action_surface.C

DISABLED = depend.C \
	crop_old.C crop_sold.C log_clone.C action_merge.C action_divide.C \
	weather_file.C hydraulic_old.C hydraulic_old2.C weather_hourly.C 
# A component is a common interface to a number of models.
# 
COMPONENTS = solute.C drain.C \
	draineqd.C condedge.C rainergy.C ponddamp.C scope_model.C seed.C \
	stomatacon.C tertiary.C biopore.C secondary.C heatrect.C unit_model.C \
	ABAprod.C solver.C element.C ui.C reaction.C scopesel.C \
	transport.C uzrect.C bound.C volume.C uz1d.C \
	rubiscoNdist.C raddist.C difrad.C organic.C movement.C integer.C\
	xysource.C gnuplot.C boolean.C stringer.C source.C photo.C \
	format.C depth.C wse.C program.C number.C domsorp.C chemistry.C \
	summary.C nitrification.C phenology.C clayom.C equil.C \
	transform.C rootdens.C select.C average.C mactrans.C macro.C \
	parser.C log.C weather.C column.C crop.C \
	action.C condition.C horizon.C 	uzmodel.C hydraulic.C \
	bioclimate.C groundwater.C am.C \
	adsorption.C tortuosity.C chemical.C \
	pet.C net_radiation.C svat.C vegetation.C 

# Submodels are combined models and components.
#
SUBMODELS = irrigate.C \
	fetch_pretty.C toplevel.C timestep.C geometry_rect.C doe.C \
        geometry1d.C fetch.C horheat.C time.C \
	som.C smb.C aom.C dom.C crpn.C vernalization.C \
	partition.C production.C \
	harvesting.C canopy_simple.C canopy_std.C root_system.C \
	ridge.C soil.C surface.C soil_water.C \
	soil_heat.C \
	snow.C harvest.C field.C \
	bioincorporation.C 

# Special or intermediate models with their own interface.
#
SPECIALS = log_dlf.C reaction_colgen.C weather_base.C \
	volume_box.C movement_solute.C scope_exchange.C photo_Farquhar.C \
	scope_multi.C scope_id.C geometry_vert.C gnuplot_base.C \
	source_file.C format_LaTeX.C log_all.C om.C select_value.C \
	weather_old.C log_extern.C log_select.C parser_file.C \
	geometry.C log_alist.C

# Various utility code that are neither a component nor a (sub)model.
# 
OTHER = scope_xysources.C lexer_flux.C lexer_soil.C iterative.C \
	water.C block_nested.C block_submodel.C block_top.C block_model.C \
	value.C type.C model_derived.C model_logable.C model_framed.C \
	printer.C printer_file.C filepos.C frame_submodel.C \
	frame_model.C scope.C attribute.C unit.C border.C resistance.C \
	convert.C units.C anystate.C imvec.C im.C frame.C \
	bdconv.C abiotic.C scope_soil.C run.C treelog_text.C treelog_store.C \
	intrinsics.C metalib.C model.C output.C scope_block.C librarian.C \
	gnuplot_utils.C scope_sources.C scope_table.C lexer_table.C \
	block.C dlf.C texture.C destination.C symbol.C \
	fao.C gaussj.C vcheck.C assertion.C xref.C oldunits.C \
	check.C check_range.C path.C traverse_delete.C \
	traverse.C treelog.C \
	lexer_data.C lexer.C daisy.C library.C plf.C \
	mathlib.C cdaisy.C nrutil.C version.C

# Utilities in header or source alone.
HEADONLY = submodeler.h memutils.h $(CXSPARSEHEAD)
SRCONLY = 

# Everything that has an interface.
#
INTERFACES = $(COMPONENTS) $(SUBMODELS) $(SPECIALS) $(OTHER)

# Select the Qt frontend files.

QTMOCHDR = qmain_edit.h qmain.h
QTMOCSRC = $(QTMOCHDR:.h=_moc.C)
QTSOURCES = $(QTMOCHDR:.h=.C) \
	qmain_tree.C qmain_item.C qmain_populate.C qmain_busy.C
QTHEADERS = $(QTSOURCES:.C=.h) 
QTOBJECTS = $(QTSOURCES:.C=${OBJ}) $(QTMOCHDR:.h=_moc${OBJ}) 

# Select the Qt4 frontend files

Q4MOCHDR = run_Qt.h vis_Qt.h log_Qt.h ui_Qt_run.h
Q4MOCSRC = $(Q4MOCHDR:.h=_moc.C)
Q4HEADERS = $(Q4MOCHDR) ui_Qt.h
Q4SOURCES = $(Q4HEADERS:.h=.C) main_Qt.C
Q4OBJECTS = $(Q4SOURCES:.C=${OBJ}) $(Q4MOCHDR:.h=_moc${OBJ}) 

ifeq ($(USE_GUI),Q4)
GUISOURCES = $(Q4SOURCES) 
GUIOBJECTS = $(Q4OBJECTS)
GUILIB = $(Q4LIB)
GUIINCLUDE = $(Q4INCLUDE)
GUIDLL = daisy_Qt.dll
MOC = $(Q4MOC)
else
GUISOURCES =
GUIOBJECTS = 
GUILIB = 
GUIINCLUDE = 
GUIDLL =
endif

ALLGUISRC = tkmain.C gmain.C $(QTSOURCES) $(Q4SOURCES)
ALLGUIHDR = $(QTHEADERS) $(Q4HEADERS)

LOSTGUISRC = pmain.C

# Select the C files that are not part of the library.
#
MAIN = main.C 

# The object files used in the daisy library.
#
LIBOBJ = $(INTERFACES:.C=${OBJ}) $(MODELS:.C=${OBJ}) $(SYSOBJECTS) \
	$(SRCONLY:.C=$(OBJ))

# Find all object files, header files, and source files.
#
OBJECTS = $(LIBOBJ) $(MAIN:.C=${OBJ}) cmain${OBJ} bugmain.o
SOURCES = $(INTERFACES) $(MODELS)  $(MAIN) \
	 cmain.c bugmain.c $(SRCONLY)
HEADERS = $(INTERFACES:.C=.h) $(HEADONLY)

# Find all printable files.
#
TEXT =  ChangeLog.3 ChangeLog.2 ChangeLog.1 setup.nsi \
	Makefile ChangeLog TODO NEWS COPYING COPYING.LIB  $(DISABLED) \
	$(HEADERS) $(SOURCES) $(ALLSYSHDR) $(ALLSYSSRC) \
	$(ALLGUIHDR) $(ALLGUISRC) $(UTESTSRC)

# The executables.
#
EXECUTABLES = daisy${EXE} tkdaisy${EXE} cdaisy${EXE} gdaisy${EXE}

# Select files to be removed by the next svn update.
#
REMOVE = gnuplot_flux.C 

REMOVED = ABAeffect_exp.C ABAeffect.C ABAeffect.h \
	stomatacon_Leuning.C stomatacon_BB.C \
	select_pF.C avalue.C alist.C avalue.h alist.h syntax.h syntax.C \
	msoltranrect_2x1.C msoltranrect_forward.C\
	select_soil.C adsorption_none.C adsorption_full.C ABAprod_expr.C \
	solute.C solute.h pedo.C pedo.h pedo_arit.C pedo_const.C \
	denitrification.C soil_NH4.C soil_NO3.C \
	denitrification.h soil_NH4.h soil_NO3.h \
	soil_heat1d.h soil_heat1d.C soil_heat_rect.h soil_heat_rect.C \
	ui_Qt_read.h ui_Qt_read.C \
	tlink32.ini daisy.bpr daisy.bpf daisy.bpg Daisy.vcproj q4main.C treelog_stream.C treelog_stream.h treelog_dual.C treelog_dual.h soil_chemical.C soil_chemicals.C chemicals.C soil_chemical.h soil_chemicals.h chemicals.h boolean_extern.C number_extern.C options.C options.h select_interval.C select_utils.h select_utils.C select_flux_top.C select_flux_bottom.C select_flux.C select_flux.h column_base.h

# These are the file extensions we deal with.
# 
.SUFFIXES:	.C ${OBJ} .h .c ${EXE} .a .cs .netmodule

# Create all the executables.
#
all:	#(EXECUTABLES)
	@echo 'Use "make native" to create a native Daisy executable.'

# Create a DLL.
#
daisy.dll: $(LIBOBJ) 
	$(CC) -shared -o $@ $^ $(CPPLIB) $(MATHLIB) $(CXSPARSELIB) -Wl,--out-implib,libdaisy.a 

daisy_Qt.dll: $(Q4OBJECTS) daisy.dll
	$(CC) -shared -o $@ $^ $(GUILIB) $(CPPLIB) $(MATHLIB) -Wl,--out-implib,libdaisy_Qt.a 


# Create the main executable.
#
daisy.exe:	main${OBJ} daisy.dll
	$(LINK)$@ $^ $(CPPLIB) $(MATHLIB)

daisyw.exe:	$(GUIOBJECTS) daisy.dll
	$(LINK)$@ $^ $(GUILIB) $(CPPLIB) $(MATHLIB) -Wl,--enable-runtime-pseudo-reloc -mwindows

daisy:	main${OBJ} $(GUIOBJECTS) $(LIBOBJ)
	$(LINK)$@ $^ $(GUILIB) $(CPPLIB) $(MATHLIB)  $(CXSPARSELIB)

exp:	
	(cd $(OBJHOME)/exp \
         && $(MAKE) VPATH=$(SRCDIR) USE_PROFILE=true -f $(SRCDIR)/Makefile daisy)

linux:	
	(mkdir -p $(NATIVEHOME) \
	 && cd $(NATIVEHOME) \
         && time $(MAKE) VPATH=$(SRCDIR) -f $(SRCDIR)/Makefile $(NATIVEEXE))

native:	
	(cd OpenMI && time $(MAKE) all ) \
	 && mkdir -p $(NATIVEHOME) \
	 && cd $(NATIVEHOME) \
         && time $(MAKE) VPATH=$(SRCDIR) -f $(SRCDIR)/Makefile $(NATIVEEXE)

cnative:
	(mkdir -p $(NATIVEHOME) \
	 && cd $(NATIVEHOME) \
         && $(MAKE) VPATH=$(SRCDIR) -f $(SRCDIR)/Makefile cdaisy.exe)

cross:
	(cd $(TARGETTYPE) \
         && $(MAKE) "PATH=/cygdrive/c/MinGW/bin:$(PATH)" \
		    "CYGHOME=C:/cygwin" Q4HOME=c:/Qt/4.3.0\
	            GCC=$(CROSSGCC) VPATH=$(SRCDIR) \
                    -f $(SRCDIR)/Makefile daisy${EXE} daisyw.exe)

# Create manager test executable.
#
mandaisy${EXE}:	manmain${OBJ} daisy.so
	$(LINK)$@  $^ $(MATHLIB)

# Create bug test executable.
#
bugdaisy${EXE}:	bugmain${OBJ} daisy.so
	$(LINK)$@  $^ $(MATHLIB)

# Create executable with embedded tcl/tk.
#
tkdaisy${EXE}:	tkmain${OBJ} daisy.so
	$(LINK)$@ $^ $(TKLIB) $(MATHLIB)

# Create executable with Gtk--.
#
gdaisy${EXE}:	gmain${OBJ} daisy.so
	$(LINK)$@ $^ $(GTKMMLIB)

# Create executable with Qt 3.
#
qdaisy${EXE}:	$(QTOBJECTS) daisy.so
	$(LINK)$@ $(QTOBJECTS) `pwd`/daisy.so $(QTLIB)

# Create the C main executable.
#
cdaisy${EXE}:  cmain${OBJ} daisy.dll
	$(LINK)$@ $^ $(CPPLIB) $(MATHLIB)

ddaisy${EXE}:  main${OBJ} daisy.dll $(GUIOBJECTS) 
	$(LINK)$@ $^ $(GUILIB) $(CPPLIB) $(MATHLIB)

cdaisy-mshe${EXE}:  cmain-mshe${OBJ} daisy.so
	$(LINK)$@ cmain-mshe${OBJ} `pwd`/daisy.so $(MATHLIB)

# Create the C main executable for testing.
#
cdaisy_test${EXE}:  cmain_test${OBJ} daisy.so
	$(LINK)$@ $^ $(MATHLIB)

# Create a shared library.
#
daisy.so: $(LIBOBJ)
	$(CC) -shared -o daisy.so $^ $(MATHLIB)

# toplevel.o cdaisy.o:
#	 $(CC) $(NOLINK) -DBUILD_DLL $<

# Create daisy plot executable.
#
pdaisy${EXE}: pmain${OBJ} time.o
	$(LINK)$@ $^ $(GTKMMDRAWLIB) $(MATHLIB)


# Boost test

btest${EXE}: btest.C
	$(LINK)$@ -isystem /usr/include/boost-1_33_1/ $< $(CPPLIB) $(MATHLIB)

# Create the MMM executable.

mmm${EXE}:	$(MOBJECTS)
	$(LINK)$@  $^ $(MATHLIB)

# Count the size of daisy.
#
wc: $(HEADERS) $(SOURCES) 
	wc -l $(HEADERS) $(SOURCES) | sort -nr

wc-h: $(HEADERS)
	wc -l $(HEADERS)

wc-s: $(SOURCES)
	wc -l $(SOURCES)

wc-split: $(MODELS) $(INTERFACES)
	cat $(MODELS) | wc
	cat $(COMPONENTS) $(COMPONENTS:.C=.h) | wc
	cat $(SUBMODELS) $(SUBMODELS:.C=.h) | wc 
	cat $(SPECIALS) $(SPECIALS:.C=.h) | wc
	cat $(OTHER) $(OTHER:.C=.h) | wc

filecount: $(HEADERS) $(SOURCES) 
	ls $(TEXT) | wc

# Update the TAGS table.
#
tags: TAGS

TAGS: $(INTERFACES) $(MODELS) $(MAIN) $(HEADERS)
	etags $(SOURCES) $(HEADERS)

# Fix DOS newline breakage.
#
dos2unix:
	perl -pi.bak -e 's/\r\n$$/\n/' $(TEXT)

# Various test targets.
#

GTESTHOME = ../gtest
GTESTINC = -isystem $(GTESTHOME)/include
GTESTLIB = -L$(GTESTHOME)/lib -lgtest -lgtest_main

UTESTSRC = ut_units.C ut_scope_exchange.C
UTESTOBJ = $(UTESTSRC:.C=${OBJ})

utest${EXE}: $(UTESTOBJ) $(LIBOBJ)
	$(CC) -o $@ $^ $(GTESTLIB) $(CPPLIB) $(MATHLIB) $(CXSPARSELIB) 

unittest:
	(mkdir -p $(NATIVEHOME) \
	 && cd $(NATIVEHOME) \
         && $(MAKE) VPATH=$(SRCDIR) -f $(SRCDIR)/Makefile utest${EXE} \
	 && ./utest${EXE})

utest: utest.exe

xtest:	test/test.dai daisy
	(cd test \
         && ../daisy test.dai \
	 && diff -u harvest_weather.log harvest.log)

ps:	txt/reference.ps


txt/reference.ps:	txt/reference.dvi
	(cd txt \
	 && dvips -f reference.dvi > reference.ps)

txt/reference.dvi:	txt/components.tex
	(cd txt \
	 && makeindex reference \
	 && latex reference.tex < /dev/null )

pdf:	txt/reference.pdf

txt/reference.pdf:	txt/components.tex
	(cd txt \
	 && makeindex reference \
	 && pdflatex reference.tex < /dev/null )

txt/components.tex: $(DAISYEXE)
	(cd txt && $(DAISYEXE) -nw all.dai -p document )

# Remove all the temporary files.
#
clean:
	rm $(OBJECTS) *.rpo $(EXECUTABLES) *.obj *.exe *.o *~

# Update the Makefile when dependencies have changed.
#
depend: $(GUISOURCES) $(SOURCES) 
	rm -f Makefile.old
	mv Makefile Makefile.old
	sed -e '/^# AUTOMATIC/q' < Makefile.old > Makefile
	$(CC) -I. -MM $^ | sed -e 's/\.o:/$${OBJ}:/' >> Makefile

# Create a ZIP file with all the sources.
#
daisy-src.zip:	$(TEXT)
	rm -f daisy-src.zip
	zip daisy-src.zip $(TEXT) daisy.ide

# Move it to ftp.
#

version.C:
	@if [ "X$(TAG)" = "X" ]; then echo "*** No tag ***"; exit 1; fi
	echo "// version.C -- automatically generated file" > version.C
	echo " " >> version.C
	echo "extern const char *const version = \"$(TAG)\";" >> version.C
	echo "extern const char *const version_date = __DATE__;" >> version.C

# Update the SVN repository.
#
svnci: $(TEXT)
	@if [ "X$(TAG)" = "X" ]; then echo "*** No tag ***"; exit 1; fi
	rm -f version.C
	$(MAKE) version.C
	cp ChangeLog ChangeLog.old
	echo `date "+%Y-%m-%d "` \
	     " Per Abrahamsen  <abraham@dina.kvl.dk>" > ChangeLog
	echo >> ChangeLog
	echo "	* Version" $(TAG) released. >> ChangeLog
	echo >> ChangeLog
	cat ChangeLog.old >> ChangeLog
	(cd OpenMI; $(MAKE) svnci);
	(cd lib; $(MAKE) svnci);
	(cd sample; $(MAKE) svnci);
	(cd txt; $(MAKE) svnci);
	(cd project; $(MAKE) svnci);
	-svn add $(TEXT)
	rm -f $(REMOVE) 
	-svn remove $(REMOVE) 
	svn commit -m "Version $(TAG)"
	-svn copy $(SVNROOT)/trunk \
	  $(SVNROOT)/tags/release_`echo $(TAG) | sed -e 's/[.]/_/g'` -m "New release"

.IGNORE: add

add:
	(cd sample && make add)
	(cd project && make add)
	svn add $(TEXT)
	-svn remove $(REMOVE)

update:
	svn update

commit:
	svn commit -m make

done:	update add commit


setup:	svnci
	$(MAKE) setupnosvn
	$(MAKE) upload

setupdocs: 
	(cd txt && $(MAKE) PATH="$(PATH):$(Q4HOME)/bin" \
		           DAISYEXE=$(SRCDIR)/$(OBJHOME)/$(DAISYEXE) \
			   SETUPDIR=$(SETUPDIR) \
			   DAISYPATH=".;$(SRCDIR)/lib;$(SRCDIR)/sample" setup)

setupnosvn: 
	@if [ "X$(TAG)" = "X" ]; then echo "*** No tag ***"; exit 1; fi
	$(MAKE) native 
	rm -rf $(SETUPDIR)
	mkdir $(SETUPDIR)
	cp ChangeLog NEWS $(SETUPDIR)
	mkdir $(SETUPDIR)/src
	cp $(TEXT) $(SETUPDIR)/src
	(cd lib && $(MAKE) SETUPDIR=$(SETUPDIR) TAG=$(TAG) setup)
	(cd sample && $(MAKE) SETUPDIR=$(SETUPDIR) TAG=$(TAG) setup)
	$(MAKE) setupdocs
	(cd exercises && $(MAKE) SETUPDIR=$(SETUPDIR) setup)
	mkdir $(SETUPDIR)/bin
	$(STRIP) -o $(SETUPDIR)/bin/daisy.exe $(OBJHOME)/daisy.exe
	$(STRIP) -o $(SETUPDIR)/bin/daisyw.exe $(OBJHOME)/daisyw.exe
	$(STRIP) -o $(SETUPDIR)/bin/daisy.dll $(OBJHOME)/daisy.dll
	cp $(Q4HOME)/bin/QtCore4.dll $(SETUPDIR)/bin
	cp $(Q4HOME)/bin/QtGui4.dll $(SETUPDIR)/bin
	cp $(MINGWHOME)/bin/mingwm10.dll $(SETUPDIR)/bin
	(cd OpenMI && $(MAKE) SETUPDIR=$(SETUPDIR) TAG=$(TAG) setup)
	$(MAKENSIS) /V2 /DVERSION=$(TAG) setup.nsi


upload:
	@if [ "X$(TAG)" = "X" ]; then echo "*** No tag ***"; exit 1; fi
	./libdeps/googlecode_upload.py -p daisy-model \
		-s "Daisy version $(TAG) installer for MS Windows" \
		-l Type-Installer,OpSys-Windows,Featured \
		daisy-$(TAG)-setup.exe

.PHONY: install
install:
	$(MAKE) native 
	rm -rf $(SETUPDIR)
	mkdir $(SETUPDIR)
	(cd lib && $(MAKE) SETUPDIR=$(SETUPDIR) TAG=$(TAG) setup)
	(cd sample && $(MAKE) SETUPDIR=$(SETUPDIR) TAG=$(TAG) setup)
	mkdir $(SETUPDIR)/bin
	cp -p $(OBJHOME)/daisy.exe $(SETUPDIR)/bin
	cp -p $(OBJHOME)/daisyw.exe $(SETUPDIR)/bin
	cp -p $(OBJHOME)/daisy.dll $(SETUPDIR)/bin
	cp $(Q4HOME)/bin/QtCore4.dll $(SETUPDIR)/bin
	cp $(Q4HOME)/bin/QtGui4.dll $(SETUPDIR)/bin
	cp $(MINGWHOME)/bin/mingwm10.dll $(SETUPDIR)/bin
	(cd OpenMI && $(MAKE) SETUPDIR=$(SETUPDIR) TAG=$(TAG) install)


# How to compile the assembler file.
#
set_exceptions${OBJ}: set_exceptions.S
	as -o set_exceptions${OBJ} set_exceptions.S

# How to compile a C++ file.
#
.C${OBJ}:
	$(CC) $(NOLINK) $<

# How to compile a C file.
#
.c${OBJ}:
	$(CCOMPILE) $(OPTIMIZE) $(PROFILE) $(NOLINK) $<

# How to mock a Qt file.
#
%_moc.C: %.h
	$(MOC) $< -o $@

# Special rule for tkmain.o
#
tkmain${OBJ}: tkmain.C
	$(CC) $(TKINCLUDE) $(NOLINK) $<

# Special rule for gmain.o
#
gmain${OBJ}: gmain.C
	$(CC) $(GTKMMINCLUDE) $(NOLINK) $<

# Special rule for Qt frontend files.

$(QTOBJECTS):
	$(CC) $(QTINCLUDE) $(NOLINK) $<

# Special rule for pmain.o
#
pmain${OBJ}: pmain.C
	$(CC) $(GTKMMDRAWINCLUDE) $(NOLINK) $<

############################################################
# AUTOMATIC -- DO NOT CHANGE THIS LINE OR ANYTHING BELOW IT!
solute${OBJ}: solute.C solute.h model_logable.h model.h symbol.h im.h \
 attribute.h block_model.h block_nested.h block.h scope.h treelog.h \
 frame_model.h frame.h librarian.h
drain${OBJ}: drain.C drain.h model_derived.h model_logable.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h librarian.h
draineqd${OBJ}: draineqd.C draineqd.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h mathlib.h assertion.h librarian.h
condedge${OBJ}: condedge.C condedge.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h mathlib.h assertion.h librarian.h soil.h geometry.h
rainergy${OBJ}: rainergy.C rainergy.h model.h symbol.h mathlib.h assertion.h \
 librarian.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h
ponddamp${OBJ}: ponddamp.C ponddamp.h model.h symbol.h mathlib.h assertion.h \
 librarian.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h
scope_model${OBJ}: scope_model.C scope_model.h scope.h attribute.h symbol.h \
 model.h block_model.h block_nested.h block.h treelog.h frame_model.h \
 frame.h assertion.h librarian.h
seed${OBJ}: seed.C seed.h model_derived.h model_logable.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h librarian.h
stomatacon${OBJ}: stomatacon.C stomatacon.h model_logable.h model.h symbol.h \
 mathlib.h assertion.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h librarian.h check.h
tertiary${OBJ}: tertiary.C tertiary.h model_derived.h model_logable.h model.h \
 symbol.h geometry.h attribute.h soil_water.h block_model.h \
 block_nested.h block.h scope.h treelog.h frame_model.h frame.h \
 librarian.h
biopore${OBJ}: biopore.C biopore.h model_framed.h model_logable.h model.h \
 symbol.h number.h im.h attribute.h block_model.h block_nested.h block.h \
 scope.h treelog.h frame_model.h frame.h librarian.h scope_multi.h \
 scope_id.h units.h memutils.h check.h geometry.h log.h time.h border.h \
 assertion.h mathlib.h
secondary${OBJ}: secondary.C secondary.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h librarian.h assertion.h check.h water.h
heatrect${OBJ}: heatrect.C heatrect.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h librarian.h
unit_model${OBJ}: unit_model.C unit_model.h unit.h symbol.h model.h check.h \
 librarian.h frame.h scope.h attribute.h block_model.h block_nested.h \
 block.h treelog.h frame_model.h mathlib.h assertion.h convert.h units.h \
 memutils.h
ABAprod${OBJ}: ABAprod.C ABAprod.h model_derived.h model_logable.h model.h \
 symbol.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h librarian.h
solver${OBJ}: solver.C solver.h model.h symbol.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h librarian.h
element${OBJ}: element.C element.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h mathlib.h assertion.h librarian.h
ui${OBJ}: ui.C ui.h model.h symbol.h toplevel.h treelog_text.h treelog.h \
 librarian.h block_model.h block_nested.h block.h scope.h attribute.h \
 frame_model.h frame.h assertion.h
reaction${OBJ}: reaction.C reaction.h model_framed.h model_logable.h model.h \
 symbol.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h librarian.h
scopesel${OBJ}: scopesel.C scopesel.h model.h symbol.h scope.h attribute.h \
 assertion.h output.h condition.h model_framed.h model_logable.h \
 memutils.h time.h block_model.h block_nested.h block.h treelog.h \
 frame_model.h frame.h librarian.h
transport${OBJ}: transport.C transport.h model.h symbol.h chemical.h \
 model_framed.h model_logable.h doe.h geometry.h attribute.h adsorption.h \
 model_derived.h block_model.h block_nested.h block.h scope.h treelog.h \
 frame_model.h frame.h librarian.h soil_water.h soil.h
uzrect${OBJ}: uzrect.C uzrect.h model_framed.h model_logable.h model.h \
 symbol.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h librarian.h
bound${OBJ}: bound.C bound.h model_derived.h model_logable.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h mathlib.h assertion.h librarian.h log.h time.h \
 border.h model_framed.h vcheck.h
volume${OBJ}: volume.C volume.h model_derived.h model_logable.h model.h \
 symbol.h geometry.h attribute.h block_model.h block_nested.h block.h \
 scope.h treelog.h frame_model.h frame.h assertion.h librarian.h
uz1d${OBJ}: uz1d.C uz1d.h model.h geometry_rect.h geometry_vert.h geometry.h \
 symbol.h attribute.h soil.h soil_water.h soil_heat.h block_model.h \
 block_nested.h block.h scope.h treelog.h frame_model.h frame.h \
 librarian.h assertion.h mathlib.h
rubiscoNdist${OBJ}: rubiscoNdist.C rubiscoNdist.h model_logable.h model.h \
 symbol.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h mathlib.h assertion.h librarian.h
raddist${OBJ}: raddist.C raddist.h model_derived.h model_logable.h model.h \
 symbol.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h mathlib.h assertion.h librarian.h
difrad${OBJ}: difrad.C difrad.h model_framed.h model_logable.h model.h \
 symbol.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h librarian.h
organic${OBJ}: organic.C organic.h model_derived.h model_logable.h model.h \
 symbol.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h librarian.h
movement${OBJ}: movement.C movement.h model_derived.h model_logable.h model.h \
 symbol.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h librarian.h tertiary.h log.h time.h \
 border.h model_framed.h assertion.h
integer${OBJ}: integer.C integer.h model.h symbol.h boolean.h submodeler.h \
 block_submodel.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_submodel.h frame.h block_model.h frame_model.h memutils.h \
 librarian.h
xysource${OBJ}: xysource.C xysource.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h assertion.h librarian.h
gnuplot${OBJ}: gnuplot.C gnuplot.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h librarian.h
boolean${OBJ}: boolean.C boolean.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h assertion.h memutils.h librarian.h
stringer${OBJ}: stringer.C stringer.h model.h symbol.h boolean.h number.h \
 submodeler.h block_submodel.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_submodel.h frame.h memutils.h librarian.h block_model.h \
 frame_model.h
source${OBJ}: source.C source.h model.h time.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h librarian.h
photo${OBJ}: photo.C photo.h model_derived.h model_logable.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h librarian.h check.h
format${OBJ}: format.C format.h model.h symbol.h assertion.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h librarian.h
depth${OBJ}: depth.C depth.h model.h symbol.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h time.h plf.h \
 lexer_data.h lexer.h filepos.h output.h condition.h model_framed.h \
 model_logable.h memutils.h number.h units.h check.h vcheck.h assertion.h \
 librarian.h mathlib.h path.h frame_submodel.h
wse${OBJ}: wse.C wse.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h program.h run.h \
 mathlib.h assertion.h librarian.h
program${OBJ}: program.C program.h model.h symbol.h run.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h librarian.h
number${OBJ}: number.C number.h symbol.h model.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h librarian.h \
 units.h memutils.h assertion.h
domsorp${OBJ}: domsorp.C domsorp.h model_framed.h model_logable.h model.h \
 symbol.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h librarian.h
chemistry${OBJ}: chemistry.C chemistry.h model_framed.h model_logable.h \
 model.h symbol.h im.h attribute.h chemical.h treelog.h block_model.h \
 block_nested.h block.h scope.h frame_model.h frame.h librarian.h \
 vcheck.h units.h memutils.h
summary${OBJ}: summary.C summary.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h librarian.h
nitrification${OBJ}: nitrification.C nitrification.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h soil.h soil_water.h soil_heat.h log.h time.h \
 border.h model_framed.h model_logable.h mathlib.h assertion.h \
 librarian.h
phenology${OBJ}: phenology.C phenology.h model_derived.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h log.h time.h border.h \
 model_framed.h librarian.h
clayom${OBJ}: clayom.C clayom.h model.h symbol.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h librarian.h
equil${OBJ}: equil.C equil.h model.h symbol.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h librarian.h
transform${OBJ}: transform.C transform.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h librarian.h
rootdens${OBJ}: rootdens.C rootdens.h model_framed.h model_logable.h model.h \
 symbol.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h check.h librarian.h
select${OBJ}: select.C select.h destination.h symbol.h model.h units.h \
 memutils.h volume.h model_derived.h model_logable.h attribute.h \
 condition.h model_framed.h block_model.h block_nested.h block.h scope.h \
 treelog.h frame_model.h frame.h column.h irrigate.h geometry.h number.h \
 scope_id.h metalib.h library.h frame_submodel.h check.h vcheck.h \
 format.h submodeler.h block_submodel.h mathlib.h assertion.h librarian.h \
 convert.h
average${OBJ}: average.C average.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h mathlib.h assertion.h librarian.h
mactrans${OBJ}: mactrans.C mactrans.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h librarian.h
macro${OBJ}: macro.C macro.h model.h symbol.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h librarian.h
parser${OBJ}: parser.C parser.h model.h symbol.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h librarian.h
log${OBJ}: log.C log.h time.h symbol.h border.h model_framed.h \
 model_logable.h model.h library.h metalib.h frame.h scope.h attribute.h \
 block_model.h block_nested.h block.h treelog.h frame_model.h daisy.h \
 program.h run.h assertion.h librarian.h
weather${OBJ}: weather.C weather.h model_derived.h model_logable.h model.h \
 symbol.h im.h attribute.h block_model.h block_nested.h block.h scope.h \
 treelog.h frame_model.h frame.h librarian.h
column${OBJ}: column.C column.h model_framed.h model_logable.h model.h \
 symbol.h irrigate.h memutils.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h log.h time.h \
 border.h librarian.h submodeler.h block_submodel.h frame_submodel.h \
 check.h
crop${OBJ}: crop.C crop.h model_framed.h model_logable.h model.h symbol.h \
 time.h om.h plf.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h mathlib.h assertion.h \
 librarian.h
action${OBJ}: action.C action.h model_framed.h model_logable.h model.h \
 symbol.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h librarian.h
condition${OBJ}: condition.C condition.h model_framed.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h librarian.h
horizon${OBJ}: horizon.C horizon.h model_derived.h model_logable.h model.h \
 symbol.h library.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h frame_submodel.h plf.h \
 horheat.h hydraulic.h mathlib.h assertion.h tortuosity.h texture.h \
 nitrification.h log.h time.h border.h model_framed.h check_range.h \
 check.h vcheck.h librarian.h secondary.h
uzmodel${OBJ}: uzmodel.C uzmodel.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h librarian.h
hydraulic${OBJ}: hydraulic.C hydraulic.h model_derived.h model_logable.h \
 model.h symbol.h library.h plf.h log.h time.h border.h model_framed.h \
 check_range.h check.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h block_submodel.h \
 frame_submodel.h submodeler.h mathlib.h assertion.h program.h run.h \
 vcheck.h librarian.h
bioclimate${OBJ}: bioclimate.C bioclimate.h model_framed.h model_logable.h \
 model.h symbol.h weather.h model_derived.h im.h attribute.h \
 block_model.h block_nested.h block.h scope.h treelog.h frame_model.h \
 frame.h mathlib.h assertion.h librarian.h
groundwater${OBJ}: groundwater.C groundwater.h model_derived.h \
 model_logable.h model.h symbol.h geometry.h attribute.h log.h time.h \
 border.h model_framed.h block_model.h block_nested.h block.h scope.h \
 treelog.h frame_model.h frame.h assertion.h librarian.h
am${OBJ}: am.C am.h model_framed.h model_logable.h model.h symbol.h im.h \
 attribute.h aom.h om.h plf.h chemical.h metalib.h frame.h scope.h \
 library.h submodeler.h block_submodel.h block_nested.h block.h treelog.h \
 frame_submodel.h frame_model.h time.h log.h border.h geometry.h check.h \
 vcheck.h mathlib.h assertion.h program.h run.h memutils.h librarian.h \
 unit.h filepos.h block_model.h
adsorption${OBJ}: adsorption.C adsorption.h model_derived.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h librarian.h mathlib.h \
 assertion.h
tortuosity${OBJ}: tortuosity.C tortuosity.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h librarian.h
chemical${OBJ}: chemical.C chemical.h model_framed.h model_logable.h model.h \
 symbol.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h librarian.h vcheck.h assertion.h
pet${OBJ}: pet.C pet.h model_framed.h model_logable.h model.h symbol.h \
 frame.h scope.h attribute.h block_model.h block_nested.h block.h \
 treelog.h frame_model.h log.h time.h border.h vegetation.h \
 model_derived.h surface.h uzmodel.h librarian.h
net_radiation${OBJ}: net_radiation.C net_radiation.h model_derived.h \
 model_logable.h model.h symbol.h log.h time.h border.h model_framed.h \
 weather.h im.h attribute.h block_model.h block_nested.h block.h scope.h \
 treelog.h frame_model.h frame.h mathlib.h assertion.h librarian.h
svat${OBJ}: svat.C svat.h model_derived.h model_logable.h model.h symbol.h \
 log.h time.h border.h model_framed.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h librarian.h
vegetation${OBJ}: vegetation.C vegetation.h model_derived.h model_logable.h \
 model.h symbol.h log.h time.h border.h model_framed.h frame.h scope.h \
 attribute.h block_model.h block_nested.h block.h treelog.h frame_model.h \
 librarian.h
irrigate${OBJ}: irrigate.C irrigate.h symbol.h memutils.h volume.h \
 model_derived.h model_logable.h model.h im.h attribute.h soil_water.h \
 bioclimate.h model_framed.h chemistry.h chemical.h frame.h scope.h \
 check.h vcheck.h block_submodel.h block_nested.h block.h treelog.h \
 frame_submodel.h submodeler.h librarian.h assertion.h mathlib.h units.h \
 log.h time.h border.h
fetch_pretty${OBJ}: fetch_pretty.C fetch_pretty.h fetch.h destination.h \
 symbol.h librarian.h model.h frame_submodel.h frame.h scope.h \
 attribute.h mathlib.h assertion.h
toplevel${OBJ}: toplevel.C toplevel.h metalib.h symbol.h frame.h scope.h \
 attribute.h daisy.h program.h model.h run.h ui.h library.h parser_file.h \
 parser.h block_top.h block.h path.h version.h assertion.h treelog_text.h \
 treelog.h treelog_store.h librarian.h units.h memutils.h frame_model.h
timestep${OBJ}: timestep.C timestep.h time.h symbol.h vcheck.h \
 frame_submodel.h frame.h scope.h attribute.h block.h assertion.h \
 mathlib.h treelog.h
geometry_rect${OBJ}: geometry_rect.C geometry_rect.h geometry_vert.h \
 geometry.h symbol.h attribute.h volume.h model_derived.h model_logable.h \
 model.h check.h vcheck.h block_model.h block_nested.h block.h scope.h \
 treelog.h frame_model.h frame.h librarian.h assertion.h mathlib.h
doe${OBJ}: doe.C doe.h log.h time.h symbol.h border.h model_framed.h \
 model_logable.h model.h geometry.h attribute.h librarian.h \
 frame_submodel.h frame.h scope.h soil.h soil_water.h treelog.h \
 assertion.h
geometry1d${OBJ}: geometry1d.C geometry1d.h geometry_vert.h geometry.h \
 symbol.h attribute.h volume.h model_derived.h model_logable.h model.h \
 block.h scope.h frame.h mathlib.h assertion.h check.h vcheck.h \
 librarian.h treelog.h
fetch${OBJ}: fetch.C fetch.h destination.h symbol.h select.h model.h units.h \
 memutils.h volume.h model_derived.h model_logable.h attribute.h \
 treelog.h frame_submodel.h frame.h scope.h librarian.h
horheat${OBJ}: horheat.C horheat.h texture.h plf.h hydraulic.h \
 model_derived.h model_logable.h model.h symbol.h frame_submodel.h \
 frame.h scope.h attribute.h check.h mathlib.h assertion.h librarian.h \
 treelog.h
time${OBJ}: time.C time.h symbol.h assertion.h log.h border.h model_framed.h \
 model_logable.h model.h frame_submodel.h frame.h scope.h attribute.h \
 vcheck.h librarian.h block.h treelog.h
som${OBJ}: som.C som.h om.h model_framed.h model_logable.h model.h symbol.h \
 plf.h librarian.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h
smb${OBJ}: smb.C smb.h om.h model_framed.h model_logable.h model.h symbol.h \
 plf.h dom.h librarian.h frame.h scope.h attribute.h assertion.h check.h \
 mathlib.h block_model.h block_nested.h block.h treelog.h frame_model.h
aom${OBJ}: aom.C aom.h om.h model_framed.h model_logable.h model.h symbol.h \
 plf.h librarian.h frame.h scope.h attribute.h check.h assertion.h smb.h \
 dom.h log.h time.h border.h geometry.h mathlib.h block_model.h \
 block_nested.h block.h treelog.h frame_model.h
dom${OBJ}: dom.C dom.h plf.h doe.h smb.h om.h model_framed.h model_logable.h \
 model.h symbol.h geometry.h attribute.h librarian.h block.h scope.h \
 frame.h soil.h soil_water.h log.h time.h border.h check.h assertion.h \
 mathlib.h
crpn${OBJ}: crpn.C crpn.h production.h symbol.h root_system.h rootdens.h \
 model_framed.h model_logable.h model.h ABAprod.h model_derived.h plf.h \
 frame_submodel.h frame.h scope.h attribute.h treelog.h log.h time.h \
 border.h mathlib.h assertion.h librarian.h check.h
vernalization${OBJ}: vernalization.C vernalization.h model_derived.h \
 model_logable.h model.h symbol.h librarian.h log.h time.h border.h \
 model_framed.h frame.h scope.h attribute.h block_model.h block_nested.h \
 block.h treelog.h frame_model.h
partition${OBJ}: partition.C partition.h plf.h librarian.h model.h symbol.h \
 frame_submodel.h frame.h scope.h attribute.h check.h mathlib.h \
 assertion.h treelog.h
production${OBJ}: production.C production.h symbol.h crpn.h partition.h plf.h \
 organic.h model_derived.h model_logable.h model.h geometry.h attribute.h \
 am.h model_framed.h im.h log.h time.h border.h treelog.h mathlib.h \
 assertion.h frame_submodel.h frame.h scope.h librarian.h
harvesting${OBJ}: harvesting.C harvesting.h time.h symbol.h plf.h \
 production.h am.h model_framed.h model_logable.h model.h im.h \
 attribute.h aom.h om.h crop.h harvest.h block_model.h block_nested.h \
 block.h scope.h treelog.h frame_model.h frame.h geometry.h log.h \
 border.h timestep.h vcheck.h mathlib.h assertion.h librarian.h \
 check_range.h check.h submodeler.h block_submodel.h frame_submodel.h
canopy_simple${OBJ}: canopy_simple.C canopy_simple.h plf.h log.h time.h \
 symbol.h border.h model_framed.h model_logable.h model.h \
 block_submodel.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_submodel.h frame.h librarian.h
canopy_std${OBJ}: canopy_std.C canopy_std.h canopy_simple.h plf.h log.h \
 time.h symbol.h border.h model_framed.h model_logable.h model.h \
 block_submodel.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_submodel.h frame.h mathlib.h assertion.h librarian.h
root_system${OBJ}: root_system.C root_system.h rootdens.h model_framed.h \
 model_logable.h model.h symbol.h ABAprod.h model_derived.h plf.h \
 librarian.h geometry.h attribute.h soil_heat.h soil_water.h soil.h \
 chemical.h chemistry.h log.h time.h border.h check.h block_model.h \
 block_nested.h block.h scope.h treelog.h frame_model.h frame.h mathlib.h \
 assertion.h metalib.h
ridge${OBJ}: ridge.C ridge.h soil.h symbol.h geometry1d.h geometry_vert.h \
 geometry.h attribute.h plf.h librarian.h model.h frame_submodel.h \
 frame.h scope.h mathlib.h assertion.h log.h time.h border.h \
 model_framed.h model_logable.h soil_water.h check.h
soil${OBJ}: soil.C soil.h symbol.h horizon.h model_derived.h model_logable.h \
 model.h geometry.h attribute.h hydraulic.h tortuosity.h groundwater.h \
 metalib.h frame.h scope.h library.h frame_submodel.h mathlib.h \
 assertion.h librarian.h submodeler.h block_submodel.h block_nested.h \
 block.h treelog.h log.h time.h border.h model_framed.h check.h vcheck.h \
 plf.h memutils.h secondary.h volume.h water.h
surface${OBJ}: surface.C surface.h uzmodel.h model.h symbol.h geometry1d.h \
 geometry_vert.h geometry.h attribute.h soil.h soil_water.h log.h time.h \
 border.h model_framed.h model_logable.h mathlib.h assertion.h \
 librarian.h plf.h ridge.h check.h treelog.h frame_submodel.h frame.h \
 scope.h
soil_water${OBJ}: soil_water.C soil_water.h geometry.h symbol.h attribute.h \
 soil.h soil_heat.h groundwater.h model_derived.h model_logable.h model.h \
 log.h time.h border.h model_framed.h librarian.h block.h scope.h check.h \
 treelog.h assertion.h mathlib.h frame_submodel.h frame.h
soil_heat${OBJ}: soil_heat.C soil_heat.h block.h scope.h attribute.h symbol.h \
 geometry.h soil.h soil_water.h surface.h uzmodel.h model.h movement.h \
 model_derived.h model_logable.h weather.h im.h frame_submodel.h frame.h \
 log.h time.h border.h model_framed.h treelog.h assertion.h librarian.h
snow${OBJ}: snow.C snow.h frame_submodel.h frame.h scope.h attribute.h \
 symbol.h log.h time.h border.h model_framed.h model_logable.h model.h \
 geometry.h soil.h soil_water.h soil_heat.h movement.h model_derived.h \
 librarian.h mathlib.h assertion.h treelog.h
harvest${OBJ}: harvest.C harvest.h time.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h log.h border.h model_framed.h model_logable.h model.h \
 librarian.h
field${OBJ}: field.C field.h irrigate.h symbol.h memutils.h border.h column.h \
 model_framed.h model_logable.h model.h log.h time.h select.h \
 destination.h units.h volume.h model_derived.h attribute.h treelog.h \
 library.h block.h scope.h assertion.h librarian.h frame_model.h frame.h \
 mathlib.h crop.h metalib.h
bioincorporation${OBJ}: bioincorporation.C bioincorporation.h \
 frame_submodel.h frame.h scope.h attribute.h symbol.h log.h time.h \
 border.h model_framed.h model_logable.h model.h geometry.h soil.h am.h \
 im.h librarian.h plf.h aom.h om.h check.h vcheck.h mathlib.h assertion.h
log_dlf${OBJ}: log_dlf.C log_dlf.h log_select.h log.h time.h symbol.h \
 border.h model_framed.h model_logable.h model.h memutils.h dlf.h \
 select.h destination.h units.h volume.h model_derived.h attribute.h \
 geometry.h assertion.h daisy.h program.h run.h block_model.h \
 block_nested.h block.h scope.h treelog.h frame_model.h frame.h \
 scope_block.h filepos.h librarian.h metalib.h library.h vcheck.h
reaction_colgen${OBJ}: reaction_colgen.C reaction_colgen.h reaction.h \
 model_framed.h model_logable.h model.h symbol.h ponddamp.h librarian.h \
 frame.h scope.h attribute.h log.h time.h border.h chemistry.h treelog.h \
 block_model.h block_nested.h block.h frame_model.h geometry.h soil.h \
 surface.h uzmodel.h
weather_base${OBJ}: weather_base.C weather_base.h weather.h model_derived.h \
 model_logable.h model.h symbol.h im.h attribute.h fao.h assertion.h \
 time.h log.h border.h model_framed.h mathlib.h librarian.h block_model.h \
 block_nested.h block.h scope.h treelog.h frame_model.h frame.h units.h \
 memutils.h
volume_box${OBJ}: volume_box.C volume_box.h volume.h model_derived.h \
 model_logable.h model.h symbol.h bound.h border.h mathlib.h assertion.h \
 librarian.h treelog.h frame.h scope.h attribute.h block_model.h \
 block_nested.h block.h frame_model.h log.h time.h model_framed.h
movement_solute${OBJ}: movement_solute.C movement_solute.h movement.h \
 model_derived.h model_logable.h model.h symbol.h memutils.h geometry.h \
 attribute.h soil_water.h transport.h chemical.h model_framed.h \
 adsorption.h tertiary.h frame.h scope.h librarian.h block_model.h \
 block_nested.h block.h treelog.h frame_model.h assertion.h mathlib.h \
 log.h time.h border.h
scope_exchange${OBJ}: scope_exchange.C scope_exchange.h model.h symbol.h \
 scope_model.h scope.h attribute.h memutils.h block_model.h \
 block_nested.h block.h treelog.h frame_model.h frame.h assertion.h \
 librarian.h
photo_Farquhar${OBJ}: photo_Farquhar.C photo_Farquhar.h photo.h \
 model_derived.h model_logable.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h rubiscoNdist.h resistance.h stomatacon.h bioclimate.h \
 model_framed.h canopy_std.h canopy_simple.h plf.h phenology.h log.h \
 time.h border.h mathlib.h assertion.h check.h librarian.h fao.h
scope_multi${OBJ}: scope_multi.C scope_multi.h scope.h attribute.h symbol.h \
 assertion.h librarian.h model.h
scope_id${OBJ}: scope_id.C scope_id.h scope.h attribute.h symbol.h \
 assertion.h mathlib.h
geometry_vert${OBJ}: geometry_vert.C geometry_vert.h geometry.h symbol.h \
 attribute.h block_model.h block_nested.h block.h scope.h treelog.h \
 frame_model.h frame.h mathlib.h assertion.h
gnuplot_base${OBJ}: gnuplot_base.C gnuplot_base.h gnuplot.h model.h symbol.h \
 vcheck.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h frame_submodel.h assertion.h librarian.h
source_file${OBJ}: source_file.C source_file.h source.h model.h time.h \
 symbol.h lexer_table.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h memutils.h timestep.h \
 vcheck.h gnuplot_utils.h mathlib.h assertion.h submodeler.h \
 block_submodel.h frame_submodel.h
format_LaTeX${OBJ}: format_LaTeX.C format_LaTeX.h format.h model.h symbol.h \
 version.h assertion.h librarian.h frame.h scope.h attribute.h
log_all${OBJ}: log_all.C log_all.h log_select.h log.h time.h symbol.h \
 border.h model_framed.h model_logable.h model.h memutils.h select.h \
 destination.h units.h volume.h model_derived.h attribute.h metalib.h \
 frame.h scope.h library.h block_model.h block_nested.h block.h treelog.h \
 frame_model.h assertion.h field.h irrigate.h column.h
om${OBJ}: om.C om.h model_framed.h model_logable.h model.h symbol.h plf.h \
 som.h smb.h dom.h frame.h scope.h attribute.h check.h vcheck.h \
 geometry.h log.h time.h border.h mathlib.h assertion.h treelog.h \
 block_model.h block_nested.h block.h frame_model.h
select_value${OBJ}: select_value.C select_value.h select.h destination.h \
 symbol.h model.h units.h memutils.h volume.h model_derived.h \
 model_logable.h attribute.h block_model.h block_nested.h block.h scope.h \
 treelog.h frame_model.h frame.h librarian.h check.h
weather_old${OBJ}: weather_old.C weather_old.h weather_base.h weather.h \
 model_derived.h model_logable.h model.h symbol.h im.h attribute.h \
 block_model.h block_nested.h block.h scope.h treelog.h frame_model.h \
 frame.h librarian.h fao.h time.h units.h memutils.h
log_extern${OBJ}: log_extern.C log_extern.h log_select.h log.h time.h \
 symbol.h border.h model_framed.h model_logable.h model.h memutils.h \
 destination.h scope.h attribute.h select.h units.h volume.h \
 model_derived.h scope_block.h block.h block_model.h block_nested.h \
 treelog.h frame_model.h frame.h assertion.h librarian.h submodeler.h \
 block_submodel.h frame_submodel.h daisy.h program.h run.h
log_select${OBJ}: log_select.C log_select.h log.h time.h symbol.h border.h \
 model_framed.h model_logable.h model.h memutils.h select.h destination.h \
 units.h volume.h model_derived.h attribute.h condition.h metalib.h \
 frame.h scope.h library.h block_top.h block.h block_model.h \
 block_nested.h treelog.h frame_model.h field.h irrigate.h format.h \
 assertion.h librarian.h daisy.h program.h run.h
parser_file${OBJ}: parser_file.C parser_file.h parser.h model.h symbol.h \
 metalib.h frame.h scope.h attribute.h library.h block_model.h \
 block_nested.h block.h treelog.h frame_model.h block_top.h lexer.h \
 filepos.h number.h integer.h plf.h time.h treelog_text.h path.h units.h \
 memutils.h mathlib.h assertion.h librarian.h frame_submodel.h
geometry${OBJ}: geometry.C geometry.h symbol.h attribute.h volume.h \
 model_derived.h model_logable.h model.h check.h vcheck.h treelog.h \
 frame_submodel.h frame.h scope.h assertion.h mathlib.h librarian.h
log_alist${OBJ}: log_alist.C log_alist.h log.h time.h symbol.h border.h \
 model_framed.h model_logable.h model.h library.h frame_submodel.h \
 frame.h scope.h attribute.h frame_model.h assertion.h metalib.h
scope_xysources${OBJ}: scope_xysources.C scope_xysources.h scope.h \
 attribute.h symbol.h memutils.h xysource.h model.h treelog.h assertion.h \
 mathlib.h
lexer_flux${OBJ}: lexer_flux.C lexer_flux.h lexer_table.h block_model.h \
 block_nested.h block.h scope.h attribute.h symbol.h treelog.h \
 frame_model.h frame.h memutils.h geometry.h mathlib.h assertion.h
lexer_soil${OBJ}: lexer_soil.C lexer_soil.h lexer_table.h block_model.h \
 block_nested.h block.h scope.h attribute.h symbol.h treelog.h \
 frame_model.h frame.h memutils.h assertion.h
iterative${OBJ}: iterative.C iterative.h assertion.h treelog.h symbol.h
water${OBJ}: water.C water.h plf.h
block_nested${OBJ}: block_nested.C block_nested.h block.h scope.h attribute.h \
 symbol.h treelog.h frame.h
block_submodel${OBJ}: block_submodel.C block_submodel.h block_nested.h \
 block.h scope.h attribute.h symbol.h treelog.h frame_submodel.h frame.h \
 submodeler.h assertion.h
block_top${OBJ}: block_top.C block_top.h block.h scope.h attribute.h symbol.h
block_model${OBJ}: block_model.C block_model.h block_nested.h block.h scope.h \
 attribute.h symbol.h treelog.h frame_model.h frame.h
value${OBJ}: value.C value.h symbol.h attribute.h assertion.h
type${OBJ}: type.C type.h attribute.h symbol.h frame.h scope.h assertion.h \
 check.h
model_derived${OBJ}: model_derived.C model_derived.h model_logable.h model.h \
 symbol.h log.h time.h border.h model_framed.h
model_logable${OBJ}: model_logable.C model_logable.h model.h symbol.h
model_framed${OBJ}: model_framed.C model_framed.h model_logable.h model.h \
 symbol.h log.h time.h border.h frame_model.h frame.h scope.h attribute.h \
 assertion.h block_model.h block_nested.h block.h treelog.h
printer${OBJ}: printer.C printer.h symbol.h
printer_file${OBJ}: printer_file.C printer_file.h printer.h symbol.h \
 metalib.h frame.h scope.h attribute.h library.h block_model.h \
 block_nested.h block.h treelog.h frame_model.h plf.h time.h parser.h \
 model.h path.h assertion.h librarian.h frame_submodel.h filepos.h
filepos${OBJ}: filepos.C filepos.h symbol.h attribute.h
frame_submodel${OBJ}: frame_submodel.C frame_submodel.h frame.h scope.h \
 attribute.h symbol.h assertion.h
frame_model${OBJ}: frame_model.C frame_model.h frame.h scope.h attribute.h \
 symbol.h assertion.h treelog.h librarian.h model.h metalib.h library.h
scope${OBJ}: scope.C scope.h attribute.h symbol.h assertion.h
attribute${OBJ}: attribute.C attribute.h symbol.h assertion.h
unit${OBJ}: unit.C unit.h symbol.h
border${OBJ}: border.C border.h
resistance${OBJ}: resistance.C resistance.h net_radiation.h model_derived.h \
 model_logable.h model.h symbol.h assertion.h treelog.h mathlib.h \
 librarian.h
convert${OBJ}: convert.C convert.h
units${OBJ}: units.C units.h memutils.h symbol.h unit_model.h unit.h model.h \
 convert.h oldunits.h treelog.h assertion.h librarian.h metalib.h frame.h \
 scope.h attribute.h library.h frame_model.h
anystate${OBJ}: anystate.C anystate.h assertion.h
imvec${OBJ}: imvec.C imvec.h symbol.h attribute.h assertion.h log.h time.h \
 border.h model_framed.h model_logable.h model.h chemical.h check.h \
 block_model.h block_nested.h block.h scope.h treelog.h frame_model.h \
 frame.h units.h memutils.h frame_submodel.h
im${OBJ}: im.C im.h symbol.h attribute.h chemical.h model_framed.h \
 model_logable.h model.h units.h memutils.h unit.h am.h log.h time.h \
 border.h block.h scope.h frame_submodel.h frame.h check.h assertion.h
frame${OBJ}: frame.C frame.h scope.h attribute.h symbol.h frame_model.h \
 frame_submodel.h block_model.h block_nested.h block.h treelog.h \
 assertion.h librarian.h model.h intrinsics.h memutils.h library.h \
 filepos.h metalib.h type.h value.h check.h vcheck.h plf.h mathlib.h
bdconv${OBJ}: bdconv.C bdconv.h convert.h symbol.h geometry.h attribute.h \
 soil.h volume.h model_derived.h model_logable.h model.h units.h \
 memutils.h assertion.h
abiotic${OBJ}: abiotic.C abiotic.h mathlib.h assertion.h
scope_soil${OBJ}: scope_soil.C scope_soil.h scope.h attribute.h symbol.h \
 geometry.h soil.h soil_water.h soil_heat.h chemical.h model_framed.h \
 model_logable.h model.h units.h memutils.h assertion.h librarian.h
run${OBJ}: run.C run.h model.h
treelog_text${OBJ}: treelog_text.C treelog_text.h treelog.h symbol.h \
 assertion.h
treelog_store${OBJ}: treelog_store.C treelog_store.h treelog.h symbol.h \
 assertion.h treelog_text.h
intrinsics${OBJ}: intrinsics.C intrinsics.h memutils.h symbol.h assertion.h \
 library.h frame_submodel.h frame.h scope.h attribute.h librarian.h \
 model.h
metalib${OBJ}: metalib.C metalib.h symbol.h frame.h scope.h attribute.h \
 intrinsics.h memutils.h librarian.h model.h library.h block_model.h \
 block_nested.h block.h treelog.h frame_model.h assertion.h path.h \
 units.h unit_model.h unit.h
model${OBJ}: model.C model.h frame.h scope.h attribute.h symbol.h
output${OBJ}: output.C output.h condition.h model_framed.h model_logable.h \
 model.h symbol.h memutils.h time.h daisy.h program.h run.h log_all.h \
 log_select.h log.h border.h log_extern.h destination.h scope.h \
 attribute.h treelog.h timestep.h vcheck.h block_model.h block_nested.h \
 block.h frame_model.h frame.h assertion.h librarian.h scope_model.h
scope_block${OBJ}: scope_block.C scope_block.h scope.h attribute.h symbol.h \
 block.h library.h number.h model.h stringer.h frame.h assertion.h \
 librarian.h
librarian${OBJ}: librarian.C librarian.h model.h symbol.h library.h metalib.h \
 frame.h scope.h attribute.h intrinsics.h memutils.h block_top.h block.h \
 treelog_text.h treelog.h assertion.h frame_model.h block_model.h \
 block_nested.h
gnuplot_utils${OBJ}: gnuplot_utils.C gnuplot_utils.h symbol.h frame.h scope.h \
 attribute.h
scope_sources${OBJ}: scope_sources.C scope_sources.h scope.h attribute.h \
 symbol.h time.h memutils.h source.h model.h treelog.h assertion.h
scope_table${OBJ}: scope_table.C scope_table.h scope.h attribute.h symbol.h \
 lexer_table.h block_model.h block_nested.h block.h treelog.h \
 frame_model.h frame.h memutils.h assertion.h
lexer_table${OBJ}: lexer_table.C lexer_table.h block_model.h block_nested.h \
 block.h scope.h attribute.h symbol.h treelog.h frame_model.h frame.h \
 memutils.h lexer_data.h lexer.h filepos.h assertion.h mathlib.h \
 submodeler.h block_submodel.h frame_submodel.h time.h vcheck.h path.h
block${OBJ}: block.C block_model.h block_nested.h block.h scope.h attribute.h \
 symbol.h treelog.h frame_model.h frame.h metalib.h library.h librarian.h \
 model.h stringer.h number.h assertion.h scope_block.h
dlf${OBJ}: dlf.C dlf.h symbol.h volume.h model_derived.h model_logable.h \
 model.h assertion.h version.h daisy.h program.h run.h toplevel.h \
 metalib.h frame.h scope.h attribute.h frame_model.h
texture${OBJ}: texture.C texture.h plf.h assertion.h mathlib.h
destination${OBJ}: destination.C destination.h symbol.h
symbol${OBJ}: symbol.C symbol.h assertion.h
fao${OBJ}: fao.C fao.h assertion.h treelog.h symbol.h mathlib.h librarian.h \
 model.h
gaussj${OBJ}: gaussj.C gaussj.h mathlib.h assertion.h
vcheck${OBJ}: vcheck.C vcheck.h symbol.h units.h memutils.h metalib.h frame.h \
 scope.h attribute.h library.h time.h plf.h assertion.h mathlib.h \
 treelog.h frame_model.h
assertion${OBJ}: assertion.C assertion.h treelog.h symbol.h mathlib.h
xref${OBJ}: xref.C xref.h symbol.h traverse.h metalib.h frame.h scope.h \
 attribute.h library.h librarian.h model.h assertion.h frame_model.h
oldunits${OBJ}: oldunits.C oldunits.h symbol.h mathlib.h assertion.h \
 memutils.h attribute.h
check${OBJ}: check.C check.h mathlib.h assertion.h treelog.h symbol.h
check_range${OBJ}: check_range.C check_range.h check.h treelog.h symbol.h
path${OBJ}: path.C path.h symbol.h assertion.h w32reg.h version.h
traverse_delete${OBJ}: traverse_delete.C traverse_delete.h symbol.h \
 traverse.h metalib.h frame.h scope.h attribute.h library.h frame_model.h \
 assertion.h
traverse${OBJ}: traverse.C traverse.h symbol.h metalib.h frame.h scope.h \
 attribute.h library.h assertion.h librarian.h model.h frame_submodel.h \
 frame_model.h
treelog${OBJ}: treelog.C treelog.h symbol.h
lexer_data${OBJ}: lexer_data.C lexer_data.h lexer.h symbol.h filepos.h time.h \
 mathlib.h assertion.h
lexer${OBJ}: lexer.C lexer.h symbol.h filepos.h treelog.h
daisy${OBJ}: daisy.C daisy.h program.h model.h symbol.h run.h weather.h \
 model_derived.h model_logable.h im.h attribute.h groundwater.h horizon.h \
 output.h condition.h model_framed.h memutils.h time.h log.h border.h \
 parser.h nitrification.h bioclimate.h hydraulic.h field.h irrigate.h \
 harvest.h block_model.h block_nested.h block.h scope.h treelog.h \
 frame_model.h frame.h action.h timestep.h vcheck.h library.h \
 submodeler.h block_submodel.h frame_submodel.h column.h scopesel.h \
 mathlib.h assertion.h librarian.h metalib.h
library${OBJ}: library.C library.h symbol.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h assertion.h \
 memutils.h filepos.h
plf${OBJ}: plf.C plf.h assertion.h mathlib.h
mathlib${OBJ}: mathlib.C mathlib.h assertion.h
cdaisy${OBJ}: cdaisy.C scope.h attribute.h symbol.h block_model.h \
 block_nested.h block.h treelog.h frame_model.h frame.h metalib.h \
 library.h daisy.h program.h model.h run.h output.h condition.h \
 model_framed.h model_logable.h memutils.h time.h toplevel.h \
 parser_file.h parser.h field.h irrigate.h border.h column.h weather.h \
 model_derived.h im.h action.h horizon.h printer_file.h printer.h \
 version.h chemical.h assertion.h frame_submodel.h filepos.h
nrutil${OBJ}: nrutil.C
version${OBJ}: version.C
xysource_xycombine${OBJ}: xysource_xycombine.C xysource.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h gnuplot_utils.h number.h scope_xysources.h \
 memutils.h assertion.h librarian.h
xysource_flux${OBJ}: xysource_flux.C xysource.h model.h symbol.h \
 gnuplot_utils.h lexer_flux.h lexer_table.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h memutils.h \
 check.h vcheck.h geometry.h time.h units.h submodeler.h block_submodel.h \
 frame_submodel.h assertion.h mathlib.h librarian.h
gnuplot_soil${OBJ}: gnuplot_soil.C gnuplot_base.h gnuplot.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h lexer_soil.h lexer_table.h memutils.h mathlib.h \
 assertion.h librarian.h time.h units.h submodeler.h block_submodel.h \
 frame_submodel.h check.h vcheck.h
reaction_sorption${OBJ}: reaction_sorption.C reaction.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h chemistry.h \
 chemical.h geometry.h soil.h soil_water.h surface.h uzmodel.h log.h \
 time.h border.h assertion.h librarian.h mathlib.h check.h
hydraulic_B_C_inverse${OBJ}: hydraulic_B_C_inverse.C hydraulic.h \
 model_derived.h model_logable.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h check.h mathlib.h assertion.h librarian.h texture.h plf.h
program_osvaldo${OBJ}: program_osvaldo.C program.h model.h symbol.h run.h \
 librarian.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h mathlib.h assertion.h path.h
vegetation_permanent${OBJ}: vegetation_permanent.C vegetation.h \
 model_derived.h model_logable.h model.h symbol.h plf.h mathlib.h \
 assertion.h log.h time.h border.h model_framed.h root_system.h \
 rootdens.h ABAprod.h canopy_simple.h geometry.h attribute.h soil.h \
 crop.h am.h im.h aom.h om.h organic.h submodeler.h block_submodel.h \
 block_nested.h block.h scope.h treelog.h frame_submodel.h frame.h \
 check.h librarian.h bioclimate.h soil_heat.h block_model.h frame_model.h
litter${OBJ}: litter.C litter.h model.h symbol.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h mathlib.h \
 assertion.h librarian.h check.h
drain_lateral${OBJ}: drain_lateral.C drain.h model_derived.h model_logable.h \
 model.h symbol.h geometry.h attribute.h soil.h soil_water.h soil_heat.h \
 surface.h uzmodel.h librarian.h block_model.h block_nested.h block.h \
 scope.h treelog.h frame_model.h frame.h mathlib.h assertion.h log.h \
 time.h border.h model_framed.h check.h draineqd.h
hydraulic_MACRO${OBJ}: hydraulic_MACRO.C hydraulic.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h plf.h mathlib.h \
 assertion.h check.h librarian.h
program_cpedata${OBJ}: program_cpedata.C program.h model.h symbol.h run.h \
 lexer_table.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h memutils.h librarian.h assertion.h \
 time.h timestep.h vcheck.h mathlib.h
reaction_boundrel${OBJ}: reaction_boundrel.C reaction.h model_framed.h \
 model_logable.h model.h symbol.h log.h time.h border.h geometry.h \
 attribute.h chemical.h chemistry.h treelog.h block_model.h \
 block_nested.h block.h scope.h frame_model.h frame.h librarian.h
log_regress${OBJ}: log_regress.C log_dlf.h log_select.h log.h time.h symbol.h \
 border.h model_framed.h model_logable.h model.h memutils.h dlf.h \
 destination.h select.h units.h volume.h model_derived.h attribute.h \
 library.h block_model.h block_nested.h block.h scope.h treelog.h \
 frame_model.h frame.h timestep.h vcheck.h librarian.h scope_block.h \
 assertion.h
reaction_Morgan98${OBJ}: reaction_Morgan98.C reaction_colgen.h reaction.h \
 model_framed.h model_logable.h model.h symbol.h ponddamp.h mathlib.h \
 assertion.h check.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h librarian.h chemistry.h \
 chemical.h log.h time.h border.h rainergy.h
reaction_Styczen88${OBJ}: reaction_Styczen88.C reaction_colgen.h reaction.h \
 model_framed.h model_logable.h model.h symbol.h ponddamp.h mathlib.h \
 assertion.h check.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h librarian.h chemistry.h \
 chemical.h log.h time.h border.h geometry.h soil.h plf.h
program_GP2D${OBJ}: program_GP2D.C program.h model.h symbol.h run.h \
 geometry_rect.h geometry_vert.h geometry.h attribute.h rootdens.h \
 model_framed.h model_logable.h treelog.h block_model.h block_nested.h \
 block.h scope.h frame_model.h frame.h submodeler.h block_submodel.h \
 frame_submodel.h check.h librarian.h assertion.h
svat_ssoc${OBJ}: svat_ssoc.C svat.h model_derived.h model_logable.h model.h \
 symbol.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h librarian.h resistance.h fao.h \
 soil_heat.h bioclimate.h model_framed.h soil.h geometry.h weather.h im.h \
 vegetation.h assertion.h log.h time.h border.h mathlib.h solver.h \
 iterative.h
reaction_Jarvis99${OBJ}: reaction_Jarvis99.C reaction_colgen.h reaction.h \
 model_framed.h model_logable.h model.h symbol.h ponddamp.h mathlib.h \
 assertion.h check.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h librarian.h chemistry.h \
 chemical.h log.h time.h border.h geometry.h soil.h surface.h uzmodel.h \
 rainergy.h plf.h
reaction_filter${OBJ}: reaction_filter.C reaction.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h transform.h \
 chemistry.h chemical.h soil.h soil_water.h log.h time.h border.h \
 assertion.h librarian.h check.h mathlib.h
seed_LAI${OBJ}: seed_LAI.C seed.h model_derived.h model_logable.h model.h \
 symbol.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h librarian.h plf.h log.h time.h border.h \
 model_framed.h
seed_release${OBJ}: seed_release.C seed.h model_derived.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h librarian.h log.h time.h \
 border.h model_framed.h check.h
stomatacon_SHA${OBJ}: stomatacon_SHA.C stomatacon.h model_logable.h model.h \
 symbol.h mathlib.h assertion.h check.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h librarian.h
tertiary_old${OBJ}: tertiary_old.C tertiary.h model_derived.h model_logable.h \
 model.h symbol.h geometry1d.h geometry_vert.h geometry.h attribute.h \
 soil.h soil_water.h chemical.h model_framed.h macro.h mactrans.h \
 librarian.h block_model.h block_nested.h block.h scope.h treelog.h \
 frame_model.h frame.h surface.h uzmodel.h groundwater.h
biopore_drain${OBJ}: biopore_drain.C biopore.h model_framed.h model_logable.h \
 model.h symbol.h number.h im.h attribute.h block_model.h block_nested.h \
 block.h scope.h treelog.h frame_model.h frame.h vcheck.h librarian.h \
 submodeler.h block_submodel.h frame_submodel.h check.h geometry.h soil.h \
 anystate.h chemical.h groundwater.h model_derived.h assertion.h \
 mathlib.h
tertiary_biopores${OBJ}: tertiary_biopores.C tertiary.h model_derived.h \
 model_logable.h model.h symbol.h biopore.h model_framed.h number.h im.h \
 attribute.h memutils.h librarian.h block_model.h block_nested.h block.h \
 scope.h treelog.h frame_model.h frame.h check.h vcheck.h geometry.h \
 soil.h soil_water.h soil_heat.h log.h time.h border.h anystate.h \
 surface.h uzmodel.h chemical.h groundwater.h units.h assertion.h \
 mathlib.h
biopore_matrix${OBJ}: biopore_matrix.C biopore.h model_framed.h \
 model_logable.h model.h symbol.h number.h im.h attribute.h imvec.h \
 block_model.h block_nested.h block.h scope.h treelog.h frame_model.h \
 frame.h vcheck.h librarian.h submodeler.h block_submodel.h \
 frame_submodel.h geometry.h soil.h volume_box.h volume.h model_derived.h \
 log.h time.h border.h check.h anystate.h chemical.h groundwater.h \
 mathlib.h assertion.h
transport_Mollerup${OBJ}: transport_Mollerup.C transport.h model.h symbol.h \
 geometry_rect.h geometry_vert.h geometry.h attribute.h soil.h solver.h \
 log.h time.h border.h model_framed.h model_logable.h frame.h scope.h \
 submodeler.h block_submodel.h block_nested.h block.h treelog.h \
 frame_submodel.h memutils.h librarian.h mathlib.h assertion.h \
 block_model.h frame_model.h
transport_Hansen${OBJ}: transport_Hansen.C transport.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h geometry1d.h geometry_vert.h geometry.h soil.h \
 adsorption.h model_derived.h model_logable.h log.h time.h border.h \
 model_framed.h mathlib.h assertion.h librarian.h
movement_1D${OBJ}: movement_1D.C movement_solute.h movement.h model_derived.h \
 model_logable.h model.h symbol.h memutils.h geometry1d.h geometry_vert.h \
 geometry.h attribute.h soil.h soil_water.h soil_heat.h groundwater.h \
 surface.h uzmodel.h weather.h im.h chemical.h model_framed.h doe.h \
 transport.h adsorption.h log.h time.h border.h submodeler.h \
 block_submodel.h block_nested.h block.h scope.h treelog.h \
 frame_submodel.h frame.h librarian.h tertiary.h assertion.h mathlib.h \
 block_model.h frame_model.h
groundwater_aquitard${OBJ}: groundwater_aquitard.C groundwater.h \
 model_derived.h model_logable.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h librarian.h check.h assertion.h depth.h geometry.h soil_water.h \
 log.h time.h border.h model_framed.h
heatrect_Mollerup${OBJ}: heatrect_Mollerup.C heatrect.h model.h symbol.h \
 solver.h geometry_rect.h geometry_vert.h geometry.h attribute.h plf.h \
 block_model.h block_nested.h block.h scope.h treelog.h frame_model.h \
 frame.h librarian.h assertion.h
heatrect_linear${OBJ}: heatrect_linear.C heatrect.h model.h symbol.h \
 geometry_rect.h geometry_vert.h geometry.h attribute.h plf.h librarian.h \
 frame.h scope.h
heatrect_none${OBJ}: heatrect_none.C heatrect.h model.h symbol.h librarian.h \
 frame.h scope.h attribute.h
transport_convection${OBJ}: transport_convection.C transport.h model.h \
 symbol.h geometry.h attribute.h soil.h adsorption.h model_derived.h \
 model_logable.h submodeler.h block_submodel.h block_nested.h block.h \
 scope.h treelog.h frame_submodel.h frame.h memutils.h librarian.h log.h \
 time.h border.h model_framed.h mathlib.h assertion.h
ABAprod_uptake${OBJ}: ABAprod_uptake.C ABAprod.h model_derived.h \
 model_logable.h model.h symbol.h number.h scope_id.h scope.h attribute.h \
 geometry.h soil_water.h units.h memutils.h assertion.h librarian.h \
 frame.h treelog.h mathlib.h block_model.h block_nested.h block.h \
 frame_model.h
ABAprod_soil${OBJ}: ABAprod_soil.C ABAprod.h model_derived.h model_logable.h \
 model.h symbol.h number.h scope_exchange.h scope_model.h scope.h \
 attribute.h memutils.h geometry.h soil_water.h assertion.h librarian.h \
 frame.h block_model.h block_nested.h block.h treelog.h frame_model.h
ABAprod_root${OBJ}: ABAprod_root.C ABAprod.h model_derived.h model_logable.h \
 model.h symbol.h number.h scope_id.h scope.h attribute.h geometry.h \
 soil_water.h units.h memutils.h assertion.h librarian.h frame.h \
 treelog.h block_model.h block_nested.h block.h frame_model.h
solver_ublas${OBJ}: solver_ublas.C solver.h model.h symbol.h assertion.h \
 librarian.h frame.h scope.h attribute.h
solver_cxsparse${OBJ}: solver_cxsparse.C solver.h model.h symbol.h \
 librarian.h ublas_cxsparse.h frame.h scope.h attribute.h
solver_none${OBJ}: solver_none.C solver.h model.h symbol.h librarian.h \
 frame.h scope.h attribute.h
movement_rect${OBJ}: movement_rect.C movement_solute.h movement.h \
 model_derived.h model_logable.h model.h symbol.h memutils.h \
 geometry_rect.h geometry_vert.h geometry.h attribute.h heatrect.h soil.h \
 soil_water.h soil_heat.h transport.h chemical.h model_framed.h \
 groundwater.h surface.h uzmodel.h weather.h im.h uzrect.h adsorption.h \
 log.h time.h border.h check.h frame_submodel.h frame.h scope.h \
 submodeler.h block_submodel.h block_nested.h block.h treelog.h \
 tertiary.h librarian.h anystate.h mathlib.h assertion.h block_model.h \
 frame_model.h
chemistry_multi${OBJ}: chemistry_multi.C chemistry.h model_framed.h \
 model_logable.h model.h symbol.h chemical.h log.h time.h border.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h assertion.h memutils.h librarian.h vcheck.h \
 check.h mathlib.h
equil_goal${OBJ}: equil_goal.C equil.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h scope_soil.h number.h check.h mathlib.h assertion.h librarian.h
equil_linear${OBJ}: equil_linear.C equil.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h number.h check.h mathlib.h assertion.h librarian.h
equil_langmuir${OBJ}: equil_langmuir.C equil.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h number.h soil.h check.h mathlib.h assertion.h librarian.h
transform_equil${OBJ}: transform_equil.C transform.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h soil.h soil_water.h equil.h scope_soil.h number.h \
 units.h memutils.h check.h mathlib.h assertion.h librarian.h
reaction_nit${OBJ}: reaction_nit.C reaction.h model_framed.h model_logable.h \
 model.h symbol.h geometry.h attribute.h soil.h soil_water.h soil_heat.h \
 chemistry.h chemical.h organic.h model_derived.h log.h time.h border.h \
 assertion.h librarian.h frame.h scope.h treelog.h
reaction_denit${OBJ}: reaction_denit.C reaction.h model_framed.h \
 model_logable.h model.h symbol.h abiotic.h librarian.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h geometry.h soil.h soil_water.h soil_heat.h organic.h \
 model_derived.h chemistry.h chemical.h plf.h log.h time.h border.h \
 check.h mathlib.h assertion.h
reaction_adsorption${OBJ}: reaction_adsorption.C reaction.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h number.h \
 adsorption.h model_derived.h chemistry.h chemical.h geometry.h soil.h \
 soil_water.h scope_soil.h units.h memutils.h log.h time.h border.h \
 assertion.h librarian.h mathlib.h
reaction_equil${OBJ}: reaction_equil.C reaction.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h number.h equil.h \
 chemistry.h chemical.h geometry.h soil.h soil_water.h scope_soil.h \
 surface.h uzmodel.h log.h time.h border.h assertion.h librarian.h \
 mathlib.h scope_id.h scope_multi.h vcheck.h
rootdens_GP2D${OBJ}: rootdens_GP2D.C rootdens.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h geometry.h log.h \
 time.h border.h check.h mathlib.h assertion.h librarian.h iterative.h \
 metalib.h library.h
rootdens_GP1D${OBJ}: rootdens_GP1D.C rootdens.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h geometry.h log.h \
 time.h border.h check.h mathlib.h assertion.h librarian.h iterative.h
number_plf${OBJ}: number_plf.C number.h symbol.h model.h plf.h units.h \
 memutils.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h librarian.h submodeler.h \
 block_submodel.h frame_submodel.h metalib.h
rubiscoNdist_forced${OBJ}: rubiscoNdist_forced.C rubiscoNdist.h \
 model_logable.h model.h symbol.h mathlib.h assertion.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h check.h librarian.h number.h scope_exchange.h scope_model.h \
 memutils.h
action_extern${OBJ}: action_extern.C action.h model_framed.h model_logable.h \
 model.h symbol.h scope_multi.h scope.h attribute.h scopesel.h number.h \
 daisy.h program.h run.h field.h irrigate.h memutils.h border.h am.h im.h \
 chemical.h log.h time.h treelog.h librarian.h block_model.h \
 block_nested.h block.h frame_model.h frame.h check.h assertion.h units.h \
 metalib.h library.h volume.h model_derived.h
rubiscoNdist_expr${OBJ}: rubiscoNdist_expr.C rubiscoNdist.h model_logable.h \
 model.h symbol.h mathlib.h assertion.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h check.h \
 librarian.h number.h scope_exchange.h scope_model.h memutils.h
uzrect_const${OBJ}: uzrect_const.C uzrect.h model_framed.h model_logable.h \
 model.h symbol.h geometry_rect.h geometry_vert.h geometry.h attribute.h \
 soil_water.h block_model.h block_nested.h block.h scope.h treelog.h \
 frame_model.h frame.h mathlib.h assertion.h librarian.h
photo_FCC3${OBJ}: photo_FCC3.C photo_Farquhar.h photo.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h rubiscoNdist.h \
 bioclimate.h model_framed.h canopy_std.h canopy_simple.h plf.h \
 phenology.h log.h time.h border.h mathlib.h assertion.h check.h \
 librarian.h
photo_FCC4${OBJ}: photo_FCC4.C photo_Farquhar.h photo.h model_derived.h \
 model_logable.h model.h symbol.h rubiscoNdist.h bioclimate.h \
 model_framed.h canopy_std.h canopy_simple.h plf.h phenology.h log.h \
 time.h border.h frame.h scope.h attribute.h block_model.h block_nested.h \
 block.h treelog.h frame_model.h mathlib.h assertion.h check.h \
 librarian.h resistance.h
reaction_std${OBJ}: reaction_std.C reaction.h model_framed.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h transform.h chemistry.h \
 chemical.h soil.h log.h time.h border.h assertion.h librarian.h
chemistry_std${OBJ}: chemistry_std.C chemistry.h model_framed.h \
 model_logable.h model.h symbol.h chemical.h reaction.h movement.h \
 model_derived.h geometry.h attribute.h soil.h soil_water.h surface.h \
 uzmodel.h block_model.h block_nested.h block.h scope.h treelog.h \
 frame_model.h frame.h log.h time.h border.h assertion.h memutils.h \
 librarian.h vcheck.h mathlib.h
groundwater_extern${OBJ}: groundwater_extern.C groundwater.h model_derived.h \
 model_logable.h model.h symbol.h output.h condition.h model_framed.h \
 memutils.h time.h number.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h units.h check.h assertion.h \
 librarian.h
transport_none${OBJ}: transport_none.C transport.h model.h symbol.h \
 geometry.h attribute.h soil.h adsorption.h model_derived.h \
 model_logable.h submodeler.h block_submodel.h block_nested.h block.h \
 scope.h treelog.h frame_submodel.h frame.h memutils.h librarian.h \
 mathlib.h assertion.h
uzrect_Mollerup${OBJ}: uzrect_Mollerup.C uzrect.h model_framed.h \
 model_logable.h model.h symbol.h geometry_rect.h geometry_vert.h \
 geometry.h attribute.h soil.h soil_water.h soil_heat.h groundwater.h \
 model_derived.h surface.h uzmodel.h solver.h log.h time.h border.h \
 frame.h scope.h block_model.h block_nested.h block.h treelog.h \
 frame_model.h mathlib.h assertion.h librarian.h anystate.h condedge.h
groundwater_flux${OBJ}: groundwater_flux.C groundwater.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h check.h librarian.h
rubiscoNdist_uniform${OBJ}: rubiscoNdist_uniform.C rubiscoNdist.h \
 model_logable.h model.h symbol.h mathlib.h assertion.h check.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h librarian.h
uzrect_2x1${OBJ}: uzrect_2x1.C uzrect.h model_framed.h model_logable.h \
 model.h symbol.h uzmodel.h uz1d.h geometry_rect.h geometry_vert.h \
 geometry.h attribute.h soil.h soil_water.h soil_heat.h groundwater.h \
 model_derived.h surface.h frame.h scope.h mathlib.h assertion.h \
 memutils.h librarian.h treelog.h block_model.h block_nested.h block.h \
 frame_model.h
select_flow${OBJ}: select_flow.C select_value.h select.h destination.h \
 symbol.h model.h units.h memutils.h volume.h model_derived.h \
 model_logable.h attribute.h block_model.h block_nested.h block.h scope.h \
 treelog.h frame_model.h frame.h border.h column.h model_framed.h \
 irrigate.h geometry.h librarian.h assertion.h mathlib.h
select_volume${OBJ}: select_volume.C select_value.h select.h destination.h \
 symbol.h model.h units.h memutils.h volume.h model_derived.h \
 model_logable.h attribute.h bdconv.h convert.h block_model.h \
 block_nested.h block.h scope.h treelog.h frame_model.h frame.h \
 geometry.h soil.h vegetation.h check.h librarian.h assertion.h mathlib.h \
 column.h model_framed.h irrigate.h
uz1d_none${OBJ}: uz1d_none.C uz1d.h model.h geometry_rect.h geometry_vert.h \
 geometry.h symbol.h attribute.h soil.h soil_water.h soil_heat.h \
 librarian.h
condition_walltime${OBJ}: condition_walltime.C condition.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h librarian.h
uz1d_richard${OBJ}: uz1d_richard.C uz1d.h model.h geometry_rect.h \
 geometry_vert.h geometry.h symbol.h attribute.h soil.h soil_water.h \
 soil_heat.h block_model.h block_nested.h block.h scope.h treelog.h \
 frame_model.h frame.h average.h librarian.h assertion.h mathlib.h
rubiscoNdist_DPF${OBJ}: rubiscoNdist_DPF.C rubiscoNdist.h model_logable.h \
 model.h symbol.h mathlib.h assertion.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h check.h \
 librarian.h
raddist_DPF${OBJ}: raddist_DPF.C raddist.h model_derived.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h vegetation.h weather.h im.h \
 mathlib.h assertion.h check.h librarian.h log.h time.h border.h \
 model_framed.h
raddist_std${OBJ}: raddist_std.C raddist.h model_derived.h model_logable.h \
 model.h symbol.h vegetation.h mathlib.h assertion.h librarian.h frame.h \
 scope.h attribute.h
difrad_DPF${OBJ}: difrad_DPF.C difrad.h model_framed.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h weather.h model_derived.h \
 im.h fao.h mathlib.h assertion.h check.h librarian.h
difrad_weather${OBJ}: difrad_weather.C difrad.h model_framed.h \
 model_logable.h model.h symbol.h weather.h model_derived.h im.h \
 attribute.h mathlib.h assertion.h librarian.h treelog.h
number_lisp${OBJ}: number_lisp.C number.h symbol.h model.h boolean.h \
 scope_multi.h scope.h attribute.h submodeler.h block_submodel.h \
 block_nested.h block.h treelog.h frame_submodel.h frame.h memutils.h \
 librarian.h assertion.h block_model.h frame_model.h
condition_extern${OBJ}: condition_extern.C condition.h model_framed.h \
 model_logable.h model.h symbol.h daisy.h program.h run.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h boolean.h output.h memutils.h time.h scope_multi.h scopesel.h \
 librarian.h assertion.h
condition_boolean${OBJ}: condition_boolean.C condition.h model_framed.h \
 model_logable.h model.h symbol.h boolean.h scope.h attribute.h \
 librarian.h assertion.h daisy.h program.h run.h treelog.h frame.h \
 block_model.h block_nested.h block.h frame_model.h
boolean_number${OBJ}: boolean_number.C boolean.h model.h symbol.h frame.h \
 scope.h attribute.h number.h memutils.h librarian.h treelog.h \
 block_model.h block_nested.h block.h frame_model.h
boolean_string${OBJ}: boolean_string.C boolean.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h librarian.h
number_soil${OBJ}: number_soil.C number.h symbol.h model.h metalib.h frame.h \
 scope.h attribute.h library.h block_model.h block_nested.h block.h \
 treelog.h frame_model.h column.h model_framed.h model_logable.h \
 irrigate.h memutils.h horizon.h model_derived.h hydraulic.h weather.h \
 im.h output.h condition.h time.h librarian.h units.h
organic_none${OBJ}: organic_none.C organic.h model_derived.h model_logable.h \
 model.h symbol.h geometry.h attribute.h librarian.h frame.h scope.h
organic_std${OBJ}: organic_std.C organic.h model_derived.h model_logable.h \
 model.h symbol.h frame_submodel.h frame.h scope.h attribute.h \
 frame_model.h submodeler.h block_submodel.h block_nested.h block.h \
 treelog.h log.h time.h border.h model_framed.h am.h im.h om.h plf.h \
 som.h smb.h dom.h domsorp.h aom.h clayom.h soil.h geometry.h \
 soil_water.h soil_heat.h chemistry.h chemical.h bioincorporation.h \
 abiotic.h mathlib.h assertion.h check_range.h check.h vcheck.h gaussj.h \
 memutils.h librarian.h library.h metalib.h block_model.h column.h \
 irrigate.h
integer_arit${OBJ}: integer_arit.C integer.h model.h symbol.h vcheck.h \
 assertion.h memutils.h librarian.h treelog.h frame.h scope.h attribute.h \
 block_model.h block_nested.h block.h frame_model.h
source_merge${OBJ}: source_merge.C source.h model.h time.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h gnuplot_utils.h units.h memutils.h vcheck.h \
 mathlib.h assertion.h librarian.h
number_source${OBJ}: number_source.C number.h symbol.h model.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h source.h time.h assertion.h librarian.h
program_file${OBJ}: program_file.C program.h model.h symbol.h run.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h path.h librarian.h
action_table${OBJ}: action_table.C action.h model_framed.h model_logable.h \
 model.h symbol.h metalib.h frame.h scope.h attribute.h library.h daisy.h \
 program.h run.h field.h irrigate.h memutils.h border.h am.h im.h units.h \
 lexer_table.h block_model.h block_nested.h block.h treelog.h \
 frame_model.h mathlib.h assertion.h librarian.h volume.h model_derived.h \
 check.h time.h
xysource_merge${OBJ}: xysource_merge.C xysource.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h gnuplot_utils.h number.h scope_sources.h time.h \
 memutils.h units.h vcheck.h librarian.h
xysource_inline${OBJ}: xysource_inline.C xysource.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h gnuplot_utils.h number.h vcheck.h assertion.h \
 librarian.h plf.h
xysource_loop${OBJ}: xysource_loop.C xysource.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h gnuplot_utils.h scope_id.h number.h check.h \
 vcheck.h assertion.h librarian.h
xysource_combine${OBJ}: xysource_combine.C xysource.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h gnuplot_utils.h number.h scope_sources.h time.h \
 memutils.h source.h assertion.h librarian.h
gnuplot_xy${OBJ}: gnuplot_xy.C gnuplot_base.h gnuplot.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h xysource.h mathlib.h assertion.h memutils.h \
 librarian.h
xysource_expr${OBJ}: xysource_expr.C xysource.h model.h symbol.h \
 lexer_table.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h memutils.h scope_table.h gnuplot_utils.h \
 number.h vcheck.h assertion.h librarian.h
gnuplot_multi${OBJ}: gnuplot_multi.C gnuplot.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h source.h time.h memutils.h librarian.h
gnuplot_time${OBJ}: gnuplot_time.C gnuplot_base.h gnuplot.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h source.h time.h mathlib.h assertion.h memutils.h \
 librarian.h
source_combine${OBJ}: source_combine.C source.h model.h time.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h number.h scope_sources.h memutils.h \
 gnuplot_utils.h vcheck.h assertion.h librarian.h
number_arit${OBJ}: number_arit.C number.h symbol.h model.h units.h memutils.h \
 vcheck.h mathlib.h assertion.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h librarian.h \
 submodeler.h block_submodel.h frame_submodel.h
source_expr${OBJ}: source_expr.C source_file.h source.h model.h time.h \
 symbol.h lexer_table.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h memutils.h timestep.h \
 vcheck.h scope_table.h boolean.h number.h librarian.h units.h
source_std${OBJ}: source_std.C source_file.h source.h model.h time.h symbol.h \
 lexer_table.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h memutils.h timestep.h vcheck.h units.h \
 librarian.h
action_markvand${OBJ}: action_markvand.C action.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h daisy.h program.h \
 run.h field.h irrigate.h memutils.h border.h crop.h time.h im.h fao.h \
 log.h mathlib.h assertion.h check.h vcheck.h librarian.h vegetation.h \
 model_derived.h submodeler.h block_submodel.h frame_submodel.h
photo_GL${OBJ}: photo_GL.C photo.h model_derived.h model_logable.h model.h \
 symbol.h block_model.h block_nested.h block.h scope.h attribute.h \
 treelog.h frame_model.h frame.h canopy_std.h canopy_simple.h plf.h \
 phenology.h mathlib.h assertion.h check.h librarian.h
program_gnuplot${OBJ}: program_gnuplot.C program.h model.h symbol.h run.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h gnuplot.h path.h memutils.h librarian.h
program_document${OBJ}: program_document.C program.h model.h symbol.h run.h \
 library.h metalib.h frame.h scope.h attribute.h block_model.h \
 block_nested.h block.h treelog.h frame_model.h printer_file.h printer.h \
 xref.h plf.h format.h assertion.h librarian.h frame_submodel.h filepos.h
program_batch${OBJ}: program_batch.C program.h model.h symbol.h run.h \
 block_top.h block.h scope.h attribute.h block_model.h block_nested.h \
 treelog.h frame_model.h frame.h path.h assertion.h memutils.h \
 librarian.h metalib.h
summary_balance${OBJ}: summary_balance.C summary.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h fetch_pretty.h fetch.h destination.h select.h \
 units.h memutils.h volume.h model_derived.h model_logable.h librarian.h
rootdens_AP${OBJ}: rootdens_AP.C rootdens.h model_framed.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h geometry.h log.h time.h \
 border.h plf.h check.h mathlib.h assertion.h librarian.h
number_const${OBJ}: number_const.C number.h symbol.h model.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h units.h memutils.h unit.h assertion.h librarian.h library.h
domsorp_std${OBJ}: domsorp_std.C domsorp.h model_framed.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h transform.h dom.h plf.h \
 som.h om.h soil.h log.h time.h border.h assertion.h librarian.h
horizon_numeric${OBJ}: horizon_numeric.C horizon.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h texture.h plf.h \
 hydraulic.h check.h vcheck.h mathlib.h assertion.h librarian.h
horizon_system${OBJ}: horizon_system.C horizon.h model_derived.h \
 model_logable.h model.h symbol.h library.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h texture.h \
 plf.h hydraulic.h check.h mathlib.h assertion.h librarian.h
pet_FAO_PM${OBJ}: pet_FAO_PM.C pet.h model_framed.h model_logable.h model.h \
 symbol.h fao.h weather.h model_derived.h im.h attribute.h soil.h \
 surface.h uzmodel.h soil_heat.h vegetation.h log.h time.h border.h \
 librarian.h frame.h scope.h block_model.h block_nested.h block.h \
 treelog.h frame_model.h net_radiation.h
pet_Hargreaves${OBJ}: pet_Hargreaves.C pet.h model_framed.h model_logable.h \
 model.h symbol.h weather.h model_derived.h im.h attribute.h fao.h log.h \
 time.h border.h mathlib.h assertion.h librarian.h frame.h scope.h
hydraulic_M_vGp${OBJ}: hydraulic_M_vGp.C hydraulic.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h plf.h mathlib.h \
 assertion.h check.h librarian.h
summary_simple${OBJ}: summary_simple.C summary.h model.h symbol.h \
 fetch_pretty.h fetch.h destination.h select.h units.h memutils.h \
 volume.h model_derived.h model_logable.h attribute.h treelog.h \
 submodeler.h block_submodel.h block_nested.h block.h scope.h \
 frame_submodel.h frame.h librarian.h block_model.h frame_model.h
phenology_TSum${OBJ}: phenology_TSum.C phenology.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h production.h \
 vernalization.h plf.h assertion.h librarian.h
phenology_std${OBJ}: phenology_std.C phenology.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h production.h \
 vernalization.h plf.h mathlib.h assertion.h librarian.h
hydraulic_hypres${OBJ}: hydraulic_hypres.C hydraulic.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h texture.h plf.h \
 mathlib.h assertion.h librarian.h
clayom_biomod${OBJ}: clayom_biomod.C clayom.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h check.h smb.h om.h model_framed.h model_logable.h plf.h soil.h \
 mathlib.h assertion.h librarian.h
clayom_old${OBJ}: clayom_old.C clayom.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h plf.h smb.h om.h model_framed.h model_logable.h soil.h \
 assertion.h librarian.h
hydraulic_Cosby${OBJ}: hydraulic_Cosby.C hydraulic.h model_derived.h \
 model_logable.h model.h symbol.h texture.h plf.h treelog.h mathlib.h \
 assertion.h librarian.h frame.h scope.h attribute.h
condition_weather${OBJ}: condition_weather.C condition.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h field.h irrigate.h \
 memutils.h border.h daisy.h program.h run.h check.h log.h time.h \
 librarian.h
rootdens_PLF${OBJ}: rootdens_PLF.C rootdens.h model_framed.h model_logable.h \
 model.h symbol.h geometry.h attribute.h plf.h submodeler.h \
 block_submodel.h block_nested.h block.h scope.h treelog.h \
 frame_submodel.h frame.h check.h vcheck.h mathlib.h assertion.h \
 memutils.h librarian.h block_model.h frame_model.h
rootdens_G_P${OBJ}: rootdens_G_P.C rootdens.h model_framed.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h geometry.h log.h time.h \
 border.h check.h mathlib.h assertion.h librarian.h
groundwater_file${OBJ}: groundwater_file.C groundwater.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h lexer_data.h lexer.h \
 filepos.h assertion.h time.h librarian.h path.h
action_fertilize${OBJ}: action_fertilize.C action.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h daisy.h program.h \
 run.h field.h irrigate.h memutils.h border.h am.h im.h check.h \
 assertion.h librarian.h volume.h model_derived.h units.h \
 frame_submodel.h
action_repeat${OBJ}: action_repeat.C action.h model_framed.h model_logable.h \
 model.h symbol.h daisy.h program.h run.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h log.h time.h \
 border.h librarian.h assertion.h
vegetation_crops${OBJ}: vegetation_crops.C vegetation.h model_derived.h \
 model_logable.h model.h symbol.h crop.h model_framed.h time.h organic.h \
 geometry.h attribute.h soil.h plf.h mathlib.h assertion.h harvest.h \
 block_model.h block_nested.h block.h scope.h treelog.h frame_model.h \
 frame.h log.h border.h librarian.h metalib.h frame_submodel.h
crop_simple${OBJ}: crop_simple.C crop.h model_framed.h model_logable.h \
 model.h symbol.h time.h root_system.h rootdens.h ABAprod.h \
 model_derived.h plf.h canopy_simple.h log.h border.h bioclimate.h \
 soil_water.h geometry.h attribute.h soil.h aom.h om.h organic.h \
 soil_heat.h am.h im.h harvest.h block_model.h block_nested.h block.h \
 scope.h treelog.h frame_model.h frame.h submodeler.h block_submodel.h \
 frame_submodel.h mathlib.h assertion.h check.h librarian.h
action_ridge${OBJ}: action_ridge.C action.h model_framed.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h daisy.h program.h run.h \
 field.h irrigate.h memutils.h border.h ridge.h librarian.h
groundwater_fixed${OBJ}: groundwater_fixed.C groundwater.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h check.h assertion.h \
 librarian.h
groundwater_deep${OBJ}: groundwater_deep.C groundwater.h model_derived.h \
 model_logable.h model.h symbol.h assertion.h librarian.h frame.h scope.h \
 attribute.h
action_heat${OBJ}: action_heat.C action.h model_framed.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h daisy.h program.h run.h \
 field.h irrigate.h memutils.h border.h check.h librarian.h
hydraulic_M_vG_compact${OBJ}: hydraulic_M_vG_compact.C hydraulic.h \
 model_derived.h model_logable.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h plf.h mathlib.h assertion.h librarian.h
action_crop${OBJ}: action_crop.C action.h model_framed.h model_logable.h \
 model.h symbol.h daisy.h program.h run.h field.h irrigate.h memutils.h \
 border.h crop.h time.h am.h im.h attribute.h log.h harvest.h \
 block_model.h block_nested.h block.h scope.h treelog.h frame_model.h \
 frame.h check_range.h check.h submodeler.h block_submodel.h \
 frame_submodel.h vcheck.h mathlib.h assertion.h librarian.h vegetation.h \
 model_derived.h units.h
groundwater_lysimeter${OBJ}: groundwater_lysimeter.C groundwater.h \
 model_derived.h model_logable.h model.h symbol.h geometry.h attribute.h \
 assertion.h librarian.h
action_message${OBJ}: action_message.C action.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h condition.h log.h \
 time.h border.h daisy.h program.h run.h librarian.h
weather_std${OBJ}: weather_std.C weather_base.h weather.h model_derived.h \
 model_logable.h model.h symbol.h im.h attribute.h chemical.h \
 model_framed.h fao.h lexer_data.h lexer.h filepos.h time.h plf.h \
 mathlib.h assertion.h units.h memutils.h submodeler.h block_submodel.h \
 block_nested.h block.h scope.h treelog.h frame_submodel.h frame.h \
 check.h vcheck.h librarian.h path.h block_model.h frame_model.h
groundwater_pipe${OBJ}: groundwater_pipe.C groundwater.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h log.h time.h \
 border.h model_framed.h geometry.h soil.h soil_heat.h soil_water.h \
 depth.h mathlib.h assertion.h check.h librarian.h
select_index${OBJ}: select_index.C select_value.h select.h destination.h \
 symbol.h model.h units.h memutils.h volume.h model_derived.h \
 model_logable.h attribute.h block_model.h block_nested.h block.h scope.h \
 treelog.h frame_model.h frame.h librarian.h vcheck.h
select_content${OBJ}: select_content.C select_value.h select.h destination.h \
 symbol.h model.h units.h memutils.h volume.h model_derived.h \
 model_logable.h attribute.h block_model.h block_nested.h block.h scope.h \
 treelog.h frame_model.h frame.h geometry.h soil.h check.h mathlib.h \
 assertion.h librarian.h column.h model_framed.h irrigate.h
select_number${OBJ}: select_number.C select_value.h select.h destination.h \
 symbol.h model.h units.h memutils.h volume.h model_derived.h \
 model_logable.h attribute.h librarian.h frame.h scope.h
select_array${OBJ}: select_array.C select.h destination.h symbol.h model.h \
 units.h memutils.h volume.h model_derived.h model_logable.h attribute.h \
 soil.h bdconv.h convert.h block_model.h block_nested.h block.h scope.h \
 treelog.h frame_model.h frame.h mathlib.h assertion.h librarian.h \
 column.h model_framed.h irrigate.h
log_table${OBJ}: log_table.C log_dlf.h log_select.h log.h time.h symbol.h \
 border.h model_framed.h model_logable.h model.h memutils.h dlf.h \
 destination.h select.h units.h volume.h model_derived.h attribute.h \
 library.h block_model.h block_nested.h block.h scope.h treelog.h \
 frame_model.h frame.h summary.h timestep.h vcheck.h librarian.h \
 scope_block.h assertion.h
log_harvest${OBJ}: log_harvest.C log.h time.h symbol.h border.h \
 model_framed.h model_logable.h model.h daisy.h program.h run.h harvest.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h dlf.h vcheck.h version.h assertion.h librarian.h
action_while${OBJ}: action_while.C action.h model_framed.h model_logable.h \
 model.h symbol.h frame.h scope.h attribute.h log.h time.h border.h \
 assertion.h memutils.h librarian.h treelog.h block_model.h \
 block_nested.h block.h frame_model.h
action_wait${OBJ}: action_wait.C action.h model_framed.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h condition.h log.h time.h \
 border.h daisy.h program.h run.h assertion.h librarian.h
action_activity${OBJ}: action_activity.C action.h model_framed.h \
 model_logable.h model.h symbol.h frame.h scope.h attribute.h log.h \
 time.h border.h memutils.h librarian.h metalib.h library.h treelog.h \
 block_model.h block_nested.h block.h frame_model.h
mactrans_std${OBJ}: mactrans_std.C mactrans.h model.h symbol.h soil_water.h \
 geometry1d.h geometry_vert.h geometry.h attribute.h plf.h mathlib.h \
 assertion.h librarian.h treelog.h frame.h scope.h
macro_std${OBJ}: macro_std.C macro.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h geometry1d.h geometry_vert.h geometry.h soil.h surface.h \
 uzmodel.h plf.h mathlib.h assertion.h log.h time.h border.h \
 model_framed.h model_logable.h check.h vcheck.h librarian.h
macro_none${OBJ}: macro_none.C macro.h model.h symbol.h librarian.h frame.h \
 scope.h attribute.h
column_std${OBJ}: column_std.C column.h model_framed.h model_logable.h \
 model.h symbol.h irrigate.h memutils.h library.h surface.h uzmodel.h \
 soil_heat.h movement.h model_derived.h drain.h groundwater.h geometry.h \
 attribute.h soil.h soil_water.h vegetation.h litter.h bioclimate.h \
 weather.h im.h chemistry.h chemical.h organic.h am.h dom.h plf.h time.h \
 log.h border.h submodeler.h block_submodel.h block_nested.h block.h \
 scope.h treelog.h frame_submodel.h frame.h scope_multi.h scopesel.h \
 units.h librarian.h assertion.h frame_model.h block_model.h mathlib.h
weather_simple${OBJ}: weather_simple.C weather_old.h weather_base.h weather.h \
 model_derived.h model_logable.h model.h symbol.h im.h attribute.h \
 block_model.h block_nested.h block.h scope.h treelog.h frame_model.h \
 frame.h time.h log.h border.h model_framed.h mathlib.h assertion.h \
 librarian.h
uzrichard${OBJ}: uzrichard.C uzmodel.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h groundwater.h model_derived.h model_logable.h surface.h \
 geometry_vert.h geometry.h soil.h soil_heat.h mathlib.h assertion.h \
 log.h time.h border.h model_framed.h average.h librarian.h
hydraulic_yolo${OBJ}: hydraulic_yolo.C hydraulic.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h plf.h mathlib.h \
 assertion.h librarian.h
hydraulic_M_vG${OBJ}: hydraulic_M_vG.C hydraulic.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h plf.h mathlib.h \
 assertion.h librarian.h
hydraulic_B_vG${OBJ}: hydraulic_B_vG.C hydraulic.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h plf.h mathlib.h \
 assertion.h librarian.h
hydraulic_M_C${OBJ}: hydraulic_M_C.C hydraulic.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h check.h mathlib.h \
 assertion.h librarian.h
hydraulic_B_C${OBJ}: hydraulic_B_C.C hydraulic.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h check.h mathlib.h \
 assertion.h librarian.h
hydraulic_M_BaC${OBJ}: hydraulic_M_BaC.C hydraulic.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h check.h mathlib.h \
 assertion.h librarian.h
hydraulic_B_BaC${OBJ}: hydraulic_B_BaC.C hydraulic.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h mathlib.h \
 assertion.h librarian.h
groundwater_static${OBJ}: groundwater_static.C groundwater.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h assertion.h \
 librarian.h
horizon_std${OBJ}: horizon_std.C horizon.h model_derived.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h texture.h plf.h hydraulic.h \
 check.h mathlib.h assertion.h librarian.h intrinsics.h memutils.h \
 library.h
crop_std${OBJ}: crop_std.C crop.h model_framed.h model_logable.h model.h \
 symbol.h time.h chemistry.h seed.h model_derived.h root_system.h \
 rootdens.h ABAprod.h plf.h canopy_std.h canopy_simple.h harvesting.h \
 production.h phenology.h partition.h vernalization.h photo.h crpn.h \
 wse.h log.h border.h timestep.h vcheck.h bioclimate.h soil_water.h \
 geometry.h attribute.h soil.h organic.h soil_heat.h am.h im.h \
 submodeler.h block_submodel.h block_nested.h block.h scope.h treelog.h \
 frame_submodel.h frame.h mathlib.h assertion.h librarian.h memutils.h \
 check.h block_model.h frame_model.h
action_sow${OBJ}: action_sow.C action.h model_framed.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h daisy.h program.h run.h \
 field.h irrigate.h memutils.h border.h crop.h time.h librarian.h check.h
action_stop${OBJ}: action_stop.C action.h model_framed.h model_logable.h \
 model.h symbol.h daisy.h program.h run.h librarian.h
condition_time${OBJ}: condition_time.C condition.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h time.h daisy.h \
 program.h run.h vcheck.h librarian.h timestep.h log.h border.h \
 submodeler.h block_submodel.h frame_submodel.h
condition_logic${OBJ}: condition_logic.C condition.h model_framed.h \
 model_logable.h model.h symbol.h log.h time.h border.h frame.h scope.h \
 attribute.h memutils.h librarian.h block_model.h block_nested.h block.h \
 treelog.h frame_model.h
action_irrigate${OBJ}: action_irrigate.C action.h model_framed.h \
 model_logable.h model.h symbol.h scope.h attribute.h block_model.h \
 block_nested.h block.h treelog.h frame_model.h frame.h daisy.h program.h \
 run.h chemical.h number.h units.h memutils.h field.h irrigate.h border.h \
 im.h check.h mathlib.h assertion.h librarian.h volume.h model_derived.h
action_lisp${OBJ}: action_lisp.C action.h model_framed.h model_logable.h \
 model.h symbol.h daisy.h program.h run.h log.h time.h border.h \
 memutils.h submodeler.h block_submodel.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_submodel.h frame.h librarian.h block_model.h \
 frame_model.h condition.h
weather_none${OBJ}: weather_none.C weather_old.h weather_base.h weather.h \
 model_derived.h model_logable.h model.h symbol.h im.h attribute.h \
 block_model.h block_nested.h block.h scope.h treelog.h frame_model.h \
 frame.h librarian.h
action_tillage${OBJ}: action_tillage.C action.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h daisy.h program.h \
 run.h field.h irrigate.h memutils.h border.h check.h librarian.h
action_harvest${OBJ}: action_harvest.C action.h model_framed.h \
 model_logable.h model.h symbol.h daisy.h program.h run.h field.h \
 irrigate.h memutils.h border.h harvest.h time.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h librarian.h vegetation.h model_derived.h
action_with${OBJ}: action_with.C action.h model_framed.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h daisy.h program.h run.h \
 field.h irrigate.h memutils.h border.h log.h time.h librarian.h
nitrification_soil${OBJ}: nitrification_soil.C nitrification.h model.h \
 symbol.h abiotic.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h mathlib.h assertion.h plf.h \
 check.h librarian.h intrinsics.h memutils.h library.h
nitrification_solute${OBJ}: nitrification_solute.C nitrification.h model.h \
 symbol.h abiotic.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h soil.h soil_water.h \
 soil_heat.h mathlib.h assertion.h plf.h check.h librarian.h
hydraulic_mod_C${OBJ}: hydraulic_mod_C.C hydraulic.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h check.h mathlib.h \
 assertion.h librarian.h
uzlr${OBJ}: uzlr.C uzmodel.h model.h symbol.h block_model.h block_nested.h \
 block.h scope.h attribute.h treelog.h frame_model.h frame.h surface.h \
 groundwater.h model_derived.h model_logable.h geometry_vert.h geometry.h \
 soil.h soil_heat.h mathlib.h assertion.h librarian.h
adsorption_vS_S${OBJ}: adsorption_vS_S.C adsorption.h model_derived.h \
 model_logable.h model.h symbol.h soil.h mathlib.h assertion.h \
 librarian.h
tortuosity_M_Q${OBJ}: tortuosity_M_Q.C tortuosity.h model.h symbol.h \
 hydraulic.h model_derived.h model_logable.h mathlib.h assertion.h \
 librarian.h frame.h scope.h attribute.h
tortuosity_linear${OBJ}: tortuosity_linear.C tortuosity.h model.h symbol.h \
 block_model.h block_nested.h block.h scope.h attribute.h treelog.h \
 frame_model.h frame.h hydraulic.h model_derived.h model_logable.h \
 librarian.h
adsorption_freundlich${OBJ}: adsorption_freundlich.C adsorption.h \
 model_derived.h model_logable.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h soil.h check.h mathlib.h assertion.h librarian.h
adsorption_linear${OBJ}: adsorption_linear.C adsorption.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h check.h soil.h \
 librarian.h
adsorption_langmuir${OBJ}: adsorption_langmuir.C adsorption.h model_derived.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h soil.h check.h \
 mathlib.h assertion.h librarian.h
bioclimate_std${OBJ}: bioclimate_std.C bioclimate.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h surface.h uzmodel.h \
 weather.h model_derived.h im.h plf.h geometry.h soil.h soil_heat.h \
 snow.h log.h time.h border.h mathlib.h assertion.h net_radiation.h pet.h \
 difrad.h raddist.h svat.h vegetation.h litter.h units.h memutils.h \
 check.h fao.h librarian.h treelog_store.h resistance.h
condition_crop${OBJ}: condition_crop.C condition.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h crop.h time.h \
 field.h irrigate.h memutils.h border.h daisy.h program.h run.h \
 check_range.h check.h mathlib.h assertion.h librarian.h
condition_soil${OBJ}: condition_soil.C condition.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h field.h irrigate.h \
 memutils.h border.h daisy.h program.h run.h check.h librarian.h
log_checkpoint${OBJ}: log_checkpoint.C log_alist.h log.h time.h symbol.h \
 border.h model_framed.h model_logable.h model.h metalib.h frame.h \
 scope.h attribute.h block_model.h block_nested.h block.h treelog.h \
 frame_model.h condition.h daisy.h program.h run.h printer_file.h \
 printer.h assertion.h librarian.h library.h path.h
uznone${OBJ}: uznone.C uzmodel.h model.h symbol.h soil.h mathlib.h \
 assertion.h librarian.h frame.h scope.h attribute.h
condition_daisy${OBJ}: condition_daisy.C condition.h model_framed.h \
 model_logable.h model.h symbol.h daisy.h program.h run.h librarian.h
chemical_std${OBJ}: chemical_std.C chemical.h model_framed.h model_logable.h \
 model.h symbol.h organic.h model_derived.h soil_heat.h soil_water.h \
 soil.h geometry.h attribute.h abiotic.h adsorption.h chemistry.h log.h \
 time.h border.h block_model.h block_nested.h block.h scope.h treelog.h \
 frame_model.h frame.h mathlib.h assertion.h plf.h check.h librarian.h \
 number.h scope_soil.h scope_multi.h vcheck.h memutils.h submodeler.h \
 block_submodel.h frame_submodel.h
hydraulic_M_BaC_Bimodal${OBJ}: hydraulic_M_BaC_Bimodal.C hydraulic.h \
 model_derived.h model_logable.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h check.h mathlib.h assertion.h librarian.h
hydraulic_B_BaC_Bimodal${OBJ}: hydraulic_B_BaC_Bimodal.C hydraulic.h \
 model_derived.h model_logable.h model.h symbol.h block_model.h \
 block_nested.h block.h scope.h attribute.h treelog.h frame_model.h \
 frame.h check.h mathlib.h assertion.h librarian.h
pet_makkink${OBJ}: pet_makkink.C pet.h model_framed.h model_logable.h model.h \
 symbol.h weather.h model_derived.h im.h attribute.h fao.h log.h time.h \
 border.h librarian.h frame.h scope.h
pet_weather${OBJ}: pet_weather.C pet.h model_framed.h model_logable.h model.h \
 symbol.h weather.h model_derived.h im.h attribute.h log.h time.h \
 border.h librarian.h frame.h scope.h
svat_none${OBJ}: svat_none.C svat.h model_derived.h model_logable.h model.h \
 symbol.h bioclimate.h model_framed.h librarian.h frame.h scope.h \
 attribute.h weather.h im.h
action_spray${OBJ}: action_spray.C action.h model_framed.h model_logable.h \
 model.h symbol.h block_model.h block_nested.h block.h scope.h \
 attribute.h treelog.h frame_model.h frame.h daisy.h program.h run.h \
 field.h irrigate.h memutils.h border.h chemical.h check.h librarian.h
pet_PM${OBJ}: pet_PM.C pet.h model_framed.h model_logable.h model.h symbol.h \
 fao.h weather.h model_derived.h im.h attribute.h soil.h surface.h \
 uzmodel.h soil_heat.h vegetation.h log.h time.h border.h librarian.h \
 frame.h scope.h net_radiation.h block_model.h block_nested.h block.h \
 treelog.h frame_model.h
svat_pmsw${OBJ}: svat_pmsw.C svat.h model_derived.h model_logable.h model.h \
 symbol.h mathlib.h assertion.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h weather.h im.h \
 geometry.h soil.h soil_water.h soil_heat.h bioclimate.h model_framed.h \
 vegetation.h log.h time.h border.h fao.h gaussj.h librarian.h nrutil.h
action_surface${OBJ}: action_surface.C action.h model_framed.h \
 model_logable.h model.h symbol.h block_model.h block_nested.h block.h \
 scope.h attribute.h treelog.h frame_model.h frame.h daisy.h program.h \
 run.h field.h irrigate.h memutils.h border.h check.h librarian.h
main${OBJ}: main.C toplevel.h treelog.h symbol.h
cmain${OBJ}: cmain.c cdaisy.h
bugmain${OBJ}: bugmain.c cdaisy.h
