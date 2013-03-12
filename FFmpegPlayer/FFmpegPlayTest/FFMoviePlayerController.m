//
//  FFMediaPlayController.m
//  FFmpegPlayTest
//
//  Created by Jack on 11/2/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import "FFMoviePlayerController.h"
#import "FFVideoScreen.h"
#import "FFDecoder.h"
#import "FFAQHandler.h"

#pragma mark - Pritvate Extension

@interface FFMoviePlayerController ()
<FFVideoScreenDelegate>
{
    BOOL screenOn;
    BOOL speakerOn;
}
@property (nonatomic, strong) FFVideoScreen* videoScreen;
@property (nonatomic, strong) FFAQHandler* audioScreen;
@property (nonatomic, strong) FFDecoder* decoder;
@end


#pragma mark - General Interface implementation
@implementation FFMoviePlayerController
@synthesize audioScreen = _audioScreen;
@synthesize videoScreen = _videoScreen;
@synthesize decoder = _decoder;
@synthesize contentURL = _contentURL;
@synthesize backgroundView = _backgroundView;
@synthesize loadState = _loadState;
@synthesize controlStyle = _controlStyle;
@synthesize repeatMode = _repeatMode;

@synthesize
scalingMode=_scalingMode,
readyForDisplay=_readyForDisplay;

@synthesize view;
- (UIView*) view
{
    return _videoScreen;
}

//------------------------------------------------------------
@synthesize shouldAutoplay = _shouldAutoplay;
//- (void) setShouldAutoplay:(BOOL)shouldAutoplay
//{
//    _shouldAutoplay = shouldAutoplay;
//    if (_shouldAutoplay && [self isPreparedToPlay] ) {
//        [self play];
//    }
//}


//------------------------------------------------------------
- (BOOL) isFullscreen
{
    //TODO: Need implementation
    return YES;
};
//------------------------------------------------------------
- (void) setFullscreen:(BOOL)fullscreen animated:(BOOL)animated
{
    //TODO: Need implementation
}

#pragma mark Initialize and utilities
//------------------------------------------------------------
- (id) initWithContentURL:(NSURL *)url
{
    
    self = [super init];
    if (self) {
        _contentURL = url;
        _playbackState = MPMoviePlaybackStateStopped;
        _loadState = MPMovieLoadStateUnknown;
        _controlStyle = MPMovieControlStyleDefault;
        _repeatMode = MPMovieRepeatModeNone;
        _shouldAutoplay = YES;
        _fullscreen = NO;
        _scalingMode = MPMovieScalingModeAspectFit;
        _readyForDisplay = NO;
        
        
        [self initDecoder];
        if (!_decoder) return nil;

        [self initAQHandler];
        if (!_audioScreen)
        {
            _decoder = nil;
            return nil;
        }
               
        [self initVideoScreen];
        if (!_videoScreen)
        {
            _decoder = nil;
            _audioScreen = nil;
            return nil;
        }
        
        screenOn = YES;
        speakerOn = YES;
        
        _loadState = MPMovieLoadStatePlayable | MPMovieLoadStatePlaythroughOK;
        
        NSLog(@"Finished init playController");
    }

    return self;
}

//------------------------------------------------------------
- (void) initDecoder
{
    _decoder = [[FFDecoder alloc] initWithContentURL:_contentURL];
}
//------------------------------------------------------------
- (void) initAQHandler
{
    _audioScreen = [[FFAQHandler alloc] initWithSource:_decoder];
}
//------------------------------------------------------------
- (void) initVideoScreen
{
    _videoScreen = [[FFVideoScreen alloc] initWithSource: _decoder
                                                delegate: self
                                             scalingMode: _scalingMode];
    //[_videoScreen setFrame:CGRectMake(0, 0, 320, 250)];
    // TODO: init background view
}


//----------------------------------------------------------
#pragma mark FFVideoScreen Delegate
- (void) screenWillShow: (FFVideoScreen*) screen
{

}
//----------------------------------------------------------
- (void) screenDidShow:(FFVideoScreen*) screen
{
    // Play video if autoplay is enabled
    if (_shouldAutoplay) {
        if ([self isPreparedToPlay] &&
            (( _loadState & (MPMovieLoadStatePlayable | MPMovieLoadStatePlaythroughOK))!=0)){
            [self play];
        }
    }
}


#pragma mark MPMediaPlayback protocol implementation
@synthesize isPreparedToPlay;
@synthesize currentPlaybackRate;
@synthesize currentPlaybackTime;
//------------------------------------------------------------
- (void) prepareToPlay
{
    if (![self isPreparedToPlay]) {
        // TODO: Need implementation
        // Prepare to play
        // Interrupt any active non-mixible audio session
        // 1. prepare audioScreen
        // 2. Prepare videoScreen
    }
}
//------------------------------------------------------------
- (BOOL) isPreparedToPlay
{
    return ([_decoder isReady] && [_audioScreen isReady] && [_videoScreen isReady]);
//    return FALSE;
}
//------------------------------------------------------------
- (void) play
{
    if ((_playbackState == MPMoviePlaybackStatePaused) ||
        (_playbackState == MPMoviePlaybackStateStopped))
    {
        if (![self isPreparedToPlay]) {
            [self prepareToPlay];
            // TODO: Check result of preparation
        }
        
        [_decoder start];
        if (screenOn) {
            [_videoScreen start];
        }
        
        if (speakerOn) {
            [_audioScreen start];
        }
        
        _playbackState = MPMoviePlaybackStatePlaying;
    }
}
//------------------------------------------------------------
- (void) pause
{
    [_decoder pause];    
}

//------------------------------------------------------------
- (void) stop
{
    // TODO: check to stop the running instance only
    [_decoder stop];
    [_videoScreen stop];
    [_audioScreen stop];
    _playbackState = MPMoviePlaybackStateStopped;
    
}
//------------------------------------------------------------
- (NSTimeInterval) currentPlaybackTime
{
    //TODO: Need implementation
    return [_decoder currentPlaybackTime];
}
//------------------------------------------------------------
- (float) currentPlaybackRate
{
    return [_decoder currentPlaybackRate];
}
//------------------------------------------------------------
- (void) beginSeekingForward
{
    //TODO: Need implementation
}
//------------------------------------------------------------
- (void) beginSeekingBackward
{
    //TODO: Need implementation
}
//------------------------------------------------------------
- (void) endSeeking
{
    //TODO: Need implementation
}

@end

    //TODO: Need implementation
//MP_EXTERN NSString *const MPMediaPlaybackIsPreparedToPlayDidChangeNotification NS_AVAILABLE_IOS(3_2);


#pragma mark - FFMovie Properties Category implementaiton
@implementation FFMoviePlayerController (FFMovieProperties)

@dynamic
movieMediaTypes,
movieSourceType,
duration,
playableDuration,
naturalSize,
initialPlaybackTime,
endPlaybackTime;

- (MPMovieMediaTypeMask) movieMediaTypes
{
    return  [_decoder mediaTypes];
}

- (MPMovieSourceType) movieSourceType
{
    //TODO checking source type base on URL
    return [_decoder mediaSourceType];
}

- (void) setMovieSourceType:(MPMovieSourceType)movieSourceType
{
    return [_decoder setMediaSourceType:movieSourceType];
}

- (NSTimeInterval) duration
{
    return [_decoder duration];
}

- (NSTimeInterval) playableDuration
{
    return [_decoder playableDuration];
}


- (CGSize) naturalSize
{
    return [_decoder videoSize];
}


- (NSTimeInterval) initialPlaybackTime
{
    return [_decoder startTime];
}

- (NSTimeInterval) endPlaybackTime
{
    return [_decoder endTime];
}


#pragma mark - Thumbnail Generation Category

// Returns a thumbnail at the given time.
- (UIImage *)thumbnailImageAtTime:(NSTimeInterval)playbackTime
                       timeOption:(MPMovieTimeOption)option
{
    // TODO: need implementation
    return nil;
}

// Asynchronously request thumbnails for one or more times, provided as an array of NSNumbers (double).
// Posts MPMoviePlayerThumbnailImageRequestDidFinishNotification on completion.
- (void)requestThumbnailImagesAtTimes:(NSArray *)playbackTimes
                           timeOption:(MPMovieTimeOption)option
{
    // TODO: Need implementation
}

// Cancels all pending asynchronous thumbnail requests.
- (void)cancelAllThumbnailImageRequests
{
    //TODO: Need implementation
}
@end