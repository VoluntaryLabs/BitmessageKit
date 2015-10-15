//
//  BMServerProcess.m
//  Bitmessage
//
//  Created by Steve Dekorte on 2/17/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//
// Notes:
// - some hacks in here to work around the missing bits of the bitmessage api

#import "BMServerProcess.h"
#import <FoundationCategoriesKit/FoundationCategoriesKit.h>
#import "BMProxyMessage.h"

@implementation BMServerProcess

static BMServerProcess *shared = nil;

+ (BMServerProcess *)sharedBMServerProcess
{
    if (!shared)
    {
        shared = [BMServerProcess alloc];
        shared = [shared init];
    }
    
    return shared;
}

- (id)init
{
    self = [super init];
    
    self.useTor = YES;
    self.debug = NO;
    
    if (self.useTor)
    {
        _torProcess = [[TorProcess alloc] init];
    }
    
    self.keysFile = [[BMKeysFile alloc] init];

    [self moveOldBitmessageFilesIfNeeded];

    [SIProcessKiller sharedSIProcessKiller]; // to end old processes

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(terminate)
                                                 name:NSApplicationWillTerminateNotification
                                               object:nil];
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)moveOldBitmessageFilesIfNeeded
{
    NSString *oldDataPath = [[NSFileManager defaultManager] applicationSupportDirectory];
    NSString *newDataPath = [self bundleDataPath];

    NSArray *fileNames = @[@"debug.log",
                           @"keys.dat",
                           @"keys_backups",
                           @"knownnodes.dat",
                           @"messages.dat",
                           @"readMessagesDB.json",
                           @"deletedMessagesDB.json"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSString *fileName in fileNames)
    {
        BOOL isDir;
        NSString *filePath = [oldDataPath stringByAppendingPathComponent:fileName];
        
        if ([fm fileExistsAtPath:filePath isDirectory:&isDir])
        {
            NSString *newFilePath = [newDataPath stringByAppendingPathComponent:fileName];
            NSError *error;
            [fm moveItemAtPath:filePath toPath:newFilePath error:&error];
            
            if (error)
            {
                NSLog(@"warning: %@", error);
            }
        }
    }
}

/*
- (NSBundle *)bundle
{
    return [NSBundle bundleForClass:self.class];
}

- (NSString *)justBundleDataPath
{
    NSString *supportFolder = [[NSFileManager defaultManager] applicationSupportDirectory];
    NSString *bundleName = [self.bundle.bundleIdentifier componentsSeparatedByString:@"."].lastObject;
    NSString *path = [supportFolder stringByAppendingPathComponent:bundleName];
    return path;
}

- (NSString *)bundleDataPath
{
    NSString *path = self.justBundleDataPath;
        
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    return path;
}
 */

- (NSString *)pybitmessageVersion
{
    NSString *versionFilePath = [self.bundle pathForResource:@"build_osx" ofType:@"py" inDirectory: @"pybitmessage"];
    
    NSError *error;
    NSString *contents = [NSString stringWithContentsOfFile:versionFilePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error == nil)
    {
        NSArray *lines = [contents componentsSeparatedByString:@"\n"];
        
        for (NSString *line in lines)
        {
            if ([line hasPrefix:@"version"])
            {
                NSString *version = [[line after:@"\""] before:@"\""];
                return version;
            }
        }
    }
    
    return nil;
}


// keys.dat config

- (NSString *)host
{
    return @"127.0.0.1";
}

- (NSNumber *)port
{
    return self.keysFile.port.asNumber;
}

- (NSNumber *)apiPort
{
    return self.keysFile.apiport.asNumber;
}

- (NSString *)username
{
    return self.keysFile.apiusername;
}

- (NSString *)password
{
    return self.keysFile.apipassword;
}

// keys.dat

- (void)setupKeysDat
{
    [self.keysFile backup];
    [self.keysFile setupForDaemon];
    
    if (!self.useTor)
    {
        [self.keysFile setupForNonTor];
        NSLog(@"*** WARNING: setting up Bitmessage for non Tor use");
        [self.keysFile setSOCKSPort:@0];
    }
    else
    {
        [self.keysFile setupForTor];
        _torProcess.debug = self.debug;
        assert(_torProcess.isRunning);
        assert(_torProcess.torSocksPort != nil); // need to launch tor first so it picks a port
        [self.keysFile setSOCKSPort:_torProcess.torSocksPort];
        //NSLog(@"*** setup Bitmessage for Tor on port %@", _torProcess.torSocksPort);
    }
    
    SIPort *startPort = [SIPort portWithNumber:_torProcess.torSocksPort];
    SIPort *port = startPort.nextBindablePort;
    SIPort *apiPort = port.nextBindablePort;
    
    // chose open ports
    [self.keysFile setPort:port.portNumber];
    [self.keysFile setApiPort:apiPort.portNumber];
    
    // randomize login
    [self.keysFile setApiUsername:NSNumber.entropyNumber.asUnsignedIntegerString];
    [self.keysFile setApiPassword:NSNumber.entropyNumber.asUnsignedIntegerString];
    
    [self.keysFile setDefaultnoncetrialsperbyte:@320];
    [self.keysFile setMaxCores:@1];
}

- (void)assertIsRunning
{
    if (!self.isRunning)
    {
        [NSException raise:@"Server not running" format:@""];
    }
}

- (BOOL)setLabel:(NSString *)aLabel onAddress:(NSString *)anAddress
{
    [self assertIsRunning];
    [NSNotificationCenter.defaultCenter postNotificationName:@"ProgressPushNotification" object:self];
    [self terminate];
    [self.keysFile setLabel:aLabel onAddress:anAddress];
    [self launch];
    [NSNotificationCenter.defaultCenter postNotificationName:@"ProgressPopNotification" object:self];
    return YES;
}

- (void)launch
{
   if (self.isRunning)
    {
        NSLog(@"Attempted to launch BM server more than once.");
        return;
    }

    self.isLaunching = YES;

    // Launch tor client
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"ProgressPushNotification" object:self];
    
    if (self.useTor && !self.torProcess.isRunning)
    {
        [self.torProcess launch];
    }
    
    BOOL hasRunBefore = self.keysFile.doesExist;
    
    if (hasRunBefore)
    {
        [self setupKeysDat];
    }
    
    if (self.debug)
    {
        NSLog(@"launching Bitmessage with keys.dat:");
        NSLog(@"    port: %@", self.port);
        NSLog(@"    apiport: %@", self.apiPort);
        //NSLog(@"    username: %@", self.username);
        //NSLog(@"    password: %@", self.password);
    }
    
    _bitmessageTask = [[SITask alloc] init];
    _inpipe = [NSPipe pipe];
    NSDictionary *environmentDict = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary *environment = [NSMutableDictionary dictionaryWithDictionary:environmentDict];
    
    if (hasRunBefore)
    {
        [environment setObject:self.username forKey:@"PYBITMESSAGE_USER"];
        [environment setObject:self.password forKey:@"PYBITMESSAGE_PASSWORD"];
    }
    else
    {
        [environment setObject:@"default" forKey:@"PYBITMESSAGE_USER"];
        [environment setObject:@"default" forKey:@"PYBITMESSAGE_PASSWORD"];
    }
    
    [environment setObject:self.bundleDataPath forKey:@"BITMESSAGE_HOME"];

    [_bitmessageTask setEnvironment:environment];
    
    NSBundle *mainBundle = [NSBundle bundleForClass:self.class];
    NSString *pythonPath       = [mainBundle pathForResource:@"python" ofType:@"exe" inDirectory: @"static-python"];
    NSString *pybitmessagePath = [mainBundle pathForResource:@"bitmessagemain" ofType:@"py" inDirectory: @"pybitmessage"];
    [_bitmessageTask setLaunchPath:pythonPath];
    
    if (self.debug || !hasRunBefore)
    {
        [_bitmessageTask setStandardOutput:[NSFileHandle fileHandleWithStandardOutput]];
        [_bitmessageTask setStandardError:[NSFileHandle fileHandleWithStandardOutput]];
    }
    else
    {
        [_bitmessageTask setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
        [_bitmessageTask setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    }
    
    [_bitmessageTask setArguments:@[pybitmessagePath]];
   
    if (self.debug)
    {
        NSLog(@"*** launching _pyBitmessage ***");
    }
    
    if (hasRunBefore)
    {
        [_bitmessageTask addWaitOnConnectToPortNumber:self.apiPort];
    }
    
    [_bitmessageTask launch];
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"ProgressPopNotification" object:self];
    
    if (!hasRunBefore)
    {
        NSLog(@"first launch - relaunching in 3 seconds to complete keys.dat setup...");
        sleep(3);
        [self terminate];
        [_bitmessageTask.task waitUntilExit];
        [self launch];
        return;
    }
    
    if (![_bitmessageTask isRunning])
    {
        NSLog(@"pybitmessage task not running after launch");
    }
    else
    {
        [self waitOnConnect];
    }
}

- (BOOL)waitOnConnect
{
    [NSNotificationCenter.defaultCenter postNotificationName:@"ProgressPushNotification"
                                                      object:self];
    
    NSTimeInterval waitInterval = .1;
    NSTimeInterval maxWait = 20;
    
    for (int i = 0; i < maxWait/waitInterval; i ++)
    {
        if ([self canConnect])
        {
            if (self.debug)
            {
                NSLog(@"connected to server");
            }
            
            [NSNotificationCenter.defaultCenter postNotificationName:@"ProgressPopNotification"
                                                              object:self];
            self.isLaunching = NO;
            return YES;
        }
        
        NSLog(@"waiting to connect to server...");
        //sleep(1);
        [NSDate waitFor:waitInterval];
    }

    self.isLaunching = NO;

    [NSException raise:@"unable to connect to Bitmessage server" format:@""];
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"ProgressPopNotification" object:self];

    return NO;
}

- (void)terminate
{
    if (_bitmessageTask)
    {
        NSLog(@"Killing bitmessage process...");
        [_bitmessageTask terminate];
        self.bitmessageTask = nil;
    }

    [self.torProcess terminate];
}

- (BOOL)isRunning
{
    if (!_bitmessageTask.isRunning)
    {
        return NO;
    }
    
    if (self.useTor && !_torProcess.isRunning)
    {
        return NO;
    }
    
    return YES;
}

- (BOOL)canConnect
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"listAddressBookEntries"];
    NSArray *params = [NSArray array];
    [message setParameters:params];
    [message sendSync];
    
    NSObject *response = [message parsedResponseValue];
    //NSLog(@"canConnect response = '%@'", response);
    return response && [response isKindOfClass:NSDictionary.class];
}

- (NSString *)pythonExePath
{
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    return [bundle pathForResource:@"python" ofType:@"exe" inDirectory: @"static-python"];
}

- (NSString *)pyhtonBinaryVersion
{
    if (!_binaryVersion)
    {
        //_binaryVersion = @"2.7.5+";
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.pythonExePath])
        {
            return @"error";
        }
        
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:self.pythonExePath];
        
        NSPipe *outPipe = [NSPipe pipe];
        
        [task setStandardInput: [NSFileHandle fileHandleWithNullDevice]];
        [task setStandardOutput:outPipe];
        [task setStandardError:outPipe];
        
        NSMutableArray *args = [NSMutableArray array];
        [args addObject:@"--version"];
        [task setArguments:args];
        
        @try
        {
            [task launch];
            [task waitUntilExit];
        }
        @catch (NSException *exception)
        {
            NSLog(@"%@", exception);
            [task terminate];
            return @"error";
        }
        
        NSData *theData = [outPipe fileHandleForReading].availableData;
        _binaryVersion = [[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding];
        
        _binaryVersion = [_binaryVersion after:@"Python"].strip;
    }
    
    return _binaryVersion;
}

- (BOOL)hasFailed
{
    return !self.isLaunching && !self.isRunning;
}

- (NSDictionary *)clientStatus
{
    /*
    Returns the 
        softwareName, 
        softwareVersion, 
        networkStatus, 
        networkConnections, 
        numberOfPubkeysProcessed, 
        numberOfMessagesProcessed, and 
        numberOfBroadcastsProcessed. 
     
        networkStatus will be one of these strings: 
            "notConnected", 
            "connectedButHaveNotReceivedIncomingConnections", or 
            "connectedAndReceivingIncomingConnections".
     */

    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"clientStatus"];
    
    //message.debug = YES;
    [message sendSync];
    
    id result =  [message parsedResponseValue];
    //NSLog(@"clientStatus = '%@'", result);
    
    return result;
}

@end
