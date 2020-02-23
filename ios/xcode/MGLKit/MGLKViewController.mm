//
// Copyright 2019 Le Hoang Quyen. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//

#import "MGLKViewController+Private.h"

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <EGL/eglext_angle.h>
#include <EGL/eglplatform.h>
#include <common/apple_platform_utils.h>
#include <common/debug.h>

#import "MGLDisplay.h"
#import "MGLKView+Private.h"

@implementation MGLKViewController

#if TARGET_OS_OSX
#    include "MGLKViewController+Mac.mm"
#else
#    include "MGLKViewController+iOS.mm"
#endif

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        [self constructor];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder])
    {
        [self constructor];
    }
    return self;
}

- (void)constructor
{
    _appWasInBackground       = YES;
    _preferredFramesPerSecond = 30;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillPause:)
                                                 name:MGLKApplicationWillResignActiveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:MGLKApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MGLKApplicationWillResignActiveNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MGLKApplicationDidBecomeActiveNotification
                                                  object:nil];
    [self deallocImpl];
}

- (void)setView:(MGLKNativeView *)view
{
    [super setView:view];
    if ([view isKindOfClass:MGLKView.class])
    {
        _glView = (MGLKView *)view;
        if (!_glView.delegate)
        {
            // If view has no delegate, set this controller as its delegate
            _glView.delegate = self;
        }
        // Store this object inside the view itself so that the view can notify
        // this controller about certain events such as moving to new window.
        _glView.controller = self;
    }
    else
    {
        if (_glView.delegate == self)
        {
            // Detach from old view
            _glView.delegate = nil;
        }
        if (_glView.controller == self)
        {
            _glView.controller = nil;
        }
        _glView = nil;
    }
}

- (void)mglkView:(MGLKView *)view drawInRect:(CGRect)rect
{
    // Default implementation do nothing.
}

- (void)appWillPause:(NSNotification *)note
{
    NSLog(@"MGLKViewController appWillPause:");
    _appWasInBackground = YES;
    [self pause];
}

- (void)appDidBecomeActive:(NSNotification *)note
{
    NSLog(@"MGLKViewController appDidBecomeActive:");
    [self resume];
}

- (void)handleAppWasInBackground
{
    if (!_appWasInBackground)
    {
        return;
    }
    // To avoid time jump when the app goes to background
    // for a long period of time.
    _lastUpdateTime = CACurrentMediaTime();

    _appWasInBackground = NO;
}

- (void)frameStep
{
    [self handleAppWasInBackground];

    CFTimeInterval now   = CACurrentMediaTime();
    _timeSinceLastUpdate = now - _lastUpdateTime;

    [self update];
    [_glView display];

    if (_needDisableVsync)
    {
        eglSwapInterval([MGLDisplay defaultDisplay].eglDisplay, 0);
        _needDisableVsync = NO;
    }
    else if (_needEnableVsync)
    {
        eglSwapInterval([MGLDisplay defaultDisplay].eglDisplay, 1);
        _needEnableVsync = NO;
    }

    _framesDisplayed++;
    _lastUpdateTime = now;

#if 0
    if (_timeSinceLastUpdate > 2 * _displayLink.duration)
    {
        NSLog(@"frame was jump by %fs", _timeSinceLastUpdate);
    }
#endif
}

- (void)update
{
    if (_delegate)
    {
        [_delegate mglkViewControllerUpdate:self];
    }
}

@end