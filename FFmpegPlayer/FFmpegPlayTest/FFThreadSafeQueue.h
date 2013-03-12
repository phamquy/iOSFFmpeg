//
//  FFThreadSafeQueue.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/12/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <queue>
using namespace std;

@interface FFThreadSafeQueue : NSObject
{
    queue<int> test;
    NSMutableArray* _container;
    NSCondition* _condition;
    
}

- (int) pushToQueue: (id) object;

@end
