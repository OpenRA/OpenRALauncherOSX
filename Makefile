.PHONY: all launcher clean sdl2 lua freetype
.DEFAULT_GOAL := launcher

SDL2_VERSION := 2.0.9
LUA_VERSION := 5.1.5
FREETYPE_VERSION := 2.10.0

all: OpenRA launchgame

launcher: all
	@echo "Generating launcher.zip"
	@mkdir -p OpenRA.app/Contents/MacOS
	@mkdir -p OpenRA.app/Contents/Resources
	@mv build/OpenRA build/launchgame OpenRA.app/Contents/MacOS
	@echo "APPL????" > OpenRA.app/Contents/PkgInfo
	@cp Info.plist OpenRA.app/Contents
	@cp dependencies/* OpenRA.app/Contents/Resources
	@zip launcher -r -9 OpenRA.app --quiet --symlinks
	@rm -rf OpenRA.app

OpenRA: OpenRA.m
	@echo "Building OpenRA"
	@mkdir -p build
	@clang -m64 OpenRA.m -o build/OpenRA -framework AppKit -mmacosx-version-min=10.7

launchgame: launchgame.m
	@echo "Building launchgame"
	@mkdir -p build
	@clang -m64 launchgame.m -o build/launchgame -framework AppKit -mmacosx-version-min=10.7

sdl2:
	@curl -s -L -O http://www.libsdl.org/release/SDL2-$(SDL2_VERSION).tar.gz
	@tar xf SDL2-$(SDL2_VERSION).tar.gz
	@rm SDL2-$(SDL2_VERSION).tar.gz
	@cd SDL2-$(SDL2_VERSION) && ./configure CFLAGS="-m64 -mmacosx-version-min=10.7" LDFLAGS="-m64 -mmacosx-version-min=10.7" --without-x --prefix "$(PWD)/build/SDL2"
	@cd SDL2-$(SDL2_VERSION) && make && make install
	@cp build/SDL2/lib/libSDL2-2.0.0.dylib dependencies/libSDL2.dylib
	@rm -rf SDL2-$(SDL2_VERSION).tar.gz SDL2-$(SDL2_VERSION) build/SDL2

lua:
	@curl -s -L -O https://www.lua.org/ftp/lua-$(LUA_VERSION).tar.gz
	@tar xf lua-$(LUA_VERSION).tar.gz
	@cd lua-$(LUA_VERSION)/src/ && patch < ../../liblua.patch
	@cd lua-$(LUA_VERSION)/src/ && make liblua.5.1.dylib
	@cp lua-$(LUA_VERSION)/src/liblua.$(LUA_VERSION).dylib dependencies/liblua.5.1.dylib
	@rm -rf lua-$(LUA_VERSION).tar.gz lua-$(LUA_VERSION)

freetype:
	@curl -s -L -O https://download.savannah.gnu.org/releases/freetype/freetype-$(FREETYPE_VERSION).tar.bz2
	@tar xf freetype-$(FREETYPE_VERSION).tar.bz2
	@cd freetype-$(FREETYPE_VERSION) && ./configure --with-png=no --with-harfbuzz=no --with-zlib=no --with-bzip2=no CFLAGS="-m64 -mmacosx-version-min=10.7" LDFLAGS="-m64 -mmacosx-version-min=10.7" --prefix "$(PWD)/build/freetype"
	@cd freetype-$(FREETYPE_VERSION) && make && make install
	@cp build/freetype/lib/libfreetype.6.dylib dependencies/
	@rm -rf freetype-$(FREETYPE_VERSION).tar.gz freetype-$(FREETYPE_VERSION) build/freetype

clean:
	@rm -rf build
	@rm -rf OpenRA.app
	@rm launcher.zip
