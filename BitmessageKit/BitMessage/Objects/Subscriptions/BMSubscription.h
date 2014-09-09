//
//  BMSubscription.h
//  Bitmarket
//
//  Created by Steve Dekorte on 1/25/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

//#import "BMAddressed.h"
#import "BMMergable.h"

@interface BMSubscription : BMMergable

@property (assign, nonatomic) BOOL enabled;

+ (BMSubscription *)withDict:(NSDictionary *)dict;

- (BOOL)subscribe;
- (void)delete;


@end
