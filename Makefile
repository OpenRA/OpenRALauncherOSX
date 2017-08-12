.PHONY: all launcher clean
.DEFAULT_GOAL := launcher

all: OpenRA launchgame

launcher: all
	@echo "Generating launcher.zip"
	@mkdir -p OpenRA.app/Contents/MacOS
	@mkdir -p OpenRA.app/Contents/Resources
	@mv build/OpenRA build/launchgame OpenRA.app/Contents/MacOS
	@echo "APPL????" > OpenRA.app/Contents/PkgInfo
	@cp Info.plist OpenRA.app/Contents
	@cp fonts.conf dependencies/* OpenRA.app/Contents/Resources
	@ln -s /Library/Frameworks/Mono.framework/Libraries/libgdiplus.dylib OpenRA.app/Contents/Resources/libgdiplus.dylib
	@zip launcher -r -9 OpenRA.app --quiet --symlinks
	@rm -rf OpenRA.app

OpenRA: OpenRA.m
	@echo "Building OpenRA"
	@mkdir -p build
	@clang -m32 OpenRA.m -o build/OpenRA -framework AppKit -mmacosx-version-min=10.7

launchgame: launchgame.m
	@echo "Building launchgame"
	@mkdir -p build
	@clang -m32 launchgame.m -o build/launchgame -framework AppKit -mmacosx-version-min=10.7

clean:
	@rm -rf build
	@rm -rf OpenRA.app
	@rm launcher.zip
