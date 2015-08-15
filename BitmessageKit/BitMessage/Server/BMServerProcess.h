//
//  BMServerProcess.h
//  Bitmessage
//
//  Created by Steve Dekorte on 2/17/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TorServerKit/TorServerKit.h>
#import <SystemInfoKit/SystemInfoKit.h>
#import "BMKeysFile.h"

@interface BMServerProcess : NSObject

+ (BMServerProcess *)sharedBMServerProcess;

@property (assign, nonatomic) BOOL debug;
@property (assign, nonatomic) BOOL useTor;
@property (strong) TorProcess *torProcess;
@property (strong) SITask *bitmessageTask;
@property (strong) NSPipe *inpipe;
@property (strong, nonatomic) BMKeysFile *keysFile;
@property (strong) NSString *binaryVersion;
@property (assign, nonatomic) BOOL isLaunching;

// keys.dat config

- (NSString *)host;
- (NSNumber *)port;
- (NSNumber *)apiPort;
- (NSString *)username;
- (NSString *)password;

// running

- (void)launch;
- (BOOL)isRunning;
- (void)terminate;

- (BOOL)canConnect;
- (BOOL)hasFailed;


// hack around BitMessage server API's inability to do this for all identities
// this method shuts down the server and modifies the keys.dat file directly

- (BOOL)setLabel:(NSString *)aLabel onAddress:(NSString *)anAddress;

//- (NSString *)bundleDataPath;

- (NSString *)pybitmessageVersion;
- (NSString *)pyhtonBinaryVersion;

- (NSDictionary *)clientStatus;

@end
