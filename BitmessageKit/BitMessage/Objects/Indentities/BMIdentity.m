//
//  BMIdentity.m
//  Bitmarket
//
//  Created by Steve Dekorte on 1/29/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import "BMIdentity.h"
#import "BMProxyMessage.h"
#import "BMServerProcess.h"

@implementation BMIdentity

- (id)init
{
    self = [super init];
    self.actions = [NSMutableArray arrayWithObjects:@"delete", nil];
    return self;
}

+ (BMIdentity *)withDict:(NSDictionary *)dict
{
    id instance = [[[self class] alloc] init];
    [instance setDict:dict];
    return instance;
}

- (NSDictionary *)dict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[self.label encodedBase64] forKey:@"label"];
    [dict setObject:self.address forKey:@"address"];
    return dict;
}

- (void)setDict:(NSDictionary *)dict
{
    self.isSynced = YES;
    self.label   = [[dict objectForKey:@"label"] decodedBase64];
    self.address = [dict objectForKey:@"address"];
}

- (NSString *)nodeTitle
{
    return self.label;
}

// ----------

- (void)delete
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"deleteAddress"];
    NSArray *params = [NSArray arrayWithObjects:self.address, nil];
    [message setParameters:params];
    //message.debug = YES;
    [message sendSync];
    id response = [message parsedResponseValue];
    NSLog(@"delete response = %@", response);
    
    [self.nodeParent removeChild:self];
    [self postParentChanged];
}

- (void)update
{
    self.isSynced = NO;
    NSLog(@"updating identity '%@' '%@'", self.address, self.label);
    
    [[BMServerProcess sharedBMServerProcess] setLabel:self.label onAddress:self.address];
    
    [self postParentChanged];
    self.isSynced = YES;
}

- (void)insert
{
    /*
    NSLog(@"insert identity '%@' '%@'", self.address, self.label);
    
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"addAddressBookEntry"];
    NSArray *params = [NSArray arrayWithObjects:self.address, self.label.encodedBase64, nil];
    [message setParameters:params];
    message.debug = YES;
    [message sendSync];
    
    id response = [message parsedResponseValue];
    NSLog(@"insert response = %@", response);
    */
}

- (NSString *)verifyActionMessage:(NSString *)actionString
{
    if ([actionString isEqualToString:@"delete"])
    {
        return @"CAUTION: This address is one of your identities. Deleting it will permanently loose the private key for the identity and you will never be able to receive or read messages sent to this address again.";
    }
    
    return nil;
}

@end
