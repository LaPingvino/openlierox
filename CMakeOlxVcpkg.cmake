# vcpkg-based dependency configuration for OpenLieroX
# This file replaces the manual library setup in CMakeOlxCommon.cmake when using vcpkg

# Find all required packages from vcpkg
find_package(Boost REQUIRED)
find_package(SDL2 CONFIG REQUIRED)
find_package(SDL2_image CONFIG REQUIRED)
find_package(CURL REQUIRED)
find_package(LibXml2 REQUIRED)
find_package(ZLIB REQUIRED)
find_package(OpenAL CONFIG REQUIRED)
find_package(Vorbis CONFIG REQUIRED)

# Set up include directories for header-only libraries
# Boost provides header files that need to be in the include path
if(Boost_FOUND)
    # Try multiple approaches to find vcpkg include directory
    set(BOOST_INCLUDE_ADDED FALSE)

    # Approach 1: Use VCPKG_INSTALLED_DIR if set
    if(DEFINED VCPKG_INSTALLED_DIR AND DEFINED VCPKG_TARGET_TRIPLET)
        include_directories("${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/include")
        message(STATUS "Boost include directory: ${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/include")
        set(BOOST_INCLUDE_ADDED TRUE)
    endif()

    # Approach 2: Use _VCPKG_INSTALLED_DIR if set
    if(NOT BOOST_INCLUDE_ADDED AND DEFINED _VCPKG_INSTALLED_DIR AND DEFINED _VCPKG_TARGET_TRIPLET)
        include_directories("${_VCPKG_INSTALLED_DIR}/${_VCPKG_TARGET_TRIPLET}/include")
        message(STATUS "Boost include directory: ${_VCPKG_INSTALLED_DIR}/${_VCPKG_TARGET_TRIPLET}/include")
        set(BOOST_INCLUDE_ADDED TRUE)
    endif()

    # Approach 3: Look relative to CMAKE_BINARY_DIR (where build/ is)
    if(NOT BOOST_INCLUDE_ADDED)
        set(VCPKG_BUILD_INCLUDE "${CMAKE_BINARY_DIR}/vcpkg_installed/${VCPKG_TARGET_TRIPLET}/include")
        if(EXISTS "${VCPKG_BUILD_INCLUDE}/boost")
            include_directories("${VCPKG_BUILD_INCLUDE}")
            message(STATUS "Boost include directory: ${VCPKG_BUILD_INCLUDE}")
            set(BOOST_INCLUDE_ADDED TRUE)
        endif()
    endif()

    # Approach 4: Try Boost_INCLUDE_DIRS variable (set by FindBoost)
    if(NOT BOOST_INCLUDE_ADDED AND DEFINED Boost_INCLUDE_DIRS)
        include_directories(${Boost_INCLUDE_DIRS})
        message(STATUS "Boost include directory: ${Boost_INCLUDE_DIRS}")
        set(BOOST_INCLUDE_ADDED TRUE)
    endif()

    # Also add Boost::headers to libraries for proper dependency tracking
    list(APPEND VCPKG_LIBS Boost::headers)
endif()

# Find optional packages
if(NOT WIN32)
    # libgd uses pkg-config
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GD IMPORTED_TARGET gdlib)

    find_package(FREEALUT CONFIG)
endif()

# X11 is a system library on Linux, not from vcpkg
if(X11)
    find_package(X11 REQUIRED)
endif()

# Set up libraries list for linking
set(VCPKG_LIBS "")

# SDL2 libraries
list(APPEND VCPKG_LIBS
    $<TARGET_NAME_IF_EXISTS:SDL2::SDL2main>
    $<TARGET_NAME_IF_EXISTS:SDL2::SDL2-static>
    $<TARGET_NAME_IF_EXISTS:SDL2::SDL2>
)

list(APPEND VCPKG_LIBS
    $<TARGET_NAME_IF_EXISTS:SDL2_image::SDL2_image-static>
    $<TARGET_NAME_IF_EXISTS:SDL2_image::SDL2_image>
)

# Network and data libraries
list(APPEND VCPKG_LIBS
    CURL::libcurl
    LibXml2::LibXml2
    ZLIB::ZLIB
)

# Audio libraries (not for dedicated server)
if(NOT DEDICATED_ONLY)
    list(APPEND VCPKG_LIBS OpenAL::OpenAL)

    if(FREEALUT_FOUND)
        list(APPEND VCPKG_LIBS FreeALUT::alut)
    endif()

    list(APPEND VCPKG_LIBS
        Vorbis::vorbisfile
        Vorbis::vorbis
        Vorbis::vorbisenc
    )

    # Graphics library (using pkg-config)
    if(GD_FOUND)
        list(APPEND VCPKG_LIBS PkgConfig::GD)
    endif()
endif()

# X11 for Linux clipboard/notify
if(X11_FOUND)
    list(APPEND VCPKG_LIBS X11::X11)
endif()

# Platform-specific libraries not from vcpkg
if(WIN32)
    list(APPEND VCPKG_LIBS
        wsock32
        wininet
        dbghelp
        user32
        gdi32
        winmm
        kernel32
    )
elseif(APPLE)
    list(APPEND VCPKG_LIBS
        "-framework Cocoa"
        "-framework Carbon"
        "-framework OpenAL"
        crypto
    )
else() # Linux/Unix
    list(APPEND VCPKG_LIBS pthread)
endif()

# Add vcpkg libraries to the main LIBS variable
set(LIBS ${LIBS} ${VCPKG_LIBS})

message(STATUS "vcpkg dependencies configured successfully")
