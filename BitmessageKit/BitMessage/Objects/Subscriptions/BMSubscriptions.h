//
//  BMSubscriptions.h
//  Bitmarket
//
//  Created by Steve Dekorte on 1/25/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import "BMNode.h"
#import "BMMessage.h"

@interface BMSubscriptions : BMNode

- (void)prepareToMessageMerge;
- (BOOL)mergeMessage:(BMMessage *)aMessage;
- (void)completeMessageMerge;

@end
