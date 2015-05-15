#################################################################################################
####################### new API => configure the package with dependencies  #####################
#################################################################################################

function( list_Public_Includes INCLUDES package component mode)
get_Mode_Variables(TARGET_SUFFIX VAR_SUFFIX ${mode})	

set(${INCLUDES} "${${package}_ROOT_DIR}/include/${${package}_${component}_HEADER_DIR_NAME}" PARENT_SCOPE)
#additionally provided include dirs (cflags -I<path>) (external/system exported include dirs)
if(${package}_${component}_INC_DIRS${mode_suffix})
	resolve_External_Includes_Path(RES_INCLUDES ${package} "${${package}_${component}_INC_DIRS${VAR_SUFFIX}}" ${mode})
	set(	${INCLUDES} ${INCLUDES} "${RES_INCLUDES}" PARENT_SCOPE)
endif()

endfunction(list_Public_Includes)

function( list_Public_Links LINKS package component mode)
get_Mode_Variables(TARGET_SUFFIX VAR_SUFFIX ${mode})	
#provided additionnal ld flags (exported external/system libraries and ldflags)		
if(${package}_${component}_LINKS${VAR_SUFFIX})
	resolve_External_Libs_Path(RES_LINKS ${package} "${${package}_${component}_LINKS${VAR_SUFFIX}}" ${mode})
set(${LINKS} ${LINKS} "${RES_LINKS}" PARENT_SCOPE)
endif()
endfunction(list_Public_Links)

function( list_Public_Definitions DEFS package component mode)
get_Mode_Variables(TARGET_SUFFIX VAR_SUFFIX ${mode})	
if(${package}_${component}_DEFS${VAR_SUFFIX}) 	
	set(${DEFS} ${${package}_${component}_DEFS${VAR_SUFFIX}} PARENT_SCOPE)
endif()

endfunction(list_Public_Definitions)

function( get_Binary_Location LOCATION_RES package component mode)
get_Mode_Variables(TARGET_SUFFIX VAR_SUFFIX ${mode})	

is_Executable_Component(IS_EXE ${package} ${component})
if(IS_EXE)
	set(${LOCATION_RES} "${${package}_ROOT_DIR}/bin/${${package}_${component}_BINARY_NAME${VAR_SUFFIX}}" PARENT_SCOPE)
elseif(NOT ${package}_${component}_TYPE STREQUAL "HEADER")
	set(${LOCATION_RES} "${${package}_ROOT_DIR}/lib/${${package}_${component}_BINARY_NAME${VAR_SUFFIX}}" PARENT_SCOPE)
endif()
endfunction(get_Binary_Location)

function(list_Private_Links PRIVATE_LINKS package component mode)
get_Mode_Variables(TARGET_SUFFIX VAR_SUFFIX ${mode})
#provided additionnal ld flags (exported external/system libraries and ldflags)		
if(${package}_${component}_PRIVATE_LINKS${VAR_SUFFIX})
	resolve_External_Libs_Path(RES_LINKS ${package} "${${package}_${component}_PRIVATE_LINKS${VAR_SUFFIX}}" ${mode})
set(${PRIVATE_LINKS} "${RES_LINKS}" PARENT_SCOPE)
endif()
endfunction(list_Private_Links)




#######################################################################################################
############# variables generated by generic functions using the Use<package>-<version>.cmake #########
############# files of each dependent package - contain full path information #########################
#######################################################################################################
# for libraries components
# XXX_YYY_INCLUDE_DIRS[_DEBUG]	# all include path to use to build an executable with the library component YYY of package XXX
# XXX_YYY_DEFINITIONS[_DEBUG]	# all definitions to use to build an executable with the library component YYY of package XXX
# XXX_YYY_LIBRARIES[_DEBUG]	# all libraries path to use to build an executable with the library component YYY of package XXX

########### this part is for runtime purpose --- see later ##############
# for application components
# XXX_YYY_EXECUTABLE[_DEBUG]	# path to the executable component YYY of package XXX

# for "launch" components (not currently existing)
# XXX_YYY_APPS[_DEBUG]		# all executables of a distributed application defined by launch component YYY of package XXX
# XXX_YYY_APP_ZZZ_PARAMS[_DEBUG]# all parameters used  
# XXX_YYY_APP_ZZZ_PARAM_VVV	# string parameter VVV for application ZZZ used by the launch file YYY of package XXX 

##################################################################################
####################### configuring build time dependencies ######################
##################################################################################

###
function(configure_Package_Build_Variables package mode)
#message(DEBUG configure_Package_Build_Variables package=${package} mode=${mode})
if(${package}_PREPARE_BUILD)#this is a guard to limit unecessary recursion
	return()
endif()

if(${package}_DURING_PREPARE_BUILD)#this is a guard to avoid cyclic recursion
	message(FATAL_ERROR "Alert : you have define cyclic dependencies between packages : Package ${package} is directly or undirectly requiring itself !")
endif()

if(mode MATCHES Release)
	set(mode_suffix "")
else()
	set(mode_suffix "_DEBUG")
endif()

set(${package}_DURING_PREPARE_BUILD TRUE)

# 1) initializing all build variable that are directly provided by each component of the target package
foreach(a_component IN ITEMS ${${package}_COMPONENTS})
	init_Component_Build_Variables(${package} ${a_component} ${${package}_ROOT_DIR} ${mode})
endforeach()

# 2) setting build variables with informations coming from package dependancies
foreach(a_component IN ITEMS ${${package}_COMPONENTS}) 
	foreach(a_package IN ITEMS ${${package}_${a_component}_DEPENDENCIES${mode_suffix}})
		foreach(a_dep_component IN ITEMS ${${package}_${a_component}_DEPENDENCY_${a_package}_COMPONENTS${mode_suffix}}) 
			update_Component_Build_Variables_With_Dependency(${package} ${a_component} ${a_package} ${a_dep_component} ${mode})
		endforeach()
	endforeach()
endforeach()

#3) setting build variables with informations coming from INTERNAL package dependancies
# these have not been checked like the others since the package components discovering mecanism has already done the job 
foreach(a_component IN ITEMS ${${package}_COMPONENTS}) 
	foreach(a_dep_component IN ITEMS ${${package}_${a_component}_INTERNAL_DEPENDENCIES${mode_suffix}}) 
		update_Component_Build_Variables_With_Internal_Dependency(${package} ${a_component} ${a_dep_component} ${mode})
	endforeach()
endforeach()

set(${package}_PREPARE_BUILD TRUE)
set(${package}_DURING_PREPARE_BUILD FALSE)
# no need to check system/external dependencies as they are already  treaten as special cases (see variable <package>__<component>_LINKS and <package>__<component>_DEFS of components)
# quite like in pkg-config tool
endfunction(configure_Package_Build_Variables)


###
function (update_Config_Include_Dirs package component dep_package dep_component mode_suffix)
	if(${dep_package}_${dep_component}_INCLUDE_DIRS${mode_suffix})	
		set(${package}_${component}_INCLUDE_DIRS${mode_suffix} ${${package}_${component}_INCLUDE_DIRS${mode_suffix}} ${${dep_package}_${dep_component}_INCLUDE_DIRS${mode_suffix}} CACHE INTERNAL "")
	endif()
endfunction(update_Config_Include_Dirs)

###
function (update_Config_Definitions package component dep_package dep_component mode_suffix)
	if(${dep_package}_${dep_component}_DEFINITIONS${mode_suffix})
		set(${package}_${component}_DEFINITIONS${mode_suffix} ${${package}_${component}_DEFINITIONS${mode_suffix}} ${${dep_package}_${dep_component}_DEFINITIONS${mode_suffix}} CACHE INTERNAL "")
	endif()
endfunction(update_Config_Definitions)

###
function(update_Config_Libraries package component dep_package dep_component mode_suffix)
	if(${dep_package}_${dep_component}_LIBRARIES${mode_suffix})
		set(	${package}_${component}_LIBRARIES${mode_suffix} 
			${${package}_${component}_LIBRARIES${mode_suffix}} 
			${${dep_package}_${dep_component}_LIBRARIES${mode_suffix}} 
			CACHE INTERNAL "") #putting dependencies after component using them (to avoid linker problems)
	endif()
endfunction(update_Config_Libraries)

###
function(init_Component_Build_Variables package component path_to_version mode)
	if(mode MATCHES Debug)
		set(mode_suffix "_DEBUG")
	else()
		set(mode_suffix "")
	endif()
	set(${package}_${component}_INCLUDE_DIRS${mode_suffix} "" CACHE INTERNAL "")
	set(${package}_${component}_DEFINITIONS${mode_suffix} "" CACHE INTERNAL "")
	set(${package}_${component}_LIBRARIES${mode_suffix} "" CACHE INTERNAL "")
	set(${package}_${component}_EXECUTABLE${mode_suffix} "" CACHE INTERNAL "")
	is_Executable_Component(COMP_IS_EXEC ${package} ${component})
	
	if(NOT COMP_IS_EXEC)
		#provided include dirs (cflags -I<path>)
		set(${package}_${component}_INCLUDE_DIRS${mode_suffix} "${path_to_version}/include/${${package}_${component}_HEADER_DIR_NAME}" CACHE INTERNAL "")
		#additionally provided include dirs (cflags -I<path>) (external/system exported include dirs)
		if(${package}_${component}_INC_DIRS${mode_suffix})
			resolve_External_Includes_Path(RES_INCLUDES ${package} "${${package}_${component}_INC_DIRS${mode_suffix}}" ${mode})
			#message("DEBUG RES_INCLUDES for ${package} ${component} = ${RES_INCLUDES}")			
			set(	${package}_${component}_INCLUDE_DIRS${mode_suffix} 
				${${package}_${component}_INCLUDE_DIRS${mode_suffix}} 
				"${RES_INCLUDES}"
				CACHE INTERNAL "")
		endif()

		#provided cflags (own CFLAGS and external/system exported CFLAGS)
		if(${package}_${component}_DEFS${mode_suffix}) 	
			set(${package}_${component}_DEFINITIONS${mode_suffix} ${${package}_${component}_DEFS${mode_suffix}} CACHE INTERNAL "")
		endif()

		#provided library (ldflags -l<path>)
		if(NOT ${package}_${component}_TYPE STREQUAL "HEADER")
			set(${package}_${component}_LIBRARIES${mode_suffix} "${path_to_version}/lib/${${package}_${component}_BINARY_NAME${mode_suffix}}" CACHE INTERNAL "")
		endif()

		#provided additionnal ld flags (exported external/system libraries and ldflags)		
		if(${package}_${component}_LINKS${mode_suffix})
			resolve_External_Libs_Path(RES_LINKS ${package} "${${package}_${component}_LINKS${mode_suffix}}" ${mode})			
			set(	${package}_${component}_LIBRARIES${mode_suffix}
				${${package}_${component}_LIBRARIES${mode_suffix}}	
				"${RES_LINKS}"
				CACHE INTERNAL "")
		endif()
		#message("FINAL init_Component_Build_Variables ${package}.${component}: \nINCLUDES = ${${package}_${component}_INCLUDE_DIRS${mode_suffix}} (var=${package}_${component}_INCLUDE_DIRS${mode_suffix}) \nDEFINITIONS = ${${package}_${component}_DEFINITIONS${mode_suffix}} (var = ${package}_${component}_DEFINITIONS${mode_suffix}) \nLIBRARIES = ${${package}_${component}_LIBRARIES${mode_suffix}}\n")
	elseif(${package}_${component}_TYPE STREQUAL "APP" OR ${package}_${component}_TYPE STREQUAL "EXAMPLE")
		
		set(${package}_${component}_EXECUTABLE${mode_suffix} "${path_to_version}/bin/${${package}_${component}_BINARY_NAME${mode_suffix}}" CACHE INTERNAL "")
	endif()
endfunction(init_Component_Build_Variables)

### 
function(update_Component_Build_Variables_With_Dependency package component dep_package dep_component mode)
if(mode MATCHES Debug)
	set(mode_suffix "_DEBUG")
else()
	set(mode_suffix "")
endif()
configure_Package_Build_Variables(${dep_package} ${mode})#!! recursion to get all updated infos
if(${package}_${component}_EXPORT_${dep_package}_${dep_component}${mode_suffix})
	update_Config_Include_Dirs(${package} ${component} ${dep_package} ${dep_component} "${mode_suffix}")
	update_Config_Definitions(${package} ${component} ${dep_package} ${dep_component} "${mode_suffix}")
	update_Config_Libraries(${package} ${component} ${dep_package} ${dep_component} "${mode_suffix}")	
else()
	if(NOT ${dep_package}_${dep_component}_TYPE STREQUAL "SHARED")#static OR header lib
		update_Config_Libraries(${package} ${component} ${dep_package} ${dep_component} "${mode_suffix}")
	endif()
	
endif()
endfunction(update_Component_Build_Variables_With_Dependency)


function(update_Component_Build_Variables_With_Internal_Dependency package component dep_component mode)
if(mode MATCHES Debug)
	set(mode_suffix "_DEBUG")
else()
	set(mode_suffix "")
endif()

if(${package}_${component}_INTERNAL_EXPORT_${dep_component}${mode_suffix})
	update_Config_Include_Dirs(${package} ${component} ${package} ${dep_component} "${mode_suffix}")
	update_Config_Definitions(${package} ${component} ${package} ${dep_component} "${mode_suffix}")
	update_Config_Libraries(${package} ${component} ${package} ${dep_component} "${mode_suffix}")	
else()#dep_component is not exported by component
	if(NOT ${package}_${dep_component}_TYPE STREQUAL "SHARED" AND NOT ${package}_${dep_component}_TYPE STREQUAL "MODULE")#static OR header lib
		update_Config_Libraries(${package} ${component} ${package} ${dep_component} "${mode_suffix}")
	endif()
	
endif()
endfunction(update_Component_Build_Variables_With_Internal_Dependency)

##################################################################################
################## finding shared libs dependencies for the linker ###############
##################################################################################

function(resolve_Source_Component_Linktime_Dependencies component THIRD_PARTY_LINKS)
is_Executable_Component(COMP_IS_EXEC ${PROJECT_NAME} ${component})
will_be_Built(COMP_WILL_BE_BUILT ${component})

if(	NOT COMP_IS_EXEC 
	OR NOT COMP_WILL_BE_BUILT)#special case for executables that need rpath link to be specified (due to system shared libraries linking system)-> the linker must resolve all target links (even shared libs) transitively
	return()
endif()

set(undirect_deps)
# 0) no need to search for system libraries as they are installed and found automatically by the OS binding mechanism, idem for external dependencies since they are always direct dependencies for the currenlty build component

# 1) searching each direct dependency in other packages
foreach(dep_package IN ITEMS ${${PROJECT_NAME}_${component}_DEPENDENCIES${USE_MODE_SUFFIX}})
	foreach(dep_component IN ITEMS ${${PROJECT_NAME}_${component}_DEPENDENCY_${dep_package}_COMPONENTS${USE_MODE_SUFFIX}})
		set(LIST_OF_DEP_SHARED)
		find_Dependent_Private_Shared_Libraries(LIST_OF_DEP_SHARED ${dep_package} ${dep_component} TRUE ${CMAKE_BUILD_TYPE})
		if(LIST_OF_DEP_SHARED)
			list(APPEND undirect_deps ${LIST_OF_DEP_SHARED})
		endif()
	endforeach()
endforeach()

# 2) searching each direct dependency in current package (no problem with undirect internal dependencies since undirect path only target install path which is not a problem for build)
foreach(dep_component IN ITEMS ${${PROJECT_NAME}_${component}_INTERNAL_DEPENDENCIES${USE_MODE_SUFFIX}})
	set(LIST_OF_DEP_SHARED)
	find_Dependent_Private_Shared_Libraries(LIST_OF_DEP_SHARED ${PROJECT_NAME} ${dep_component} TRUE ${CMAKE_BUILD_TYPE})
	if(LIST_OF_DEP_SHARED)
		list(APPEND undirect_deps ${LIST_OF_DEP_SHARED})
	endif()
endforeach()

if(undirect_deps) #if true we need to be sure that the rpath-link does not contain some dirs of the rpath (otherwise the executable may not run)
	list(REMOVE_DUPLICATES undirect_deps)	
	get_target_property(thelibs ${component}${INSTALL_NAME_SUFFIX} LINK_LIBRARIES)
	set_target_properties(${component}${INSTALL_NAME_SUFFIX} PROPERTIES LINK_LIBRARIES "${thelibs};${undirect_deps}")
	set(${THIRD_PARTY_LINKS} ${undirect_deps} PARENT_SCOPE)#TODO here verify it is OK
endif()
endfunction(resolve_Source_Component_Linktime_Dependencies)


function(find_Dependent_Private_Shared_Libraries LIST_OF_UNDIRECT_DEPS package component is_direct mode)
set(undirect_list)
if(mode MATCHES Release)
	set(mode_binary_suffix "")
	set(mode_var_suffix "")
else()
	set(mode_binary_suffix "-dbg")
	set(mode_var_suffix "_DEBUG")
endif()
# 0) no need to search for systems dependencies as they can be found automatically using OS shared libraries binding mechanism

# 1) searching public external dependencies 
if(NOT is_direct) #otherwise external dependencies are direct dependencies so their LINKS (i.e. exported links) are already taken into account (not private)
	if(${package}_${component}_LINKS${mode_var_suffix})
		resolve_External_Libs_Path(RES_LINKS ${package} "${${package}_${component}_LINKS${mode_var_suffix}}" ${mode})#resolving libraries path against external packages path
		foreach(ext_dep IN ITEMS ${RES_LINKS})
			is_Shared_Lib_With_Path(IS_SHARED ${ext_dep})
			if(IS_SHARED)
				list(APPEND undirect_list ${ext_dep})
			endif()
		endforeach()
	endif()
endif()

# 1-bis) searching private external dependencies
if(${package}_${component}_PRIVATE_LINKS${mode_var_suffix})
	resolve_External_Libs_Path(RES_PRIVATE_LINKS ${package} "${${package}_${component}_PRIVATE_LINKS${mode_var_suffix}}" ${mode})#resolving libraries path against external packages path
	foreach(ext_dep IN ITEMS ${RES_PRIVATE_LINKS})
		is_Shared_Lib_With_Path(IS_SHARED ${ext_dep})
		if(IS_SHARED)
			list(APPEND undirect_list ${ext_dep})
		endif()
	endforeach()
endif()

# 2) searching in dependent packages
foreach(dep_package IN ITEMS ${${package}_${component}_DEPENDENCIES${mode_var_suffix}})
	foreach(dep_component IN ITEMS ${${package}_${component}_DEPENDENCY_${dep_package}_COMPONENTS${mode_var_suffix}}) 
		set(UNDIRECT)
		if(is_direct) # current component is a direct dependency of the application
			if(	${dep_package}_${dep_component}_TYPE STREQUAL "STATIC"
				OR ${dep_package}_${dep_component}_TYPE STREQUAL "HEADER"
				OR ${package}_${component}_EXPORTS_${dep_package}_${dep_component}${mode_var_suffix})
				 #the potential shared lib dependencies of the header or static lib will be direct dependencies of the application OR the shared lib dependency is a direct dependency of the application 
				find_Dependent_Private_Shared_Libraries(UNDIRECT ${dep_package} ${dep_component} TRUE ${mode}) 
			else()#it is a shared lib that is not exported
				find_Dependent_Private_Shared_Libraries(UNDIRECT ${dep_package} ${dep_component} FALSE ${mode}) #the shared lib dependency is NOT a direct dependency of the application 
				list(APPEND undirect_list "${${dep_package}_ROOT_DIR}/lib/${${dep_package}_${dep_component}_BINARY_NAME${mode_var_suffix}}")				
			endif()
		else() #current component is NOT a direct dependency of the application
			if(	${dep_package}_${dep_component}_TYPE STREQUAL "STATIC"
				OR ${dep_package}_${dep_component}_TYPE STREQUAL "HEADER")
				find_Dependent_Private_Shared_Libraries(UNDIRECT ${dep_package} ${dep_component} FALSE ${mode})
			else()#it is a shared lib that is exported or NOT
				find_Dependent_Private_Shared_Libraries(UNDIRECT ${dep_package} ${dep_component} FALSE ${mode}) #the shared lib dependency is a direct dependency of the application 
				list(APPEND undirect_list "${${dep_package}_ROOT_DIR}/lib/${${dep_package}_${dep_component}_BINARY_NAME${mode_var_suffix}}")				
			endif()
		endif()		
		
		if(UNDIRECT)
			list(APPEND undirect_list ${UNDIRECT})
		endif()
	endforeach()
endforeach()

# 3) searching in current package
foreach(dep_component IN ITEMS ${${package}_${component}_INTERNAL_DEPENDENCIES${mode_var_suffix}})
	set(UNDIRECT)
	if(is_direct) # current component is a direct dependency of the application
		if(	${package}_${dep_component}_TYPE STREQUAL "STATIC"
			OR ${package}_${dep_component}_TYPE STREQUAL "HEADER"
			OR ${package}_${component}_INTERNAL_EXPORTS_${dep_component}${mode_var_suffix})
			find_Dependent_Private_Shared_Libraries(UNDIRECT ${package} ${dep_component} TRUE ${mode}) #the potential shared lib dependencies of the header or static lib will be direct dependencies of the application OR the shared lib dependency is a direct dependency of the application 
		else()#it is a shared lib that is not exported
			find_Dependent_Private_Shared_Libraries(UNDIRECT ${package} ${dep_component} FALSE ${mode}) #the shared lib dependency is NOT a direct dependency of the application
			#adding this shared lib to the links of the application
			if(${package} STREQUAL ${PROJECT_NAME})
				#special case => the currenlty built package is the target package (may be not the case on recursion on another package)
				# we cannot target the lib folder as it does not exist at build time in the build tree
				# we simply target the corresponding build "target"
				list(APPEND undirect_list "${dep_component}${mode_binary_suffix}")		
			else()			
				list(APPEND undirect_list "${${package}_ROOT_DIR}/lib/${${package}_${dep_component}_BINARY_NAME${mode_var_suffix}}")		
			endif()		
		endif()
	else() #current component is NOT a direct dependency of the application
		if(	${package}_${dep_component}_TYPE STREQUAL "STATIC"
			OR ${package}_${dep_component}_TYPE STREQUAL "HEADER")
			find_Dependent_Private_Shared_Libraries(UNDIRECT ${package} ${dep_component} FALSE ${mode})
		else()#it is a shared lib that is exported or NOT
			find_Dependent_Private_Shared_Libraries(UNDIRECT ${package} ${dep_component} FALSE ${mode}) #the shared lib dependency is NOT a direct dependency of the application in all cases
			
			#adding this shared lib to the links of the application
			if(${package} STREQUAL ${PROJECT_NAME})
				#special case => the currenlty built package is the target package (may be not the case on recursion on another package)
				# we cannot target the lib folder as it does not exist at build time in the build tree
				# we simply target the corresponding build "target"
				list(APPEND undirect_list "${dep_component}${mode_binary_suffix}")		
			else()			
				list(APPEND undirect_list "${${package}_ROOT_DIR}/lib/${${package}_${dep_component}_BINARY_NAME${mode_var_suffix}}")		
			endif()	
		endif()
	endif()
	
	if(UNDIRECT)
		list(APPEND undirect_list ${UNDIRECT})
	endif()
endforeach()

if(undirect_list) #if true we need to be sure that the rpath-link does not contain some dirs of the rpath (otherwise the executable may not run)
	list(REMOVE_DUPLICATES undirect_list)
	set(${LIST_OF_UNDIRECT_DEPS} "${undirect_list}" PARENT_SCOPE)
endif()
endfunction(find_Dependent_Private_Shared_Libraries)


##################################################################################
################## binary packages configuration #################################
##################################################################################

### resolve runtime dependencies for packages
function(resolve_Package_Runtime_Dependencies package build_mode)
if(${package}_PREPARE_RUNTIME)#this is a guard to limit recursion -> the runtime has already been prepared
	return()
endif()

if(${package}_DURING_PREPARE_RUNTIME)
	message(FATAL_ERROR "Alert : cyclic dependencies between packages found : Package ${package} is undirectly requiring itself !")
	return()
endif()
set(${package}_DURING_PREPARE_RUNTIME TRUE)

if(build_mode MATCHES Debug)
set(MODE_SUFFIX _DEBUG)
elseif(build_mode MATCHES Release) 
set(MODE_SUFFIX "")
else()
message(FATAL_ERROR "bad argument, unknown mode \"${build_mode}\"")
endif()

# 1) resolving runtime dependencies by recursion (resolving dependancy packages' components first)
if(${package}_DEPENDENCIES${MODE_SUFFIX}) 
	foreach(dep IN ITEMS ${${package}_DEPENDENCIES${MODE_SUFFIX}})
		resolve_Package_Runtime_Dependencies(${dep} ${build_mode})
	endforeach()
endif()
# 2) resolving runtime dependencies of the package's own components
foreach(component IN ITEMS ${${package}_COMPONENTS})
	resolve_Bin_Component_Runtime_Dependencies(${package} ${component} ${build_mode})
endforeach()
set(${package}_DURING_PREPARE_RUNTIME FALSE)
set(${package}_PREPARE_RUNTIME TRUE)
endfunction(resolve_Package_Runtime_Dependencies)


### resolve runtime dependencies for components
function(resolve_Bin_Component_Runtime_Dependencies package component mode)
if(	${package}_${component}_TYPE STREQUAL "SHARED"
	OR ${package}_${component}_TYPE STREQUAL "MODULE" 
	OR ${package}_${component}_TYPE STREQUAL "APP" 
	OR ${package}_${component}_TYPE STREQUAL "EXAMPLE")
	if(mode MATCHES Debug)
		set(mode_suffix "_DEBUG")
	else()
		set(mode_suffix "")
	endif()
	# 1) getting direct runtime dependencies	
	get_Bin_Component_Runtime_Dependencies(ALL_SHARED_LIBS ${package} ${component} ${mode})#suppose that findPackage has resolved everything

	# 2) adding direct private external dependencies
	if(${package}_${component}_PRIVATE_LINKS${mode_suffix})#if there are exported links
		resolve_External_Libs_Path(RES_PRIVATE_LINKS ${package} "${${package}_${component}_PRIVATE_LINKS${mode_suffix}}" ${mode})#resolving libraries path against external packages path
		if(RES_PRIVATE_LINKS)
			foreach(lib IN ITEMS ${RES_PRIVATE_LINKS})
				is_Shared_Lib_With_Path(IS_SHARED ${lib})
				if(IS_SHARED)
					list(APPEND ALL_SHARED_LIBS ${lib})
				endif()
			endforeach()
		endif()
	endif()
	create_Bin_Component_Symlinks(${package} ${component} ${mode} "${ALL_SHARED_LIBS}")
endif()
endfunction(resolve_Bin_Component_Runtime_Dependencies)


### configuring components runtime paths (links to libraries)
function(create_Bin_Component_Symlinks bin_package bin_component mode shared_libs)
if(mode MATCHES Release)
	set(mode_string "")
elseif(mode MATCHES Debug)
	set(mode_string "-dbg")
else()
	return()
endif()

#creatings symbolic links
foreach(lib IN ITEMS ${shared_libs})
	create_Rpath_Symlink(${lib} ${${bin_package}_ROOT_DIR} ${bin_component}${mode_string})
endforeach()
endfunction(create_Bin_Component_Symlinks)


### recursive function to find runtime dependencies
function(get_Bin_Component_Runtime_Dependencies ALL_SHARED_LIBS package component mode)
	if(mode MATCHES Release)
		set(mode_binary_suffix "")
		set(mode_var_suffix "")
	elseif(mode MATCHES Debug)
		set(mode_binary_suffix "-dbg")
		set(mode_var_suffix "_DEBUG")
	else()
		return()
	endif()
	set(result "")

	# 1) adding directly exported external dependencies (only those bound to external package are interesting, system dependencies do not need a specific traetment)
	if(${package}_${component}_LINKS${mode_var_suffix})#if there are exported links
		resolve_External_Libs_Path(RES_LINKS ${package} "${${package}_${component}_LINKS${mode_var_suffix}}" ${mode})#resolving libraries path against external packages path
		if(RES_LINKS)
			foreach(lib IN ITEMS ${RES_LINKS})
				is_Shared_Lib_With_Path(IS_SHARED ${lib})
				if(IS_SHARED)
					list(APPEND result ${lib})
				endif()
			endforeach()
		endif()
	endif()
	

	# 2) adding package components dependencies
	foreach(dep_pack IN ITEMS ${${package}_${component}_DEPENDENCIES${mode_var_suffix}})
		#message("DEBUG : ${component}  depends on package ${dep_pack}")
		foreach(dep_comp IN ITEMS ${${package}_${component}_DEPENDENCY_${dep_pack}_COMPONENTS${mode_var_suffix}})
			#message("DEBUG : ${component} depends on package ${dep_comp} in ${dep_pack}")
			if(${dep_pack}_${dep_comp}_TYPE STREQUAL "HEADER" OR ${dep_pack}_${dep_comp}_TYPE STREQUAL "STATIC")		
				get_Bin_Component_Runtime_Dependencies(INT_DEP_SHARED_LIBS ${dep_pack} ${dep_comp} ${mode}) #need to resolve external symbols whether the component is exported or not (it may have unresolved symbols coming from shared libraries)
				if(INT_DEP_SHARED_LIBS)
					list(APPEND result ${INT_DEP_SHARED_LIBS})
				endif()
			elseif(${dep_pack}_${dep_comp}_TYPE STREQUAL "SHARED")
				list(APPEND result ${${dep_pack}_ROOT_DIR}/lib/${${dep_pack}_${dep_comp}_BINARY_NAME${mode_var_suffix}})#the shared library is a direct dependency of the component
				is_Bin_Component_Exporting_Other_Components(EXPORTING ${dep_pack} ${dep_comp} ${mode})
				if(EXPORTING) # doing transitive search only if shared libs export something
					get_Bin_Component_Runtime_Dependencies(INT_DEP_SHARED_LIBS ${dep_pack} ${dep_comp} ${mode}) #need to resolve external symbols whether the component is exported or not
					if(INT_DEP_SHARED_LIBS)# guarding against shared libs presence
						list(APPEND result ${INT_DEP_SHARED_LIBS})
					endif()
				endif() #no need to resolve external symbols if the shared library component is not exported
			endif()
		endforeach()
	endforeach()
	#message("DEBUG : runtime deps for component ${component}, AFTER PACKAGE DEPENDENCIES => ${result} ")

	# 3) adding internal components dependencies
	foreach(int_dep IN ITEMS ${${package}_${component}_INTERNAL_DEPENDENCIES${mode_var_suffix}})
		if(${package}_${int_dep}_TYPE STREQUAL "HEADER" OR ${package}_${int_dep}_TYPE STREQUAL "STATIC")		
			get_Bin_Component_Runtime_Dependencies(INT_DEP_SHARED_LIBS ${package} ${int_dep} ${mode}) #need to resolve external symbols whether the component is exported or not (it may have unresolved symbols coming from shared libraries)
			if(INT_DEP_SHARED_LIBS)
				list(APPEND result ${INT_DEP_SHARED_LIBS})
			endif()
		elseif(${package}_${int_dep}_TYPE STREQUAL "SHARED")
			# no need to link internal dependencies with symbolic links (they will be found automatically)
			is_Bin_Component_Exporting_Other_Components(EXPORTING ${package} ${int_dep} ${mode})
			if(EXPORTING) # doing transitive search only if shared libs export something
				get_Bin_Component_Runtime_Dependencies(INT_DEP_SHARED_LIBS ${package} ${int_dep} ${mode}) #need to resolve external symbols whether the component is exported or not
				if(INT_DEP_SHARED_LIBS)# guarding against shared libs presence
					list(APPEND result ${INT_DEP_SHARED_LIBS})
				endif()
			endif() #no need to resolve external symbols if the shared library component is not exported
		endif()
	endforeach()
	#message("DEBUG : runtime deps for component ${component}, AFTER INTERNAL DEPENDENCIES => ${result} ")
	# 4) adequately removing first duplicates in the list
	list(REVERSE result)
	list(REMOVE_DUPLICATES result)
	list(REVERSE result)
	#message("DEBUG : runtime deps for component ${component}, AFTER RETURNING => ${result} ")
	set(${ALL_SHARED_LIBS} ${result} PARENT_SCOPE)
endfunction(get_Bin_Component_Runtime_Dependencies)


##################################################################################
####################### source package run time dependencies #####################
##################################################################################

### configuring source components (currntly built) runtime paths (links to libraries)
function(create_Source_Component_Symlinks bin_component shared_libs)
foreach(lib IN ITEMS ${shared_libs})
	install_Rpath_Symlink(${lib} ${${PROJECT_NAME}_DEPLOY_PATH} ${bin_component})
endforeach()
endfunction(create_Source_Component_Symlinks)

### 
function(resolve_Source_Component_Runtime_Dependencies component THIRD_PARTY_LIBS)
if(	${PROJECT_NAME}_${component}_TYPE STREQUAL "SHARED" 
	OR ${PROJECT_NAME}_${component}_TYPE STREQUAL "MODULE" 
	OR ${PROJECT_NAME}_${component}_TYPE STREQUAL "APP" 
	OR ${PROJECT_NAME}_${component}_TYPE STREQUAL "EXAMPLE" )
	# 1) getting all public runtime dependencies (including inherited ones)	
	get_Bin_Component_Runtime_Dependencies(ALL_SHARED_LIBS ${PROJECT_NAME} ${component} ${CMAKE_BUILD_TYPE})
	
	# 2) adding direct private external dependencies
	if(${PROJECT_NAME}_${component}_PRIVATE_LINKS${USE_MODE_SUFFIX})#if there are exported links
		resolve_External_Libs_Path(RES_PRIVATE_LINKS ${PROJECT_NAME} "${${PROJECT_NAME}_${component}_PRIVATE_LINKS${USE_MODE_SUFFIX}}" ${CMAKE_BUILD_TYPE})#resolving libraries path against external packages path
		if(RES_PRIVATE_LINKS)
			foreach(lib IN ITEMS ${RES_PRIVATE_LINKS})
				is_Shared_Lib_With_Path(IS_SHARED ${lib})
				if(IS_SHARED)
					list(APPEND ALL_SHARED_LIBS ${lib})
				endif()
			endforeach()
		endif()
	endif()
	# 3) in case of an executable component add thirs party (undirect) links
	if(THIRD_PARTY_LIBS)
		list(APPEND ALL_SHARED_LIBS ${THIRD_PARTY_LIBS})
	endif()
	create_Source_Component_Symlinks(${component}${INSTALL_NAME_SUFFIX} "${ALL_SHARED_LIBS}")
endif()
endfunction(resolve_Source_Component_Runtime_Dependencies)

###############################################################################################
############################## cleaning the installed tree #################################### 
###############################################################################################
function(clean_Install_Dir)

if(	${CMAKE_BUILD_TYPE} MATCHES Release 
	AND EXISTS ${WORKSPACE_DIR}/install/${PROJECT_NAME}/${${PROJECT_NAME}_DEPLOY_PATH}
	AND IS_DIRECTORY ${WORKSPACE_DIR}/install/${PROJECT_NAME}/${${PROJECT_NAME}_DEPLOY_PATH})# if package is already installed
	# calling a script that will do the job in its own context (to avoid problem when including cmake scripts that would redefine critic variables)
	execute_process(COMMAND ${CMAKE_COMMAND} -DWORKSPACE_DIR=${WORKSPACE_DIR} 
						 -DPACKAGE_NAME=${PROJECT_NAME}
						 -DPACKAGE_INSTALL_VERSION=${${PROJECT_NAME}_DEPLOY_PATH} 
						 -DPACKAGE_VERSION=${${PROJECT_NAME}_VERSION}
						 -DNEW_USE_FILE=${CMAKE_BINARY_DIR}/share/Use${PROJECT_NAME}-${${PROJECT_NAME}_VERSION}.cmake
						 -P ${WORKSPACE_DIR}/share/cmake/system/Clear_PID_Package_Install.cmake
			WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
endif()
endfunction(clean_Install_Dir)


