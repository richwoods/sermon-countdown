//
//  JTOutputWindow.h
//  Parent Pager
//
//  Created by Jason Terhorst on 9/8/14.
//  Copyright (c) 2014 Jason Terhorst. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	kCountdownModeNone,
	kCountdownModeStage,
	kCountdownModeNormal
} JTCountdownDisplayMode;

@interface JTOutputWindow : NSWindow

- (instancetype)initWithScreenIndex:(NSUInteger)screenIndex;

@property (nonatomic, assign) NSInteger screenIndex;

@property (nonatomic, strong) NSString * payloadOutput;

@property (nonatomic, assign) BOOL shouldDisplay;

@end
