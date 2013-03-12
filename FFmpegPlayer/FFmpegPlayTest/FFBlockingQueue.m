//
//  FFBlockingQueue.m
//  FFmpegPlayTest
//
//  Created by Jack on 11/13/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import "FFBlockingQueue.h"



@implementation FFBlockingQueue

- (id) initWithCapacity:(NSUInteger)numItems
{
    
}

- (int) size
{
    [self count];
}
- (int) capacity
{
    return arrayCapacity;
}
- (id) get
{
    return  [self firstObject];
}

- (void) put: (id) object{}
- (void) flush{}
@end
