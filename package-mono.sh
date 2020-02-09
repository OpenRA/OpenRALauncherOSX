#!/bin/bash

# This *must* match the mono version defined in .travis.yml
MONO_VERSION="6.4.0"

OUTPUT="$1"
mkdir -p "${OUTPUT}/Contents/MacOS/"
mkdir -p "${OUTPUT}/Contents/Resources/etc/mono/4.5/"
mkdir -p "${OUTPUT}/Contents/Resources/lib/mono/4.5/"

mkdir mono
pushd mono
curl -sLO https://download.mono-project.com/runtimes/raw/mono-${MONO_VERSION}-osx-10.9-x64
unzip "mono-${MONO_VERSION}-osx-10.9-x64"

cp bin/mono "${OUTPUT}/Contents/MacOS/"
sed "s|\$mono_libdir/||g" etc/mono/config > "${OUTPUT}/Contents/Resources/etc/mono/config"
cp etc/mono/4.5/machine.config "${OUTPUT}/Contents/Resources/etc/mono/4.5/"

# libmono-native-compat.dylib is not packaged in the mkbundle runtime
# Copy it from the native mono installation (from travis-ci) instead
cp "/Library/Frameworks/Mono.framework/Versions/${MONO_VERSION}/lib/libmono-native-compat.dylib" "${OUTPUT}/Contents/Resources/lib/mono/4.5/"

# Runtime dependencies
# The required files can be found by running the following in the OpenRA engine directory:
#   cp OpenRA.Game.exe OpenRA.Game.dll # Work around a mkbundle issue where it can't see exes as deps
#   mkbundle -o foo --simple OpenRA.Game.exe OpenRA.Platforms.Default.dll mods/*/*.dll -L "$(dirname $(which mkbundle))/../lib/mono/4.5/ -L mods/common
# The "Assembly:" lines list the required dlls
# Note that some assemblies may reference native libraries. These can be reviewed by running
#   monodis <assembly> | grep extern
# and looking for extension-less names that are then mapped in etc/mono/config or names that list a .so extension directly.

pushd "lib/mono/4.5" > /dev/null
cp Mono.Security.dll mscorlib.dll System.Configuration.dll System.Core.dll System.dll System.Numerics.dll System.Security.dll System.Xml.dll "${OUTPUT}/Contents/Resources/lib/mono/4.5/"
popd > /dev/null
popd

rm -rf mono