# CMakeLists.txt for Signal FFI Wrapper
# Phase 14: Signal Protocol Implementation - Option 1
#
# Build configuration for Android and Linux platforms

cmake_minimum_required(VERSION 3.18.1)
project(signal_ffi_wrapper)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Include directories
# Note: We need to include the libsignal-ffi header directory
# The actual path will depend on where libsignal is located
include_directories(
    ../libsignal/swift/Sources/SignalFfi
)

# Source files
set(SOURCES
    wrapper.c
)

# Create shared library
add_library(signal_ffi_wrapper SHARED ${SOURCES})

# Platform-specific settings
if(ANDROID)
    # Android-specific settings
    set_target_properties(signal_ffi_wrapper PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../android/${ANDROID_ABI}"
    )
elseif(APPLE)
    # macOS-specific settings
    set_target_properties(signal_ffi_wrapper PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../macos"
    )
elseif(UNIX)
    # Linux-specific settings
    set_target_properties(signal_ffi_wrapper PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../linux"
    )
endif()
