/*
 * OpenRA mono launcher.
 * Based on a cut-down version of MonoDevelop's monostub.m.
 * The original file did not include an explicit licence, so it is assumed
 * to be covered by the LGPL as specified in the Xamarin Studio "About" dialog.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <unistd.h>
#include <dlfcn.h>
#include <errno.h>
#include <ctype.h>

#import <Cocoa/Cocoa.h>

#define RET_MONO_NOT_FOUND 131
#define RET_MONO_INIT_ERROR 132
#define RET_MONO_VERSION_OUTDATED 133

typedef int (* mono_main)(int argc, char **argv);
typedef void (* mono_free)(void *ptr);
typedef char *(* mono_get_runtime_build_info)(void);

static int check_mono_version(const char *version, const char *req_version)
{
	char *req_end, *end;
	long req_val, val;

	while (*req_version)
	{
		req_val = strtol(req_version, &req_end, 10);
		if (req_version == req_end || (*req_end && *req_end != '.'))
		{
			fprintf(stderr, "Bad version requirement string '%s'\n", req_end);
			return FALSE;
		}

		req_version = req_end;
		if (*req_version)
			req_version++;

		val = strtol (version, &end, 10);
		if (version == end || val < req_val)
			return FALSE;

		if (val > req_val)
			return TRUE;

		if (*req_version == '.' && *end != '.')
			return FALSE;

		version = end + 1;
	}

	return TRUE;
}

int main (int argc, char **argv)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// Default value - can be overriden by setting MonoMinVersion in Info.plist
	NSString *req_mono_version = @"3.2";

	NSDictionary *plist = [[NSBundle mainBundle] infoDictionary];
	if (plist)
	{
		NSString *version_obj = [plist objectForKey:@"MonoMinVersion"];
		if (version_obj && [version_obj length] > 0)
			req_mono_version = version_obj;
	}

	struct rlimit limit;
	if (getrlimit (RLIMIT_NOFILE, &limit) == 0 && limit.rlim_cur < 1024)
	{
		limit.rlim_cur = MIN(limit.rlim_max, 1024);
		setrlimit(RLIMIT_NOFILE, &limit);
	}

	void *libmono = dlopen("/Library/Frameworks/Mono.framework/Versions/Current/lib/libmono-2.0.dylib", RTLD_LAZY);

	if (libmono == NULL)
	{
		fprintf (stderr, "Failed to load libmono-2.0.dylib: %s\n", dlerror());
		return RET_MONO_NOT_FOUND;
	}

	mono_main _mono_main = (mono_main)dlsym(libmono, "mono_main");
	if (!_mono_main)
	{
		fprintf(stderr, "Could not load mono_main(): %s\n", dlerror());
		return RET_MONO_INIT_ERROR;
	}

	mono_free _mono_free = (mono_free)dlsym(libmono, "mono_free");
	if (!_mono_free)
	{
		fprintf(stderr, "Could not load mono_free(): %s\n", dlerror());
		return RET_MONO_INIT_ERROR;
	}

	mono_get_runtime_build_info _mono_get_runtime_build_info = (mono_get_runtime_build_info)dlsym(libmono, "mono_get_runtime_build_info");
	if (!_mono_get_runtime_build_info)
	{
		fprintf(stderr, "Could not load mono_get_runtime_build_info(): %s\n", dlerror());
		return RET_MONO_INIT_ERROR;
	}

	char *mono_version = _mono_get_runtime_build_info();
	if (!check_mono_version(mono_version, [req_mono_version UTF8String]))
		return RET_MONO_VERSION_OUTDATED;

	[pool drain];

	return _mono_main(argc, argv);
}