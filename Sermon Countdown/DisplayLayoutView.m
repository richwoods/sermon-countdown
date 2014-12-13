//
//  DisplayLayoutView.m
//
//  Created by Jason Terhorst on 10/28/13.
//  Copyright (c) 2013. All rights reserved.
//

#import "DisplayLayoutView.h"



@implementation DisplayLayoutView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

		displayPopups = [NSMutableArray array];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateScreens) name:NSApplicationDidChangeScreenParametersNotification object:nil];

		[self updateScreens];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {

		displayPopups = [NSMutableArray array];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateScreens) name:NSApplicationDidChangeScreenParametersNotification object:nil];

		[self updateScreens];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateScreens;
{
	for (NSPopUpButton * popup in displayPopups)
	{
		[popup removeFromSuperview];
	}

	[displayPopups removeAllObjects];

	[self setNeedsDisplay:YES];

	NSUInteger screenIndex = 0;

	for (NSScreen * screen in [NSScreen screens])
	{
		NSRect translatedScreenRect = NSMakeRect([self centerMonitorPoint].x + (screen.frame.origin.x / [self screenDrawScaleRatio]), [self centerMonitorPoint].y + (screen.frame.origin.y / [self screenDrawScaleRatio]), screen.frame.size.width / [self screenDrawScaleRatio], screen.frame.size.height / [self screenDrawScaleRatio]);

		NSPopUpButton * button = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(translatedScreenRect.origin.x, translatedScreenRect.origin.y, translatedScreenRect.size.width, 22)];
		[button addItemsWithTitles:@[@"None", @"Stage", @"Normal"]];
		[button setTarget:self];
		[button setAction:@selector(popoverChanged:)];

		if ([[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)screenIndex]])
		{
			NSUInteger selectionIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)screenIndex]] integerValue];
			[button selectItemAtIndex:selectionIndex];
		}
		else
		{
			NSUInteger selectionIndex = 2;
			if (screenIndex == 0)
			{
				selectionIndex = 0;
			}
			else if (screenIndex == 1)
			{
				selectionIndex = 1;
			}

			[button selectItemAtIndex:selectionIndex];
		}

		[self addSubview:button];
		[displayPopups addObject:button];

		screenIndex++;
	}
}

- (void)popoverChanged:(id)sender;
{
	NSUInteger screenIndex = [displayPopups indexOfObject:sender];
	NSUInteger selectionIndex = [sender indexOfSelectedItem];

	NSLog(@"popover changed: %lu for screen %lu", (unsigned long)selectionIndex, (unsigned long)screenIndex);

	[[NSUserDefaults standardUserDefaults] setObject:@(selectionIndex) forKey:[NSString stringWithFormat:@"%lu", (unsigned long)screenIndex]];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];

	[[NSColor whiteColor] set];
	[[NSBezierPath bezierPathWithRect:[self bounds]] fill];

	[[NSColor grayColor] set];
	[[NSBezierPath bezierPathWithRect:[self bounds]] stroke];


	[NSBezierPath setDefaultLineWidth:2];

	NSRect screenAreaRect = NSMakeRect(0, 0, [self scaledSizeForScreens].width, [self scaledSizeForScreens].height);
	screenAreaRect.origin.x = (self.bounds.size.width / 2) - (screenAreaRect.size.width / 2);
	screenAreaRect.origin.y = (self.bounds.size.height / 2) - (screenAreaRect.size.height / 2);
	
	[[NSColor purpleColor] set];

	for (NSScreen * screen in [NSScreen screens])
	{
		NSRect translatedScreenRect = NSMakeRect([self centerMonitorPoint].x + (screen.frame.origin.x / [self screenDrawScaleRatio]), [self centerMonitorPoint].y + (screen.frame.origin.y / [self screenDrawScaleRatio]), screen.frame.size.width / [self screenDrawScaleRatio], screen.frame.size.height / [self screenDrawScaleRatio]);

		NSURL *imageURL = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:screen];
		
		NSImage * desktopImage = [[NSImage alloc] initWithContentsOfFile:[imageURL path]];

		[desktopImage drawInRect:translatedScreenRect fromRect:NSMakeRect(0, 0, desktopImage.size.width, desktopImage.size.height) operation:NSCompositeCopy fraction:1.0];

		[[NSBezierPath bezierPathWithRect:translatedScreenRect] stroke];
	}

}


// ratio = width / height
// if outer ratio > inner ratio, use height
// if inner ratio > outer ratio, use width

- (CGPoint)centerPoint
{
	return CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
}

- (NSPoint)centerMonitorPoint
{
	NSSize centerMonitorSize = [NSScreen mainScreen].frame.size;
	centerMonitorSize.width = centerMonitorSize.width / [self screenDrawScaleRatio];
	centerMonitorSize.height = centerMonitorSize.height / [self screenDrawScaleRatio];

	return NSMakePoint([self centerPoint].x - (centerMonitorSize.width / 2), [self centerPoint].y - (centerMonitorSize.height / 2));
}


- (NSRect)fullNormalizedActualPixelSizeOfScreens
{
	NSRect defaultRect = [NSScreen mainScreen].frame;

	for (NSScreen * screen in [NSScreen screens])
	{
		defaultRect = NSUnionRect(screen.frame, defaultRect);
	}

	return defaultRect;
}

- (CGSize)scaledSizeForScreens
{
	CGSize currentSize = [self fullNormalizedActualPixelSizeOfScreens].size;
	float viewScaleRatio = currentSize.width / (self.bounds.size.width - 20);
	if ((currentSize.height / viewScaleRatio) > (self.bounds.size.height - 20))
	{
		viewScaleRatio = currentSize.height / (self.bounds.size.height - 20);
	}

	currentSize.width = currentSize.width / viewScaleRatio;
	currentSize.height = currentSize.height / viewScaleRatio;

	return currentSize;
}

- (CGFloat)screenDrawScaleRatio
{
	CGSize currentSize = [self fullNormalizedActualPixelSizeOfScreens].size;
	CGFloat viewScaleRatio = currentSize.width / (self.bounds.size.width - 20);
	if ((currentSize.height / viewScaleRatio) > (self.bounds.size.height - 20))
	{
		viewScaleRatio = currentSize.height / (self.bounds.size.height - 20);
	}

	return viewScaleRatio;
}

- (float)scaleRatioForWidth
{
	return [self fullNormalizedActualPixelSizeOfScreens].size.width / (self.frame.size.width - 20);
}

- (float)scaleRatioForHeight
{
	return [self fullNormalizedActualPixelSizeOfScreens].size.height / (self.frame.size.height - 20);
}

@end
