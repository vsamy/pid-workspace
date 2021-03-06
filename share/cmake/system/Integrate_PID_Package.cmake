#########################################################################################
#       This file is part of the program PID                                            #
#       Program description : build system supportting the PID methodology              #
#       Copyright (C) Robin Passama, LIRMM (Laboratoire d'Informatique de Robotique     #
#       et de Microelectronique de Montpellier). All Right reserved.                    #
#                                                                                       #
#       This software is free software: you can redistribute it and/or modify           #
#       it under the terms of the CeCILL-C license as published by                      #
#       the CEA CNRS INRIA, either version 1                                            #
#       of the License, or (at your option) any later version.                          #
#       This software is distributed in the hope that it will be useful,                #
#       but WITHOUT ANY WARRANTY; without even the implied warranty of                  #
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the                    #
#       CeCILL-C License for more details.                                              #
#                                                                                       #
#       You can find the complete license description on the official website           #
#       of the CeCILL licenses family (http://www.cecill.info/index.en.html)            #
#########################################################################################

#############################################################################################################
########### this is the script file to call to integrate local modificaiton with those of a remote  #########
#############################################################################################################

include(${WORKSPACE_DIR}/pid/Workspace_Platforms_Info.cmake) #loading the current platform configuration

list(APPEND CMAKE_MODULE_PATH ${WORKSPACE_DIR}/share/cmake/system)
include(PID_Git_Functions NO_POLICY_SCOPE)

# check that current branch of package is integration
get_Repository_Current_Branch(BRANCH_NAME ${WORKSPACE_DIR}/packages/${TARGET_PACKAGE})
if(NOT BRANCH_NAME STREQUAL "integration")
	message("[PID] ERROR : the integration of ${TARGET_PACKAGE} must be made on integration branch. Please run integrate command on integration branch.")
	return()
endif()

# check if the package has a remote
is_Package_Connected(ORIGIN_CONNECTED ${TARGET_PACKAGE} origin)
is_Package_Connected(OFFICIAL_CONNECTED ${TARGET_PACKAGE} official)
if(NOT ORIGIN_CONNECTED OR NOT OFFICIAL_CONNECTED)
	message("[PID] INFO : nothing to integrate because ${TARGET_PACKAGE} has no origin AND official remote repositories defined. Simply define an ADDRESS with in the declare_PID_Package function, in the package root CMakeLists.txt.")
	return()
endif()

# check for modifications
has_Modifications(HAS_MODIFS ${TARGET_PACKAGE})
if(HAS_MODIFS)
	message("[PID] ERROR : impossible to do integration of package ${TARGET_PACKAGE} because there are modifications to commit or stash before.")
	return()
endif() # from here we can navigate between branches freely

# from here => ready to integrate

#updating graph from remotes
update_Remotes(${TARGET_PACKAGE})

#merging origin/integration
integrate_Branch(${TARGET_PACKAGE} origin/integration)
has_Modifications(HAS_MODIFS ${TARGET_PACKAGE})
if(HAS_MODIFS)
	message("[PID] ERROR : merge problem when trying to integrate all modifications of package ${TARGET_PACKAGE}. Please solve them before launching integrate command again.")
	return()
endif()

#merging official/integration
if(WITH_OFFICIAL STREQUAL "true")
	integrate_Branch(${TARGET_PACKAGE} official/integration)
	has_Modifications(HAS_MODIFS ${TARGET_PACKAGE})
	if(HAS_MODIFS)
		message("[PID] ERROR : merge problem when trying to integrate all modifications of package ${TARGET_PACKAGE}. Please solve them before launching integrate command again.")
		return()
	else()
		get_Remotes_To_Update(REMOTES ${TARGET_PACKAGE})
		if(REMOTES)
			publish_Repository_Integration(${TARGET_PACKAGE})
			update_Remotes(${TARGET_PACKAGE})
			message("[PID] INFO : integration process is finished.")
		else()
			message("[PID] INFO : integration process is finished, nothing to push to origin.")
		endif()

	endif()

else()
	get_Remotes_To_Update(REMOTES ${TARGET_PACKAGE})
	if(REMOTES)
		publish_Repository_Integration(${TARGET_PACKAGE})
		update_Remotes(${TARGET_PACKAGE})
		message("[PID] INFO : integration process is finished.")
	else()
		message("[PID] INFO : integration process is finished, nothing to push to origin.")
	endif()
endif()
