//
//  ICMPHeader.h
//  GBPing
//
//  Created by Luka Mirosevic on 15/11/2012.
//  Copyright (c) 2012 Goonbee. All rights reserved.
//

#ifndef GBPing_ICMPHeader_h
#define GBPing_ICMPHeader_h

#include <AssertMacros.h>

#pragma mark - IP and ICMP On-The-Wire Format

#ifndef check_compile_time
#define check_compile_time __Check_Compile_Time
#endif

// The following declarations specify the structure of ping packets on the wire.

// IP header structure:

struct IPHeader {
    uint8_t     versionAndHeaderLength;
    uint8_t     differentiatedServices;
    uint16_t    totalLength;
    uint16_t    identification;
    uint16_t    flagsAndFragmentOffset;
    uint8_t     timeToLive;
    uint8_t     protocol;
    uint16_t    headerChecksum;
    uint8_t     sourceAddress[4];
    uint8_t     destinationAddress[4];
    // options...
    // data...
};
typedef struct IPHeader IPHeader;

check_compile_time(sizeof(IPHeader) == 20);
check_compile_time(offsetof(IPHeader, versionAndHeaderLength) == 0);
check_compile_time(offsetof(IPHeader, differentiatedServices) == 1);
check_compile_time(offsetof(IPHeader, totalLength) == 2);
check_compile_time(offsetof(IPHeader, identification) == 4);
check_compile_time(offsetof(IPHeader, flagsAndFragmentOffset) == 6);
check_compile_time(offsetof(IPHeader, timeToLive) == 8);
check_compile_time(offsetof(IPHeader, protocol) == 9);
check_compile_time(offsetof(IPHeader, headerChecksum) == 10);
check_compile_time(offsetof(IPHeader, sourceAddress) == 12);
check_compile_time(offsetof(IPHeader, destinationAddress) == 16);

// ICMP type and code combinations:

enum {
    kICMPTypeEchoReply   = 0,           // code is always 0
    kICMPTypeEchoRequest = 8            // code is always 0
};

// ICMP header structure:

struct ICMPHeader {
    uint8_t     type;
    uint8_t     code;
    uint16_t    checksum;
    uint16_t    identifier;
    uint16_t    sequenceNumber;
    // data...
};
typedef struct ICMPHeader ICMPHeader;

check_compile_time(sizeof(ICMPHeader) == 8);
check_compile_time(offsetof(ICMPHeader, type) == 0);
check_compile_time(offsetof(ICMPHeader, code) == 1);
check_compile_time(offsetof(ICMPHeader, checksum) == 2);
check_compile_time(offsetof(ICMPHeader, identifier) == 4);
check_compile_time(offsetof(ICMPHeader, sequenceNumber) == 6);

static inline uint16_t in_cksum(const void *buffer, size_t bufferLen)
// This is the standard BSD checksum code, modified to use modern types.
{
    size_t              bytesLeft;
    int32_t             sum;
    const uint16_t *    cursor;
    union {
        uint16_t        us;
        uint8_t         uc[2];
    } last;
    uint16_t            answer;

    bytesLeft = bufferLen;
    sum = 0;
    cursor = buffer;

    /*
     * Our algorithm is simple, using a 32 bit accumulator (sum), we add
     * sequential 16 bit words to it, and at the end, fold back all the
     * carry bits from the top 16 bits into the lower 16 bits.
     */
    while (bytesLeft > 1) {
        sum += *cursor;
        cursor += 1;
        bytesLeft -= 2;
    }

    /* mop up an odd byte, if necessary */
    if (bytesLeft == 1) {
        last.uc[0] = * (const uint8_t *) cursor;
        last.uc[1] = 0;
        sum += last.us;
    }

    /* add back carry outs from top 16 bits to low 16 bits */
    sum = (sum >> 16) + (sum & 0xffff);	/* add hi 16 to low 16 */
    sum += (sum >> 16);			/* add carry */
    answer = (uint16_t) ~sum;   /* truncate to 16 bits */

    return answer;
}

static inline NSData *ICMPPackageCreate(uint16_t identifier, uint16_t sequenceNumber, NSUInteger payloadSize)
{
    char tempBuffer[payloadSize];
    memset(tempBuffer, 7, payloadSize);

    // Construct the ping packet.
    NSData *payload = [[NSData alloc] initWithBytes:tempBuffer length:payloadSize];
    NSMutableData *package = [NSMutableData dataWithLength:sizeof(ICMPHeader) + payload.length];

    ICMPHeader *header = package.mutableBytes;
    header->type = kICMPTypeEchoRequest;
    header->code = 0;
    header->checksum = 0;
    header->identifier     = OSSwapHostToBigInt16(identifier);
    header->sequenceNumber = OSSwapHostToBigInt16(sequenceNumber);
    memcpy(&header[1], payload.bytes, payload.length);

    // The IP checksum returns a 16-bit number that's already in correct byte order
    // (due to wacky 1's complement maths), so we just put it into the packet as a
    // 16-bit unit.
    header->checksum = in_cksum(package.bytes, package.length);

    return package;
}

static inline BOOL ICMPExtractResponseFromData(NSData *data, NSData **ipHeaderData, NSData **ipData, NSData **icmpHeaderData, NSData **icmpData)
{
    NSMutableData *buffer = data.mutableCopy;

    if (buffer.length < (sizeof(IPHeader) + sizeof(ICMPHeader))) {
        return NO;
    }

    const IPHeader *ipHeader = buffer.mutableBytes;
    assert((ipHeader->versionAndHeaderLength & 0xF0) == 0x40);     // IPv4
    assert(ipHeader->protocol == 1);                               // ICMP
    size_t ipHeaderLength = (ipHeader->versionAndHeaderLength & 0x0F) * sizeof(uint32_t);

    *ipHeaderData = [buffer subdataWithRange:NSMakeRange(0, sizeof(IPHeader))];

    if (buffer.length >= sizeof(IPHeader) + ipHeaderLength) {
        *ipData = [buffer subdataWithRange:NSMakeRange(sizeof(IPHeader), ipHeaderLength)];
    }

    if (buffer.length < ipHeaderLength + sizeof(ICMPHeader)) {
        return NO;
    }

    size_t icmpHeaderOffset = ipHeaderLength;
    ICMPHeader *icmpHeader = (ICMPHeader *)(((uint8_t *)buffer.mutableBytes) + icmpHeaderOffset);

    uint16_t receivedChecksum = icmpHeader->checksum;
    icmpHeader->checksum = 0;
    uint16_t calculatedChecksum = in_cksum(icmpHeader, buffer.length - icmpHeaderOffset);
    icmpHeader->checksum = receivedChecksum;

    if (receivedChecksum != calculatedChecksum) {
        NSLog(@"%s: invalid ICMP header. Checksums did not match", __PRETTY_FUNCTION__);
        return NO;
    }

    *icmpHeaderData = [buffer subdataWithRange:NSMakeRange(icmpHeaderOffset, sizeof(ICMPHeader))];
    *icmpData = [buffer subdataWithRange:NSMakeRange(icmpHeaderOffset + sizeof(ICMPHeader), buffer.length - (icmpHeaderOffset + sizeof(ICMPHeader)))];

    return YES;
}

#endif
