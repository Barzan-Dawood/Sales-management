# This file controls Flutter-level build steps. It should not be edited.
cmake_minimum_required(VERSION 3.10)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter tool.
if(EXISTS ${EPHEMERAL_DIR}/generated_config.cmake)
  include(${EPHEMERAL_DIR}/generated_config.cmake)
else()
  # Default values when generated_config.cmake is not yet available
  # These will be overridden when Flutter generates the file
  if(NOT DEFINED FLUTTER_ROOT)
    set(FLUTTER_ROOT "$ENV{FLUTTER_ROOT}")
  endif()
  if(NOT DEFINED FLUTTER_TARGET_PLATFORM)
    set(FLUTTER_TARGET_PLATFORM "linux-x64")
  endif()
  if(NOT DEFINED FLUTTER_TARGET_ARCH)
    set(FLUTTER_TARGET_ARCH "x64")
  endif()
  if(NOT DEFINED PROJECT_DIR)
    get_filename_component(PROJECT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
  endif()
endif()

# TODO: Move the rest of this into files in ephemeral. See
# https://github.com/flutter/flutter/issues/57146.

# Serves the same purpose as list(TRANSFORM ... PREPEND ...),
# which isn't available in 3.10.
function(list_prepend LIST_NAME PREFIX)
    set(NEW_LIST "")
    foreach(element ${${LIST_NAME}})
        list(APPEND NEW_LIST "${PREFIX}${element}")
    endforeach(element)
    set(${LIST_NAME} "${NEW_LIST}" PARENT_SCOPE)
endfunction()

# === Flutter Library ===
# System-level dependencies.
# PkgConfig is only available on Linux/Unix systems
# On Windows, this will fail but allows CMake to configure for IDE purposes
# Actual Linux builds must be done on Linux or WSL
find_package(PkgConfig)
if(PkgConfig_FOUND)
  pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)
  pkg_check_modules(GLIB REQUIRED IMPORTED_TARGET glib-2.0)
  pkg_check_modules(GIO REQUIRED IMPORTED_TARGET gio-2.0)
else()
  # Create stub targets for Windows IDE configuration
  # These won't work for actual builds - Linux builds must be done on Linux/WSL
  message(WARNING "PkgConfig not found. Linux builds require PkgConfig and GTK libraries.")
  message(WARNING "For actual Linux builds, use Linux or WSL. This configuration is for IDE purposes only.")
  
  # Create stub imported targets
  add_library(PkgConfig::GTK INTERFACE IMPORTED)
  add_library(PkgConfig::GLIB INTERFACE IMPORTED)
  add_library(PkgConfig::GIO INTERFACE IMPORTED)
endif()

set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/libflutter_linux_gtk.so")

# Published to parent scope for install step.
set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)
set(PROJECT_BUILD_DIR "${PROJECT_DIR}/build/" PARENT_SCOPE)
set(AOT_LIBRARY "${PROJECT_DIR}/build/lib/libapp.so" PARENT_SCOPE)

list(APPEND FLUTTER_LIBRARY_HEADERS
  "fl_basic_message_channel.h"
  "fl_binary_codec.h"
  "fl_binary_messenger.h"
  "fl_dart_project.h"
  "fl_engine.h"
  "fl_json_message_codec.h"
  "fl_json_method_codec.h"
  "fl_message_codec.h"
  "fl_method_call.h"
  "fl_method_channel.h"
  "fl_method_codec.h"
  "fl_method_response.h"
  "fl_plugin_registrar.h"
  "fl_plugin_registry.h"
  "fl_standard_message_codec.h"
  "fl_standard_method_codec.h"
  "fl_string_codec.h"
  "fl_value.h"
  "fl_view.h"
  "flutter_linux.h"
)
list_prepend(FLUTTER_LIBRARY_HEADERS "${EPHEMERAL_DIR}/flutter_linux/")
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}"
)
target_link_libraries(flutter INTERFACE "${FLUTTER_LIBRARY}")
target_link_libraries(flutter INTERFACE
  PkgConfig::GTK
  PkgConfig::GLIB
  PkgConfig::GIO
)
add_dependencies(flutter flutter_assemble)

# === Flutter tool backend ===
# _phony_ is a non-existent file to force this command to run every time,
# since currently there's no way to get a full input/output list from the
# flutter tool.
add_custom_command(
  OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY_HEADERS}
    ${CMAKE_CURRENT_BINARY_DIR}/_phony_
  COMMAND ${CMAKE_COMMAND} -E env
    ${FLUTTER_TOOL_ENVIRONMENT}
    "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.sh"
      ${FLUTTER_TARGET_PLATFORM} ${CMAKE_BUILD_TYPE}
  VERBATIM
)
add_custom_target(flutter_assemble DEPENDS
  "${FLUTTER_LIBRARY}"
  ${FLUTTER_LIBRARY_HEADERS}
)
