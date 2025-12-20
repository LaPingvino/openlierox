# vcpkg Setup for OpenLieroX

This document explains the vcpkg-based dependency management system for OpenLieroX.

## Overview

OpenLieroX now supports vcpkg for cross-platform dependency management. This solves the problem of having consistent dependencies across different build environments and platforms.

## Key Files

- **vcpkg.json** - Manifest file listing all dependencies
- **triplets/*.cmake** - Custom triplet files for cross-compilation with Zig
- **CMakeOlxVcpkg.cmake** - vcpkg-specific dependency configuration
- **CMakeOlxCommon.cmake** - Modified to support USE_VCPKG option

## Building with vcpkg

### Prerequisites

1. **Zig** (version 0.15.2 or compatible)
2. **CMake** (version 3.10+)
3. **vcpkg** (automatically handled by GitHub Actions)

### Local Build

```bash
# Clone vcpkg if you don't have it
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.sh
export VCPKG_ROOT=$(pwd)
cd ..

# Install dependencies for your platform
$VCPKG_ROOT/vcpkg install \
  --triplet=x64-linux-zig \
  --overlay-triplets=./triplets

# Configure with CMake
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake \
  -DVCPKG_TARGET_TRIPLET=x64-linux-zig \
  -DVCPKG_OVERLAY_TRIPLETS=./triplets \
  -DUSE_VCPKG=ON \
  -DHAWKNL_BUILTIN=Yes \
  -DLIBZIP_BUILTIN=Yes \
  -DLIBLUA_BUILTIN=Yes

# Build
cmake --build build -j$(nproc)
```

### Cross-Compilation

The triplets support cross-compilation to all target platforms:

- `x64-linux-zig` - Linux x86_64
- `arm64-linux-zig` - Linux ARM64
- `x64-osx-zig` - macOS x86_64
- `arm64-osx-zig` - macOS ARM64 (Apple Silicon)
- `x64-windows-zig` - Windows x86_64
- `arm64-windows-zig` - Windows ARM64

Example cross-compiling for Windows from Linux:

```bash
$VCPKG_ROOT/vcpkg install \
  --triplet=x64-windows-zig \
  --overlay-triplets=./triplets

cmake -B build-windows \
  -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake \
  -DVCPKG_TARGET_TRIPLET=x64-windows-zig \
  -DVCPKG_OVERLAY_TRIPLETS=./triplets \
  -DUSE_VCPKG=ON \
  -DHAWKNL_BUILTIN=Yes \
  -DLIBZIP_BUILTIN=Yes \
  -DLIBLUA_BUILTIN=Yes \
  -DX11=OFF

cmake --build build-windows
```

## Dependencies Managed by vcpkg

- SDL2
- SDL2_image
- curl
- libxml2
- zlib
- libgd (Linux/macOS)
- OpenAL
- freealut (Linux/macOS)
- libvorbis
- libogg

## Building Without vcpkg

You can still build the traditional way by setting `-DUSE_VCPKG=OFF`:

```bash
cmake -B build -DUSE_VCPKG=OFF
cmake --build build
```

This will use system-installed libraries as before.

## How It Works

### Triplet Files

Each triplet file (`triplets/*-zig.cmake`) configures:
- Target architecture
- Target OS
- Zig compiler wrapper via `zig-toolchain.cmake`

### Zig Toolchain

The `triplets/zig-toolchain.cmake` file:
- Finds the Zig executable
- Sets up Zig as both C and C++ compiler
- Passes the target triple to Zig for cross-compilation

### GitHub Actions

The workflow:
1. Sets up vcpkg binary caching for faster builds
2. Installs Zig
3. Runs vcpkg to install dependencies for each platform
4. Configures CMake with vcpkg toolchain + Zig
5. Builds for all 6 target platforms

## Troubleshooting

### Zig not found

Make sure Zig is in your PATH:
```bash
which zig
```

### vcpkg dependencies fail to build

Try clearing the vcpkg cache:
```bash
rm -rf $VCPKG_ROOT/buildtrees
```

### Library not found at link time

Check that the triplet is correctly configured and vcpkg installed successfully:
```bash
ls vcpkg_installed/<triplet>/lib
```

## Benefits

✅ Consistent dependencies across all platforms
✅ No need for platform-specific package managers
✅ Reproducible builds via locked baseline
✅ Binary caching for faster CI builds
✅ Still use Zig for excellent cross-compilation

## Migration Notes

The old build system is still available by setting `-DUSE_VCPKG=OFF`. However, the vcpkg approach is recommended for CI/CD and cross-platform builds.
