cmake_minimum_required(VERSION 3.15.0)

set(CMAKE_BUILD_TYPE "Release"                            CACHE STRING  "Choose the type of build.")
set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR}/out  CACHE PATH    "The path to install to.")
set(UL_MSYS2_PATH "C:\\tools\\msys64\\msys2_shell.cmd"    CACHE PATH    "(Windows only) The path to the MSYS2 shell script.")

set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")

project(FFmpeg C CXX)

# Define which decoders to enable in FFmpeg
set(DECODERS vp8 vp9 aac mp2 mp3)

# Define which parsers to enable in FFmpeg
set(PARSERS aac aac_latm mpegaudio vp8 vp9)

# Define which demuxers to enable in FFmpeg
set(DEMUXERS aac mp3 mpegps wav)

set(FFMPEG_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE PATH "Location of 'ffmpeg'")
set(FFMPEG_BUILD_DIR "${CMAKE_BINARY_DIR}/ffmpeg")
set(FFMPEG_INSTALL_DIR "${FFMPEG_BUILD_DIR}/out")

set(CONFIG_ARGS "${FFMPEG_DIR}/configure --prefix=${FFMPEG_INSTALL_DIR}")

if (CMAKE_SYSTEM_NAME MATCHES "Linux")
    set(CONFIG_ARGS "${CONFIG_ARGS} --enable-pic --disable-asm")
elseif (CMAKE_SYSTEM_NAME MATCHES "Darwin")
    set(CONFIG_ARGS "${CONFIG_ARGS} --enable-asm")
elseif (CMAKE_SYSTEM_NAME MATCHES "Windows")
    set(CONFIG_ARGS "${CONFIG_ARGS} --toolchain=msvc --enable-asm")
else ()
    message(FATAL_ERROR "Unhandled target OS: '${CMAKE_SYSTEM_NAME}'")
endif ()

if(CMAKE_SIZEOF_VOID_P EQUAL 4)
    # CMake Target arch is 32-bit
    set(CONFIG_ARGS "${CONFIG_ARGS} --arch=x86")
else ()
    set(CONFIG_ARGS "${CONFIG_ARGS} --arch=x86_64")
endif()

# Set common args (disable everything by default, we'll enable what we need below)
set(CONFIG_ARGS "${CONFIG_ARGS} --enable-static --disable-shared --disable-encoders --disable-muxers --disable-filters --disable-decoders --disable-parsers --disable-demuxers --disable-protocols --disable-devices")

# Disable debug symbols in non-debug builds
if (NOT CMAKE_BUILD_TYPE MATCHES "Debug")
    set(CONFIG_ARGS "${CONFIG_ARGS} --disable-debug")
endif ()

# Enable decoders one by one
foreach(decoder ${DECODERS})
    set(CONFIG_ARGS "${CONFIG_ARGS} --enable-decoder=${decoder}")
endforeach()

# Enable parsers one by one
foreach(parser ${PARSERS})
    set(CONFIG_ARGS "${CONFIG_ARGS} --enable-parser=${parser}")
endforeach()

# Enable demuxers one by one
foreach(demuxer ${DEMUXERS})
    set(CONFIG_ARGS "${CONFIG_ARGS} --enable-demuxer=${demuxer}")
endforeach()

if (CMAKE_HOST_SYSTEM_NAME MATCHES "Windows")
    if (NOT EXISTS ${UL_MSYS2_PATH})
        message(FATAL_ERROR "Could not find MSYS2 at the following path (set 'UL_MSYS2_PATH' to the install path): '${UL_MSYS2_PATH}'")
    endif ()

    add_custom_command(OUTPUT "${FFMPEG_BUILD_DIR}/config.h"
                        COMMAND cmd /c ${UL_MSYS2_PATH} -mingw64 -use-full-path -here -defterm -no-start -c ${CONFIG_ARGS}
                        WORKING_DIRECTORY "${FFMPEG_BUILD_DIR}"
                        COMMENT "Configuring FFmpeg.")

    add_custom_command(OUTPUT "${FFMPEG_BUILD_DIR}/ffmpeg.exe"
                        COMMAND cmd /c ${UL_MSYS2_PATH} -mingw64 -use-full-path -here -defterm -no-start -c "make -j8"
                        DEPENDS "${FFMPEG_BUILD_DIR}/config.h"
                        WORKING_DIRECTORY "${FFMPEG_BUILD_DIR}"
                        COMMENT "Building FFmpeg.")

    add_custom_command(OUTPUT "${FFMPEG_INSTALL_DIR}/lib/libavcodec.a"
                        COMMAND cmd /c ${UL_MSYS2_PATH} -mingw64 -use-full-path -here -defterm -no-start -c "make install"
                        DEPENDS "${FFMPEG_BUILD_DIR}/ffmpeg.exe"
                        WORKING_DIRECTORY "${FFMPEG_BUILD_DIR}"
                        COMMENT "Installing FFmpeg.")

    if (CMAKE_SYSTEM_NAME MATCHES "Windows")
        # We need to rename .a files to .lib files on Windows
        add_custom_command(OUTPUT "${FFMPEG_INSTALL_DIR}/lib/libavcodec.lib"
                            COMMAND cmd /c xcopy *.a *.lib
                            DEPENDS "${FFMPEG_INSTALL_DIR}/lib/libavcodec.a"
                            WORKING_DIRECTORY "${FFMPEG_INSTALL_DIR}/lib"
                            COMMENT "Renaming .a files to .lib.")

        add_custom_target(FFmpeg ALL DEPENDS "${FFMPEG_INSTALL_DIR}/lib/libavcodec.lib")
        INSTALL(DIRECTORY "${FFMPEG_INSTALL_DIR}/include" DESTINATION ".")
        INSTALL(DIRECTORY "${FFMPEG_INSTALL_DIR}/lib" DESTINATION "." FILES_MATCHING PATTERN "*.lib")
    else ()
        # We're compiling for Linux/macOS on a Windows host, keep .a extension
        add_custom_target(FFmpeg ALL DEPENDS "${FFMPEG_INSTALL_DIR}/lib/libavcodec.a")
        INSTALL(DIRECTORY "${FFMPEG_INSTALL_DIR}/include" DESTINATION ".")
        INSTALL(DIRECTORY "${FFMPEG_INSTALL_DIR}/lib" DESTINATION "." FILES_MATCHING PATTERN "*.a")
    endif ()
else ()
    add_custom_command(OUTPUT "${FFMPEG_BUILD_DIR}/config.h"
                        COMMAND bash ${CONFIG_ARGS}
                        WORKING_DIRECTORY "${FFMPEG_BUILD_DIR}"
                        COMMENT "Configuring FFmpeg.")

    add_custom_command(OUTPUT "${FFMPEG_BUILD_DIR}/ffmpeg"
                        COMMAND "make -j8"
                        DEPENDS "${FFMPEG_BUILD_DIR}/config.h"
                        WORKING_DIRECTORY "${FFMPEG_BUILD_DIR}"
                        COMMENT "Building FFmpeg.")

    add_custom_command(OUTPUT "${FFMPEG_INSTALL_DIR}/lib/libavcodec.a"
                        COMMAND "make install"
                        DEPENDS "${FFMPEG_BUILD_DIR}/ffmpeg"
                        WORKING_DIRECTORY "${FFMPEG_BUILD_DIR}"
                        COMMENT "Installing FFmpeg.")

    add_custom_target(FFmpeg ALL DEPENDS "${FFMPEG_INSTALL_DIR}/lib/libavcodec.a")

    INSTALL(DIRECTORY "${FFMPEG_INSTALL_DIR}/include" DESTINATION ".")
    INSTALL(DIRECTORY "${FFMPEG_INSTALL_DIR}/lib" DESTINATION "." FILES_MATCHING PATTERN "*.a")
endif ()

include(CreateSDK.cmake)