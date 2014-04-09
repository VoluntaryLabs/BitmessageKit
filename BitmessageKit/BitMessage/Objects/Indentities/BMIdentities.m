//
//  BMIdentities.m
//  Bitmarket
//
//  Created by Steve Dekorte on 1/29/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import "BMIdentities.h"
#import "BMProxyMessage.h"
#import "BMIdentity.h"
//#import "BMAddressed.h"
#import "NSString+BM.h"

@implementation BMIdentities

- (id)init
{
    self = [super init];
    self.actions = [NSMutableArray arrayWithObjects:@"add", nil];
    self.shouldSelectChildOnAdd = YES;
    return self;
}

- (void)fetch
{
    [self setChildren:[self listAddresses2]];
    [self sortChildren];
}

- (BMClient *)client
{
    return (BMClient *)self.nodeParent;
}

- (NSMutableArray *)listAddresses2 // identities
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"listAddresses2"];
    NSArray *params = [NSArray arrayWithObjects:nil];
    [message setParameters:params];
    [message sendSync];
    
    NSMutableArray *identities = [NSMutableArray array];
    
    //NSLog(@"[message parsedResponseValue] = %@", [message parsedResponseValue]);
    
    NSArray *dicts = [[message parsedResponseValue] objectForKey:@"addresses"];
    
    //NSLog(@"\n\ndicts = %@", dicts);
    
    for (NSDictionary *dict in dicts)
    {
        NSString *label = [[dict objectForKey:@"label"] decodedBase64];
                
        if (![label hasPrefix:@"[chan] "])
        {
            BMIdentity *child = [BMIdentity withDict:dict];
            [identities addObject:child];
        }
        /*
        else
        {
            [self.client.channels addChild:child];
        }
         */
    }
    
    //NSLog(@"\n\n contacts = %@", contacts);
    
    return identities;
}

- (BMIdentity *)createFirstIdentityIfAbsent
{
    if (!self.firstIdentity)
    {
        [self add];
    }
    
    return self.firstIdentity;
}

- (void)add
{
    [self createRandomAddressWithLabel:[BMAddressed defaultLabel]];
}

- (void)createRandomAddressWithLabel:(NSString *)label
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"createRandomAddress"];
    NSArray *params = [NSArray arrayWithObjects:label.encodedBase64, nil];
    [message setParameters:params];
    [message sendSync];
    id response = [message parsedResponseValue];
    NSLog(@"createRandomAddress response %@", response);
    [self fetch];
    
    [self postSelfChanged];
}

- (BMIdentity *)firstIdentity
{
    return (BMIdentity *)self.children.firstObject;
}

/*
- (NSString *)firstIdentityLabel
{
    BMIdentity *identity = (BMIdentity *)self.children.firstObject;
    
    if (identity)
    {
        return identity.label;
    }
    
    return nil;
}


- (NSString *)firstIdentityAddress
{
    BMIdentity *identity = (BMIdentity *)self.children.firstObject;
    
    if (identity)
    {
        return identity.address;
    }
    
    return nil;
}
 */

- (NSString *)nodeTitle
{
    return @"My Identities";
}


@end
