#!/bin/bash
# Test script to verify vcpkg setup for OpenLieroX

set -e

echo "=== OpenLieroX vcpkg Setup Test ==="
echo ""

# Check for required tools
echo "Checking for required tools..."

if ! command -v zig &> /dev/null; then
    echo "❌ Zig not found. Please install Zig 0.15.2 or compatible."
    exit 1
fi
echo "✓ Zig found: $(zig version)"

if ! command -v cmake &> /dev/null; then
    echo "❌ CMake not found. Please install CMake 3.10+."
    exit 1
fi
echo "✓ CMake found: $(cmake --version | head -1)"

# Check for vcpkg
if [ -z "$VCPKG_ROOT" ]; then
    echo "❌ VCPKG_ROOT not set. Please set it to your vcpkg installation directory."
    echo "   Example: export VCPKG_ROOT=/path/to/vcpkg"
    exit 1
fi

if [ ! -f "$VCPKG_ROOT/vcpkg" ]; then
    echo "❌ vcpkg executable not found at $VCPKG_ROOT/vcpkg"
    exit 1
fi
echo "✓ vcpkg found at: $VCPKG_ROOT"

# Check for required files
echo ""
echo "Checking for required files..."

REQUIRED_FILES=(
    "vcpkg.json"
    "triplets/x64-linux-zig.cmake"
    "triplets/arm64-linux-zig.cmake"
    "triplets/x64-osx-zig.cmake"
    "triplets/arm64-osx-zig.cmake"
    "triplets/x64-windows-zig.cmake"
    "triplets/arm64-windows-zig.cmake"
    "triplets/zig-toolchain.cmake"
    "CMakeOlxVcpkg.cmake"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing file: $file"
        exit 1
    fi
    echo "✓ Found: $file"
done

echo ""
echo "=== All checks passed! ==="
echo ""
echo "You can now build with vcpkg. Example:"
echo ""
echo "  # Install dependencies for your platform"
echo "  \$VCPKG_ROOT/vcpkg install --triplet=x64-linux-zig --overlay-triplets=./triplets"
echo ""
echo "  # Configure CMake"
echo "  cmake -B build \\"
echo "    -DCMAKE_TOOLCHAIN_FILE=\$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake \\"
echo "    -DVCPKG_TARGET_TRIPLET=x64-linux-zig \\"
echo "    -DVCPKG_OVERLAY_TRIPLETS=./triplets \\"
echo "    -DUSE_VCPKG=ON \\"
echo "    -DHAWKNL_BUILTIN=Yes \\"
echo "    -DLIBZIP_BUILTIN=Yes \\"
echo "    -DLIBLUA_BUILTIN=Yes"
echo ""
echo "  # Build"
echo "  cmake --build build -j\$(nproc)"
echo ""
