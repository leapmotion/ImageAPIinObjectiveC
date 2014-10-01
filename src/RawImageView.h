//
//  RawImageView.h
//  SampleObjectiveC
//
//  Created by Joe Ward on 9/26/14.
//  Copyright (c) 2014 Leap Motion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LeapObjectiveC.h"

@interface RawImageView : NSImageView <LeapListener>
- (id) initWithFrame:(NSRect)frame controller:(LeapController *)controller andImageID:(int)ID;
@end
