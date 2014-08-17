//
//  BMMessageGroup.h
//  Bitmessage
//
//  Created by Steve Dekorte on 3/25/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import "BMNode.h"
#import "BMMessage.h"
#import "BMUnreadCountable.h"

@interface BMMessageGroup : BMUnreadCountable


// --- merging --------------------------

/*
@property (strong, nonatomic) NSMutableArray *mergingChildren;

- (void)prepareToMergeChildren;
- (BOOL)mergeChild:(BMMessage *)aMessage;
- (void)completeMergeChildren;
*/

// -- unread count ----------------------

/*
@property (assign, nonatomic) NSInteger unreadCount;

- (void)updateUnreadCount;
- (void)incrementUnreadCount;
- (void)decrementUnreadCount;
*/

// -----------------------

- (void)deleteAll;

@end
