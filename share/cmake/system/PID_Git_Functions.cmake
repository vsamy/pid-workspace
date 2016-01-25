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


######################################################################
############# function used to navigate between branches #############
######################################################################

###
function(go_To_Integration package)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git checkout integration
		OUTPUT_QUIET ERROR_QUIET)
endfunction(go_To_Integration)
###
function(go_To_Master package)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git checkout master
		OUTPUT_QUIET ERROR_QUIET)
endfunction(go_To_Master)

###
function(go_To_Workspace_Master)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR} git checkout master
		OUTPUT_QUIET ERROR_QUIET)
endfunction(go_To_Workspace_Master)

###
function(go_To_Workspace_Development)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR} git checkout development
		OUTPUT_QUIET ERROR_QUIET)
endfunction(go_To_Workspace_Development)

###
function(go_To_Commit repo branch)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${repo} git checkout ${branch}
		OUTPUT_QUIET ERROR_QUIET)
endfunction(go_To_Commit)

###
function(go_To_Version package version)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git checkout tags/v${version}
		OUTPUT_QUIET ERROR_QUIET)
endfunction(go_To_Version)


###
function(get_Repository_Version_Tags AVAILABLE_VERSIONS package)
set(${AVAILABLE_VERSIONS} PARENT_SCOPE)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git tag -l v*
		OUTPUT_VARIABLE res)

if(NOT res) #no version available => BUG
	return()
endif()
string(REPLACE "\n" ";" GIT_VERSIONS ${res})
set(${AVAILABLE_VERSIONS} ${GIT_VERSIONS} PARENT_SCOPE)
endfunction(get_Repository_Version_Tags)

###
function(normalize_Version_Tags VERSION_NUMBERS VERSIONS_TAGS)
foreach(tag IN ITEMS ${VERSIONS_TAGS})
	string(REGEX REPLACE "^v(.*)$" "\\1" VNUMBERS ${tag})
	list(APPEND result ${VNUMBERS})
endforeach()
set(${VERSION_NUMBERS} ${result} PARENT_SCOPE)
endfunction(normalize_Version_Tags)


###
function(get_Repository_Current_Branch BRANCH_NAME repo)
set(${BRANCH_NAME} PARENT_SCOPE)
execute_process(COMMAND git branch
		WORKING_DIRECTORY ${repo}
		OUTPUT_VARIABLE current_branches ERROR_QUIET)
string(REPLACE "\n" ";" GIT_BRANCHES ${current_branches})

foreach(branch IN ITEMS ${GIT_BRANCHES})
	string(REGEX REPLACE "^\\* (.*)$" "\\1" A_BRANCH ${branch})
	if(NOT "${branch}" STREQUAL "${A_BRANCH}")#i.e. match found (this is the current branch)
		set(${BRANCH_NAME} ${A_BRANCH} PARENT_SCOPE)
		break()
	endif()
endforeach()
return()
endfunction(get_Repository_Current_Branch)


###
function(get_Repository_Current_Commit COMMIT_NAME repo)
set(${COMMIT_NAME} PARENT_SCOPE)
execute_process(COMMAND git log -n 1
		WORKING_DIRECTORY ${repo}
		OUTPUT_VARIABLE last_log ERROR_QUIET)
string(REPLACE "\n" ";" LINES ${last_log})
string(REGEX REPLACE "^commit ([^;]+).*$" "\\1" SHA1_ID ${LINES})
set(${COMMIT_NAME} ${SHA1_ID} PARENT_SCOPE)
endfunction(get_Repository_Current_Commit)


###
function(save_Repository_Context INITIAL_COMMIT SAVED_CONTENT package)
get_Repository_Current_Branch(BRANCH_NAME ${WORKSPACE_DIR}/packages/${package})
if(NOT BRANCH_NAME)
	get_Repository_Current_Commit(COMMIT_NAME ${WORKSPACE_DIR}/packages/${package})
	set(CONTEXT ${COMMIT_NAME})
else()
	set(CONTEXT ${BRANCH_NAME})
endif()
set(${INITIAL_COMMIT} ${CONTEXT} PARENT_SCOPE)

execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git stash save OUTPUT_QUIET ERROR_QUIET)
set(${SAVED_CONTENT} TRUE PARENT_SCOPE)
endfunction(save_Repository_Context)

###
function(restore_Repository_Context package initial_commit saved_content)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git checkout -- license.txt OUTPUT_QUIET ERROR_QUIET)#this is a mandatory step due to the generation of a versionned license file when build takes place

go_To_Commit(${WORKSPACE_DIR}/packages/${package} ${initial_commit})
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git stash pop OUTPUT_QUIET ERROR_QUIET)
endfunction(restore_Repository_Context)


###
function(save_Workspace_Repository_Context INITIAL_COMMIT SAVED_CONTENT)
get_Repository_Current_Branch(BRANCH_NAME ${WORKSPACE_DIR})
if(NOT BRANCH_NAME)
get_Repository_Current_Commit(COMMIT_NAME ${WORKSPACE_DIR})
set(CONTEXT ${COMMIT_NAME})
else()
set(CONTEXT ${BRANCH_NAME})
endif()
set(${INITIAL_COMMIT} ${CONTEXT} PARENT_SCOPE)

execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR} git stash save OUTPUT_QUIET ERROR_QUIET)
set(${SAVED_CONTENT} TRUE PARENT_SCOPE)
endfunction(save_Workspace_Repository_Context)

###
function(restore_Workspace_Repository_Context initial_commit saved_content)
go_To_Commit(${WORKSPACE_DIR} ${initial_commit})
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR} git stash pop OUTPUT_QUIET ERROR_QUIET)
endfunction(restore_Workspace_Repository_Context)

######################################################################
############# function used to merge standard branches ###############
######################################################################

###
function(merge_Into_Master package version_string)
go_To_Master(${package})
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git merge integration)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git tag -a v${version_string} -m "releasing version ${version_string}")
endfunction(merge_Into_Master)

###
function(merge_Into_Integration package)
go_To_Integration(${package})
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git merge master)
endfunction(merge_Into_Integration)

###
function(commit_Current_Repository_Branch package commit_message)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git add --all)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git commit -m "${commit_message}")
endfunction(commit_Current_Repository_Branch)


### registering the address means registering the CMakelists.txt
function(register_Repository_Address package)
go_To_Integration(${package})
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git add CMakeLists.txt)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git commit -m "adding repository address to the root CMakeLists.txt file")
endfunction(register_Repository_Address)

###
function(register_Repository_Version package version_string)
go_To_Integration(${package})
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git add CMakeLists.txt)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git commit -m "start new version ${version_string}")
endfunction(register_Repository_Version)

#############################################################################
############# function used to publish/update modifications   ###############
#############################################################################

###
function(publish_References_In_Workspace_Repository package)
if(EXISTS ${WORKSPACE_DIR}/share/cmake/find/Find${package}.cmake AND EXISTS ${WORKSPACE_DIR}/share/cmake/references/Refer${package}.cmake)
	execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR} git add share/cmake/find/Find${package}.cmake)
	execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR} git add share/cmake/references/Refer${package}.cmake)
	execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR} git commit -m "${package} registered")
	execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR} git push origin master)
else()
	message("ERROR : problem registering package ${package}, cannot generate adequate cmake files")
endif()
endfunction(publish_References_In_Workspace_Repository)

###
function(publish_Repository_Version package version_string)
go_To_Master(${package})
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git push origin master)#releasing on master branch
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git push origin v${version_string})#releasing version tag
endfunction(publish_Repository_Version)

###
function(publish_Repository_Integration package)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git push origin integration)#releasing on master branch
endfunction(publish_Repository_Integration)


###
function(update_Repository_Versions package)
go_To_Master(${package})
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git pull origin master)#pulling master branch of origin
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git fetch origin --tags)#getting new tags
endfunction(update_Repository_Versions)

###
function(update_Workspace_Repository remote)
go_To_Workspace_Master()
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR} git pull ${remote} master)#pulling master branch of origin or official
endfunction(update_Workspace_Repository)

######################################################################
############################ other functions #########################
######################################################################

### to know whether a package as a remote or not
function(is_Package_Connected CONNECTED package branch)
	execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git remote show ${branch} OUTPUT_QUIET ERROR_VARIABLE res)
	if(NOT res OR res STREQUAL "")
		set(${CONNECTED} TRUE PARENT_SCOPE)
	else()
		set(${CONNECTED} FALSE PARENT_SCOPE)
	endif()
endfunction()

### function called when deploying a package from reference files
function(clone_Repository IS_DEPLOYED package url)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages git clone ${url} OUTPUT_QUIET ERROR_QUIET)
if(EXISTS ${WORKSPACE_DIR}/packages/${package} AND IS_DIRECTORY ${WORKSPACE_DIR}/packages/${package})
	set(${IS_DEPLOYED} TRUE PARENT_SCOPE)
	execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git fetch origin OUTPUT_QUIET ERROR_QUIET)
	execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git checkout integration OUTPUT_QUIET ERROR_QUIET)#go to integration to create the local branch
	execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git checkout master OUTPUT_QUIET ERROR_QUIET)#go back to master by default

	# now adding reference to official remote with official == origin (default case)
	execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git remote add official ${url})
	execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git fetch official OUTPUT_QUIET ERROR_QUIET) #updating remote branches for official remote
else()
	set(${IS_DEPLOYED} FALSE PARENT_SCOPE)
	message("[PID notification] ERROR: impossible to clone the repository of package ${package} (bad repository address or you have no clone rights for this repository). Please contact the administrator of this package.")
endif()
endfunction(clone_Repository)

function(test_Remote_Initialized package url INITIALIZED)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/pid git clone ${url} OUTPUT_QUIET ERROR_QUIET)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/pid/${package} git branch -a OUTPUT_VARIABLE res ERROR_QUIET)
if (res MATCHES "origin/integration") #repository is initialized if there is a
	set(${INITIALIZED} TRUE PARENT_SCOPE)
else()
	set(${INITIALIZED} FALSE PARENT_SCOPE)
endif()
execute_process(COMMAND ${CMAKE_COMMAND} -E remove_directory ${WORKSPACE_DIR}/pid/${package} OUTPUT_QUIET ERROR_QUIET)
endfunction(test_Remote_Initialized)

### create a repository with no official remote specified (for now)
function(init_Repository package)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git init OUTPUT_QUIET ERROR_QUIET)
#otherwise we need to initialize the system
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git add -A  OUTPUT_QUIET ERROR_QUIET)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git commit -m "initialization of package done" OUTPUT_QUIET ERROR_QUIET)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git tag -a v0.0.0 -m "creation of package" OUTPUT_QUIET ERROR_QUIET)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git checkout -b integration master  OUTPUT_QUIET ERROR_QUIET)
endfunction(init_Repository)

### first time the package is connected after its creation
function(connect_Repository package url)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git remote add origin ${url})
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git remote add official ${url})
go_To_Master(${package}) #updating official (theorically just to synchronize adequately remote tracking branches)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git pull official master)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git fetch official --tags)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git push origin --tags OUTPUT_QUIET ERROR_QUIET)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git push origin master  OUTPUT_QUIET ERROR_QUIET)
go_To_Integration(${package}) #updating origin (theorically just to synchronize adequately remote tracking branches)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git pull origin integration)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git push origin integration  OUTPUT_QUIET ERROR_QUIET)
endfunction(connect_Repository)

### rare use function: when official repository has moved
function(reconnect_Repository package url)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git remote set-url official ${url})
go_To_Master(${package})
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git pull official master)#updating master
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git fetch official --tags  OUTPUT_QUIET ERROR_QUIET)
go_To_Integration(${package})
endfunction(reconnect_Repository)

###
function(change_Origin_Repository package url)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git remote set-url origin ${url} OUTPUT_QUIET ERROR_QUIET)
go_To_Integration(${package})
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git pull origin integration OUTPUT_QUIET ERROR_QUIET)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/packages/${package} git push origin integration OUTPUT_QUIET ERROR_QUIET)
message("[PID notification] INFO: Origin remote has been changed to ${url}.")
endfunction(change_Origin_Repository)



### getting the package name given a repository address
function(get_Repository_Name RES_NAME git_url)
#testing ssh address
string(REGEX REPLACE "^[^@]+@[^:]+:(.+)$" "\\1" REPO_PATH ${git_url})
if(REPO_PATH STREQUAL "${git_url}")
	#testing https address
	string(REGEX REPLACE "^https?://(.*)$" "\\1" REPO_PATH ${git_url})
	if(REPO_PATH STREQUAL "${git_url}")
		return()
	endif()
endif()
get_filename_component(REPO_NAME ${REPO_PATH} NAME_WE)
set(${RES_NAME} ${REPO_NAME} PARENT_SCOPE) 
endfunction(get_Repository_Name)

######################################################################
############## wiki repository related functions #####################
######################################################################

###
function(clone_Wiki_Repository IS_DEPLOYED package url)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/wikis git clone ${url} OUTPUT_QUIET ERROR_QUIET)
if(EXISTS ${WORKSPACE_DIR}/wikis/${package}.wiki AND IS_DIRECTORY ${WORKSPACE_DIR}/wikis/${package}.wiki)
	set(${IS_DEPLOYED} TRUE PARENT_SCOPE)
	execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/wikis/${package}.wiki git fetch origin OUTPUT_QUIET ERROR_QUIET) #just in case of
else()
	set(${IS_DEPLOYED} FALSE PARENT_SCOPE)
	message("[PID ERROR] : impossible to clone the repository of package ${package} wiki (bad repository address or you have no clone rights for this repository). Please contact the administrator of this package.")
endif()
endfunction(clone_Wiki_Repository)

###
function(init_Wiki_Repository CONNECTED package wiki_git_url)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/wikis/${package}.wiki git init OUTPUT_QUIET ERROR_QUIET)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/wikis/${package}.wiki git remote add origin ${wiki_git_url} OUTPUT_QUIET ERROR_QUIET)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/wikis/${package}.wiki git add -A OUTPUT_QUIET ERROR_QUIET)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/wikis/${package}.wiki git commit -m "initialization of wiki" OUTPUT_QUIET ERROR_QUIET)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/wikis/${package}.wiki git push origin master OUTPUT_QUIET ERROR_QUIET)
#now testing if everything is OK using the git log command
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/wikis/${package}.wiki git log --oneline --decorate --max-count=1 OUTPUT_VARIABLE res ERROR_QUIET)
if (NOT "${res}" STREQUAL "")
	string(FIND "${res}" "master" INDEX_LOCAL)
	string(FIND "${res}" "origin/master" INDEX_REMOTE)
	if(INDEX_LOCAL GREATER 0 AND INDEX_REMOTE GREATER 0)# both found => the last commit on master branch is tracked by local and remote master branch  
		set(${CONNECTED} TRUE PARENT_SCOPE)
		return()
	endif()
endif()
set(${CONNECTED} FALSE PARENT_SCOPE)
endfunction(init_Wiki_Repository)

###
function(update_Wiki_Repository package)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/wikis/${package}.wiki git pull origin master OUTPUT_QUIET ERROR_QUIET)#pulling master branch of origin (in case of) => merge can take place
endfunction(update_Wiki_Repository)

###
function(publish_Wiki_Repository package)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/wikis/${package}.wiki git add -A OUTPUT_QUIET ERROR_QUIET)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/wikis/${package}.wiki git commit -m "initialization of wiki" OUTPUT_QUIET ERROR_QUIET)
execute_process(COMMAND ${CMAKE_COMMAND} -E chdir ${WORKSPACE_DIR}/wikis/${package}.wiki git push origin master)#pushing to master branch of origin
endfunction(publish_Wiki_Repository package)

