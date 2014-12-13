//
//  DisplayLayoutView.m
//
//  Created by Jason Terhorst on 10/28/13.
//  Copyright (c) 2013. All rights reserved.
//

#import "DisplayLayoutView.h"

@class DisplayView;

@protocol DisplayViewDelegate <NSObject>
@required
- (void)popoverChangedForView:(DisplayView *)view;

@end

@interface DisplayView : NSView

@property (nonatomic, strong) NSPopUpButton * displayPopup;
@property (nonatomic, strong) NSImageView * imageView;
@property (nonatomic, assign) NSInteger screenIndex;
@property (nonatomic, weak) id<DisplayViewDelegate> delegate;

@end

@implementation DisplayView

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self) {
		_imageView = [[NSImageView alloc] initWithFrame:self.bounds];
		_imageView.imageScaling = NSImageScaleAxesIndependently;
		[self addSubview:_imageView];
		_imageView.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;

		_displayPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(10, 10, self.bounds.size.width - 20, 22)];
		[self addSubview:_displayPopup];
		_displayPopup.autoresizingMask = NSViewMaxYMargin|NSViewWidthSizable;

		[_displayPopup addItemsWithTitles:@[@"None", @"Stage", @"Normal"]];
		[_displayPopup setTarget:self];
		[_displayPopup setAction:@selector(popoverChanged:)];

		if ([[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)_screenIndex]])
		{
			NSUInteger selectionIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)_screenIndex]] integerValue];
			if ([_displayPopup indexOfSelectedItem] != selectionIndex)
			{
				[_displayPopup selectItemAtIndex:selectionIndex];
			}
		}
		else
		{
			NSUInteger selectionIndex = 2;
			if (_screenIndex == 0)
			{
				selectionIndex = 0;
			}
			else if (_screenIndex == 1)
			{
				selectionIndex = 1;
			}

			if ([_displayPopup indexOfSelectedItem] != selectionIndex)
			{
				[_displayPopup selectItemAtIndex:selectionIndex];
			}
		}
	}
	return self;
}

- (void)popoverChanged:(id)sender;
{
	NSUInteger selectionIndex = [sender indexOfSelectedItem];

	NSLog(@"popover changed: %lu for screen %lu", (unsigned long)selectionIndex, (unsigned long)_screenIndex);

	[[NSUserDefaults standardUserDefaults] setObject:@(selectionIndex) forKey:[NSString stringWithFormat:@"%lu", (unsigned long)_screenIndex]];
}

@end

@interface DisplayLayoutView ()
{
	NSMutableArray * _displayViews;
}

@end

@implementation DisplayLayoutView

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateScreens) name:NSApplicationDidChangeScreenParametersNotification object:nil];

		[self updateScreens];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {

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
	if ([_displayViews count] == 0 || [_displayViews count] != [[NSScreen screens] count])
	{
		for (DisplayView * dis in _displayViews)
		{
			[dis removeFromSuperview];
		}

		_displayViews = [NSMutableArray array];

		NSInteger iterator = 0;
		for (iterator = 0; iterator < [[NSScreen screens] count]; iterator++)
		{
			DisplayView * dis = [[DisplayView alloc] initWithFrame:NSMakeRect(0, 0, 200, 150)];
			dis.screenIndex = iterator;
			[self addSubview:dis];
			[_displayViews addObject:dis];

			NSURL *imageURL = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:[[NSScreen screens] objectAtIndex:iterator]];
			NSImage * desktopImage = [[NSImage alloc] initWithContentsOfFile:[imageURL path]];
			dis.imageView.image = desktopImage;
		}
	}

	[self setNeedsDisplay:YES];

	NSUInteger screenIndex = 0;

	for (NSScreen * screen in [NSScreen screens])
	{
		NSRect translatedScreenRect = NSMakeRect([self centerMonitorPoint].x + (screen.frame.origin.x / [self screenDrawScaleRatio]), [self centerMonitorPoint].y + (screen.frame.origin.y / [self screenDrawScaleRatio]), screen.frame.size.width / [self screenDrawScaleRatio], screen.frame.size.height / [self screenDrawScaleRatio]);

		DisplayView * dis = [_displayViews objectAtIndex:screenIndex];
		[dis setFrame:translatedScreenRect];

		screenIndex++;
	}
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

	NSUInteger screenIndex = 0;

	for (NSScreen * screen in [NSScreen screens])
	{
		NSRect translatedScreenRect = NSMakeRect([self centerMonitorPoint].x + (screen.frame.origin.x / [self screenDrawScaleRatio]), [self centerMonitorPoint].y + (screen.frame.origin.y / [self screenDrawScaleRatio]), screen.frame.size.width / [self screenDrawScaleRatio], screen.frame.size.height / [self screenDrawScaleRatio]);
		translatedScreenRect.origin.x = translatedScreenRect.origin.x + [self _xOffset];
		translatedScreenRect.origin.y = translatedScreenRect.origin.y + [self _yOffset];

		[[NSBezierPath bezierPathWithRect:translatedScreenRect] stroke];

		DisplayView * view = [_displayViews objectAtIndex:screenIndex];
		view.frame = translatedScreenRect;

		screenIndex++;
	}

//	CGFloat keyWidth = [self fullNormalizedActualPixelSizeOfScreens].size.width / [self screenDrawScaleRatio];
//	CGFloat keyHeight = [self fullNormalizedActualPixelSizeOfScreens].size.height / [self screenDrawScaleRatio];
//	[[NSBezierPath bezierPathWithRect:NSMakeRect((self.bounds.size.width - keyWidth) / 2, (self.bounds.size.height - keyHeight) / 2, keyWidth, keyHeight)] fill];
}




- (CGPoint)centerPoint
{
	return CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
}

- (NSPoint)centerMonitorPoint
{
	NSSize centerMonitorSize = [NSScreen mainScreen].frame.size;
	centerMonitorSize.width = centerMonitorSize.width / [self screenDrawScaleRatio];
	centerMonitorSize.height = centerMonitorSize.height / [self screenDrawScaleRatio];

	return NSMakePoint(0 - ([self _minimumPointXOrigin] / [self screenDrawScaleRatio]), 0 - ([self _minimumPointYOrigin] / [self screenDrawScaleRatio]));
}

- (CGFloat)_minimumPointXOrigin
{
	NSScreen * firstScreen = [[NSScreen screens] firstObject];
	CGFloat xPos = firstScreen.frame.origin.x;
	for (NSScreen * scr in [NSScreen screens])
	{
		if (scr.frame.origin.x < xPos)
		{
			xPos = scr.frame.origin.x;
		}
	}
	return xPos;
}

- (CGFloat)_minimumPointYOrigin
{
	NSScreen * firstScreen = [[NSScreen screens] firstObject];
	CGFloat yPos = firstScreen.frame.origin.y;
	for (NSScreen * scr in [NSScreen screens])
	{
		if (scr.frame.origin.y < yPos)
		{
			yPos = scr.frame.origin.x;
		}
	}
	return yPos;
}

- (CGFloat)_xOffset
{
	CGFloat scaledScreenWidth = ([self fullNormalizedActualPixelSizeOfScreens].size.width / [self screenDrawScaleRatio]);

	return (self.bounds.size.width - scaledScreenWidth) / 2;
}

- (CGFloat)_yOffset
{
	CGFloat scaledScreenHeight = ([self fullNormalizedActualPixelSizeOfScreens].size.height / [self screenDrawScaleRatio]);

	return (self.bounds.size.height - scaledScreenHeight) / 2;
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
	CGFloat viewScaleRatio = [self screenDrawScaleRatio];

	currentSize.width = currentSize.width / viewScaleRatio;
	currentSize.height = currentSize.height / viewScaleRatio;

	return currentSize;
}

// ratio = width / height
// if outer ratio > inner ratio, use height
// if inner ratio > outer ratio, use width

- (CGFloat)screenDrawScaleRatio
{
	CGFloat outerRatio = self.bounds.size.width / self.bounds.size.height;
	CGFloat innerRatio = [self fullNormalizedActualPixelSizeOfScreens].size.width / [self fullNormalizedActualPixelSizeOfScreens].size.height;
	CGFloat viewScaleRatio = [self fullNormalizedActualPixelSizeOfScreens].size.height / (self.bounds.size.height - 20);
	if (innerRatio > outerRatio)
	{
		viewScaleRatio = [self fullNormalizedActualPixelSizeOfScreens].size.width / (self.bounds.size.width - 20);
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
