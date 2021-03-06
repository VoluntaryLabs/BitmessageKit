//
//  BMChannels.m
//  Bitmarket
//
//  Created by Steve Dekorte on 1/28/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMChannels.h"
#import "BMChannel.h"
#import "BMProxyMessage.h"
#import "BMMessage.h"
#import <FoundationCategoriesKit/FoundationCategoriesKit.h>

@implementation BMChannels

- (id)init
{
    self = [super init];
    self.nodeShouldSelectChildOnAdd = @YES;
    
    {
        NavActionSlot *slot = [self.navMirror newActionSlotWithName:@"add"];
        [slot setVisibleName:@"add"];
    }
    
    return self;
}

- (void)fetch
{
    [self.children mergeWith:[self listAddresses2]];
    [self setChildren:self.children]; // so node parents set
    [self sortChildren];
}

- (NSMutableArray *)listAddresses2 // identities
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"listAddresses2"];
    NSArray *params = [NSArray array];
    [message setParameters:params];
    [message sendSync];
    
    NSMutableArray *items = [NSMutableArray array];
    
    //NSLog(@"[message parsedResponseValue] = %@", [message parsedResponseValue]);
    
    NSArray *dicts = [[message parsedResponseValue] objectForKey:@"addresses"];
    
    //NSLog(@"\n\ndicts = %@", dicts);
    
    for (NSDictionary *dict in dicts)
    {
        BMChannel *child = [BMChannel withDict:dict];
        
        if ([child.label hasPrefix:@"[chan] "])
        {
            [items addObject:child];
        }
    }
    
    return items;
}

- (void)add
{
    BMChannel *channel = [[BMChannel alloc] init];
    [self addChild:channel];
    //[channel create];
    //[self refresh];
}

- (NSString *)nodeTitle
{
    return @"Channels";
}

- (NSNumber *)nodeSuggestedWidth
{
    return @180.0;
}


- (BMChannel *)channelWithPassphrase:(NSString *)aPassphrase
{
    for (BMChannel *channel in self.children)
    {
        //NSLog(@"channel.passphrase = '%@'", channel.passphrase);
        
        if ([channel.passphrase isEqualToString:aPassphrase])
        {
            return channel;
        }
    }
    
    return nil;
}

- (BMChannel *)channelWithPassphraseJoinIfNeeded:(NSString *)aPassphrase
{
    BMChannel *channel = [self channelWithPassphrase:aPassphrase];
    
    if (!channel)
    {
        channel = [[BMChannel alloc] init];
        [channel setPassphrase:aPassphrase];
        //[channel join];
        [channel create];
        [self addChild:channel];
        // need to add error checking
    }
    
    return channel;
}

// ----------------------------------------

- (void)leaveAll
{
    [self leaveAllExceptThoseInSet:[NSSet set]];
}

- (void)leaveAllExceptThoseInSet:(NSSet *)keepSet
{
    for (BMChannel *child in self.children.copy)
    {
        if (![keepSet containsObject:child])
        {
            [child delete];
        }
    }
}

@end
