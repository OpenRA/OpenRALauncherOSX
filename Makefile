.PHONY: all deps launcher sdl2 lua freetype mono clean
.DEFAULT_GOAL := launcher

SDL2_VERSION := 2.0.12
LUA_VERSION := 5.1.5
FREETYPE_VERSION := 2.10.0
OPENALSOFT_VERSION := 1.20.1

all: deps launcher

deps: sdl2 lua freetype openalsoft mono

launcher: OpenRA
	@echo "Generating launcher.zip"
	@mkdir -p build/OpenRA.app/Contents/Resources
	@echo "APPL????" > build/OpenRA.app/Contents/PkgInfo
	@cp Info.plist build/OpenRA.app/Contents
	@cp Eluant.dll.config build/OpenRA.app/Contents/Resources
	@cd build && zip launcher -r -9 OpenRA.app --quiet --symlinks

OpenRA: OpenRA.m
	@echo "Building OpenRA"
	@mkdir -p build/OpenRA.app/Contents/MacOS/
	@clang -m64 OpenRA.m -o build/OpenRA.app/Contents/MacOS/OpenRA -framework AppKit -mmacosx-version-min=10.9

sdl2:
	@curl -s -L -O http://www.libsdl.org/release/SDL2-$(SDL2_VERSION).tar.gz
	@tar xf SDL2-$(SDL2_VERSION).tar.gz
	@rm SDL2-$(SDL2_VERSION).tar.gz
	@cd SDL2-$(SDL2_VERSION) && ./configure CFLAGS="-m64 -mmacosx-version-min=10.9" LDFLAGS="-m64 -mmacosx-version-min=10.9" --without-x --prefix "$(PWD)/build/SDL2"
	@cd SDL2-$(SDL2_VERSION) && make && make install
	@mkdir -p build/OpenRA.app/Contents/Resources
	@cp build/SDL2/lib/libSDL2-2.0.0.dylib build/libSDL2.dylib
	@rm -rf SDL2-$(SDL2_VERSION).tar.gz SDL2-$(SDL2_VERSION) build/SDL2

lua:
	@curl -s -L -O https://www.lua.org/ftp/lua-$(LUA_VERSION).tar.gz
	@tar xf lua-$(LUA_VERSION).tar.gz
	@cd lua-$(LUA_VERSION)/src/ && patch < ../../liblua.patch
	@cd lua-$(LUA_VERSION)/src/ && make liblua.5.1.dylib
	@mkdir -p build/OpenRA.app/Contents/Resources
	@cp lua-$(LUA_VERSION)/src/liblua.$(LUA_VERSION).dylib build/liblua.5.1.dylib
	@rm -rf lua-$(LUA_VERSION).tar.gz lua-$(LUA_VERSION)

freetype:
	@curl -s -L -O https://download.savannah.gnu.org/releases/freetype/freetype-$(FREETYPE_VERSION).tar.bz2
	@tar xf freetype-$(FREETYPE_VERSION).tar.bz2
	@cd freetype-$(FREETYPE_VERSION) && ./configure --with-png=no --with-harfbuzz=no --with-zlib=no --with-bzip2=no CFLAGS="-m64 -mmacosx-version-min=10.9" LDFLAGS="-m64 -mmacosx-version-min=10.9" --prefix "$(PWD)/build/freetype"
	@cd freetype-$(FREETYPE_VERSION) && make && make install
	@mkdir -p build/OpenRA.app/Contents/Resources
	@cp build/freetype/lib/libfreetype.6.dylib build/libfreetype.6.dylib
	@rm -rf freetype-$(FREETYPE_VERSION).tar.gz freetype-$(FREETYPE_VERSION) build/freetype

openalsoft:
	@curl -s -L -O https://openal-soft.org/openal-releases/openal-soft-$(OPENALSOFT_VERSION).tar.bz2
	@tar xf openal-soft-$(OPENALSOFT_VERSION).tar.bz2
	@cd openal-soft-$(OPENALSOFT_VERSION)/build && cmake .. -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 -DALSOFT_EXAMPLES=OFF
	@cd openal-soft-$(OPENALSOFT_VERSION)/build && make
	@mkdir -p build/OpenRA.app/Contents/Resources
	@cp openal-soft-$(OPENALSOFT_VERSION)/build/libopenal.$(OPENALSOFT_VERSION).dylib build/libopenal.1.dylib
	@rm -rf openal-soft-$(OPENALSOFT_VERSION).tar.bz2 openal-soft-$(OPENALSOFT_VERSION)

mono:
	@./package-mono.sh $(PWD)/build/OpenRA.app

clean:
	@rm -rf build
	@rm launcher.zip
