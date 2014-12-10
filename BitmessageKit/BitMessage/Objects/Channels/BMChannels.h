//
//  BMChannels.h
//  Bitmarket
//
//  Created by Steve Dekorte on 1/28/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMNode.h"
#import "BMChannel.h"

@interface BMChannels : BMNode

- (BMChannel *)channelWithPassphraseJoinIfNeeded:(NSString *)aTitle;
- (BMChannel *)channelWithPassphrase:(NSString *)aPassphrase;

- (void)leaveAll;
- (void)leaveAllExceptThoseInSet:(NSSet *)keepSet;

@end
