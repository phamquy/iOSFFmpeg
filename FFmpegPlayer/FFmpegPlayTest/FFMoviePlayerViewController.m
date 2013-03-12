//
//  FFMoviePlayerViewController.m
//  FFmpegPlayTest
//
//  Created by Jack on 11/5/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import "FFMoviePlayerViewController.h"

@implementation FFMoviePlayerViewController

@synthesize moviePlayer=_moviePlayer;

- (id) initWithContentURL:(NSURL *)contentURL
{
    self = [super init];
    if (self) {
        // TODO: implementation
    }
    return self;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    // TODO: Implementaiton
    return YES;
}

@end

@implementation UIViewController (FFMoviePlayerViewController)

- (void) presentFFMoviePlayerViewControllerAnimated:(FFMoviePlayerViewController *)moviePlayerViewController
{
    
}

- (void) dismissFFMoviePlayerViewControllerAnimated
{
    
}

@end