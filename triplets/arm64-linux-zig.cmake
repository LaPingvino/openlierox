set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

set(VCPKG_CMAKE_SYSTEM_NAME Linux)
set(VCPKG_CMAKE_SYSTEM_PROCESSOR aarch64)

# vcpkg's default linux.cmake hardcodes aarch64-linux-gnu-gcc for arm64
# cross-compile. We use zig wrappers exported via CC/CXX instead, so
# chainload our own toolchain that respects those env vars.
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/zig-chainload.cmake")

# Force vcpkg to build X11 libraries instead of using system ones
set(X_VCPKG_FORCE_VCPKG_X_LIBRARIES ON)
