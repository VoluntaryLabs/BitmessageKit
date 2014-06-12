//
//  BMServerProcess.h
//  Bitmessage
//
//  Created by Steve Dekorte on 2/17/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMKeysFile.h"

@interface BMServerProcess : NSObject

+ (BMServerProcess *)sharedBMServerProcess;

@property (strong) NSTask *torTask;
@property (strong) NSTask *pyBitmessageTask;
@property (strong) NSPipe *inpipe;

@property (retain, nonatomic) NSString *host;
@property (assign) int port;
@property (assign) int apiPort;

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) BMKeysFile *keysFile;
@property (strong, nonatomic) NSString *dataPath;


- (void)launch;
- (void)launchTor;
- (BOOL)isProcessRunningWithName:(NSString *)name pid:(pid_t)pid;
- (BOOL)isRunning;
- (void)terminate;
- (BOOL)canConnect;


// hack around BitMessage server API's inability to do this for all identities
// this method shuts down the server and modifies the keys.dat file directly

- (BOOL)setLabel:(NSString *)aLabel onAddress:(NSString *)anAddress;

- (NSString *)serverDataFolder;

@end
