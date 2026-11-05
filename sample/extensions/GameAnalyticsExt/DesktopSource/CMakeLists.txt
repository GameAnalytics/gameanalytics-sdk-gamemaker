# Builds the GameAnalytics GameMaker extension library for desktop targets.
#
# The C++ SDK is built as a static library and linked in, so the result is one
# self-contained dynamic library — dynamic because GameMaker loads desktop
# extensions with dlopen/LoadLibrary, self-contained so there is nothing to
# place next to the game.
#
# GA_HTTP_USE_CURL is forced OFF: the extension supplies its own GAHttpClient
# that goes through GameMaker's HTTP (see GameAnalyticsHttpGM.cpp), which is
# what keeps libcurl, OpenSSL and vcpkg out of the build.
#
# Usage:
#   cmake -S . -B build -DGA_SDK_DIR=/path/to/gameanalytics-sdk-cpp
#   cmake --build build --config Release
#
# Output name matches what GameAnalyticsExt.yy expects per platform:
#   macOS   libGameAnalytics.dylib   (universal x86_64 + arm64)
#   Linux   libGameAnalytics.so
#   Windows GameAnalytics.dll         (64-bit)

cmake_minimum_required(VERSION 3.16)

# Must precede project(): the architecture list has to be in place before the
# compiler checks run, or the build silently comes out single-slice.
if(APPLE AND NOT DEFINED CMAKE_OSX_ARCHITECTURES)
    set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64" CACHE STRING "universal build")
    set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0" CACHE STRING "minimum macOS")
endif()

project(GameAnalyticsGMExtension CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED GA_SDK_DIR)
    set(GA_SDK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../gameanalytics-sdk-cpp"
        CACHE PATH "Path to the gameanalytics-sdk-cpp checkout")
endif()

get_filename_component(GA_SDK_DIR "${GA_SDK_DIR}" ABSOLUTE)
if(NOT EXISTS "${GA_SDK_DIR}/CMakeLists.txt")
    message(FATAL_ERROR "C++ SDK not found at ${GA_SDK_DIR} — pass -DGA_SDK_DIR=<path>")
endif()
message(STATUS "GameAnalytics C++ SDK: ${GA_SDK_DIR}")

# --- the SDK, static, with its default cURL client disabled ----------------
set(GA_SHARED_LIB    OFF CACHE BOOL "" FORCE)
set(GA_BUILD_SAMPLE  OFF CACHE BOOL "" FORCE)
set(USE_VCPKG        OFF CACHE BOOL "" FORCE)
set(GA_HTTP_USE_CURL OFF CACHE BOOL "" FORCE)

add_subdirectory("${GA_SDK_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/ga-sdk" EXCLUDE_FROM_ALL)

# --- the extension entry points -------------------------------------------
add_library(GameAnalyticsGM SHARED
    GameAnalyticsGM.cpp
    GameAnalyticsHttpGM.cpp)

target_include_directories(GameAnalyticsGM PRIVATE
    "${GA_SDK_DIR}/include"
    "${GA_SDK_DIR}/source/gameanalytics"      # GAUtilities.h, for re-signing
    "${GA_SDK_DIR}/source/dependencies")      # headers the above pulls in

target_link_libraries(GameAnalyticsGM PRIVATE GameAnalytics)

# The SDK is static, so its symbols must be pulled in whole — GameMaker
# resolves the extension's entry points by name at load time.
if(APPLE)
    target_link_options(GameAnalyticsGM PRIVATE
        "-Wl,-force_load,$<TARGET_FILE:GameAnalytics>")
elseif(UNIX)
    target_link_options(GameAnalyticsGM PRIVATE
        "-Wl,--whole-archive" "$<TARGET_FILE:GameAnalytics>" "-Wl,--no-whole-archive")
endif()

# zlib: the SDK gzips request bodies and GML strings cannot carry NUL bytes, so
# the body is inflated before being handed to GameMaker. macOS and Linux have
# zlib in the base system; on Windows it comes from the toolchain (vcpkg's
# zlib, or MSYS2/mingw's).
find_package(ZLIB REQUIRED)
target_link_libraries(GameAnalyticsGM PRIVATE ZLIB::ZLIB)

# --- naming expected by GameAnalyticsExt.yy --------------------------------
set_target_properties(GameAnalyticsGM PROPERTIES PREFIX "" OUTPUT_NAME "GameAnalytics")

if(APPLE)
    set_target_properties(GameAnalyticsGM PROPERTIES
        OUTPUT_NAME "GameAnalytics" PREFIX "lib" SUFFIX ".dylib")
elseif(UNIX)
    set_target_properties(GameAnalyticsGM PROPERTIES
        OUTPUT_NAME "GameAnalytics" PREFIX "lib" SUFFIX ".so")
elseif(WIN32)
    # 64-bit only. 32-bit Windows was dropped: GameMaker's Windows target is
    # x64, and the extension declares exactly one Windows library.
    if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
        message(FATAL_ERROR
            "32-bit Windows is not supported — configure with -A x64")
    endif()

    # GameAnalyticsExt.yy declares this library as GameAnalytics.dll, and the
    # C++ SDK's static library is GameAnalytics.lib. On MSVC the DLL's import
    # library would claim that same name and path, and the linker refuses it
    # (LNK1149), so the import library — a build artifact that is never
    # shipped — is given a different name.
    set_target_properties(GameAnalyticsGM PROPERTIES
        RUNTIME_OUTPUT_NAME "GameAnalytics"
        ARCHIVE_OUTPUT_NAME "GameAnalyticsGM")
endif()

# Drop the built library straight into the extension folder.
add_custom_command(TARGET GameAnalyticsGM POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:GameAnalyticsGM>"
        "${CMAKE_CURRENT_SOURCE_DIR}/.."
    COMMENT "Installing $<TARGET_FILE_NAME:GameAnalyticsGM> into the extension")
