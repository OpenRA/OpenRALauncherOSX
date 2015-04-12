This repository holds the native OSX components of OpenRA.

After updating the launcher code or dependencies you must:

1. Use `make launcher` to build a zip containing the launcher app template.
2. Upload the template as a new release.
3. Update `packaging/osx/buildpackage.sh` in the main OpenRA repository to use the new release package.


The SDL dependency was compiled from SDL 2.0.3 using:
`./configure CFLAGS="-m32 -mmacosx-version-min=10.5" LDFLAGS="-m32 -mmacosx-version-min=10.5" --without-x`

The lua dependency was compiled from Lua 5.1.5 using unknown options (presumably similar to SDL).