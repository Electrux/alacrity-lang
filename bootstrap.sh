#!/usr/bin/env bash

compiler="clang++"
os=$(uname)

if [[ "$os" == 'Linux' ]]; then
	compiler="g++"
fi

if ! [[ -z "${COMPILER}" ]]; then
	compiler="${COMPILER}"
fi

compiler_version=$($compiler --version)
echo "Using compiler: $compiler, version: $compiler_version"

echo "Creating directories ..."

mkdir -p "buildfiles/src/Interpreter"
mkdir -p "buildfiles/src/Lexer"
mkdir -p "buildfiles/src/Modules/builds"
mkdir -p "buildfiles/src/Parser"

# Binary: al

find src -name "*.cpp" | grep -v "Modules" | grep -v "main.cpp" | while read -r src_file; do
	echo "Compiling: $src_file ..."
	$compiler -O2 -fPIC -std=c++17 -c $src_file -o buildfiles/$src_file.o -I/usr/local/include
	if ! [[ $? == 0 ]]; then
		break
	fi
done

if ! [[ $? == 0 ]]; then
	echo "Error in compiling sources, will not continue"
	exit $?
fi

buildfiles=$(find buildfiles -name "*.cpp.o" | paste -sd " " -)
fs="-lstdc++fs"
if [[ "$os" == 'Darwin' ]]; then
	fs="-I/usr/local/opt/llvm/include -L/usr/local/opt/llvm/lib -lc++fs"
fi

echo "Building binary: al..."
$compiler -O2 -fPIC -std=c++17 -g -o buildfiles/al src/main.cpp $buildfiles -I/usr/local/include -L/usr/local/lib -ldl -lpthread $fs

# Library: core
echo "Building libray: core..."
$compiler -O2 -fPIC -std=c++17 -shared -o buildfiles/libcore.so src/Modules/core.cpp $buildfiles -I/usr/local/include -L/usr/local/lib -ldl -lpthread $fs

# Library: os
echo "Building libray: os..."
$compiler -O2 -fPIC -std=c++17 -shared -o buildfiles/libos.so src/Modules/os.cpp $buildfiles -I/usr/local/include -L/usr/local/lib -ldl -lpthread $fs

# Library: string
echo "Building libray: string..."
$compiler -O2 -fPIC -std=c++17 -shared -o buildfiles/libstring.so src/Modules/string.cpp $buildfiles -I/usr/local/include -L/usr/local/lib -ldl -lpthread $fs

# Library: math
echo "Building libray: math..."
$compiler -O2 -fPIC -std=c++17 -shared -o buildfiles/libmath.so src/Modules/math.cpp $buildfiles -I/usr/local/include -L/usr/local/lib -ldl -lpthread $fs

# Library: list
echo "Building libray: list..."
$compiler -O2 -fPIC -std=c++17 -shared -o buildfiles/liblist.so src/Modules/list.cpp $buildfiles -I/usr/local/include -L/usr/local/lib -ldl -lpthread $fs

# Library: audio
echo "Building libray: audio..."
$compiler -O2 -fPIC -std=c++17 -shared -o buildfiles/libaudio.so src/Modules/audio.cpp $buildfiles -I/usr/local/include -L/usr/local/lib -ldl -lpthread -lsfml-audio $fs

# Library: project
echo "Building libray: project..."
$compiler -O2 -fPIC -std=c++17 -shared -o buildfiles/libproject.so src/Modules/project.cpp $buildfiles -I/usr/local/include -L/usr/local/lib -ldl -lpthread $fs

# Library: builds
echo "Building libray: builds..."
$compiler -O2 -fPIC -std=c++17 -shared -o buildfiles/libbuilds.so src/Modules/builds.cpp src/Modules/builds/cxx.cpp src/Modules/builds/c.cpp $buildfiles -I/usr/local/include -L/usr/local/lib -ldl -lpthread $fs

# Install this

mkdir -p /usr/local/share/allang_tests/

if [[ $? != 0 ]]; then
	echo "You might wanna run this as root for installation!"
	exit $?
fi

mkdir -p /usr/local/share/allang_libs/

cp_cmd="cp -r "

if [[ "$os" == 'Linux' ]]; then
	cp_cmd="cp -r --remove-destination "
fi

echo "Installing files..."
$cp_cmd buildfiles/al /usr/local/bin
$cp_cmd buildfiles/lib*.so /usr/local/share/allang_libs/
$cp_cmd build_libs/* /usr/local/share/allang_tests/