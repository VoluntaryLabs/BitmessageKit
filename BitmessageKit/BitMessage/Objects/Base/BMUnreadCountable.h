//
//  BMUnreadCountable.h
//  BitmessageKit
//
//  Created by Steve Dekorte on 8/15/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMNode.h"

@interface BMUnreadCountable : BMNode

@property (assign, nonatomic) NSInteger unreadCount;

- (void)updateUnreadCount;
- (void)changedUnreadCount;
- (void)incrementUnreadCount;
- (void)decrementUnreadCount;

@end
