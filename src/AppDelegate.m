/******************************************************************************\
* Copyright (C) 2012-2013 Leap Motion, Inc. All rights reserved.               *
* Leap Motion proprietary and confidential. Not for distribution.              *
* Use subject to the terms of the Leap Motion SDK Agreement available at       *
* https://developer.leapmotion.com/sdk_agreement, or another agreement         *
* between Leap Motion and you, your company or other organization.             *
\******************************************************************************/

#import "AppDelegate.h"
#import "UndistortedImageView.h"
#import "RawImageView.h"
#import "RawImageWithTips.h"
#import "UndistortedImageViewWithTips.h"

@implementation AppDelegate

LeapController *controller;
NSMutableArray *windows;

- (void)awakeFromNib
{
    windows = [[NSMutableArray alloc] init];
    controller = [[LeapController alloc] init];
    [controller addListener:self];
}

- (void)onConnect:(NSNotification *)notification
{
    NSLog(@"Device connected.");
    LeapController *controller = (LeapController *)[notification object];
    [controller setPolicyFlags:LEAP_POLICY_IMAGES];
    [controller.config setBool:@"tracking_tool_enabled" value:YES];
    [controller.config save];
}

- (void)onFrame:(NSNotification *)notification
{
    LeapController *controller = (LeapController *)[notification object];
    LeapDevice *device = [controller.devices objectAtIndex:0];
    LeapFrame *frame = [controller frame:0];

    if (frame.images.count > 1) { //Set image display values in main window
        LeapImage *left = [frame.images objectAtIndex:0];
        LeapImage *right = [frame.images objectAtIndex:1];
        [self.leftID setStringValue:[NSString stringWithFormat:@"%i",left.id]];
        [self.rightID setStringValue:[NSString stringWithFormat:@"%i",right.id]];
        [self.leftSize setStringValue:[NSString stringWithFormat:@"(%d, %d)",left.width, left.height]];
        [self.rightSize setStringValue:[NSString stringWithFormat:@"(%d, %d)",right.width, right.height]];
        [self.leftDistortionMapSize setStringValue:[NSString stringWithFormat:@"(%d, %d)",left.distortionWidth, left.distortionHeight]];
        [self.rightDistortionMapSize setStringValue:[NSString stringWithFormat:@"(%d, %d)",right.distortionWidth, right.distortionHeight]];
        [self.rayOffsets setStringValue:[NSString stringWithFormat:@"(%f, %f)",left.rayOffsetX, left.rayOffsetY]];
        [self.rayScales setStringValue:[NSString stringWithFormat:@"(%f, %f)",left.rayScaleX, left.rayScaleY]];
        [self.isFlipped setStringValue:[NSString stringWithFormat:@"%@",(device.isFlipped) ? @"Yes" : @"No"]];
    }

}

//Open window displaying the raw images from the cameras
- (IBAction)showRawImage:(id)sender
{
    LeapFrame *frame = [controller frame:0];
    if (frame.images.count > 0) {
        LeapImage *leftImage = [frame.images objectAtIndex:0];
        LeapImage *rightImage = [frame.images objectAtIndex:1];

        NSWindow * window =  [self createWindow:CGRectMake(200, 200, 2 * leftImage.width, leftImage.height) withTitle:@"Raw Image"];
        [windows addObject:window];
        NSView *iWindowView = window.contentView;

        NSRect rightImageFrame = NSMakeRect(leftImage.width,0,rightImage.width, rightImage.height);
        RawImageView *rightImageView = [[RawImageView alloc] initWithFrame:rightImageFrame controller:controller andImageID:rightImage.id];
        [iWindowView addSubview:rightImageView];

        NSRect leftImageFrame = NSMakeRect(0,0,leftImage.width, leftImage.height);
        RawImageView *leftImageView = [[RawImageView alloc] initWithFrame:leftImageFrame controller:controller andImageID:leftImage.id];
        [iWindowView addSubview:leftImageView];

        [window makeKeyAndOrderFront: window];
    }

}

//Open window displaying the distortion-corrected images from the cameras
- (IBAction)showUndistortedImage:(id)sender {
    LeapFrame *frame = [controller frame:0];
    if (frame.images.count > 0) {
        LeapImage *leftImage = [frame.images objectAtIndex:0];
        LeapImage *rightImage = [frame.images objectAtIndex:1];

        NSWindow * dwindow =  [self createWindow:CGRectMake(0, 0,  2 * leftImage.width, leftImage.width) withTitle:@"Undistorted Image"];
        [windows addObject:dwindow];
        [dwindow makeKeyAndOrderFront: dwindow];

        NSView *dWindowView = dwindow.contentView;

        NSOpenGLPixelFormatAttribute attrs[] =
        {
            NSOpenGLPFADoubleBuffer,
            NSOpenGLPFADepthSize, 24,
            NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
            0
        };

        NSOpenGLPixelFormat* pixFmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
        if (pixFmt == nil) {
            NSLog(@"Pixel format creation failed.");
        }

        NSRect leftImageFrame = NSMakeRect(0,0,leftImage.width, leftImage.height);
        UndistortedImageView *leftUnwarpWithShaderView = [[UndistortedImageView alloc] initWithFrame:leftImageFrame pixelFormat:pixFmt andController:controller andImageID:leftImage.id];
        [dWindowView addSubview:leftUnwarpWithShaderView];

        NSRect rightImageFrame = NSMakeRect(leftImage.width,0,rightImage.width, rightImage.height);
        UndistortedImageView *rightUnwarpWithShaderView = [[UndistortedImageView alloc] initWithFrame:rightImageFrame pixelFormat:pixFmt andController:controller andImageID:rightImage.id];
        [dWindowView addSubview:rightUnwarpWithShaderView];
    }
}

//Open window displaying the raw images from the cameras with overlayed fingertip positions
- (IBAction)showRawImageWithTips:(id)sender {
    LeapFrame *frame = [controller frame:0];
    if (frame.images.count > 0) {
        LeapImage *leftImage = [frame.images objectAtIndex:0];
        LeapImage *rightImage = [frame.images objectAtIndex:1];

        NSWindow * window =  [self createWindow:CGRectMake(200, 200, 2 * leftImage.width, leftImage.height) withTitle:@"Raw Image with Finger Tips"];
        [windows addObject:window];
        NSView *iWindowView = window.contentView;

        NSRect rightImageFrame = NSMakeRect(leftImage.width,0,rightImage.width, rightImage.height);
        RawImageWithTips *rightImageView = [[RawImageWithTips alloc] initWithFrame:rightImageFrame controller:controller andImageID:rightImage.id];
        [iWindowView addSubview:rightImageView];

        NSRect leftImageFrame = NSMakeRect(0,0,leftImage.width, leftImage.height);
        RawImageWithTips *leftImageView = [[RawImageWithTips alloc] initWithFrame:leftImageFrame controller:controller andImageID:leftImage.id];
        [iWindowView addSubview:leftImageView];

        [window makeKeyAndOrderFront: window];
    }
}

//Open window displaying the distortion-corrected images from the cameras with overlayed fingertip positions
- (IBAction)showUndistortedImageWithTips:(id)sender {
    LeapFrame *frame = [controller frame:0];
    if (frame.images.count > 0) {
        LeapImage *leftImage = [frame.images objectAtIndex:0];
        LeapImage *rightImage = [frame.images objectAtIndex:1];

        NSWindow * dwindow =  [self createWindow:CGRectMake(0, 0,  2 * leftImage.width, leftImage.width) withTitle:@"Undistorted Image with Finger Tips"];
        [windows addObject:dwindow];
        [dwindow makeKeyAndOrderFront: dwindow];

        NSView *dWindowView = dwindow.contentView;

        NSOpenGLPixelFormatAttribute attrs[] =
        {
            NSOpenGLPFADoubleBuffer,
            NSOpenGLPFADepthSize, 24,
            NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
            0
        };

        NSOpenGLPixelFormat* pixFmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
        if (pixFmt == nil) {
            NSLog(@"Pixel format creation failed.");
        }

        NSRect leftImageFrame = NSMakeRect(0,0,leftImage.width, leftImage.height);
        UndistortedImageViewWithTips *leftUnwarpWithShaderView = [[UndistortedImageViewWithTips alloc] initWithFrame:leftImageFrame pixelFormat:pixFmt andController:controller andImageID:leftImage.id];
        [dWindowView addSubview:leftUnwarpWithShaderView];

        NSRect rightImageFrame = NSMakeRect(leftImage.width,0,rightImage.width, rightImage.height);
        UndistortedImageViewWithTips *rightUnwarpWithShaderView = [[UndistortedImageViewWithTips alloc] initWithFrame:rightImageFrame pixelFormat:pixFmt andController:controller andImageID:rightImage.id];
        [dWindowView addSubview:rightUnwarpWithShaderView];
    }
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication
{
    return YES;
}

//Utility function to create a window
- (NSWindow *) createWindow:(NSRect)frame withTitle:(NSString *)title
{
    NSUInteger styleMask =    NSResizableWindowMask | NSClosableWindowMask | NSTitledWindowMask;
    NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
    NSWindow * window =  [[NSWindow alloc] initWithContentRect:rect styleMask:styleMask backing: NSBackingStoreBuffered defer:false];
    [window setTitle:title];
    return window;
}

@end
