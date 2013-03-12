/*
 *  mach_util.h/.c - Helper functions for using Mach time on the Mac and iPhone platforms
 *  Written by jamesghurley<at>gmail.com
 */

#ifndef __MACH_UTIL_H
#define __MACH_UTIL_H

#if !defined(__COREAUDIO_USE_FLAT_INCLUDES__)
#include <CoreAudio/CoreAudioTypes.h>
#else
#include <CoreAudioTypes.h>
#endif

#include <mach/mach_time.h>
#include <mach/mach.h>


void mu_init();

UInt64 mu_convertToNanos(UInt64 inHostTime);
UInt64 mu_convertFromNanos(UInt64 inNanos);
UInt64 mu_currentTimeInNanos();
UInt64 mu_currentTimeInMicros();
UInt64 mu_convertToMicros(UInt64 inHostTime);

#endif
