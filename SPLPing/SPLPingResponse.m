//
//  SPLPingResponse.m
//  SPLPing
//
//  Created by Oliver Letterer.
//  Copyright 2015 Oliver Letterer. All rights reserved.
//

#import "SPLPingResponse.h"

@implementation SPLPingResponse

- (instancetype)initWithSequenceNumber:(NSInteger)sequenceNumber duration:(NSTimeInterval)duration identifier:(uint16_t)identifier ipAddress:(NSString *)ipAddress error:(nullable NSError *)error
{
    if (self = [super init]) {
        _sequenceNumber = sequenceNumber;
        _duration = duration;
        _error = error;
        _identifier = identifier;
        _ipAddress = ipAddress;
    }
    return self;
}

@end
