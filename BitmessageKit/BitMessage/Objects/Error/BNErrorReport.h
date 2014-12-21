//
//  BNErrorReport.h
//  BitmessageKit
//
//  Created by Steve Dekorte on 12/15/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BNErrorReport : NSObject

@property (assign, nonatomic) BOOL debug;
@property (strong, nonatomic) NSString *reportAddress;
@property (strong, nonatomic) NSException *exception;
@property (strong, nonatomic) NSAlert *alert;

+ (BNErrorReport *)sharedBNErrorReport;
- (void)reportException:(NSException *)anException;

- (void)askUserToSend;
- (BOOL)send;

- (BOOL)isOpen;

@end
