/*
 * Copyright 2007-2015 The OpenRA Developers (see AUTHORS)
 * This file is part of OpenRA, which is free software. It is made
 * available to you under the terms of the GNU General Public License
 * as published by the Free Software Foundation. For more information,
 * see COPYING.
 */

#import <Cocoa/Cocoa.h>

#define RET_MONO_NOT_FOUND 131
#define RET_MONO_INIT_ERROR 132
#define RET_MONO_VERSION_OUTDATED 133
#define RET_OPENRA_RESTARTING 1

@interface ORALauncher : NSObject <NSApplicationDelegate>
- (void)launchGameWithArgs: (NSArray *)gameArgs;
@end

@implementation ORALauncher

BOOL launched = NO;
NSTask *gameTask;

- (void)showMonoPromptWithMinimumVersion: (NSString *)monoMinVersion
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Cannot launch OpenRA"];
	NSString *msg = [NSString stringWithFormat: @"OpenRA requires Mono %@ or later. Please install the Mono MDK package and try again.", monoMinVersion];
	[alert setInformativeText:msg];
	[alert addButtonWithTitle:@"Download Mono"];
	[alert addButtonWithTitle:@"Quit"];
	NSInteger answer = [alert runModal];
	[alert release];

	if (answer == NSAlertFirstButtonReturn)
		[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://www.mono-project.com/download/"]];
}

- (void)showCrashPrompt
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Fatal Error"];
	[alert setInformativeText:@"OpenRA has encountered a fatal error and must close.\nPlease refer to the crash logs and FAQ for more information."];
	[alert addButtonWithTitle:@"View Logs"];
	[alert addButtonWithTitle:@"View FAQ"];
	[alert addButtonWithTitle:@"Quit"];

	NSInteger answer = [alert runModal];
	[alert release];

	if (answer == NSAlertFirstButtonReturn)
	{
		NSString *logDir = [@"~/Library/Application Support/OpenRA/Logs/" stringByExpandingTildeInPath];
		NSString *logFile = [logDir stringByAppendingPathComponent: @"exception.log"];
		[[NSWorkspace sharedWorkspace] selectFile: logFile inFileViewerRootedAtPath: logDir];
	}
	else if (answer == NSAlertSecondButtonReturn)
		[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://wiki.openra.net/FAQ"]];
}

// Application was launched via a file association
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	NSArray *gameArgs = [NSArray array];
	if ([[filename pathExtension] isEqualToString:@"orarep"])
		gameArgs = [NSArray arrayWithObject: [NSString stringWithFormat: @"Launch.Replay=%@", filename]];
	else if ([[filename pathExtension] isEqualToString:@"oramod"])
		gameArgs = [NSArray arrayWithObject: [NSString stringWithFormat: @"Game.Mod=%@", filename]];

	[self launchGameWithArgs: gameArgs];

	return YES;
}

// Application was launched via a URL handler
- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSArray *gameArgs = [NSArray array];

	NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	if ([url hasPrefix:@"openra://"])
	{
		NSString *trimmed = [url substringFromIndex:9];
		NSArray *parts = [trimmed componentsSeparatedByString:@":"];
		NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];

		if ([parts count] == 2 && [formatter numberFromString: [parts objectAtIndex:1]] != nil)
			gameArgs = [NSArray arrayWithObject: [NSString stringWithFormat: @"Launch.Connect=%@", trimmed]];

		[formatter release];
	}

	[self launchGameWithArgs: gameArgs];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	// Register for url and file events
	LSSetDefaultHandlerForURLScheme((CFStringRef)@"openra", (CFStringRef)@"net.openra.launcher");
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self launchGameWithArgs: [NSArray array]];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)theApplication
{
	return YES;
}

- (void)launchGameWithArgs: (NSArray *)gameArgs
{
	if (launched)
	{
		NSLog(@"launchgame is already running... ignoring request.");
		return;
	}

	launched = YES;

	// Default values - can be overriden by setting MonoMinVersion and MonoGameExe in Info.plist
	NSString *gameName = @"OpenRA.Game.exe";

	NSDictionary *plist = [[NSBundle mainBundle] infoDictionary];
	if (plist)
	{
		NSString *exeValue = [plist objectForKey:@"MonoGameExe"];
		if (exeValue && [exeValue length] > 0)
			gameName = exeValue;
	}

	NSString *exePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: @"Contents/MacOS/"];
	NSString *gamePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: @"Contents/Resources/"];

	NSString *launchPath = [exePath stringByAppendingPathComponent: @"launchgame"];
	NSMutableArray *launchArgs = [NSMutableArray arrayWithCapacity: [gameArgs count] + 2];
	[launchArgs addObject: @"--debug"];
	[launchArgs addObject: [gamePath stringByAppendingPathComponent: gameName]];
	[launchArgs addObjectsFromArray: gameArgs];

	NSLog(@"Running launchgame with arguments:");
	for (size_t i = 0; i < [launchArgs count]; i++)
		NSLog(@"%@", [launchArgs objectAtIndex: i]);

	gameTask = [[NSTask alloc] init];
	[gameTask setCurrentDirectoryPath: gamePath];
	[gameTask setLaunchPath: launchPath];
	[gameTask setArguments: launchArgs];

	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(taskExited:)
		name: NSTaskDidTerminateNotification
		object: gameTask
	];

	[gameTask launch];
}

- (void)taskExited:(NSNotification *)note
{
	[[NSNotificationCenter defaultCenter]
		removeObserver:self
		name:NSTaskDidTerminateNotification
		object:gameTask
	];

	int ret = [gameTask terminationStatus];

	NSLog(@"launchgame exited with code %d", ret);
	[gameTask release];
	gameTask = nil;

	// We're done here
	if (ret == 0)
		exit(0);

	// Make the error dialog visible
	[NSApp setActivationPolicy: NSApplicationActivationPolicyRegular];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];

	if (ret == RET_MONO_NOT_FOUND || ret == RET_MONO_INIT_ERROR || ret == RET_MONO_VERSION_OUTDATED)
	{
		NSString *monoMinVersion = @"3.2";
		NSDictionary *plist = [[NSBundle mainBundle] infoDictionary];
		if (plist)
		{
			NSString *versionValue = [plist objectForKey:@"MonoMinVersion"];
			if (versionValue && [versionValue length] > 0)
				monoMinVersion = versionValue;
		}

		[self showMonoPromptWithMinimumVersion: monoMinVersion];
	}
	else if (ret != RET_OPENRA_RESTARTING)
	{
		[self showCrashPrompt];
	}

	exit(1);
}

@end

int main(int argc, char **argv)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSApplication *application = [NSApplication sharedApplication];
	ORALauncher *launcher = [[ORALauncher alloc] init];
	[NSApp setActivationPolicy: NSApplicationActivationPolicyProhibited];

	[application setDelegate:launcher];
	[application run];

	[launcher release];
	[pool drain];

	return EXIT_SUCCESS;
}
