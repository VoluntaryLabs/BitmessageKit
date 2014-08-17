//
//  BMMessageGroup.m
//  Bitmessage
//
//  Created by Steve Dekorte on 3/25/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import "BMMessageGroup.h"
#import <FoundationCategoriesKit/FoundationCategoriesKit.h>

@implementation BMMessageGroup

/*
- (void)prepareToMergeChildren
{
    self.mergingChildren = [NSMutableArray array];
}

- (BOOL)mergeChild:(BMMessage *)aMessage
{
    return NO;
}

- (void)completeMergeChildren
{
    [self.children mergeWith:self.mergingChildren];
    [self setChildren:self.children]; // so node parents set
    self.mergingChildren = nil;
}
*/

// ----------------------

/*
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
   // [[NSNotificationCenter defaultCenter]
    //     postNotificationName:@"BMReceivedMessagesUnreadCountChanged"
     //    object:self];
   // [self.nodeParent postParentChanged];
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
 */


// ------------------------------

- (void)deleteAll
{
    for (BMMessage *msg in self.children)
    {
        [msg delete];
    }
}

- (BOOL)canSearch
{
    return YES;
}


@end
