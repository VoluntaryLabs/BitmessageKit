//
//  BMAddressed.h
//  Bitmessage
//
//  Created by Steve Dekorte on 2/21/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

//#import "BMNode.h"
//@interface BMAddressed : BMNode


#import "BMUnreadCountable.h"

@interface BMAddressed : BMUnreadCountable

@property (retain, nonatomic) NSString *label;
@property (retain, nonatomic) NSString *address; // base64
@property (assign, nonatomic) BOOL isSynced;

+ (NSString *)defaultLabel;

+ (id)withDict:(NSDictionary *)dict;
- (void)setDict:(NSDictionary *)dict;
- (NSMutableDictionary *)dict;

- (BOOL)hasUnsetLabel;

- (NSString *)nodeTitle;

- (BOOL)isValidAddress;
- (NSString *)visibleLabel;
- (void)setVisibleLabel:(NSString *)aLabel;
- (BOOL)canLiveUpdate;

@end
