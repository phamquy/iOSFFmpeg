//
//  FFVideoPicture.m
//  FFmpegPlayTest
//
//  Created by Jack on 12/4/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import "FFVideoPicture.h"

#pragma mark - FFVideoPicture

//#########################################################################
@interface FFVideoPicture()
{
    AVPicture _avPicture;
    uint8_t*  _pData;
}
@end


@implementation FFVideoPicture
@synthesize data=_data,
width=_width,
height=_height,
pts=_pts;

- (id) initWithPixelFormat: (FFPixelFormat) format
                     width: (int) width
                    height: (int) height
{
    self = [super init];
    if (self) {
        _width=width;
        _height=height;
        int dataSize = avpicture_get_size(format, _width, _height);
        _pData = av_malloc(dataSize);
        _data = [NSMutableData dataWithBytesNoCopy:(void*)_pData
                                            length:dataSize
                                      freeWhenDone:NO];
        
        //JLogPic(@"Picture data length: %d", [_data length]);
        avpicture_fill(&_avPicture, _pData, format,_width,_height);
    }
    return self;
}

- (const void * const) pdata
{
    return _pData;
}

- (AVPicture* const) avPicture
{
    return &_avPicture;
}

- (void)dealloc
{
    av_free(_pData);
    _pData = 0;
}
@end

@implementation FFVideoPicture (YUVPicture)


- (const void * const) yData
{
    return _avPicture.data[0];
}

- (const void * const) uData
{
    return _avPicture.data[1];
}

- (const void * const) vData
{
    return _avPicture.data[2];
}

@end