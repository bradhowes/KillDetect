//
//  BRHAppDelegate.h
//  KillDetect
//
//  Created by Brad Howes on 1/24/14.
//  Copyright (c) 2014 Brad Howes. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SRWebSocket;

@interface BRHAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) SRWebSocket* connection;

@end
