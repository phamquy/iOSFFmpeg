//
//  FFMoviePlayerViewController.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/5/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FFMoviePlayerController;
@interface FFMoviePlayerViewController : NSObject {
@private
    id _internal;
}

- (id) initWithContentURL: (NSURL *) contentURL;

@property(nonatomic, readonly) FFMoviePlayerController* moviePlayer;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation; // Default is YES.
@end


// -----------------------------------------------------------------------------
// UIViewController Additions
// Additions to present a fullscreen movie player as a modal view controller using the standard movie player transition.

@interface UIViewController (FFMoviePlayerViewController)

- (void)presentFFMoviePlayerViewControllerAnimated:(FFMoviePlayerViewController *)moviePlayerViewController;
- (void)dismissFFMoviePlayerViewControllerAnimated;

@end