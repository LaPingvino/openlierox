set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE dynamic)

set(VCPKG_CMAKE_SYSTEM_NAME Linux)

# Set ZIG_TARGET before chainload so it's available to the toolchain
set(ZIG_TARGET "aarch64-linux-gnu" CACHE STRING "Zig target triple" FORCE)

set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/zig-toolchain.cmake")
