# Zig toolchain for vcpkg cross-compilation
# ZIG_TARGET should be set by the triplet file or environment

# Guard against multiple inclusions
if(DEFINED _ZIG_TOOLCHAIN_LOADED)
    return()
endif()
set(_ZIG_TOOLCHAIN_LOADED TRUE)

# Try to get ZIG_TARGET from cache, environment, or fail
if(NOT DEFINED ZIG_TARGET)
    if(DEFINED ENV{ZIG_TARGET})
        set(ZIG_TARGET "$ENV{ZIG_TARGET}" CACHE STRING "Zig target triple" FORCE)
    else()
        message(FATAL_ERROR "ZIG_TARGET must be defined (set via triplet or ZIG_TARGET environment variable)")
    endif()
endif()

# Find Zig executable
find_program(ZIG_EXECUTABLE zig REQUIRED)

# Create wrapper scripts for Zig to avoid CMAKE_C_COMPILER_ARG1 issues
set(ZIG_WRAPPER_DIR "${CMAKE_CURRENT_BINARY_DIR}/zig-wrappers")
file(MAKE_DIRECTORY "${ZIG_WRAPPER_DIR}")

# Create C compiler wrapper
file(WRITE "${ZIG_WRAPPER_DIR}/zig-cc" "#!/bin/sh\nexec ${ZIG_EXECUTABLE} cc -target ${ZIG_TARGET} \"$@\"\n")
file(CHMOD "${ZIG_WRAPPER_DIR}/zig-cc" PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

# Create C++ compiler wrapper
file(WRITE "${ZIG_WRAPPER_DIR}/zig-cxx" "#!/bin/sh\nexec ${ZIG_EXECUTABLE} c++ -target ${ZIG_TARGET} \"$@\"\n")
file(CHMOD "${ZIG_WRAPPER_DIR}/zig-cxx" PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

# Set compilers to use wrapper scripts
set(CMAKE_C_COMPILER "${ZIG_WRAPPER_DIR}/zig-cc" CACHE FILEPATH "C compiler")
set(CMAKE_CXX_COMPILER "${ZIG_WRAPPER_DIR}/zig-cxx" CACHE FILEPATH "C++ compiler")

# Set the system processor based on target
if(ZIG_TARGET MATCHES "^x86_64")
    set(CMAKE_SYSTEM_PROCESSOR x86_64 CACHE STRING "")
elseif(ZIG_TARGET MATCHES "^aarch64")
    set(CMAKE_SYSTEM_PROCESSOR aarch64 CACHE STRING "")
endif()

# For vcpkg ports, we need to make sure the compiler works
set(CMAKE_C_COMPILER_WORKS TRUE CACHE BOOL "")
set(CMAKE_CXX_COMPILER_WORKS TRUE CACHE BOOL "")
