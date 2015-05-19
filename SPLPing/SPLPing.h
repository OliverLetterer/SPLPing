//
//  SPLPing.h
//  SPLPing
//
//  Created by CocoaPods on 05/10/2015.
//  Copyright (c) 2015 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <SPLPing/SPLPingConfiguration.h>
#import <SPLPing/SPLPingResponse.h>

FOUNDATION_EXPORT double SPLPingVersionNumber;
FOUNDATION_EXPORT const unsigned char SPLPingVersionString[];



NS_ASSUME_NONNULL_BEGIN

/**
 Pinger for a specific host.
 */
@interface SPLPing : NSObject

@property (nonatomic, readonly) NSString *host;
@property (nonatomic, readonly) NSString *ip;

@property (nonatomic, readonly) SPLPingConfiguration *configuration;

@property (nonatomic, nullable, copy) void(^observer)(SPLPing *ping, SPLPingResponse *response);

@property (nonatomic, readonly) uint16_t identifier;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithIPv4Address:(NSString *)ipv4Address configuration:(SPLPingConfiguration *)configuration;
- (instancetype)initWithHost:(NSString *)host ipv4Address:(NSData *)ipv4Address configuration:(SPLPingConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

+ (void)pingToHost:(NSString *)host configuration:(SPLPingConfiguration *)configuration completion:(void(^)(SPLPing *__nullable ping, NSError *__nullable error))completion;
+ (void)pingOnce:(NSString *)host configuration:(SPLPingConfiguration *)configuration completion:(void(^)(SPLPingResponse *response))completion;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
