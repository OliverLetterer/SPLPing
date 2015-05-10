//
//  SPLPingConfiguration.m
//  SPLPing
//
//  Created by Oliver Letterer.
//  Copyright 2015 Oliver Letterer. All rights reserved.
//

#import "SPLPingConfiguration.h"



@implementation SPLPingConfiguration

- (instancetype)init
{
    return [self initWithPingInterval:1.0];
}

- (instancetype)initWithPingInterval:(NSTimeInterval)pingInterval
{
    return [self initWithPingInterval:pingInterval timeoutInterval:10.0];
}

- (instancetype)initWithPingInterval:(NSTimeInterval)pingInterval timeoutInterval:(NSTimeInterval)timeoutInterval
{
    return [self initWithPingInterval:pingInterval timeoutInterval:timeoutInterval timeToLive:0];
}

- (instancetype)initWithPingInterval:(NSTimeInterval)pingInterval timeoutInterval:(NSTimeInterval)timeoutInterval timeToLive:(NSInteger)timeToLive
{
    return [self initWithPingInterval:pingInterval timeoutInterval:timeoutInterval timeToLive:timeToLive payloadSize:64];
}

- (instancetype)initWithPingInterval:(NSTimeInterval)pingInterval timeoutInterval:(NSTimeInterval)timeoutInterval timeToLive:(NSInteger)timeToLive payloadSize:(NSUInteger)payloadSize
{
    if (self = [super init]) {
        _pingInterval = pingInterval;
        _timeoutInterval = timeoutInterval;
        _timeToLive = timeToLive;
        _payloadSize = payloadSize;
    }
    return self;
}

@end
