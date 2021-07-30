#!/bin/bash
# Build script
mkdir -p build
cd build

export CC=/usr/bin/clang
export CXX=/usr/bin/clang++

decoders=( vp8 vp9 aac mp2 mp3 )
parsers=( aac aac_latm mpegaudio vp8 vp9 )
demuxers=( aac mp3 mpegps wav )

conf="../configure --prefix=$(pwd)/out --arch=x86_64 --disable-asm --enable-pic --enable-static --disable-shared --disable-debug --disable-encoders --disable-muxers --disable-filters --disable-decoders --disable-parsers --disable-demuxers --disable-protocols --disable-devices "

for i in "${decoders[@]}"
do
	conf="$conf --enable-decoder=$i"
done

for i in "${parsers[@]}"
do
	conf="$conf --enable-parser=$i"
done

for i in "${demuxers[@]}"
do
	conf="$conf --enable-demuxer=$i"
done

echo Configuring FFmpeg...
eval "$conf"

echo Building FFmpeg...
export CFLAGS=-fPIC
echo "%define PIC 1" >> config.asm
make -j8

echo Installing FFmpeg
make install

cd ..

