/******************************************************************************\
* Copyright (C) 2012-2013 Leap Motion, Inc. All rights reserved.               *
* Leap Motion proprietary and confidential. Not for distribution.              *
* Use subject to the terms of the Leap Motion SDK Agreement available at       *
* https://developer.leapmotion.com/sdk_agreement, or another agreement         *
* between Leap Motion and you, your company or other organization.             *
\******************************************************************************/

#import <Cocoa/Cocoa.h>
#import "LeapObjectiveC.h"

@class Sample;

@interface AppDelegate : NSObject <NSApplicationDelegate, LeapListener>

@property (nonatomic, strong, readwrite)IBOutlet NSWindow *window;

@property (weak) IBOutlet NSTextField *leftID;
@property (weak) IBOutlet NSTextField *rightID;
@property (weak) IBOutlet NSTextField *leftSize;
@property (weak) IBOutlet NSTextField *leftDistortionMapSize;
@property (weak) IBOutlet NSTextField *rayOffsets;
@property (weak) IBOutlet NSTextField *rayScales;
@property (weak) IBOutlet NSTextField *isFlipped;
@property (weak) IBOutlet NSTextField *rightSize;
@property (weak) IBOutlet NSTextField *rightDistortionMapSize;

- (IBAction)showRawImage:(id)sender;
- (IBAction)showUndistortedImage:(id)sender;
- (IBAction)showRawImageWithTips:(id)sender;
- (IBAction)showUndistortedImageWithTips:(id)sender;
@end
