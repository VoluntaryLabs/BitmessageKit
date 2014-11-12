//
//  BMChannel.h
//  Bitmarket
//
//  Created by Steve Dekorte on 1/28/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMAddressed.h"
#import "BMMessage.h"
#import "BMMergable.h"

@interface BMChannel : BMMergable

@property (retain, nonatomic) NSString *passphrase;
@property (retain, nonatomic) NSString *difficulty;
@property (assign, nonatomic) NSInteger unreadCount;

+ (BMChannel *)withDict:(NSDictionary *)dict;

- (void)setPassphrase:(NSString *)passphrase;
- (NSString *)passphrase;

- (void)create;
- (void)delete;

@end
