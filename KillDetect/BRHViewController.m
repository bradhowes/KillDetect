//
//  BRHViewController.m
//  KillDetect
//
//  Created by Brad Howes on 1/24/14.
//  Copyright (c) 2014 Brad Howes. All rights reserved.
//

#import "BRHViewController.h"
#import "BRHAppDelegate.h"
#import "BRHLogger.h"

static NSString* const kHost = @"harrison.local";
static NSUInteger const kPort = 10000;

const uint8_t pingString[] = "ping\n";
const uint8_t pongString[] = "pong\n";

@interface BRHViewController () <NSStreamDelegate>

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic) BOOL sentPing;
@property (nonatomic, strong) NSTimer* restarter;

- (void)logChanged:(NSNotification*)notification;
- (void)attemptReconnect;
- (void)reconnect:(NSTimer*)timer;
- (void)connectToServer;

@end

@implementation BRHViewController

static void* kDelegateObserverContext = &kDelegateObserverContext;

- (void)viewDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logChanged:) name:BRHLogContentsChanged object:[BRHLogger sharedInstance]];
    self.log.attributedText = [[NSAttributedString alloc] initWithString:[[BRHLogger sharedInstance] contents] attributes:self.log.typingAttributes];
    [self connectToServer];
    [super viewDidLoad];
}

- (void)attemptReconnect
{
    [self.inputStream close];
    [self.outputStream close];
    self.restarter = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(reconnect:) userInfo:nil repeats:NO];
}

- (void)reconnect:(NSTimer*)timer
{
    [self connectToServer];
}

- (void)connectToServer
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)(kHost), kPort, &readStream, &writeStream);

    self.sentPing = NO;
    self.inputStream = (__bridge_transfer NSInputStream *)readStream;
    self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    [self.inputStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    [self.outputStream open];
    
    [[UIApplication sharedApplication] setKeepAliveTimeout:600 handler:^{
        if (self.outputStream) {
            [self.outputStream write:pingString maxLength:strlen((char*)pingString)];
            [BRHLogger add:@"Ping sent"];
        }
    }];
}

- (void)logChanged:(NSNotification*)notification
{
    if (notification.userInfo == nil) {
        self.log.text = @"";
    }
    else {
        NSString* line = notification.userInfo[@"line"];
        [self.log.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:line attributes:_log.typingAttributes]];
        [self.log scrollRangeToVisible:NSMakeRange(_log.text.length, 0)];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.log scrollRangeToVisible:NSMakeRange(_log.text.length, 0)];
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (IBAction)clearLog:(id)sender {
    [[BRHLogger sharedInstance] clear];
}

- (void)didReceiveMemoryWarning
{
    [BRHLogger add:@"didReceiveMemoryWarning"];
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventNone:
            // do nothing.
            break;
            
        case NSStreamEventEndEncountered:
            [BRHLogger add:@"stream connection closed"];
            [self attemptReconnect];
            break;

        case NSStreamEventErrorOccurred:
            [BRHLogger add:@"Had error: %@", aStream.streamError];
            [self attemptReconnect];
            break;

        case NSStreamEventHasBytesAvailable:
            if (aStream == self.inputStream) {
                uint8_t buffer[1024];
                NSInteger bytesRead = [self.inputStream read:buffer maxLength:1024];
                NSString* stringRead = [[NSString alloc] initWithBytes:buffer length:bytesRead encoding:NSUTF8StringEncoding];
                stringRead = [stringRead stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

                [BRHLogger add:@"Received: %@", stringRead];

                if ([stringRead isEqualToString:@"notify"]) {
                    UILocalNotification *notification = [[UILocalNotification alloc] init];
                    notification.alertBody = @"New VOIP call";
                    notification.alertAction = @"Answer";
                    [BRHLogger add:@"Notification sent"];
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                }
                else if ([stringRead isEqualToString:@"ping"]) {
                    [self.outputStream write:pongString maxLength:strlen((char*)pongString)];
                }
            }
            break;
            
        case NSStreamEventHasSpaceAvailable:
            if (aStream == self.outputStream && ! self.sentPing) {
                self.sentPing = YES;
                [self.outputStream write:pingString maxLength:strlen((char*)pingString)];
                [BRHLogger add:@"Ping sent"];
            }
            break;

        case NSStreamEventOpenCompleted:
            if (aStream == self.inputStream) {
                [BRHLogger add:@"Connection Opened"];
            }
            break;
            
        default:
            break;
    }
}

@end
