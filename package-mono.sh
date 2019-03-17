#!/bin/bash
MONO_VERSION=$1
OUTPUT="$(pwd)/dependencies"
mkdir -p "${OUTPUT}/etc/mono/4.5/"
mkdir -p "${OUTPUT}/lib/mono/4.5/"

mkdir mono
pushd mono
curl -sLO https://download.mono-project.com/runtimes/raw/mono-${MONO_VERSION}-osx-10.7-x64
unzip mono-${MONO_VERSION}-osx-10.7-x64

cp bin/mono "${OUTPUT}"
cp etc/mono/config "${OUTPUT}/etc/mono/"
cp etc/mono/4.5/machine.config "${OUTPUT}/etc/mono/4.5/"

# Runtime dependencies
# The required files can be found by running the following in the OpenRA engine directory:
#   cp OpenRA.Game.exe OpenRA.Game.dll # Work around a mkbundle issue where it can't see exes as deps
#   mkbundle -o foo --simple OpenRA.Game.exe OpenRA.Platforms.Default.dll mods/*/*.dll -L "$(dirname $(which mkbundle))/../lib/mono/4.5/ -L mods/common
# The "Assembly:" lines list the required dlls
# Note that some assemblies may reference native libraries. These can be reviewed by running
#   monodis <assembly> | grep extern
# and looking for extension-less names that are then mapped in etc/mono/config or names that list a .so extension directly.

pushd "lib/mono/4.5" > /dev/null
cp Mono.Security.dll mscorlib.dll System.Configuration.dll System.Core.dll System.dll System.Numerics.dll System.Security.dll System.Xml.dll "${OUTPUT}/lib/mono/4.5/"
popd > /dev/null
popd

rm -rf mono