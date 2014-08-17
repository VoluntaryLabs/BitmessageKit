//
//  BMUnreadCountable.h
//  BitmessageKit
//
//  Created by Steve Dekorte on 8/15/14.
//  Copyright (c) 2014 Adam Thorsen. All rights reserved.
//

#import "BMNode.h"

@interface BMUnreadCountable : BMNode

@property (assign, nonatomic) NSInteger unreadCount;

- (void)updateUnreadCount;
- (void)incrementUnreadCount;
- (void)decrementUnreadCount;

@end
