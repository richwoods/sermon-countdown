//
//  AppDelegate.h
//  Sermon Countdown
//
//  Created by Jason Terhorst on 11/20/14.
//  Copyright (c) 2014 Worship Kit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    
}

@property (nonatomic, assign) IBOutlet NSMenu * statusMenu;
@property (nonatomic, assign) IBOutlet NSWindow * settingsWindow;

@property (nonatomic, strong) NSArray * displayTitles;
@property (nonatomic, assign) NSInteger selectedDisplayIndex;

- (IBAction)startCountdown:(id)sender;

- (IBAction)showSettings:(id)sender;
- (IBAction)quitPager:(id)sender;

@end

static NSString * WKOutputScreenChangedNotification = @"WKOutputScreenChanged";