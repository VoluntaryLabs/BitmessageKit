//
//  BMReceivedMessages.m
//  Bitmarket
//
//  Created by Steve Dekorte on 1/25/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import "BMReceivedMessages.h"
#import "BMReceivedMessage.h"
#import "BMClient.h"
#import <FoundationCategoriesKit/FoundationCategoriesKit.h>
#import "BMMessage.h"

@implementation BMReceivedMessages

- (id)init
{
    self = [super init];
    //self.actions = [NSMutableArray arrayWithObjects:@"refresh", nil];
    self.children = [NSMutableArray array];
    return self;
}

- (void)fetch
{
    //self.children = [self getAllInboxMessages];
    [self.children mergeWith:[self getAllInboxMessages]];
    [self setChildren:self.children]; // so node parents set
    
    [self sortChildren];
    
    [self updateUnreadCount];
}

- (void)updateUnreadTile
{
    NSNumber *num = [NSNumber numberWithInteger:self.unreadCount];
    NSDictionary *dict = [NSDictionary dictionaryWithObject:num forKey:@"number"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NavDocTileUpdate" object:dict];
}

- (void)updateUnreadCount
{
    NSInteger lastUnreadCount = self.unreadCount;

    [super updateUnreadCount];

    if (!_hasFetchedBefore && (lastUnreadCount != self.unreadCount))
    {
        [self updateUnreadTile];
    }
    
    _hasFetchedBefore = YES;
}

- (void)sortChildren
{
    NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"receivedTime" ascending:NO];
    [self.children sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
}

- (BMClient *)client
{
    return (BMClient *)self.nodeParent;
}

- (NSMutableArray *)filterMessages:(NSMutableArray *)messages
{
    NSMutableArray *results = [NSMutableArray array];

    BMSubscriptions *subscriptions = self.client.subscriptions;
    [subscriptions prepareToMergeChildren];
    
    BMChannels *channels = self.client.channels;
    [channels prepareToMergeChildren];
    
    for (BMReceivedMessage *message in messages)
    {
        // remove deleted
        if ([self.client.deletedMessagesDB hasMarked:message.msgid])
        {
            [message delete];
        }
        else
        {
            if ([subscriptions mergeChild:message])
            {
                continue;
            }
            else
            if ([channels mergeChild:message])
            {
                continue;
            }
            else
            {
                [results addObject:message];
            }
        }
    }
    
    [subscriptions completeMergeChildren];
    [channels completeMergeChildren];
    
    return results;
}

- (NSMutableArray *)getAllInboxMessages
{
    NSMutableArray *messages = [[[BMClient sharedBMClient] messages]
            getMessagesWithMethod:@"getAllInboxMessages"
            andKey:@"inboxMessages"
            class:[BMReceivedMessage class]];
    
    messages = [self filterMessages:messages];
    
    return messages;
}

- (NSString *)nodeTitle
{
    return @"Inbox";
}

@end
