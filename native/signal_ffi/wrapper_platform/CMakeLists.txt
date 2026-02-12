# CMakeLists.txt for Platform-Specific Callback Bridge
# Phase 14: Signal Protocol Implementation - Option 1

cmake_minimum_required(VERSION 3.10)
project(signal_callback_bridge)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Add source files
add_library(signal_callback_bridge SHARED
    callback_bridge.c
)

# Set output directory
set_target_properties(signal_callback_bridge PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/../.."
)

# Platform-specific settings
if(APPLE)
    set_target_properties(signal_callback_bridge PROPERTIES
        MACOSX_RPATH ON
        BUILD_WITH_INSTALL_RPATH ON
    )
    # Set install_name explicitly to @loader_path (resolves relative to library's directory)
    set_target_properties(signal_callback_bridge PROPERTIES
        INSTALL_NAME "@loader_path/libsignal_callback_bridge.dylib"
    )
endif()

if(UNIX AND NOT APPLE)
    # Linux
    set_target_properties(signal_callback_bridge PROPERTIES
        PREFIX "lib"
    )
endif()

if(WIN32)
    # Windows
    set_target_properties(signal_callback_bridge PROPERTIES
        PREFIX ""
        SUFFIX ".dll"
    )
endif()
