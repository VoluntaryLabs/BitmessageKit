//
//  BMChannel.m
//  Bitmarket
//
//  Created by Steve Dekorte on 1/28/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMChannel.h"
#import "BMProxyMessage.h"
#import "BMAddress.h"
#import "BMClient.h"
#import <FoundationCategoriesKit/FoundationCategoriesKit.h>

@implementation BMChannel

+ (NSString *)defaultLabel
{
    return @"Enter channel label";
}

- (id)init
{
    self = [super init];
    [self setPassphrase:self.class.defaultLabel];
    [self setAddress:@""];
    [self setDifficulty:@"1"];
    self.nodeSuggestedWidth = @180;
    
    {
        NavActionSlot *slot = [self.navMirror newActionSlotWithName:@"message"];
        [slot setVisibleName:@"message"];
    }
    
    {
        NavActionSlot *slot = [self.navMirror newActionSlotWithName:@"delete"];
        [slot setVisibleName:@"delete"];
        [slot setVerifyMessage: @"Are you sure you want to stop receiving this channel?"];
    }
    
    return self;
}

- (NSNumber *)nodeForceDisplayChildren
{
    return [NSNumber numberWithBool:self.children.count > 0];
}

// -----------------------------

+ (BMChannel *)withDict:(NSDictionary *)dict
{
    id instance = [[[self class] alloc] init];
    [instance setDict:dict];
    //NSLog(@"channel dict: %@", dict);
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

- (void)fetch
{
}

- (BOOL)shouldOwnMessage:(BMMessage *)aMessage
{
    return [aMessage.toAddress isEqualToString:self.address];
}

// -----------------------------

- (void)setPassphrase:(NSString *)passphrase
{
    self.label = [NSString stringWithFormat:@"[chan] %@", passphrase];
}

- (NSString *)passphrase
{
    NSString *prefix = @"[chan] ";
    
    if ([self.label hasPrefix:prefix])
    {
        return [self.label stringByReplacingOccurrencesOfString:prefix withString:@""];
    }
    
    return @"";
}

- (void)justCreate
{
    // createChan	 <passphrase>	 0.4.2	 Creates a new chan. passphrase must be base64 encoded. Outputs the corresponding Bitmessage address.
    //NSLog(@"BMChannel createChan '%@'", self.passphrase);
    
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"createChan"];
    NSArray *params = [NSArray arrayWithObjects:self.passphrase.encodedBase64, self.difficulty, nil];
    [message setParameters:params];
    //message.debug = YES;
    [message sendSync];
    self.address = [message responseValue];
    
    if (self.address == nil)
    {
        [NSException raise:@"unable to create channel address" format:nil];
    }
    
    if ([self.address hasPrefix:@"BM"])
    {
        self.isSynced = YES;
    }
}

- (void)create
{
    [self justCreate];
    //[self join];
    [self.nodeParent addChild:self];
    //[self postParentChanged];
}

- (void)join
{
    // Don't need this method as createChan will add the address?
    // this method appears to be for when the API isn't used to create the channel address
    
    // joinChan	 <passphrase> <address>	 0.4.2	 Join a chan. passphrase must be base64 encoded. Outputs "success"
    
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"joinChan"];
    NSArray *params = [NSArray arrayWithObjects:self.passphrase.encodedBase64, self.address, nil];
    [message setParameters:params];
    //message.debug = YES;
    [message sendSync];
    id response = [message parsedResponseValue];
    NSLog(@"response %@", response);
    [self.nodeParent addChild:self];
    //[self postParentChanged];
}

- (void)delete
{
    self.isSynced = NO;
    [self leave];
}

- (void)justLeave
{
    // leaveChan <address>	 0.4.2	 Leave a chan.
    // Outputs "success". Note that at this time,
    // the address is still shown in the UI until a restart.
    
    //NSLog(@"BMChannel justLeave '%@'", self.address);

    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"leaveChan"];
    NSArray *params = [NSArray arrayWithObjects:self.address, nil];
    [message setParameters:params];
    //message.debug = YES;
    [message sendSync];
    //id response = [message parsedResponseValue];
    //NSLog(@"response %@", response);
    
    //[self.nodeParent removeChild:self];
}

- (void)leave
{
    [self deleteAllChildren];
    [self justLeave];
    [self removeFromParent];
    [self postParentChanged];
}

- (NSString *)nodeTitle
{
    return self.passphrase;
}

- (NSString *)visibleLabel
{
    return self.passphrase;
}

- (void)setVisibleLabel:(NSString *)aLabel
{
    self.passphrase = aLabel;
}

- (void)update
{
    self.isSynced = NO;
    [self justLeave];
    [self create];
    self.isSynced = YES;
    [self postParentChanged];
}

// ------------------------------

- (void)sortChildren
{
    NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"receivedTime" ascending:NO];
    [self.children sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
}

// -------------------

- (BOOL)canSearch
{
    return YES;
}

// --- merge ---

- (SEL)mergeAttributeSelector
{
    return @selector(toAddress);
}

@end
