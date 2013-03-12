/*
 *  mach_util.h/.c - Helper functions for using Mach time on the Mac and iPhone platforms
 *  Written by jamesghurley<at>gmail.com
 */

#include "mach_util.h"

static Float64	sFrequency;

static UInt32	sMinDelta;
static UInt32	sToNanosNumerator;
static UInt32	sToNanosDenominator;
static UInt32	sFromNanosNumerator;
static UInt32	sFromNanosDenominator;

static int		sIsInited = 0;

void mu_init(){
	struct mach_timebase_info	theTimeBaseInfo;
	
	mach_timebase_info(&theTimeBaseInfo);
	sMinDelta = 1;
	sToNanosNumerator = theTimeBaseInfo.numer;
	sToNanosDenominator = theTimeBaseInfo.denom;
	sFromNanosNumerator = sToNanosDenominator;
	sFromNanosDenominator = sToNanosNumerator;
	
	//	the frequency of that clock is: (sToNanosDenominator / sToNanosNumerator) * 10^9
	sFrequency = (Float64)sToNanosDenominator / (Float64)sToNanosNumerator;
	sFrequency *= 1000000000.0;
	sIsInited = 1;
	
}

inline UInt64 mu_convertToNanos(UInt64 inHostTime)
{
	if(!sIsInited)
	{
		mu_init();
	}
	
	Float64 thePartialAnswer = (Float64)inHostTime / (Float64)sToNanosDenominator;
	Float64 theFloatAnswer   = (thePartialAnswer * (Float64)sToNanosNumerator);
	
	
	return (UInt64)theFloatAnswer;
}
inline UInt64 mu_convertFromNanos(UInt64 inNanos)
{
	if(!sIsInited)
	{
		mu_init();
	}
	
	Float64 theNumerator = (Float64)sToNanosNumerator;
	Float64 theDenominator = (Float64)sToNanosDenominator;
	Float64 theNanos = (Float64)inNanos;
	
	Float64 thePartialAnswer = theNanos / theNumerator;
	Float64 theFloatAnswer = thePartialAnswer * theDenominator;
	UInt64 theAnswer = (UInt64)theFloatAnswer;
	
	
	return theAnswer;
}
inline UInt64 mu_convertToMicros(UInt64 inHostTime)
{
	if(!sIsInited)
	{
		mu_init();
	}
	
	Float64 thePartialAnswer = (Float64)inHostTime / (Float64)sToNanosDenominator;
	Float64 theFloatAnswer   = (thePartialAnswer * (Float64)sToNanosNumerator) / 1000.f;
	
	
	return (UInt64)theFloatAnswer;
}
inline UInt64 mu_currentTimeInNanos(){
	return mu_convertToNanos(mach_absolute_time());
}
inline UInt64 mu_currentTimeInMicros() {
	return mu_convertToMicros(mach_absolute_time());
}