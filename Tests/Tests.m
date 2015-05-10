//
//  SPLPingTests.m
//  SPLPingTests
//
//  Created by Oliver Letterer on 05/10/2015.
//  Copyright (c) 2015 Oliver Letterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <SPLPing/SPLPing.h>

@interface PingTests : XCTestCase

@property (nonatomic, strong) SPLPing *ping;

@end

@implementation PingTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];

    [self.ping stop];
    self.ping = nil;
}

- (void)testExample
{
    XCTAssert(YES, @"Pass");
}

@end
