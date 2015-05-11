//
//  SPLPingTests.m
//  SPLPingTests
//
//  Created by Oliver Letterer on 05/10/2015.
//  Copyright (c) 2015 Oliver Letterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <Expecta/Expecta.h>
#import <SPLPing/SPLPing.h>

@interface PingTests : XCTestCase

@property (nonatomic, strong) SPLPing *ping;

@end

@implementation PingTests

- (void)tearDown
{
    [super tearDown];

    [self.ping stop];
    self.ping = nil;
}

- (void)testPingToLocalhost
{
    SPLPingConfiguration *config = [[SPLPingConfiguration alloc] initWithPingInterval:1.0];
    self.ping = [[SPLPing alloc] initWithIPv4Address:@"127.0.0.1" configuration:config];

    __block SPLPingResponse *response = nil;
    [self.ping setObserver:^(SPLPing * __nonnull ping, SPLPingResponse * __nonnull _response) {
        response = _response;
    }];
    [self.ping start];

    expect(response).willNot.beNil();
    expect(response.error).to.beNil();
    expect(response.duration).to.beGreaterThan(0.0);
}

- (void)testPingToLocalhostOnce
{
    SPLPingConfiguration *config = [[SPLPingConfiguration alloc] initWithPingInterval:1.0];

    __block SPLPingResponse *response = nil;
    [SPLPing pingOnce:@"127.0.0.1" configuration:config completion:^(SPLPingResponse *_response) {
        response = _response;
    }];

    expect(response).willNot.beNil();
    expect(response.error).to.beNil();
    expect(response.duration).to.beGreaterThan(0.0);
}

- (void)testPingToGoogle
{
    SPLPingConfiguration *config = [[SPLPingConfiguration alloc] initWithPingInterval:1.0];

    __block SPLPingResponse *response = nil;
    [SPLPing pingToHost:@"google.com" configuration:config completion:^(SPLPing * __nullable ping, NSError * __nullable error) {
        self.ping = ping;

        [self.ping setObserver:^(SPLPing * __nonnull ping, SPLPingResponse * __nonnull _response) {
            response = _response;
        }];
        [self.ping start];
    }];

    expect(response).willNot.beNil();
    expect(response.error).to.beNil();
    expect(response.duration).to.beGreaterThan(0.0);
}

@end
