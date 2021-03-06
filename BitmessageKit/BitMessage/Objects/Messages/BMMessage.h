//
//  BMMessage.h
//  Bitmarket
//
//  Created by Steve Dekorte on 1/25/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMNode.h"

@interface BMMessage : BMNode

@property (retain, nonatomic) NSNumber *encodingType;
@property (retain, nonatomic) NSString *toAddress;
@property (retain, nonatomic) NSString *msgid;
@property (retain, nonatomic) NSString *message;
@property (retain, nonatomic) NSString *fromAddress;
@property (retain, nonatomic) NSNumber *receivedTime; // RECEIVED
@property (retain, nonatomic) NSNumber *lastActionTime; // SENT
@property (retain, nonatomic) NSString *subject;
@property (retain, nonatomic) NSString *status; // SENT?
@property (retain, nonatomic) NSString *ackData; // SENT?
@property (assign, nonatomic) BOOL read; // SENT ONLY

+ (BMMessage *)withDict:(NSDictionary *)dict;

- (BOOL)isEqual:(id)object;

- (void)setDict:(NSDictionary *)dict;
- (NSDictionary *)dict;

- (NSString *)subjectString;
- (NSString *)messageString;

- (NSString *)fromAddressLabel;
- (NSString *)toAddressLabel;

- (NSDate *)date;
- (NSTimeInterval)ageInSeconds;


- (BOOL)send;
- (BOOL)broadcast;
- (void)delete;
- (void)justDelete;

- (void)markAsRead;
- (void)markAsUnread;
- (void)setReadState:(BOOL)isRead;


- (NSMutableAttributedString *)messageStringWithAttributes:(NSDictionary *)attributes;

- (void)show;
- (NSNumber *)estimatedSecondsForPow;

@end
