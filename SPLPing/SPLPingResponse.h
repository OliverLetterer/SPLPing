//
//  SPLPingResponse.h
//  SPLPing
//
//  Created by Oliver Letterer.
//  Copyright 2015 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>



NS_ASSUME_NONNULL_BEGIN

/**
 A response to a single ping.
 */
@interface SPLPingResponse : NSObject

@property (nonatomic, readonly) uint16_t identifier;
@property (nonatomic, nullable, readonly) NSString *ipAddress;

@property (nonatomic, readonly) NSInteger sequenceNumber;
@property (nonatomic, readonly) NSTimeInterval duration;

@property (nonatomic, nullable, readonly) NSError *error;

- (instancetype)initWithSequenceNumber:(NSInteger)sequenceNumber duration:(NSTimeInterval)duration identifier:(uint16_t)identifier ipAddress:(nullable NSString *)ipAddress error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
