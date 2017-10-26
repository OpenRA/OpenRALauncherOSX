This repository holds the native OSX components of OpenRA.

The Makefile includes targets that self-document and automate the dependency compilation.

After updating the launcher code or dependencies you must:

1. Use `make launcher` to build a zip containing the launcher app template.
2. Upload the template as a new release.
3. Update `packaging/osx/buildpackage.sh` in the main OpenRA repository to use the new release package.