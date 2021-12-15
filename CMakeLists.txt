cmake_minimum_required(VERSION 3.15.0)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)

include(common)

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

set(CONFIG_ARGS ${FFMPEG_DIR}/configure --prefix=${FFMPEG_INSTALL_DIR})

# Platform-specific configure args should be defined in platform toolchain
if (UL_FFMPEG_ARGS)
    list(APPEND CONFIG_ARGS ${UL_FFMPEG_ARGS})
endif ()

# Set common args (disable everything by default, we'll enable what we need below)
list(APPEND CONFIG_ARGS --enable-static --disable-shared --disable-encoders --disable-muxers --disable-filters --disable-decoders --disable-parsers --disable-demuxers --disable-protocols --disable-devices)

# Disable debug symbols in non-debug builds
if (NOT CMAKE_BUILD_TYPE MATCHES "Debug")
    list(APPEND CONFIG_ARGS --disable-debug)
endif ()

# Enable decoders one by one
foreach(decoder ${DECODERS})
    list(APPEND CONFIG_ARGS --enable-decoder=${decoder})
endforeach()

# Enable parsers one by one
foreach(parser ${PARSERS})
    list(APPEND CONFIG_ARGS --enable-parser=${parser})
endforeach()

# Enable demuxers one by one
foreach(demuxer ${DEMUXERS})
    list(APPEND CONFIG_ARGS --enable-demuxer=${demuxer})
endforeach()

function(JOIN VALUES GLUE OUTPUT)
  string (REGEX REPLACE "([^\\]|^);" "\\1${GLUE}" _TMP_STR "${VALUES}")
  string (REGEX REPLACE "[\\](.)" "\\1" _TMP_STR "${_TMP_STR}") #fixes escaping
  set (${OUTPUT} "${_TMP_STR}" PARENT_SCOPE)
endfunction()

JOIN("${CONFIG_ARGS}" " " CONFIG_ARGS_STR)

if (CMAKE_HOST_SYSTEM_NAME MATCHES "Windows")
    if (NOT EXISTS ${UL_MSYS2_PATH})
        message(FATAL_ERROR "Could not find MSYS2 at the following path (set 'UL_MSYS2_PATH' to the install path): '${UL_MSYS2_PATH}'")
    endif ()

    add_custom_command(OUTPUT "${FFMPEG_BUILD_DIR}/config.h"
                        COMMAND cmd /c ${UL_MSYS2_PATH} -mingw64 -use-full-path -here -defterm -no-start -c ${CONFIG_ARGS_STR}
                        WORKING_DIRECTORY "${FFMPEG_BUILD_DIR}"
                        COMMENT "Configuring FFmpeg."
                        VERBATIM)

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
                        COMMAND ${CONFIG_ARGS}
                        WORKING_DIRECTORY "${FFMPEG_BUILD_DIR}"
                        COMMENT "Configuring FFmpeg."
                        VERBATIM)

    add_custom_command(OUTPUT "${FFMPEG_BUILD_DIR}/ffmpeg"
                        COMMAND make -j8
                        DEPENDS "${FFMPEG_BUILD_DIR}/config.h"
                        WORKING_DIRECTORY "${FFMPEG_BUILD_DIR}"
                        COMMENT "Building FFmpeg.")

    add_custom_command(OUTPUT "${FFMPEG_INSTALL_DIR}/lib/libavcodec.a"
                        COMMAND make install
                        DEPENDS "${FFMPEG_BUILD_DIR}/ffmpeg"
                        WORKING_DIRECTORY "${FFMPEG_BUILD_DIR}"
                        COMMENT "Installing FFmpeg.")

    add_custom_target(FFmpeg ALL DEPENDS "${FFMPEG_INSTALL_DIR}/lib/libavcodec.a")

    INSTALL(DIRECTORY "${FFMPEG_INSTALL_DIR}/include" DESTINATION ".")
    INSTALL(DIRECTORY "${FFMPEG_INSTALL_DIR}/lib" DESTINATION "." FILES_MATCHING PATTERN "*.a")
endif ()

include(CreateSDK.cmake)