//
//  BMAddressed.m
//  Bitmessage
//
//  Created by Steve Dekorte on 2/21/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMAddressed.h"
#import "BMAddress.h"
#import "BMClient.h"
#import "BMReceivedMessage.h"

//#import "NavTheme.h"

@implementation BMAddressed

+ (NSString *)defaultLabel
{
    return @"Enter Name";
}

- (id)init
{
    self = [super init];
    return self;
}

+ (id)withDict:(NSDictionary *)dict
{
    id instance = [[[self class] alloc] init];
    [instance setDict:dict];
    return instance;
}

- (NSMutableDictionary *)dict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[self.label encodedBase64] forKey:@"label"];
    [dict setObject:self.address forKey:@"address"];
    return dict;
}

- (void)setDict:(NSDictionary *)dict
{
    self.label   = [[dict objectForKey:@"label"] decodedBase64];
    self.address = [dict objectForKey:@"address"];
}

// --------------------------

/*
- (void)setLabel:(NSString *)label
{
    _label = [label strip];
}
*/

- (NSUInteger)hash
{
    return [self.address hash];
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[BMAddressed class]])
    {
        return NO;
    }
    
    return [_address isEqual:[(BMAddressed *)object address]];
}

// -----------------------------

- (BOOL)hasUnsetLabel
{
    return [self.label isEqualToString:[[self class] defaultLabel]];
}

- (NSString *)nodeTitle
{
    return self.label;
}

- (NSString *)visibleLabel
{
    return self.label;
}

- (void)setVisibleLabel:(NSString *)aLabel
{
    self.label = aLabel;
}

- (BOOL)isValidAddress
{
    return [BMAddress isValidAddress:self.address];
}

- (BOOL)canLiveUpdate
{
    return NO;
}

// -----------------------

// UI - move to category

- (NSNumber *)nodeSuggestedWidth
{
    return @350.0;
}

@end

