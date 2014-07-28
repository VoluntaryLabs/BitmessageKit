//
//  BMKeysFile.h
//  Bitmessage
//
//  Created by Steve Dekorte on 2/22/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMKeysFile : NSObject

@property (strong) NSMutableDictionary *dict;

- (void)setupForDaemon;
- (void)setupForNonDaemon; // call this when shutting down
- (void)setupForTor;
- (void)setupForNonTor;

- (BOOL)setApiPort:(NSUInteger)aPort;
- (BOOL)setPort:(NSUInteger)aPort;
- (BOOL)setSOCKSPort:(NSString *)aString;
- (BOOL)setApiUsername:(NSString *)aString;
- (BOOL)setApiPassword:(NSString *)aString;
- (BOOL)setLabel:(NSString *)aLabel onAddress:(NSString *)anAddress;

- (BOOL)doesExist;

- (void)backup;

@end
