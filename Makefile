all: OpenRA launchgame

launcher: all
	mkdir -p OpenRA.app/Contents/MacOS
	mkdir -p OpenRA.app/Contents/Resources
	mv OpenRA launchgame OpenRA.app/Contents/MacOS
	echo "APPL????" > OpenRA.app/Contents/PkgInfo
	cp Info.plist OpenRA.app/Contents
	cp fonts.conf dependencies/* OpenRA.app/Contents/Resources
	ln -s /Library/Frameworks/Mono.framework/Libraries/libgdiplus.dylib OpenRA.app/Contents/Resources/libgdiplus.dylib
	zip launcher -r -9 OpenRA.app --quiet --symlinks
	rm -rf OpenRA.app

OpenRA: OpenRA.m
	clang -m32 OpenRA.m -o OpenRA -framework AppKit -mmacosx-version-min=10.6

launchgame: launchgame.m
	clang -m32 launchgame.m -o launchgame -framework AppKit -mmacosx-version-min=10.6

clean:
	rm OpenRA launchgame
	rm -rf OpenRA.app