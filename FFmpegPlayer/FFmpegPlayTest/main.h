//
//  main.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/14/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#ifndef FFmpegPlayTest_main_h
#define FFmpegPlayTest_main_h


// Debug switcher

//#define DEBUG_PACKET
//#define DEBUG_PICTURE
//#define DEBUG_ABUFFER
//
//// Debug in decoder
//#define DEBUG_AUDIO
//#define DEBUG_VIDEO
//#define DEBUG_DEMUX
//
//#define DEBUG_AQHANDLE
//#define DEBUG_DECODER
//#define DEBUG_SCREEN


#pragma mark -
#pragma mark Macros

#ifdef DEBUG
#   define JLog(fmt, ...) NSLog((fmt), ##__VA_ARGS__);
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#   define DEnter() DLog(@"ENTER")
#   define DExit() DLog(@"EXIT")
#else
#   define JLog(...)
#   define DLog(...)
#   define DEnter()
#   define DExit()
#endif

#define CITrace	DLog()

// ALog always displays output regardless of the DEBUG setting
#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

#endif
