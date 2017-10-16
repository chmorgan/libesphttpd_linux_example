cmake_minimum_required(VERSION 3.9)

enable_testing()

include(ExternalProject)

set(DEFAULT_INSTALL_DIR ${CMAKE_BINARY_DIR}/install)

set(ARGS "-DCMAKE_INSTALL_PREFIX=${DEFAULT_INSTALL_DIR}")

message("ARGS is ${ARGS}")

ExternalProject_Add(esphttpd
	SOURCE_DIR "${CMAKE_SOURCE_DIR}/libesphttpd"
	DOWNLOAD_COMMAND ""
	UPDATE_COMMAND ""
	CMAKE_ARGS ${ARGS}
)

ExternalProject_Add(httpd
	SOURCE_DIR "${CMAKE_SOURCE_DIR}/httpd"
	DOWNLOAD_COMMAND ""
	UPDATE_COMMAND ""
	CMAKE_ARGS ${ARGS}
)

ExternalProject_Add(tests
	SOURCE_DIR "${CMAKE_SOURCE_DIR}/tests"
	DOWNLOAD_COMMAND ""
	UPDATE_COMMAND ""
	CMAKE_ARGS ${ARGS}
)

add_test(NAME test_post
	COMMAND ${DEFAULT_INSTALL_DIR}/bin/test_post.sh
	WORKING_DIRECTORY ${DEFAULT_INSTALL_DIR}/bin
)
