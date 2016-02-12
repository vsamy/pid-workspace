#########################################################################################
#	This file is part of the program PID						#
#  	Program description : build system supportting the PID methodology  		#
#  	Copyright (C) Robin Passama, LIRMM (Laboratoire d'Informatique de Robotique 	#
#	et de Microelectronique de Montpellier). All Right reserved.			#
#											#
#	This software is free software: you can redistribute it and/or modify		#
#	it under the terms of the CeCILL-C license as published by			#
#	the CEA CNRS INRIA, either version 1						#
#	of the License, or (at your option) any later version.				#
#	This software is distributed in the hope that it will be useful,		#
#	but WITHOUT ANY WARRANTY; without even the implied warranty of			#
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the			#
#	CeCILL-C License for more details.						#
#											#
#	You can find the complete license description on the official website 		#
#	of the CeCILL licenses family (http://www.cecill.info/index.en.html)		#
#########################################################################################

set(x11_FOUND FALSE CACHE INTERNAL "")
# - Find x11 installation
# Try to find X11 on UNIX systems. The following values are defined
#  x11_FOUND        - True if X11 is available
#  x11_LIBRARIES    - link against these to use X11
if (UNIX)
  
  # X11 is never a framework and some header files may be
  # found in tcl on the mac
  set(CMAKE_FIND_FRAMEWORK_SAVE ${CMAKE_FIND_FRAMEWORK})
  set(CMAKE_FIND_FRAMEWORK NEVER)

  # MODIFICATION for our needs: must be in default system folders so do not provide additionnal folders !!!!!
  find_path(x11_X11_INCLUDE_PATH X11/X.h)
  find_path(x11_Xlib_INCLUDE_PATH X11/Xlib.h)
  find_path(x11_ICE_INCLUDE_PATH X11/ICE/ICE.h)
  find_path(x11_SM_INCLUDE_PATH X11/SM/SM.h)

  find_library(x11_X11_LIB X11) 
  find_library(x11_ICE_LIB ICE)
  find_library(x11_SM_LIB SM)
  find_library(x11_Xext_LIB Xext)

  # no need to check for include or library dirs as all must be in default system folders (no configuration required)

  set(x11_LIBRARIES) # start with empty list
  set(x11_PATH)

  set(IS_FOUND TRUE)
  if(x11_X11_INCLUDE_PATH AND x11_Xlib_INCLUDE_PATH AND x11_X11_LIB)
	set(x11_LIBRARIES ${x11_LIBRARIES} ${x11_X11_LIB} )
	set(x11_PATH ${x11_PATH} ${x11_Xlib_INCLUDE_PATH} ${x11_X11_INCLUDE_PATH})
  else()
	message("[PID] ERROR : when finding x11 framework, cannot find X11 base library.")
	set(IS_FOUND FALSE)
  endif()

  if(x11_Xext_LIB)
    	set(x11_LIBRARIES ${x11_LIBRARIES} ${x11_Xext_LIB})
  else()
    	message("[PID] ERROR : when finding x11 framework, cannot find X11 extension library.")
	set(IS_FOUND FALSE)
  endif()

  if(x11_ICE_LIB AND x11_ICE_INCLUDE_PATH)
   	set(x11_LIBRARIES ${x11_LIBRARIES} ${x11_ICE_LIB})
	set(x11_PATH ${x11_PATH} ${x11_ICE_INCLUDE_PATH})
  else()
	message("[PID] ERROR : when finding x11 framework, cannot find ICE library.")
	set(IS_FOUND FALSE)
  endif ()

  if(x11_SM_LIB AND x11_SM_INCLUDE_PATH)
   	set(x11_LIBRARIES ${x11_LIBRARIES} ${x11_SM_LIB})
	set(x11_PATH ${x11_PATH} ${x11_SM_INCLUDE_PATH})
  else()
	message("[PID] ERROR : when finding x11 framework, cannot find SM library.")
	set(IS_FOUND FALSE)
  endif ()

  if(IS_FOUND)
	set(x11_FOUND TRUE  CACHE INTERNAL "")
  endif ()

unset(IS_FOUND)
unset(x11_X11_INCLUDE_PATH CACHE)
unset(x11_Xlib_INCLUDE_PATH CACHE)
unset(x11_X11_LIB CACHE)
unset(x11_Xext_LIB CACHE)
unset(x11_ICE_LIB CACHE)
unset(x11_ICE_INCLUDE_PATH CACHE)
unset(x11_SM_LIB CACHE)
unset(x11_SM_INCLUDE_PATH CACHE)

set(CMAKE_FIND_FRAMEWORK ${CMAKE_FIND_FRAMEWORK_SAVE})
endif ()
