# FFmpeg Build Instructions

## Setting up your build environment

### Setting up on Windows

1. Install Visual Studio 2019 (Free Community Edition works fine). Remember to select the C++ packages.
2. Install Chocolatey (https://chocolatey.org).
3. Run the following from command line: 

```
choco install cmake ninja nasm msys2
```

*The build scripts expect that msys2 will be installed to `C:\tools\msys64`. You'll need to pass 
`-DUL_MSYS2_PATH="C:\your\msys2\path"` to the CMake command line if this is not the case.*

4. Run the msys2 shell (open a new command prompt and type `msys2`) and run the following to
   install the needed development packages:

```
pacman -S --needed base-devel
```

Hit Enter to install all packages by default.

5. Add the following locations to your PATH on Windows (or similar locations if Windows was not
   installed on the `C:\` drive):

 * `C:\Program Files\CMake\bin`
 * `C:\Program Files\NASM`

### Setting up on macOS

1. Install Xcode Command Line Tools (or the full Xcode package).
2. Download the macOS 10.14 Platform SDK from https://github.com/phracker/MacOSX-SDKs/releases and
   extract it to `/Library/Developer/CommandLineTools/SDKs/MacOSX10.14.sdk`.
3. Install Homebrew (https://brew.sh/)
4. Run the following from the Terminal to setup the needed homebrew packages:

```
brew install cmake ninja nasm
```

### Setting up on Linux 

To get everything on Linux, just type the following:
 
```
sudo apt install cmake ninja-build
```

## Building from source

### Building on Windows

At present, to build with Visual Studio, you need to run cmake from inside the
VS 2019 command prompt. Press `Start`, and search for `VS 2019`, and click on
`x64 Native Tools Command Prompt for VS 2019`, or a prompt named similar to
that.

Then, from the `x64 Native Tools Command Prompt for VS 2019`, change directories to this folder
and run the following:

```
mkdir build
cd build
cmake .. -GNinja
ninja
ninja install
```

### Building on macOS and Linux

To build for macOS/Linux:

```
mkdir build
cd build
cmake .. -GNinja
ninja
ninja install
```

## Build products

Build products will be in `<build_dir>/out`.
