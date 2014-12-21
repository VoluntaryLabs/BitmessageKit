//
//  BMSubscription.m
//  Bitmarket
//
//  Created by Steve Dekorte on 1/25/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMSubscription.h"
#import "BMProxyMessage.h"
#import "BMClient.h"
#import "BMAddress.h"

@implementation BMSubscription

+ (NSString *)defaultLabel
{
    return @"Enter subscription label";
}

- (id)init
{
    self = [super init];
    self.label = self.class.defaultLabel;

    {
        NavActionSlot *slot = [self.navMirror newActionSlotWithName:@"message"];
        [slot setVisibleName:@"message"];
    }
    
    {
        NavActionSlot *slot = [self.navMirror newActionSlotWithName:@"delete"];
        [slot setVisibleName:@"delete"];
        [slot setVerifyMessage:@"Are you sure you want to stop receiving this subscription?"];
    }
    
    return self;
}

- (BOOL)nodeForceDisplayChildren
{
    return self.children.count > 0;
}

+ (BMSubscription *)withDict:(NSDictionary *)dict
{
    id instance = [[[self class] alloc] init];
    [instance setDict:dict];
    return instance;
}

- (NSMutableDictionary *)dict
{
    NSMutableDictionary *dict = [super dict];
    [dict setObject:[NSNumber numberWithBool:self.enabled] forKey:@"enabled"];
    return dict;
}

- (void)setDict:(NSDictionary *)dict
{
    self.isSynced = YES;
    [super setDict:dict];
    self.enabled = [[dict objectForKey:@"enabled"] boolValue];
}

- (NSString *)description
{
    return [self.dict description];
}

- (NSString *)nodeTitle
{
    return self.label;
}

- (NSString *)nodeNote
{
    return [super nodeNote];
}

/*
- (void)fetch
{
    // is this right?
    //self.children = [[BMClient.sharedBMClient messages] getSentMessagesBySender:self.address];
}
*/

// ----------------------

- (BOOL)justSubscribe
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"addSubscription"];
    NSArray *params = [NSArray arrayWithObjects:self.address,
                       [self.label encodedBase64], nil];
    [message setParameters:params];
    message.debug = NO;
    [message sendSync];
    id response = [message responseValue];
    NSLog(@"response %@", response);
    return YES;
}

- (BOOL)subscribe
{
    return [self justSubscribe];
}

- (void)justDelete
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"deleteSubscription"];
    NSArray *params = [NSArray arrayWithObjects:self.address, nil];
    [message setParameters:params];
    //message.debug = YES;
    [message sendSync];
    //id response = [message parsedResponseValue];
    //NSLog(@"response %@", response);
}

- (void)delete
{
    [self deleteAllChildren];
    [self justDelete];
    [self removeFromParent];
    [self postParentChanged];
}

- (void)update
{
    NSLog(@"updating subscription '%@' '%@'", self.address, self.label);
    
    [self justDelete];
    
    if ([self justSubscribe])
    {
        [self postParentChanged];
    }
}

- (NSString *)visibleLabel
{
    return self.label;
}

- (void)setVisibleLabel:(NSString *)aLabel
{
    self.label = aLabel;
}

- (void)sortChildren
{
    NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"receivedTime" ascending:NO];
    [self.children sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
}

- (BOOL)canSearch
{
    return YES;
}

// --- merge ---

- (SEL)mergeAttributeSelector
{
    return @selector(fromAddress);
}

/*
- (void)updateUnreadCount
{
    [super updateUnreadCount];
}
*/

- (BOOL)shouldMergeChild:(BMMessage *)aMessage
{
    // for testing, timeservice is BM-BcbRqcFFSQUUmXFKsPJgVQPSiFA3Xash
    
    if ([aMessage.fromAddress isEqualToString:self.address]
        && [aMessage.toAddress isEqualToString:@"[Broadcast subscribers]"]
        )
    {
        //NSLog(@"TO %@", aMessage.toAddress);
        //NSLog(@"FROM %@", aMessage.fromAddress);

        return YES;
    }
    
    return NO;
}

@end
