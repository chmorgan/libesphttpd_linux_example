cmake_minimum_required(VERSION 3.9)

# Compilation step for static resources
# See https://beesbuzz.biz/blog/e/2014/07/31-embedding_binary_resources_with_cmake_and_c11.php
FUNCTION(ADD_RESOURCES out_var)
  SET(result)
  FOREACH(in_f ${ARGN})
    FILE(RELATIVE_PATH src_f ${CMAKE_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/${in_f})
    SET(out_f "${PROJECT_BINARY_DIR}/${in_f}.o")
    SET(src_f_tmp "${PROJECT_BINARY_DIR}/${src_f}")
    MESSAGE(STATUS ${src_f})
    MESSAGE(STATUS ${src_f_tmp})
    ADD_CUSTOM_COMMAND(OUTPUT ${out_f}
      COMMAND ld -r -b binary -o ${out_f} ${src_f}
      DEPENDS ${in_f}
      WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
      COMMENT "Adding object ${out_f}"
      VERBATIM
      )
    LIST(APPEND result ${out_f})
  ENDFOREACH()
  SET(${out_var} "${result}" PARENT_SCOPE)
ENDFUNCTION()

# A simple program that uses resources
ADD_RESOURCES(certificateResources cacert.der prvtkey.der)

add_custom_command(OUTPUT libwebpages-espfs.a
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/html
    COMMAND find | ${CMAKE_INSTALL_PREFIX}/bin/mkespfsimage > ${CMAKE_BINARY_DIR}/webpages.espfs
    COMMAND objcopy -I binary -O elf64-x86-64 -B i386 --rename-section .data=.rodata ${CMAKE_BINARY_DIR}/webpages.espfs ${CMAKE_BINARY_DIR}/webpages.espfs.o.tmp
    COMMAND gcc -nostdlib -Wl,-r ${CMAKE_BINARY_DIR}/webpages.espfs.o.tmp -o ${CMAKE_BINARY_DIR}/webpages.espfs.o -Wl,-T ${CMAKE_SOURCE_DIR}/linker.ld
    COMMAND ar cru ${CMAKE_BINARY_DIR}/libwebpages-espfs.a ${CMAKE_BINARY_DIR}/webpages.espfs.o
)

add_custom_target(libwebpages_target DEPENDS libwebpages-espfs.a)

# create an library target out of the library compilation result
add_library(libwebpages STATIC IMPORTED GLOBAL)
add_dependencies(libwebpages libwebpages_target)

# specify where the library is and where to find the headers
set_target_properties(libwebpages
    PROPERTIES
    IMPORTED_LOCATION libwebpages-espfs.a
)

add_executable(httpd main.c ${certificateResources})

target_compile_definitions(httpd PUBLIC "CONFIG_ESPHTTPD_MAX_CONNECTIONS=100")

target_link_libraries(httpd libwebpages)


find_library(ESPHTTPD_LIBRARY NAMES esphttpd)
message("Found library ${ESPHTTPD_LIBRARY}")
target_link_libraries(httpd ${ESPHTTPD_LIBRARY})

find_package(OpenSSL REQUIRED)
if( OpenSSL_FOUND )
    include_directories(${OPENSSL_INCLUDE_DIRS})
    link_directories(${OPENSSL_LIBRARIES})
    message(STATUS "Using OpenSSL ${OPENSSL_VERSION}")
endif()
target_link_libraries(httpd ${OPENSSL_LIBRARIES})

find_package(Threads)
target_link_libraries(httpd ${CMAKE_THREAD_LIBS_INIT})

find_library(RT_LIBRARY rt)
if(!RT_LIBRARY_FOUND)
    message(STATUS "Unable to find rt")
else()
    message(STATUS "rt found ${RT_LIBRARY}")
endif()
target_link_libraries(httpd ${RT_LIBRARY})

target_include_directories(httpd PUBLIC ${CMAKE_INSTALL_PREFIX}/include)

install(TARGETS httpd DESTINATION bin)
