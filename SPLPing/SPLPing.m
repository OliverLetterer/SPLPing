//
//  SPLPing.m
//  SPLPing
//
//  Created by Oliver Letterer on 10.05.15.
//  Copyright (c) 2015 Oliver Letterer. All rights reserved.
//

#import "SPLPing.h"
#import "ICMPHeader.h"

#import <CFNetwork/CFNetwork.h>
#import <netinet/in.h>
#import <arpa/inet.h>

static NSData *getIPv4AddressFromHost(NSString *host, NSError **error)
{
    CFStreamError streamError;
    CFHostRef hostRef = CFHostCreateWithName(NULL, (__bridge CFStringRef)host);
    BOOL success = CFHostStartInfoResolution(hostRef, kCFHostAddresses, &streamError);

    if (!success) {
        if (streamError.domain == kCFStreamErrorDomainNetDB) {
            *error = [NSError errorWithDomain:(NSString *)kCFErrorDomainCFNetwork code:kCFHostErrorUnknown userInfo:@{ (id)kCFGetAddrInfoFailureKey: @(streamError.error) }];
        } else {
            *error = [NSError errorWithDomain:(NSString *)kCFErrorDomainCFNetwork code:kCFHostErrorUnknown userInfo:nil];
        }

        CFRelease(hostRef);
        return nil;
    }

    Boolean resolved = false;
    NSArray *addresses = (__bridge NSArray *)CFHostGetAddressing(hostRef, &resolved);

    for (NSData *address in addresses) {
        const struct sockaddr *socketAddress = (const struct sockaddr *)address.bytes;

        if (address.length >= sizeof(struct sockaddr) && socketAddress->sa_family == AF_INET) {
            CFRelease(hostRef);
            return address;
        }
    }

    *error = [NSError errorWithDomain:(NSString *)kCFErrorDomainCFNetwork code:kCFHostErrorHostNotFound userInfo:nil];
    CFRelease(hostRef);

    return nil;
}



@interface SPLPing ()

@property (nonatomic, assign) BOOL hasScheduledNextPing;

@property (nonatomic, readonly) NSData *ipv4Address;

@property (nonatomic, assign) CFSocketRef socket;
@property (nonatomic, assign) CFRunLoopSourceRef socketSource;

@property (nonatomic, assign) BOOL isPinging;
@property (nonatomic, assign) uint16_t currentSequenceNumber;
@property (nonatomic, strong) NSDate *currentStartDate;

@property (nonatomic, copy) dispatch_block_t timeoutBlock;

- (void)socket:(CFSocketRef)socket didReadData:(NSData *)data;

@end



static void socketCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    SPLPing *ping = (__bridge SPLPing *)info;

    if (type == kCFSocketDataCallBack) {
        [ping socket:s didReadData:(__bridge NSData *)data];
    }
}

@implementation SPLPing

#pragma mark - Initialization

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

+ (void)pingToHost:(NSString *)host configuration:(SPLPingConfiguration *)configuration completion:(void(^)(SPLPing *ping, NSError *error))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSData *ipv4Address = getIPv4AddressFromHost(host, &error);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                completion(nil, error);
            } else {
                completion([[SPLPing alloc] initWithHost:host ipv4Address:ipv4Address configuration:configuration], nil);
            }
        });
    });
}

+ (void)pingOnce:(NSString *)host configuration:(SPLPingConfiguration *)configuration completion:(void(^)(SPLPingResponse *response))completion
{
    NSDate *startDate = [NSDate date];

    [SPLPing pingToHost:host configuration:configuration completion:^(SPLPing * __nullable ping, NSError * __nullable error) {
        if (error) {
            SPLPingResponse *response = [[SPLPingResponse alloc] initWithSequenceNumber:1 duration:[[NSDate date] timeIntervalSinceDate:startDate] identifier:0 ipAddress:nil error:error];
            return completion(response);
        }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"

        [ping setObserver:^(SPLPing * __nonnull _ping, SPLPingResponse * __nonnull response) {
            [ping stop];
            [ping setObserver:nil];
            completion(response);
        }];

#pragma clang diagnostic pop

        [ping start];
    }];
}

- (instancetype)initWithHost:(NSString *)host ipv4Address:(NSData *)ipv4Address configuration:(SPLPingConfiguration *)configuration
{
    if (self = [super init]) {
        _host = host;
        _ipv4Address = ipv4Address;
        _configuration = configuration;
        _identifier = arc4random();

        const struct sockaddr_in *socketAddress = _ipv4Address.bytes;
        _ip = [NSString stringWithCString:inet_ntoa(socketAddress->sin_addr) encoding:NSASCIIStringEncoding];

        CFSocketContext context = {
            .info = (__bridge void *)self,
        };

        _socket = CFSocketCreate(NULL, AF_INET, SOCK_DGRAM, IPPROTO_ICMP, kCFSocketDataCallBack, socketCallback, &context);
        _socketSource = CFSocketCreateRunLoopSource(NULL, _socket, 0);
        CFRunLoopAddSource(CFRunLoopGetMain(), _socketSource, kCFRunLoopCommonModes);
    }
    return self;
}

- (instancetype)initWithIPv4Address:(NSString *)ipv4Address configuration:(SPLPingConfiguration *)configuration
{
    struct sockaddr_in socketAddress;
    memset(&socketAddress, 0, sizeof(socketAddress));

    socketAddress.sin_len = sizeof(socketAddress);
    socketAddress.sin_family = AF_INET;
    socketAddress.sin_port = 0;
    socketAddress.sin_addr.s_addr = inet_addr(ipv4Address.UTF8String);

    NSData *data = [NSData dataWithBytes:&socketAddress length:sizeof(socketAddress)];
    return [self initWithHost:ipv4Address ipv4Address:data configuration:configuration];
}

- (void)dealloc
{
    [self stop];

    CFRunLoopSourceInvalidate(_socketSource), CFRelease(_socketSource), _socketSource = nil;
    CFRelease(_socket), _socket = nil;
}

#pragma mark - Instance methods

- (void)start
{
    if (self.isPinging) {
        return;
    }

    self.isPinging = YES;
    self.currentSequenceNumber = 0;
    self.currentStartDate = nil;
    [self _sendPing];
}

- (void)stop
{
    self.isPinging = NO;
    self.currentSequenceNumber = 0;
    self.currentStartDate = nil;

    if (self.timeoutBlock) {
        dispatch_block_cancel(self.timeoutBlock);
        self.timeoutBlock = nil;
    }
}

#pragma mark - socket callback

- (void)socket:(CFSocketRef)socket didReadData:(NSData *)data
{
    NSParameterAssert([NSThread currentThread].isMainThread);
    NS_VALID_UNTIL_END_OF_SCOPE id strongSelf = self;

    __block NSData *ipHeaderData = nil, *ipData = nil, *icmpHeaderData = nil, *icmpData = nil;
    NSString *(^extractIPAddress)(void) = ^NSString *(void) {
        if (ipHeaderData == nil) {
            return nil;
        }

        const IPHeader *ipHeader = ipHeaderData.bytes;
        const uint8_t *sourceAddress = ipHeader->sourceAddress;
        return [NSString stringWithFormat:@"%d.%d.%d.%d", sourceAddress[0], sourceAddress[1], sourceAddress[2], sourceAddress[3]];
    };

    if (!ICMPExtractResponseFromData(data, &ipHeaderData, &ipData, &icmpHeaderData, &icmpData)) {
        if (ipHeaderData != nil && ![self.ip isEqualToString:extractIPAddress()]) {
            return;
        }

        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotDecodeRawData userInfo:@{}];
        SPLPingResponse *response = [[SPLPingResponse alloc] initWithSequenceNumber:self.currentSequenceNumber duration:[[NSDate date] timeIntervalSinceDate:self.currentStartDate] identifier:self.identifier ipAddress:nil error:error];

        if (self.observer) {
            self.observer(self, response);
        }

        return [self _scheduleNextPing];
    }

    NSString *ipString = extractIPAddress();
    if (![self.ip isEqualToString:ipString]) {
        return;
    }

    const ICMPHeader *icmpHeader = icmpHeaderData.bytes;

    uint16_t identifier = OSSwapHostToBigInt16(icmpHeader->identifier);
    uint16_t sequenceNumber = OSSwapHostToBigInt16(icmpHeader->sequenceNumber);

    if (self.observer) {
        self.observer(self, [[SPLPingResponse alloc] initWithSequenceNumber:sequenceNumber duration:[[NSDate date] timeIntervalSinceDate:self.currentStartDate] identifier:identifier ipAddress:ipString error:nil]);
    }

    return [self _scheduleNextPing];
}

#pragma mark - Private category implementation ()

- (void)_sendPing
{
    NSParameterAssert([NSThread currentThread].isMainThread);

    if (!self.isPinging) {
        return;
    }

    NSParameterAssert(self.timeoutBlock == nil);

    self.currentSequenceNumber++;
    self.currentStartDate = [NSDate date];

    NSData *icmpPackage = ICMPPackageCreate(self.identifier, self.currentSequenceNumber, self.configuration.payloadSize);
    CFSocketError socketError = CFSocketSendData(self.socket, (CFDataRef)self.ipv4Address, (CFDataRef)icmpPackage, self.configuration.timeoutInterval);

    if (socketError == kCFSocketError) {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotFindHost userInfo:@{}];
        SPLPingResponse *response = [[SPLPingResponse alloc] initWithSequenceNumber:self.currentSequenceNumber duration:[[NSDate date] timeIntervalSinceDate:self.currentStartDate] identifier:self.identifier ipAddress:nil error:error];

        if (self.observer) {
            self.observer(self, response);
        }

        return [self _scheduleNextPing];
    } else if (socketError == kCFSocketTimeout) {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:@{}];
        SPLPingResponse *response = [[SPLPingResponse alloc] initWithSequenceNumber:self.currentSequenceNumber duration:[[NSDate date] timeIntervalSinceDate:self.currentStartDate] identifier:self.identifier ipAddress:nil error:error];

        if (self.observer) {
            self.observer(self, response);
        }

        return [self _scheduleNextPing];
    }

    NSParameterAssert(socketError == kCFSocketSuccess);

    __weak typeof(self) weakSelf = self;
    uint16_t currentSequenceNumber = self.currentSequenceNumber;

    self.timeoutBlock = dispatch_block_create(DISPATCH_BLOCK_ASSIGN_CURRENT, ^{
        __strong typeof(self) self = weakSelf;
        if (currentSequenceNumber != self.currentSequenceNumber) {
            return;
        }

        self.timeoutBlock = nil;
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:@{}];
        SPLPingResponse *response = [[SPLPingResponse alloc] initWithSequenceNumber:self.currentSequenceNumber duration:[[NSDate date] timeIntervalSinceDate:self.currentStartDate] identifier:self.identifier ipAddress:nil error:error];

        if (self.observer) {
            self.observer(self, response);
        }

        [self _scheduleNextPing];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.configuration.timeoutInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), self.timeoutBlock);
}

- (void)_scheduleNextPing
{
    NSParameterAssert([NSThread currentThread].isMainThread);

    if (self.hasScheduledNextPing) {
        return;
    }

    self.hasScheduledNextPing = YES;
    if (self.timeoutBlock) {
        dispatch_block_cancel(self.timeoutBlock);
        self.timeoutBlock = nil;
    }

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.configuration.pingInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(self) self = weakSelf;
        self.hasScheduledNextPing = NO;
        [self _sendPing];
    });
}

@end

