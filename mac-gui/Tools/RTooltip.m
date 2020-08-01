/*
 *  R.app : a Cocoa front end to: "R A Computer Language for Statistical Data Analysis"
 *  
 *  R.app Copyright notes:
 *                     Copyright (C) 2004-12  The R Foundation
 *                     written by Stefano M. Iacus and Simon Urbanek
 *
 *                  
 *  R Copyright notes:
 *                     Copyright (C) 1995-1996   Robert Gentleman and Ross Ihaka
 *                     Copyright (C) 1998-2001   The R Development Core Team
 *                     Copyright (C) 2002-2004   The R Foundation
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  A copy of the GNU General Public License is available via WWW at
 *  http://www.gnu.org/copyleft/gpl.html.  You can also obtain it by
 *  writing to the Free Software Foundation, Inc., 59 Temple Place,
 *  Suite 330, Boston, MA  02111-1307  USA.
 *
 *  This code is based on the open source tm_dialog plugin for TextMate http://www.macromates.com
 *  originally written by Ciáran Walsh, Allan Odgaard (TMDHTMLtip)
 *  and was heavily modified by H.-J. Bibiko (it's also used in the open source project Sequl Pro 
 *  http://www.sequelpro.com)
 *
 *
 *  RTooltip.m
 *
 *  Created by Hans-J. Bibiko on 26/02/2012.
 *
 *	Usage:
 *	#import "Tools/RTooltip.h"
 *	
 *	[RTooltip showWithObject:@"Hello World"];
 *
 *	[RTooltip showWithObject:@"<h1>Hello</h1>I am a <b>tooltip</b>" ofType:@"html" 
 *			displayOptions:[NSDictionary dictionaryWithObjectsAndKeys:
 *			@"Monaco", @"fontname", 
 *			@"#EEEEEE", @"backgroundcolor", 
 *			@"20", @"fontsize", 
 *			@"transparent", @"transparent", nil]];
 *	
 *	[RTooltip  showWithObject:(id)content 
 *					atLocation:(NSPoint)point 
 *						ofType:(NSString *)type 
 *				displayOptions:(NSDictionary *)displayOptions]
 *	
 *			content: a NSString with the actual content; a NSImage object AND type:"image"
 *			  point: n NSPoint where the tooltip should be shown
 *			         if not given it will be shown under the current caret position or
 *			         if no caret could be found in the upper left corner of the current window
 *			           a passed NSPoint of {-1, -1} will use the current adjusted mouse position
 *			   type: a NSString of: "text", "html", or "image"; no type - 'text' is default
 *	 displayOptions: a NSDictionary with the following keys (all values must be of type NSString):
 *	                       fontname, fontsize, backgroundcolor (as #RRGGBB), transparent (any value)
 *	                 if no displayOptions are passed or if a key doesn't exist the following default
 *	                 are taken:
 *	                       "Lucida Grande", "10", "#F9FBC5", NO
 *	
 *	See more possible syntaxa in RTooltip to init a tooltip
 */

#import "RTooltip.h"

#include <tgmath.h>

static NSInteger RTooltipCounter = 0;

static CGFloat slow_in_out (CGFloat t)
{
	if(t < 1.0f)
		t = 1.0f / (1.0f + exp((-t*12.0f)+6.0f));
	if(t>1.0f) return 1.0f;
	return t;
}

@interface RTooltip (Private)

- (void)setContent:(NSString *)content withOptions:(NSDictionary *)displayOptions;
- (void)runUntilUserActivity;
- (void)stopAnimation:(id)sender;
- (void)sizeToContent;
+ (NSPoint)caretPosition;
+ (void)setDisplayOptions:(NSDictionary *)aDict;
- (void)initMeWithOptions:(NSDictionary *)displayOptions;

@end

@interface WebView (LeopardOnly)

- (void)setDrawsBackground:(BOOL)drawsBackground;

@end

@implementation RTooltip

// ==================
// = Setup/teardown =
// ==================

+ (void)showWithObject:(id)content atLocation:(NSPoint)point
{
	[self showWithObject:content atLocation:point ofType:@"text" displayOptions:[NSDictionary dictionary]];
}

+ (void)showWithObject:(id)content atLocation:(NSPoint)point ofType:(NSString *)type
{
	[self showWithObject:content atLocation:point ofType:type displayOptions:nil];
}

+ (void)showWithObject:(id)content
{
	[self showWithObject:content atLocation:[self caretPosition] ofType:@"text" displayOptions:nil];
}

+ (void)showWithObject:(id)content ofType:(NSString *)type
{
	[self showWithObject:content atLocation:[self caretPosition] ofType:type displayOptions:nil];
}

+ (void)showWithObject:(id)content ofType:(NSString *)type displayOptions:(NSDictionary *)options
{
	[self showWithObject:content atLocation:[self caretPosition] ofType:type displayOptions:options];
}

+ (void)showWithObject:(id)content atLocation:(NSPoint)point ofType:(NSString *)type displayOptions:(NSDictionary *)displayOptions
{

	RTooltipCounter++;

	RTooltip* tip = [RTooltip new]; // Automatically released on close
	[tip initMeWithOptions:displayOptions];
	if(point.x == -1 && point.y == -1) {
		point = [NSEvent mouseLocation];
		point.y -= 16;
	}
	[tip setFrameTopLeftPoint:point];
	if([type isEqualToString:@"text"]) {
		NSString* html = nil;
		NSMutableString* text = [[(NSString*)content mutableCopy] autorelease];
		if(text)
		{
			[text replaceOccurrencesOfString:@"&" withString:@"&amp;" options:0 range:NSMakeRange(0, [text length])];
			[text replaceOccurrencesOfString:@"<" withString:@"&lt;" options:0 range:NSMakeRange(0, [text length])];
			[text insertString:[NSString stringWithFormat:@"<pre style=\"font-family:'%@';\">", 
				([displayOptions objectForKey:@"fontname"]) ? [displayOptions objectForKey:@"fontname"] : @"Lucida Grande"] 
				atIndex:0];
			[text appendString:@"</pre>"];
			html = text;
		}
		else
		{
			html = @"Error";
		}
		[tip setContent:html withOptions:displayOptions];
	}
	else if([type isEqualToString:@"html"]) {
		[tip setContent:(NSString*)content withOptions:displayOptions];
	}
	else if([type isEqualToString:@"image"]) {
		[tip setBackgroundColor:[NSColor clearColor]];
		[tip setOpaque:NO];
		[tip setLevel:NSNormalWindowLevel];
		[tip setExcludedFromWindowsMenu:YES];
		[tip setAlphaValue:1];

		NSSize s = [(NSImage *)content size];
		
		// Downsize a large image
		NSInteger w = s.width;
		NSInteger h = s.height;
		if(w>h) {
			if(s.width > 200) {
				w = 200;
				h = 200/s.width*s.height;
			}
		} else {
			if(s.height > 200) {
				h = 200;
				w = 200/s.height*s.width;
			}
		}
		
		// Show image in a NSImageView
		NSImageView *backgroundImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0,0,w, h)];
		[backgroundImageView setImage:(NSImage *)content];
		[backgroundImageView setFrameSize:NSMakeSize(w, h)];
		[tip setContentView:backgroundImageView];
		[tip setContentSize:NSMakeSize(w,h)];
		[tip setFrameTopLeftPoint:point];
		[tip sizeToContent];
		[tip orderFront:self];
		[tip performSelector:@selector(runUntilUserActivity) withObject:nil afterDelay:0.0f];
		[backgroundImageView release];
	}
	else {
		[tip setContent:(NSString*)content withOptions:displayOptions];
		NSBeep();
		NSLog(@"RTooltip: Type '%@' is not supported. Please use 'text' or 'html'. Tooltip is displayed as type 'html'", type);
	}

}

- (void)initMeWithOptions:(NSDictionary *)displayOptions
{
	[self setReleasedWhenClosed:YES];
	[self setAlphaValue:0.97f];
	[self setOpaque:NO];
	[self setBackgroundColor:[NSColor colorWithDeviceRed:1.0f green:0.96f blue:0.76f alpha:1.0f]];
	[self setBackgroundColor:[NSColor clearColor]];
	[self setHasShadow:YES];
	[self setLevel:NSStatusWindowLevel];
	[self setHidesOnDeactivate:YES];
	[self setIgnoresMouseEvents:YES];

	webPreferences = [[WebPreferences alloc] initWithIdentifier:@"R Tooltip"];
	[webPreferences setJavaScriptEnabled:YES];

	NSString *fontName = ([displayOptions objectForKey:@"fontname"]) ? [displayOptions objectForKey:@"fontname"] : @"Lucida Grande";
	int fontSize = ([displayOptions objectForKey:@"fontsize"]) ? [[displayOptions objectForKey:@"fontsize"] intValue] : 10;
	if(fontSize < 5) fontSize = 5;
	
	NSFont* font = [NSFont fontWithName:fontName size:fontSize];
	[webPreferences setStandardFontFamily:[font familyName]];
	[webPreferences setDefaultFontSize:fontSize];
	[webPreferences setDefaultFixedFontSize:fontSize];

	webView = [[WebView alloc] initWithFrame:NSZeroRect];
	[webView setPreferencesIdentifier:@"R Tooltip"];
	[webView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[webView setFrameLoadDelegate:self];
	if ([webView respondsToSelector:@selector(setDrawsBackground:)])
	    [webView setDrawsBackground:NO];

	[self setContentView:webView];
	
}

- (id)init;
{
	if((self = [self initWithContentRect:NSMakeRect(1,1,1,1) 
					styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO]))
	{
	}
	return self;
}

- (void)dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[didOpenAtDate release];
	[webView release];
	[webPreferences release];
	[super dealloc];
}

+ (void)setDisplayOptions:(NSDictionary *)aDict
{
	// displayOptions = [NSDictionary dictionaryWithDictionary:aDict];
}

+ (NSPoint)caretPosition
{
	NSPoint pos;
	id fr = [[NSApp keyWindow] firstResponder];

	//If first responder is a textview return the caret position
	if([fr isKindOfClass:[NSTextView class]] && ([fr alignment] == NSLeftTextAlignment || [fr alignment] == NSNaturalTextAlignment)) {
		NSRange range = NSMakeRange([fr selectedRange].location, 0);
		NSRange glyphRange = [[fr layoutManager] glyphRangeForCharacterRange:range actualCharacterRange:NULL];
		NSRect boundingRect = [[fr layoutManager] boundingRectForGlyphRange:glyphRange inTextContainer:[fr textContainer]];
		boundingRect = [fr convertRect: boundingRect toView:NULL];
		pos = [[fr window] convertBaseToScreen: NSMakePoint(boundingRect.origin.x + boundingRect.size.width,boundingRect.origin.y + boundingRect.size.height)];
		NSFont* font = [fr font];
		if(font) pos.y -= [font pointSize]*1.3f;
		return pos;
	// Otherwise return mouse location
	} else {
		pos = [NSEvent mouseLocation];
		pos.y -= 16;
		return pos;
	}
}

// ===========
// = Webview =
// ===========
- (void)setContent:(NSString *)content withOptions:(NSDictionary *)displayOptions
{

	NSString *fullContent =	@"<html>"
				@"<head>"
				@"  <style type='text/css' media='screen'>"
				@"      body {"
				@"          background: %@;"
				@"          margin: 0;"
				@"          padding: 2px;"
				@"          overflow: hidden;"
				@"          display: table-cell;"
				@"          max-width: 800px;"
				@"      }"
				@"      pre { white-space: pre-wrap; }"
				@"  </style>"
				@"</head>"
				@"<body>%@</body>"
				@"</html>";

	NSString *bgColor = ([displayOptions objectForKey:@"backgroundcolor"]) ? [displayOptions objectForKey:@"backgroundcolor"] : @"#F9FBC5";
	BOOL isTransparent = ([displayOptions objectForKey:@"transparent"]) ? YES : NO;


	fullContent = [NSString stringWithFormat:fullContent, isTransparent ? @"transparent" : bgColor, content];
	[[webView mainFrame] loadHTMLString:fullContent baseURL:nil];

}

- (void)sizeToContent
{

	NSRect frame;

	// Current tooltip position
	NSPoint pos = NSMakePoint([self frame].origin.x, [self frame].origin.y + [self frame].size.height);

	// Find the screen which we are displaying on
	NSRect screenFrame = [[NSScreen mainScreen] frame];
	NSScreen* candidate;
	for(candidate in [NSScreen screens])
	{
		if(NSMinX([candidate frame]) < pos.x && NSMinX([candidate frame]) > NSMinX(screenFrame))
			screenFrame = [candidate frame];
	}

	// is contentView a webView calculate actual rendered size via JavaScript
	if([[[[self contentView] class] description] isEqualToString:@"WebView"]) {
		// The webview is set to a large initial size and then sized down to fit the content
		[self setContentSize:NSMakeSize(screenFrame.size.width - screenFrame.size.width / 3.0f , screenFrame.size.height)];

		NSInteger height  = [[[webView windowScriptObject] evaluateWebScript:@"document.body.offsetHeight + document.body.offsetTop;"] integerValue];
		NSInteger width   = [[[webView windowScriptObject] evaluateWebScript:@"document.body.offsetWidth + document.body.offsetLeft;"] integerValue];
	
		[webView setFrameSize:NSMakeSize(width, height)];

		frame = [self frameRectForContentRect:[webView frame]];
	} else {
		frame = [self frame];
	}
	
	//Adjust frame to fit into the screenFrame
	frame.size.width  = MIN(NSWidth(frame), NSWidth(screenFrame));
	frame.size.height = MIN(NSHeight(frame), NSHeight(screenFrame));

	[self setFrame:frame display:NO];

	//Adjust tooltip origin to fit into the screenFrame
	pos.x = MAX(NSMinX(screenFrame), MIN(pos.x, NSMaxX(screenFrame)-NSWidth(frame)));
	pos.y = MIN(MAX(NSMinY(screenFrame)+NSHeight(frame), pos.y), NSMaxY(screenFrame));

	[self setFrameTopLeftPoint:pos];
	
}

- (void)webView:(WebView*)sender didFinishLoadForFrame:(WebFrame*)frame;
{
	[self sizeToContent];
	[self orderFront:self];
	[self performSelector:@selector(runUntilUserActivity) withObject:nil afterDelay:0];
}

// ==================
// = Event handling =
// ==================
- (BOOL)shouldCloseForMousePosition:(NSPoint)aPoint
{
	CGFloat ignorePeriod = 0.05f;
	if(-[didOpenAtDate timeIntervalSinceNow] < ignorePeriod)
		return NO;

	if(NSEqualPoints(mousePositionWhenOpened, NSZeroPoint))
	{
		mousePositionWhenOpened = aPoint;
		return NO;
	}

	NSPoint p = mousePositionWhenOpened;
	CGFloat deltaX = p.x - aPoint.x;
	CGFloat deltaY = p.y - aPoint.y;
	CGFloat dist = sqrt(deltaX * deltaX + deltaY * deltaY);

	CGFloat moveThreshold = 10;
	return dist > moveThreshold;
}

- (void)runUntilUserActivity
{
	[self setValue:[NSDate date] forKey:@"didOpenAtDate"];
	mousePositionWhenOpened = NSZeroPoint;


	NSWindow* appKeyWindow = [[NSApp keyWindow] retain];
	BOOL didAcceptMouseMovedEvents = [appKeyWindow acceptsMouseMovedEvents];
	[appKeyWindow setAcceptsMouseMovedEvents:YES];
	NSEvent* event = nil;
	NSInteger eventType;
	while((event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantFuture] inMode:NSDefaultRunLoopMode dequeue:YES]))
	{
		eventType = [event type];
		if(eventType == NSKeyDown || eventType == NSLeftMouseDown || eventType == NSRightMouseDown || eventType == NSOtherMouseDown || eventType == NSScrollWheel)
			break;

		if(eventType == NSMouseMoved && [self shouldCloseForMousePosition:[NSEvent mouseLocation]])
			break;

		if(appKeyWindow != [NSApp keyWindow] || ![NSApp isActive])
			break;
		
		if(RTooltipCounter > 1)
			break;
		[NSApp sendEvent:event];

	}

	[appKeyWindow setAcceptsMouseMovedEvents:didAcceptMouseMovedEvents];
	[appKeyWindow release];

	[self orderOut:self];

	// If we still have an event, pass it on to the app to ensure all actions are performed
	[NSApp sendEvent:event];

}

// =============
// = Animation =
// =============
- (void)orderOut:(id)sender
{
	if(![self isVisible] || animationTimer)
		return;

	[self stopAnimation:self];
	[self setValue:[NSDate date] forKey:@"animationStart"];
	[self setValue:[NSTimer scheduledTimerWithTimeInterval:0.001f target:self selector:@selector(animationTick:) userInfo:nil repeats:YES] forKey:@"animationTimer"];
}

- (void)animationTick:(id)sender
{
	CGFloat alpha = 0.97f * (1.0f - 40*slow_in_out(-2.2f * (float)[animationStart timeIntervalSinceNow]));

	if(alpha > 0.0f && RTooltipCounter==1)
	{
		[self setAlphaValue:alpha];
	}
	else
	{
		[self stopAnimation:self];

		RTooltipCounter--;
		if(RTooltipCounter < 0) RTooltipCounter = 0;

		[self close];

	}
}

- (void)stopAnimation:(id)sender;
{
	if(animationTimer)
	{
		[[self retain] autorelease];
		[animationTimer invalidate];
		[self setValue:nil forKey:@"animationTimer"];
		[self setValue:nil forKey:@"animationStart"];
		[self setAlphaValue:0.97f];
	}
}

@end
