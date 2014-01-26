//
//  BRHAppDelegate.m
//  KillDetect
//
//  Created by Brad Howes on 1/24/14.
//  Copyright (c) 2014 Brad Howes. All rights reserved.
//

#import "BRHAppDelegate.h"
#import "BRHLogger.h"

@implementation BRHAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    [BRHLogger add:@"applicationWillResignActive"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [BRHLogger add:@"applicationDidBecomeActive"];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [BRHLogger add:@"applicationDidEnterBackground"];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [BRHLogger add:@"applicationWillEnterForeground"];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [BRHLogger add:@"applicationWillTerminate"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"terminated"];
}

@end
