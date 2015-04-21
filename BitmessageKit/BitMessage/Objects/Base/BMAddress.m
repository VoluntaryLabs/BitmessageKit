//
//  BMAddress.m
//  Bitmarket
//
//  Created by Steve Dekorte on 1/29/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMAddress.h"
#import "BMProxyMessage.h"

static NSMutableDictionary *_validAddressCache = nil;

@implementation BMAddress

+ (NSMutableDictionary *)validAddressCache
{
    if (!_validAddressCache)
    {
        _validAddressCache = [NSMutableDictionary dictionary];
    }
    
    return _validAddressCache;
}

+ (BOOL)isValidAddress:(NSString *)address
{
    NSNumber *value = [self.validAddressCache objectForKey:address];
    
    if (value)
    {
        return value.boolValue;
    }
    
    if (![address hasPrefix:@"BM-"] || !([address length] > 30))
    {
        return NO;
    }
    
    BMAddress *add = [[BMAddress alloc] init];
    add.address = address;
    [add decode];
    BOOL isValid = add.isValid;

    [self.validAddressCache setObject:[NSNumber numberWithBool:isValid] forKey:address];
    
    return isValid;
}

- (void)setDict:(NSDictionary *)dict
{
    self.status = [dict objectForKey:@"status"];
    self.addressVersion = [dict objectForKey:@"addressVersion"];
    self.streamNumber = [dict objectForKey:@"streamNumber"];
    self.ripe = [[dict objectForKey:@"ripe"] decodedBase64];
}

- (void)decode
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"decodeAddress"];
    [message setParameters:[NSArray arrayWithObject:self.address]];
    //message.debug = YES;
    [message sendSync];
    id dict = [message parsedResponseValue];

    //NSLog(@"response %@", dict);

    if (![[dict objectForKey:@"status"] isEqualToString:@"success"])
    {
        self.isValid = NO;
    }
    else
    {
        self.isValid = YES;
        [self setDict:dict];
    }
}

@end
