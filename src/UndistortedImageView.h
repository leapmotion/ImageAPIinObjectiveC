//
//  UndistortedOpenGLView.h
//  SampleObjectiveC
//
//  Created by Joe Ward on 9/17/14.
//  Copyright (c) 2014 Leap Motion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LeapObjectiveC.h"

@interface UndistortedImageView : NSOpenGLView <LeapListener>
- (id)initWithFrame:(NSRect)frame pixelFormat:(NSOpenGLPixelFormat *)format andController:(LeapController *)controller andImageID:(int)ID;
@end
