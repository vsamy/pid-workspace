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

include(${WORKSPACE_DIR}/share/cmake/constraints/configurations/pcre3/installable_pcre3.cmake)
if(pcre3_INSTALLABLE)
	message("[PID] INFO : trying to install pcre3...")
	execute_process(COMMAND sudo apt-get install libpcre3-dev)
	include(${WORKSPACE_DIR}/share/cmake/constraints/configurations/pcre3/find_pcre3.cmake)
	if(pcre3_FOUND)
		message("[PID] INFO : pcre3 installed !")
		set(pcre3_INSTALLED TRUE)
	else()
		set(pcre3_INSTALLED FALSE)
		message("[PID] INFO : install of pcre3 has failed !")
	endif()
else()
	set(pcre3_INSTALLED FALSE)
endif()
