//
//  UndistortedImageView.m
//  SampleObjectiveC
//
//  Created by Joe Ward on 9/17/14.
//  Copyright (c) 2014 Leap Motion. All rights reserved.
//

#import "UndistortedImageView.h"
#import "LeapObjectiveC.h"
#import "OpenGLUtil.h"
#import <OpenGL/gl3.h>

@implementation UndistortedImageView {
    GLint swapInterval;
    GLuint program;
    GLuint vao;
    GLuint raw;
    GLuint distortion;
    GLint rawImageLocation;
    GLint distortionImageLocation;

    bool deviceChanged;
    bool wasFlipped;

    int _ID;
    LeapController *_controller;
    NSTimer *renderTimer;
}

- (id)initWithFrame:(NSRect)frame pixelFormat:(NSOpenGLPixelFormat *)format andController:(LeapController *)controller andImageID:(int)ID
{
    self = [self initWithFrame:frame pixelFormat:format];
    if(self)
    {
        swapInterval = 1;
        deviceChanged = true;
        wasFlipped = true;
        [[self superview]setAutoresizingMask:NSViewWidthSizable];
        _ID = ID;
        _controller = controller;
        [_controller addListener:self]; //for onConnect and onDeviceChange events

        //Use an NSTimer for gfx rather than the onFrame to avoid overdriving the graphics
        renderTimer = [NSTimer timerWithTimeInterval:0.001   //a 1ms time interval
                                target:self
                                selector:@selector(timerFired:)
                                userInfo:nil
                                repeats:YES];
 
        [[NSRunLoop currentRunLoop] addTimer:renderTimer
                                    forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:renderTimer
                                    forMode:NSEventTrackingRunLoopMode]; //Ensure timer fires during resize
    }
    return self;
}

- (void)timerFired:(id)sender
{
    [self setNeedsDisplay:YES];
}

- (void)onConnect:(NSNotification *)notification
{
    NSLog(@"Device connected.");
    LeapController *controller = (LeapController *)[notification object];
    [controller setPolicyFlags:LEAP_POLICY_IMAGES];
}

- (void)onDeviceChange:(NSNotification *)notification
{
    NSLog(@"Device change.");
    deviceChanged = true;
}

- (void) prepareOpenGL
{
  NSLog(@"Open GL version: %s", glGetString(GL_VERSION));

  [super prepareOpenGL];
  [[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];

  program  = [OpenGLUtil createProgramForContext:[self openGLContext]
                                vertexShader:[[NSBundle mainBundle]pathForResource:@"vertexImage" ofType:@"vsh"]
                              fragmentShader:[[NSBundle mainBundle] pathForResource:@"fragmentImage" ofType:@"fsh"]];

  raw         = [OpenGLUtil bindTextureUnitForContext:[self openGLContext] inSlot:0];
  distortion = [OpenGLUtil bindTextureUnitForContext:[self openGLContext] inSlot:1];

  distortionImageLocation = glGetUniformLocation(program, "distortion");
  glProgramUniform1i(program, distortionImageLocation, GL_TEXTURE1);

  [self createScene];

}


- (void) createScene
{
    [[self openGLContext] makeCurrentContext];
    [OpenGLUtil checkGLError:@"make context current"];


    const int attributeCount = 5;
    const GLfloat vertices[] = {
        -1.0f, -1.0f, 0.0f, 0.0f, 0.0f,
         1.0f, -1.0f, 0.0f, 1.0f, 0.0f,
         1.0f,  1.0f, 0.0f, 1.0f, 1.0f,
        -1.0f,  1.0f, 0.0f, 0.0f, 1.0f
    };

    const GLubyte triangles[] = {
        0, 1, 2,
        2, 3, 0
    };

    glGenVertexArrays (1, &vao);
    glBindVertexArray (vao);

    GLuint vbo;
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glEnableVertexAttribArray (0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, attributeCount * sizeof(GLfloat), 0);

    GLuint texAttrib = glGetAttribLocation(program, "inTexCoord");
    glEnableVertexAttribArray(texAttrib);
    glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, attributeCount * sizeof(GLfloat), (const GLvoid *) (3 * sizeof(GLfloat)));

    GLuint elementBuffer;
    glGenBuffers(1, &elementBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(triangles), triangles, GL_STATIC_DRAW);

    [OpenGLUtil checkGLError:@"Error creating scene"];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    for(LeapDevice *device in _controller.devices)
    {
        if (device.isStreaming && wasFlipped != device.isFlipped) {
            deviceChanged = true;
        }
    }
    LeapFrame *frame = [_controller frame:0];
    if (frame.images.count > 0) {
        [self renderImage:[frame.images objectAtIndex:_ID]];
    }

}

- (void) renderImage:(LeapImage *)image
{
    [[self openGLContext] makeCurrentContext];

    //Upload distortion map to GPU texture if device has changed
    if (deviceChanged) {
        glBindTexture(GL_TEXTURE_2D, distortion);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RG32F, 64, 64, 0, GL_RG, GL_FLOAT, image.distortion);
        [OpenGLUtil checkGLError:@"Error loading distortion map"];
    }

    //Upload image data to GPU texture
    glBindTexture(GL_TEXTURE_2D, raw);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, image.width, image.height, 0, GL_RED, GL_UNSIGNED_BYTE, image.data);
    [OpenGLUtil checkGLError:@"Error loading raw image data"];

    glBindVertexArray(vao);
    glUseProgram(program);

    glUniform1i(rawImageLocation, 0);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, raw);

    glUniform1i(distortionImageLocation, 1);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, distortion);

    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, (void*)0);
    [OpenGLUtil checkGLError:@"Error trying to draw triangles"];

    [[self openGLContext] flushBuffer];

}

- (void)reshape
{
    [[self openGLContext] makeCurrentContext];
    float screenWidth = (float)[_window frame].size.width;
    float screenHeight = (float)[_window frame].size.height;
    glViewport(0,0,screenWidth/2,screenHeight);
    if (_ID == 0) {
        [super setFrame:NSMakeRect(0, 0, screenWidth/2, screenHeight)];
    } else{
        [super setFrame:NSMakeRect(screenWidth/2, 0, screenWidth/2, screenHeight)];
    }
}

- (void) dealloc
{
    [_controller removeListener:self];
}

@end
