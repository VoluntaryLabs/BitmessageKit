//
//  BMSubscriptions.h
//  Bitmarket
//
//  Created by Steve Dekorte on 1/25/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import "BMNode.h"
#import "BMMessage.h"
#import "BMSubscription.h"

@interface BMSubscriptions : BMNode

- (BMSubscription *)subscriptionWithAddress:(NSString *)anAddress;
- (BMSubscription *)subscriptionWithAddressAddIfNeeded:(NSString *)anAddress;

@end
