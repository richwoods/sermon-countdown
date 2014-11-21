//
//  AppDelegate.m
//  Sermon Countdown
//
//  Created by Jason Terhorst on 11/20/14.
//  Copyright (c) 2014 Worship Kit. All rights reserved.
//

#import "AppDelegate.h"

#import "JTOutputWindow.h"

@interface AppDelegate ()
{
    NSStatusItem * statusItem;
    NSInteger _remainingSeconds;
}

@property (weak) IBOutlet NSWindow *window;
@property (nonatomic, strong) JTOutputWindow * outputWindow;
@property (nonatomic, strong) NSTimer * outputTimer;

@property (nonatomic, strong) NSString * outputString;

@property (nonatomic, weak) IBOutlet NSTextField * hoursField;
@property (nonatomic, weak) IBOutlet NSTextField * minutesField;
@property (nonatomic, weak) IBOutlet NSTextField * secondsField;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateScreens) name:WKOutputScreenChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateScreens) name:NSApplicationDidChangeScreenParametersNotification object:nil];

    self.outputString = @"";
    
    [self _updateScreens];
}

- (NSString *)_countdownStringForSeconds:(NSInteger)seconds
{
    long conv_secs = lroundf(seconds); // Modulo (%) operator below needs int or long
    
    NSInteger hour = conv_secs / 3600;
    NSInteger mins = (conv_secs % 3600) / 60;
    NSInteger secs = conv_secs % 60;
    
    NSNumberFormatter * timeFormatter = [[NSNumberFormatter alloc] init];
    [timeFormatter setMinimumIntegerDigits:2];
    [timeFormatter setMaximumFractionDigits:0];
    
    if (hour > 0)
        return [NSString stringWithFormat:@"%@:%@:%@", [timeFormatter stringFromNumber:@(hour)], [timeFormatter stringFromNumber:@(mins)], [timeFormatter stringFromNumber:@(secs)]];
    
    return [NSString stringWithFormat:@"%@:%@", [timeFormatter stringFromNumber:@(mins)], [timeFormatter stringFromNumber:@(secs)]];
}

- (IBAction)startCountdown:(id)sender
{
    _remainingSeconds = ([_hoursField integerValue] * 60 * 60) + ([_minutesField integerValue] * 60) + ([_secondsField integerValue]);
    
    _outputTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_updateCountdown) userInfo:nil repeats:YES];
    
    [_window orderOut:nil];
    
    self.outputString = [self _countdownStringForSeconds:_remainingSeconds];
    [self _updateScreens];
}

- (void)_updateCountdown
{
    if (_remainingSeconds < 1)
    {
        [_outputTimer invalidate];
        _outputTimer = nil;
        
        [_outputWindow orderOut:nil];
        _outputWindow = nil;
        
        [_window makeKeyAndOrderFront:nil];
        
        return;
    }
    
    _remainingSeconds = _remainingSeconds - 1;
    
    self.outputString = [self _countdownStringForSeconds:_remainingSeconds];
    
    [self _updateScreens];
}

- (IBAction)showSettings:(id)sender;
{
    [_settingsWindow makeKeyAndOrderFront:nil];
}

- (IBAction)toggleOutput:(NSButton *)sender
{
    _outputWindow.visible = !_outputWindow.visible;
}

- (IBAction)quitPager:(id)sender
{
    [[NSApplication sharedApplication] terminate:nil];
}

- (void)_updateScreens
{
    if ([self.outputString length] < 1)
    {
        [_outputWindow orderOut:nil];
        _outputWindow = nil;
        
        return;
    }
    
    if (!_outputWindow)
    {
        _outputWindow = [[JTOutputWindow alloc] initWithScreenIndex:1];
        _outputWindow.level = NSStatusWindowLevel + 2;
        [_outputWindow setBackgroundColor:[NSColor clearColor]];
        [_outputWindow setOpaque:NO];
        [_outputWindow setHasShadow:NO];
        [_outputWindow orderFront:nil];
        [_outputWindow setFrame:[[[NSScreen screens] objectAtIndex:1] frame] display:YES];
    }
    [_outputWindow setPayloadOutput:self.outputString];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}



@end
