//
//  BMKeysFile.h
//  Bitmessage
//
//  Created by Steve Dekorte on 2/22/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMKeysFile : NSObject

@property (strong) NSMutableDictionary *dict;

- (void)setupForDaemon;
- (void)setupForNonDaemon; // call this when shutting down
- (void)setupForTor;
- (void)setupForNonTor;

- (void)setApiPort:(NSNumber *)aPort;
- (NSString *)apiport;

- (void)setPort:(NSNumber *)aPort;
- (NSString *)port;

- (void)setSOCKSPort:(NSNumber *)aString;
- (NSString *)socksport;

- (void)setApiUsername:(NSString *)aString;
- (NSString *)apiusername;

- (void)setApiPassword:(NSString *)aString;
- (NSString *)apipassword;

- (void)setDefaultnoncetrialsperbyte:(NSNumber *)aPow;
- (NSNumber *)defaultnoncetrialsperbyte;


- (BOOL)setLabel:(NSString *)aLabel onAddress:(NSString *)anAddress;

- (BOOL)doesExist;

- (void)backup;

@end
