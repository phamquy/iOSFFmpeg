//
//  FFVideoPicture.h
//  FFmpegPlayTest
//
//  Created by Jack on 12/4/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFmpeg.h"
typedef enum PixelFormat FFPixelFormat;

@interface FFVideoPicture : NSObject
@property (nonatomic, strong) NSMutableData* data;
@property (nonatomic) NSInteger width;
@property (nonatomic) NSInteger height;
@property (nonatomic) NSTimeInterval pts;

- (id) initWithPixelFormat: (FFPixelFormat) format
                     width: (int) width
                    height: (int) height;

- (AVPicture* const) avPicture;
- (const void * const) pdata;
@end


@interface FFVideoPicture (YUVPicture)
- (const void * const) yData;
- (const void * const) uData;
- (const void * const) vData;
@end
