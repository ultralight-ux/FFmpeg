@echo off
setlocal EnableDelayedExpansion
set "VCVARS=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat"
set "MSYS2=C:\msys64\msys2_shell.cmd -mingw64 -use-full-path -here -defterm -no-start -c"
set DIRNAME=build-win-msvc-2019

if not exist %DIRNAME% mkdir %DIRNAME%
cd %DIRNAME%

echo Setting up MSVC 2019 build environment...
call "%VCVARS%" amd64

echo Configuring FFmpeg...
set conf=../configure --prefix=$(pwd)/out --toolchain=msvc --arch=x86_64 --enable-asm --enable-static --disable-shared --disable-debug --disable-encoders --disable-muxers --disable-filters --disable-decoders --disable-parsers --disable-demuxers --disable-protocols --disable-devices 

set decoders=vp8 vp9 aac mp2 mp3

set parsers=aac aac_latm mpegaudio vp8 vp9

set demuxers=aac mp3 mpegps wav

(for %%a in (%decoders%) do ( set conf=!conf! --enable-decoder=%%a))
(for %%a in (%parsers%) do ( set conf=!conf! --enable-parser=%%a))
(for %%a in (%demuxers%) do ( set conf=!conf! --enable-demuxer=%%a))

call %MSYS2% "%conf%"

echo Building FFmpeg...
call %MSYS2% "make -j8"

echo Installing FFmpeg...
call %MSYS2% "make install"

echo Renaming .a files to .lib...
ren out\lib\*.a *.lib

cd ..