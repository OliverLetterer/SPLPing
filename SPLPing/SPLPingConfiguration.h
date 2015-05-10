//
//  SPLPingConfiguration.h
//  SPLPing
//
//  Created by Oliver Letterer.
//  Copyright 2015 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>



NS_ASSUME_NONNULL_BEGIN

/**
 Configuration for a SPLPing instance.
 */
@interface SPLPingConfiguration : NSObject

@property (nonatomic, readonly) NSTimeInterval pingInterval; // defaults to 1.0
@property (nonatomic, readonly) NSTimeInterval timeoutInterval; // defaults to 10.0
@property (nonatomic, readonly) NSInteger timeToLive; // defaults to 0. Currently unused.
@property (nonatomic, readonly) NSUInteger payloadSize; // defaults to 64 bytes

- (instancetype)init;
- (instancetype)initWithPingInterval:(NSTimeInterval)pingInterval;
- (instancetype)initWithPingInterval:(NSTimeInterval)pingInterval timeoutInterval:(NSTimeInterval)timeoutInterval;
- (instancetype)initWithPingInterval:(NSTimeInterval)pingInterval timeoutInterval:(NSTimeInterval)timeoutInterval timeToLive:(NSInteger)timeToLive;
- (instancetype)initWithPingInterval:(NSTimeInterval)pingInterval timeoutInterval:(NSTimeInterval)timeoutInterval timeToLive:(NSInteger)timeToLive payloadSize:(NSUInteger)payloadSize NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
