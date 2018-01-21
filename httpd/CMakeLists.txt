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

find_package(OpenSSL REQUIRED)
if( OpenSSL_FOUND )
    include_directories(${OPENSSL_INCLUDE_DIRS})
    link_directories(${OPENSSL_LIBRARIES})
    message(STATUS "Using OpenSSL ${OPENSSL_VERSION}")
endif()

find_library(RT_LIBRARY rt)
if(!RT_LIBRARY_FOUND)
    message(STATUS "Unable to find rt")
else()
    message(STATUS "rt found ${RT_LIBRARY}")
endif()

find_package(Threads)

find_library(ESPHTTPD_LIBRARY NAMES esphttpd)
message("Found library ${ESPHTTPD_LIBRARY}")

function(configure_target target_name)
    add_executable(${target_name} main.c ${certificateResources})

    target_compile_definitions(${target_name} PUBLIC "CONFIG_ESPHTTPD_SHUTDOWN_SUPPORT")
    target_compile_definitions(${target_name} PUBLIC "CONFIG_ESPHTTPD_SSL_SUPPORT")

    target_link_libraries(${target_name} libwebpages)

    target_link_libraries(${target_name} ${ESPHTTPD_LIBRARY})

    target_link_libraries(${target_name} ${OPENSSL_LIBRARIES})

    target_link_libraries(${target_name} ${CMAKE_THREAD_LIBS_INIT})

    target_link_libraries(${target_name} ${RT_LIBRARY})

    target_include_directories(${target_name} PUBLIC ${CMAKE_INSTALL_PREFIX}/include)

    install(TARGETS ${target_name} DESTINATION bin)
endfunction(configure_target)

configure_target(httpd)
