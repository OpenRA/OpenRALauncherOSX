# OpenRALauncherOSX [![Travis CI build status](https://travis-ci.org/OpenRA/OpenRALauncherOSX.svg?branch=master)](https://travis-ci.org/OpenRA/OpenRALauncherOSX)

This repository holds the native OSX components for [OpenRA](https://github.com/OpenRA/OpenRA) and the [OpenRA Mod SDK](https://github.com/OpenRA/OpenRAModSDK).

Code is automatically compiled using Travis CI and deployed to a GitHub Release.
When new changes are merged, push a new tag and then update the tag references in [fetch-thirdparty-deps-osx.sh](https://github.com/OpenRA/OpenRA/blob/bleed/thirdparty/fetch-thirdparty-deps-osx.sh), [buildpackage.sh](https://github.com/OpenRA/OpenRA/blob/bleed/packaging/osx/buildpackage.sh), and [mod.config](https://github.com/OpenRA/OpenRAModSDK/blob/master/mod.config).
