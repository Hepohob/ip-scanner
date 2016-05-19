//
//  GetHostName.m
//  ip-scanner
//
//  Created by Алексей Неронов on 14.05.16.
//  Copyright © 2016 Алексей Неронов. All rights reserved.
//

#include <netdb.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#import "GetHostName.h"

@implementation GetHostName

- (NSArray *)hostnamesForIPv4Address:(NSString *)address
{
    struct addrinfo *result = NULL;
    struct addrinfo hints;
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_flags = AI_NUMERICHOST;
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = 0;
    
    int errorStatus = getaddrinfo([address cStringUsingEncoding:NSASCIIStringEncoding], NULL, &hints, &result);
    if (errorStatus != 0) {
        return nil;
    }
    
    CFDataRef addressRef = CFDataCreate(NULL, (UInt8 *)result->ai_addr, result->ai_addrlen);
    if (addressRef == nil) {
        return nil;
    }
    freeaddrinfo(result);
    
    CFHostRef hostRef = CFHostCreateWithAddress(kCFAllocatorDefault, addressRef);
    if (hostRef == nil) {
        return nil;
    }
    CFRelease(addressRef);
    
    BOOL succeeded = CFHostStartInfoResolution(hostRef, kCFHostNames, NULL);
    if (!succeeded) {
        return nil;
    }
    
    NSMutableArray *hostnames = [NSMutableArray array];
    
    CFArrayRef hostnamesRef = CFHostGetNames(hostRef, NULL);
    for (int currentIndex = 0; currentIndex < [(__bridge NSArray *)hostnamesRef count]; currentIndex++) {
        [hostnames addObject:[(__bridge NSArray *)hostnamesRef objectAtIndex:currentIndex]];
    }
    
    return hostnames;
}

-(NSString*) returnHostName:(NSString*)ipAddress
{
    struct addrinfo *results = NULL;
    char hostname[NI_MAXHOST] = {0};
    
    if ( getaddrinfo("192.168.1.51", NULL, NULL, &results) != 0 ) NSLog (@"Could not get any info for the address");
    
    for (struct addrinfo *r = results; r; r = r->ai_next)
    {
        if (getnameinfo(r->ai_addr, r->ai_addrlen, hostname, sizeof hostname, NULL, 0 , 0) != 0)
            continue; // try next one
        else
        {
            NSLog (@"Found hostname: %s", hostname);
            break;
        }
    }
    
    freeaddrinfo(results);
    
    
    NSLog(@"----- %@",[self hostnamesForAddress:@"192.168.1.1"]);
/*
    unsigned char *ptr;
    ptr = (unsigned char *)LLADDR((struct sockaddr_dl *)(temp_addr)->ifa_addr);
    
    NSString *ip = [NSString stringWithUTF8String: inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
    NSArray *hostsNames = [self hostnamesForAddress:ip];
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:
                                 @{
                                   @"name": @(temp_addr->ifa_name),
                                   @"flags": @(temp_addr->ifa_flags),
                                   @"ip" : ip,
                                   @"family": @(temp_addr->ifa_addr->sa_family),
                                   @"mac" :  [NSString stringWithFormat:@"MAC[%02x:%02x:%02x:%02x:%02x:%02x]", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)],
                                   @"hostName" : hostsNames.count ? hostsNames : @""
                                   }
                                 ];
    */
    return [NSString stringWithFormat:@"ip address is %@ name is !!!!!",ipAddress];
}

- (NSArray *)hostnamesForAddress:(NSString *)address {
    // Get the host reference for the given address.
    struct addrinfo      hints;
    struct addrinfo      *result = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_flags    = AI_NUMERICHOST;
    hints.ai_family   = PF_UNSPEC; /* Allow IPv4 or IPv6 */
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = 0;
    hints.ai_canonname = NULL;
    hints.ai_addr = NULL;
    hints.ai_next = NULL;
    
    int errorStatus = getaddrinfo([address cStringUsingEncoding:NSASCIIStringEncoding], NULL, &hints, &result);
    if (errorStatus != 0) return @[[self getErrorDescription:errorStatus]];
    
    CFDataRef addressRef = CFDataCreate(NULL, (UInt8 *)result->ai_addr, result->ai_addrlen);
    if (addressRef == nil) return nil;
    
    freeaddrinfo(result);
    CFHostRef hostRef = CFHostCreateWithAddress(kCFAllocatorDefault, addressRef);
    if (hostRef == nil) return nil;
    CFRelease(addressRef);
    BOOL isSuccess = CFHostStartInfoResolution(hostRef, kCFHostNames, NULL);
    if (!isSuccess) return nil;
    
    // Get the hostnames for the host reference.
    CFArrayRef hostnamesRef = CFHostGetNames(hostRef, NULL);
    NSMutableArray *hostnames = [NSMutableArray array];
    for (int currentIndex = 0; currentIndex < [(__bridge NSArray *)hostnamesRef count]; currentIndex++) {
        [hostnames addObject:[(__bridge NSArray *)hostnamesRef objectAtIndex:currentIndex]];
    }
    
    return hostnames;
}

- (NSString *)getErrorDescription:(NSInteger)errorCode
{
    NSString *errorDescription = @"";;
    switch (errorCode) {
        case EAI_ADDRFAMILY: {
            errorDescription = @" address family for hostname not supported";
            break;
        }
        case EAI_AGAIN: {
            errorDescription = @" temporary failure in name resolution";
            break;
        }
        case EAI_BADFLAGS: {
            errorDescription = @" invalid value for ai_flags";
            break;
        }
        case EAI_FAIL: {
            errorDescription = @" non-recoverable failure in name resolution";
            break;
        }
        case EAI_FAMILY: {
            errorDescription = @" ai_family not supported";
            break;
        }
        case EAI_MEMORY: {
            errorDescription = @" memory allocation failure";
            break;
        }
        case EAI_NODATA: {
            errorDescription = @" no address associated with hostname";
            break;
        }
        case EAI_NONAME: {
            errorDescription = @" hostname nor servname provided, or not known";
            break;
        }
        case EAI_SERVICE: {
            errorDescription = @" servname not supported for ai_socktype";
            break;
        }
        case EAI_SOCKTYPE: {
            errorDescription = @" ai_socktype not supported";
            break;
        }
        case EAI_SYSTEM: {
            errorDescription = @" system error returned in errno";
            break;
        }
        case EAI_BADHINTS: {
            errorDescription = @" invalid value for hints";
            break;
        }
        case EAI_PROTOCOL: {
            errorDescription = @" resolved protocol is unknown";
            break;
        }
        case EAI_OVERFLOW: {
            errorDescription = @" argument buffer overflow";
            break;
        }
    }
    return errorDescription;
}

@end
