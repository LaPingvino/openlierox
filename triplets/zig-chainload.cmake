# Custom chainload toolchain for vcpkg cross-compile via the zig wrappers
# created in CI. vcpkg's default scripts/toolchains/linux.cmake hardcodes
# aarch64-linux-gnu-gcc / aarch64-linux-gnu-g++ when it sees
# VCPKG_TARGET_ARCHITECTURE=arm64 on an x86_64 host. We don't have those
# packages installed; we use zig as the cross compiler instead. By pointing
# VCPKG_CHAINLOAD_TOOLCHAIN_FILE at this file in the triplet, we override
# the default toolchain and pick up the wrappers via CC/CXX env vars
# exported by the workflow.

if(DEFINED ENV{CC})
    set(CMAKE_C_COMPILER "$ENV{CC}" CACHE FILEPATH "C compiler")
endif()
if(DEFINED ENV{CXX})
    set(CMAKE_CXX_COMPILER "$ENV{CXX}" CACHE FILEPATH "CXX compiler")
endif()

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
