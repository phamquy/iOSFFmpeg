//
//  FFMediaPlayController.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/2/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>


#pragma mark - General Interface
@interface FFMoviePlayerController : NSObject <MPMediaPlayback>

- (id)initWithContentURL:(NSURL *)url;
@property(nonatomic, copy) NSURL *contentURL;

// The view in which the media and playback controls are displayed.
@property(nonatomic, readonly) UIView *view;

// A view for customization which is always displayed behind movie content.
@property(nonatomic, readonly) UIView *backgroundView;

// Returns the current playback state of the movie player.
@property(nonatomic, readonly) MPMoviePlaybackState playbackState;

// Returns the network load state of the movie player.
@property(nonatomic, readonly) MPMovieLoadState loadState;

// The style of the playback controls. Defaults to MPMovieControlStyleDefault.
@property(nonatomic) MPMovieControlStyle controlStyle;

// Determines how the movie player repeats when reaching the end of playback. Defaults to MPMovieRepeatModeNone.
@property(nonatomic) MPMovieRepeatMode repeatMode;

// Indicates if a movie should automatically start playback when it is likely to finish uninterrupted based on e.g. network conditions. Defaults to NO.
@property(nonatomic) BOOL shouldAutoplay;

// Determines if the movie is presented in the entire screen (obscuring all other application content). Default is NO.
// Setting this property to YES before the movie player's view is visible will have no effect.
@property(nonatomic, getter=isFullscreen) BOOL fullscreen;
- (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated;

// Determines how the content scales to fit the view. Defaults to MPMovieScalingModeAspectFit.
@property(nonatomic) MPMovieScalingMode scalingMode;

// Returns YES if the first video frame has been made ready for display for the current item.
// Will remain NO for items that do not have video tracks associated.
@property(nonatomic, readonly) BOOL readyForDisplay NS_AVAILABLE_IOS(6_0);

@end


#pragma mark - Movie Properties Category
// -----------------------------------------------------------------------------
// Movie properties of the current movie prepared for playback.

@interface FFMoviePlayerController (FFMovieProperties)

// The types of media in the movie, or MPMovieMediaTypeNone if not known.
@property(nonatomic, readonly) MPMovieMediaTypeMask movieMediaTypes;

// The playback type of the movie. Defaults to MPMovieSourceTypeUnknown.
// Specifying a playback type before playing the movie can result in faster load times.
@property(nonatomic) MPMovieSourceType movieSourceType;

// The duration of the movie, or 0.0 if not known.
@property(nonatomic, readonly) NSTimeInterval duration;

// The currently playable duration of the movie, for progressively downloaded network content.
@property(nonatomic, readonly) NSTimeInterval playableDuration;

// The natural size of the movie, or CGSizeZero if not known/applicable.
@property(nonatomic, readonly) CGSize naturalSize;

// The start time of movie playback. Defaults to NaN, indicating the natural start time of the movie.
@property(nonatomic) NSTimeInterval initialPlaybackTime;

// The end time of movie playback. Defaults to NaN, which indicates natural end time of the movie.
@property(nonatomic) NSTimeInterval endPlaybackTime;

// Indicates whether the movie player allows AirPlay video playback. Defaults to YES on iOS 5.0 and later.
///  @property(nonatomic) BOOL allowsAirPlay NS_AVAILABLE_IOS(4_3);

// Indicates whether the movie player is currently playing video via AirPlay.
/// @property(nonatomic, readonly, getter=isAirPlayVideoActive) BOOL airPlayVideoActive NS_AVAILABLE_IOS(5_0);

@end




/**
 // -----------------------------------------------------------------------------
 // Movie Player Notifications
 
 // Posted when the scaling mode changes.
 MP_EXTERN NSString *const MPMoviePlayerScalingModeDidChangeNotification;
 
 // Posted when movie playback ends or a user exits playback.
 MP_EXTERN NSString *const MPMoviePlayerPlaybackDidFinishNotification;
 
 MP_EXTERN NSString *const MPMoviePlayerPlaybackDidFinishReasonUserInfoKey NS_AVAILABLE_IOS(3_2); // NSNumber (MPMovieFinishReason)
 
 // Posted when the playback state changes, either programatically or by the user.
 MP_EXTERN NSString *const MPMoviePlayerPlaybackStateDidChangeNotification NS_AVAILABLE_IOS(3_2);
 
 // Posted when the network load state changes.
 MP_EXTERN NSString *const MPMoviePlayerLoadStateDidChangeNotification NS_AVAILABLE_IOS(3_2);
 
 // Posted when the currently playing movie changes.
 MP_EXTERN NSString *const MPMoviePlayerNowPlayingMovieDidChangeNotification NS_AVAILABLE_IOS(3_2);
 
 // Posted when the movie player enters or exits fullscreen mode.
 MP_EXTERN NSString *const MPMoviePlayerWillEnterFullscreenNotification NS_AVAILABLE_IOS(3_2);
 MP_EXTERN NSString *const MPMoviePlayerDidEnterFullscreenNotification NS_AVAILABLE_IOS(3_2);
 MP_EXTERN NSString *const MPMoviePlayerWillExitFullscreenNotification NS_AVAILABLE_IOS(3_2);
 MP_EXTERN NSString *const MPMoviePlayerDidExitFullscreenNotification NS_AVAILABLE_IOS(3_2);
 MP_EXTERN NSString *const MPMoviePlayerFullscreenAnimationDurationUserInfoKey NS_AVAILABLE_IOS(3_2); // NSNumber of double (NSTimeInterval)
 MP_EXTERN NSString *const MPMoviePlayerFullscreenAnimationCurveUserInfoKey NS_AVAILABLE_IOS(3_2);     // NSNumber of NSUInteger (UIViewAnimationCurve)
 
 // Posted when the movie player begins or ends playing video via AirPlay.
 MP_EXTERN NSString *const MPMoviePlayerIsAirPlayVideoActiveDidChangeNotification NS_AVAILABLE_IOS(5_0);
 
 // Posted when the ready for display state changes.
 MP_EXTERN NSString *const MPMoviePlayerReadyForDisplayDidChangeNotification NS_AVAILABLE_IOS(6_0);
 
 // -----------------------------------------------------------------------------
 // Movie Property Notifications
 
 // Calling -prepareToPlay on the movie player will begin determining movie properties asynchronously.
 // These notifications are posted when the associated movie property becomes available.
 MP_EXTERN NSString *const MPMovieMediaTypesAvailableNotification NS_AVAILABLE_IOS(3_2);
 MP_EXTERN NSString *const MPMovieSourceTypeAvailableNotification NS_AVAILABLE_IOS(3_2); // Posted if the movieSourceType is MPMovieSourceTypeUnknown when preparing for playback.
 MP_EXTERN NSString *const MPMovieDurationAvailableNotification NS_AVAILABLE_IOS(3_2);
 MP_EXTERN NSString *const MPMovieNaturalSizeAvailableNotification NS_AVAILABLE_IOS(3_2);
 
 */

#pragma mark - Thumbnail Generation Category
// -----------------------------------------------------------------------------
// Thumbnails
@interface FFMoviePlayerController (FFMoviePlayerThumbnailGeneration)

// Returns a thumbnail at the given time.
- (UIImage *)thumbnailImageAtTime:(NSTimeInterval)playbackTime timeOption:(MPMovieTimeOption)option;

// Asynchronously request thumbnails for one or more times, provided as an array of NSNumbers (double).
// Posts MPMoviePlayerThumbnailImageRequestDidFinishNotification on completion.
- (void)requestThumbnailImagesAtTimes:(NSArray *)playbackTimes timeOption:(MPMovieTimeOption)option;

// Cancels all pending asynchronous thumbnail requests.
- (void)cancelAllThumbnailImageRequests;

@end


/**
 // Posted when new timed metadata arrives.
 MP_EXTERN NSString *const MPMoviePlayerTimedMetadataUpdatedNotification NS_AVAILABLE_IOS(4_0);
 MP_EXTERN NSString *const MPMoviePlayerTimedMetadataUserInfoKey NS_AVAILABLE_IOS(4_0);       // NSArray of the most recent MPTimedMetadata objects.
 
 // Additional dictionary keys for use with the 'allMetadata' property. All keys are optional.
 MP_EXTERN NSString *const MPMoviePlayerTimedMetadataKeyName NS_AVAILABLE_IOS(4_0);           // NSString
 MP_EXTERN NSString *const MPMoviePlayerTimedMetadataKeyInfo NS_AVAILABLE_IOS(4_0);           // NSString
 MP_EXTERN NSString *const MPMoviePlayerTimedMetadataKeyMIMEType NS_AVAILABLE_IOS(4_0);       // NSString
 MP_EXTERN NSString *const MPMoviePlayerTimedMetadataKeyDataType NS_AVAILABLE_IOS(4_0);       // NSString
 MP_EXTERN NSString *const MPMoviePlayerTimedMetadataKeyLanguageCode NS_AVAILABLE_IOS(4_0);   // NSString (ISO 639-2)
 
 // -----------------------------------------------------------------------------
 
 @interface FFMoviePlayerController (FFMovieLogging)
 
 // Returns an object that represents a snapshot of the network access log. Can be nil.
 @property (nonatomic, readonly) MPMovieAccessLog *accessLog NS_AVAILABLE_IOS(4_3);
 
 // Returns an object that represents a snapshot of the error log. Can be nil.
 @property (nonatomic, readonly) MPMovieErrorLog *errorLog NS_AVAILABLE_IOS(4_3);
 
 @end
 */