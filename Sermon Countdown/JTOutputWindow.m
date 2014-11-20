//
//  JTOutputWindow.m
//  Parent Pager
//
//  Created by Jason Terhorst on 9/8/14.
//  Copyright (c) 2014 Jason Terhorst. All rights reserved.
//

#import "JTOutputWindow.h"

#import <QuartzCore/QuartzCore.h>

@interface JTOutputWindow ()
{
    NSString * _payloadOutput;

	CATextLayer * _pagerTextLayer;

    //NSTimer * _outputTimer;
}

@end

CGFloat fontSize = 45;

@implementation JTOutputWindow

- (instancetype)initWithScreenIndex:(NSUInteger)screenIndex
{
	NSScreen * selectedScreen = [NSScreen mainScreen];
	if (screenIndex < [[NSScreen screens] count])
	{
		selectedScreen = [[NSScreen screens] objectAtIndex:screenIndex];
	}

	NSRect screenRect = [selectedScreen frame];

	self = [super initWithContentRect:screenRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:selectedScreen];
	if (self)
	{
		_screenIndex = screenIndex;

		[[self contentView] setWantsLayer:YES];
		
		_pagerTextLayer = [CATextLayer layer];
		_pagerTextLayer.frame = CGRectMake(40, 10, [[self contentView] layer].bounds.size.width - 20, 100);
		_pagerTextLayer.string = @"";
		_pagerTextLayer.font = (__bridge CFTypeRef)([NSFont fontWithName:@"Helvetica" size:40]);
		
        if (![[NSUserDefaults standardUserDefaults] valueForKey:@"text_output_tint"])
            _pagerTextLayer.foregroundColor = (__bridge CGColorRef)([NSColor whiteColor]);
        else
            _pagerTextLayer.foregroundColor = (__bridge CGColorRef)([NSColor colorWithWhite:[[NSUserDefaults standardUserDefaults] floatForKey:@"text_output_tint"] alpha:1.0]);
		
        _pagerTextLayer.alignmentMode = kCAAlignmentLeft;
		_pagerTextLayer.opaque = NO;
		_pagerTextLayer.backgroundColor = (__bridge CGColorRef)([NSColor clearColor]);
		_pagerTextLayer.shadowColor = (__bridge CGColorRef)([NSColor blackColor]);
		_pagerTextLayer.shadowOffset = CGSizeMake(1, 1);
		_pagerTextLayer.shadowOpacity = 1.0;
		[[[self contentView] layer] addSublayer:_pagerTextLayer];

		float bodySize = fontSize;
		NSFont * bodyFont = [NSFont fontWithName:@"Myriad Pro Bold" size:bodySize];
		if (!bodyFont)
		{
			bodyFont = [NSFont boldSystemFontOfSize:bodySize];
		}

		bodySize = [self actualFontSizeForText:@"000000" withFont:bodyFont withOriginalSize:bodySize];
		bodyFont = [NSFont fontWithName:bodyFont.fontName size:bodySize];
		_pagerTextLayer.font = (__bridge CFTypeRef)(bodyFont);
		_pagerTextLayer.fontSize = bodySize;
        
        
        [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"text_output_tint" options:NSKeyValueObservingOptionNew context:nil];
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"text_output_tint"])
    {
        if (![[NSUserDefaults standardUserDefaults] valueForKey:@"text_output_tint"])
            _pagerTextLayer.foregroundColor = (__bridge CGColorRef)([NSColor whiteColor]);
        else
            _pagerTextLayer.foregroundColor = (__bridge CGColorRef)([NSColor colorWithWhite:[[NSUserDefaults standardUserDefaults] floatForKey:@"text_output_tint"] alpha:1.0]);
    }
}

- (void)dealloc
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"text_output_tint"];
}

- (void)setVisible:(BOOL)visible
{
	_pagerTextLayer.hidden = !visible;
}

- (BOOL)visible
{
	return !_pagerTextLayer.hidden;
}

- (void)timerComplete:(NSTimer *)timer
{
    _payloadOutput = nil;

	_pagerTextLayer.string = @"";
}

- (void)setPayloadOutput:(NSString *)payloadOutput
{
    _payloadOutput = payloadOutput;

	_pagerTextLayer.string = payloadOutput;

	float bodySize = fontSize;
	NSFont * bodyFont = [NSFont fontWithName:@"Myriad Pro Bold" size:bodySize];
	if (!bodyFont)
	{
		bodyFont = [NSFont boldSystemFontOfSize:bodySize];
	}

	bodySize = [self actualFontSizeForText:_payloadOutput withFont:bodyFont withOriginalSize:bodySize];
	bodyFont = [NSFont fontWithName:bodyFont.fontName size:bodySize];
	_pagerTextLayer.font = (__bridge CFTypeRef)(bodyFont);
	_pagerTextLayer.fontSize = bodySize;
}



- (float)portWidth
{
	return [[self contentView] layer].frame.size.width;
}

- (float)portHeight
{
	return [[self contentView] layer].frame.size.height;
}



- (float)textScaleRatio;
{
	return [self portWidth] / 1024;
}

- (float)actualFontSizeForText:(NSString *)text withFont:(NSFont *)aFont withOriginalSize:(float)originalSize;
{
	float scaledSize = originalSize * [self textScaleRatio];

	if (!aFont)
	{
		aFont = [NSFont systemFontOfSize:scaledSize];
	}
	aFont = [NSFont fontWithName:aFont.fontName size:scaledSize];

	float longestLineWidth = 1;

	NSArray * textComponents = [text componentsSeparatedByString:@"\n"];

	if ([textComponents count] < 2 || [text length] < 2)
	{
		NSDictionary * attribs = [NSDictionary dictionaryWithObject:aFont forKey:NSFontAttributeName];

		NSSize textSize = [text sizeWithAttributes:attribs];
		if (textSize.width > longestLineWidth)
			longestLineWidth = textSize.width;
	}
	else
	{
		for (NSString * line in textComponents)
		{
			NSDictionary * attribs = [NSDictionary dictionaryWithObject:aFont forKey:NSFontAttributeName];

			NSSize textSize = [line sizeWithAttributes:attribs];
			if (textSize.width > longestLineWidth)
				longestLineWidth = textSize.width;
		}
	}

	//NSLog(@"text width: %f, scaled text size: %f, original text size: %f", longestLineWidth, scaledSize, originalSize);

	if (longestLineWidth > [self portWidth] - ([self portWidth] * 0.1))
	{
		float ratio = ([self portWidth] - ([self portWidth] * 0.1)) / longestLineWidth;
		scaledSize = scaledSize * ratio;
	}

	//NSLog(@"final text size to fit: %f", scaledSize);

	return scaledSize;
}


@end
