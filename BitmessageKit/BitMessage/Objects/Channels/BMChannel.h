//
//  BMChannel.h
//  Bitmarket
//
//  Created by Steve Dekorte on 1/28/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import "BMAddressed.h"
#import "BMMessage.h"
#import "BMMergable.h"

@interface BMChannel : BMMergable

//@property (retain, nonatomic) NSMutableArray *mergingChildren;
@property (retain, nonatomic) NSString *passphrase;
@property (retain, nonatomic) NSString *difficulty;
@property (assign, nonatomic) NSInteger unreadCount;

+ (BMChannel *)withDict:(NSDictionary *)dict;

- (void)setPassphrase:(NSString *)passphrase;
- (NSString *)passphrase;


- (void)create;
//- (void)join;
- (void)delete;

@end
