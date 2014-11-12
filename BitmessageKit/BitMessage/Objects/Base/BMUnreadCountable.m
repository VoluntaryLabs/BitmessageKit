//
//  BMUnreadCountable.m
//  BitmessageKit
//
//  Created by Steve Dekorte on 8/15/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMUnreadCountable.h"
#import "BMMessage.h"

@implementation BMUnreadCountable

- (void)fetch
{
    [super fetch];
    [self updateUnreadCount];
}

- (NSString *)nodeNote
{
    if (self.unreadCount)
    {
        return [NSString stringWithFormat:@"%i", (int)self.unreadCount];
    }
    
    return nil;
}

- (void)decrementUnreadCount
{
    _unreadCount --;
    [self changedUnreadCount];
}

- (void)incrementUnreadCount
{
    _unreadCount ++;
    [self changedUnreadCount];
}

- (void)updateUnreadCount
{
    //NSLog(@"updateUnreadCount");
    NSInteger lastUnreadCount = _unreadCount;
    
    _unreadCount = 0;
    
    for (BMMessage *message in self.children)
    {
        if (![message read])
        {
            _unreadCount ++;
        }
    }
    
    if ((lastUnreadCount != _unreadCount))
    {
        [self changedUnreadCount];
    }
}

- (void)changedUnreadCount
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:@(self.unreadCount) forKey:@"number"];
    
     [NSNotificationCenter.defaultCenter
        postNotificationName:@"BMReceivedMessagesUnreadCountChanged"
        object:self
        userInfo:userInfo];

    [self postParentChanged];
}


- (BOOL)addChild:(id)aChild
{
    BOOL result = [super addChild:aChild];
    
    if (![(BMMessage *)aChild read])
    {
        [self incrementUnreadCount];
    }
    
    return result;
}

- (void)removeChild:(id)aChild
{
    [super removeChild:aChild];
    
    if (![(BMMessage *)aChild read])
    {
        [self decrementUnreadCount];
    }
}

@end
