//
//  BMServerProcess.m
//  Bitmessage
//
//  Created by Steve Dekorte on 2/17/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMServerProcess.h"
#import "BMProcesses.h"
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
    self.debug = YES;
    
    // Get custom ports to prevent conflicts between bit* apps
    NSBundle *mainBundle = [NSBundle mainBundle];
    self.port    = [[mainBundle objectForInfoDictionaryKey:@"BitmessagePort"] intValue];
    self.apiPort = [[mainBundle objectForInfoDictionaryKey:@"BitmessageAPIPort"] intValue];
    self.host     = @"127.0.0.1";
    self.username = @"bitmarket"; // this will get replaced with something random on startup
    self.password = @"87342873428901648473823"; // this will get replaced with something random on startup
    
    self.dataPath =
        [NSString stringWithString:[[NSFileManager defaultManager] applicationSupportDirectory]];

    if (self.useTor)
    {
        _torProcess = [[BMTorProcess alloc] init];
        _torProcess.torPort = [mainBundle objectForInfoDictionaryKey:@"TorPort"];
        assert(_torProcess.torPort != nil);
        _torProcess.serverDataFolder = self.serverDataFolder;
    }
    
    self.keysFile = [[BMKeysFile alloc] init];
    //[self setupKeysDat];
    
    return self;
}

- (long)entropy
{
    // yeah, this isn't great
    unsigned int entropy = (unsigned int)time(NULL) + (unsigned int)clock();
    srandom(entropy);
    return random();
}

- (void)randomizeLogin
{
    self.username = [NSString stringWithFormat:@"%i", (int)self.entropy];
    self.password = [NSString stringWithFormat:@"%i", (int)self.entropy];
    [self.keysFile setApiUsername:self.username];
    [self.keysFile setApiPassword:self.password];
}

- (void)setupKeysDat
{
    [self.keysFile backup];
    [self.keysFile setupForDaemon];
    
    if (!self.useTor)
    {
        [self.keysFile setupForNonTor];
        NSLog(@"*** setup Bitmessage for non tor use");
        [self.keysFile setSOCKSPort: @""];
    }
    else
    {
        [self.keysFile setupForTor];
        [self.keysFile setSOCKSPort: _torProcess.torPort];
        NSLog(@"*** setup Bitmessage for tor on port %@", _torProcess.torPort);
    }
    
    [self.keysFile setApiPort:self.apiPort];
    [self.keysFile setPort:self.port];
    [self randomizeLogin];
    [self.keysFile setPow:1024];
}

- (void)assertIsRunning
{
    if (!self.isRunning)
    {
        [NSException raise:@"Server not running" format:nil];
    }
}

- (BOOL)setLabel:(NSString *)aLabel onAddress:(NSString *)anAddress
{
    [self assertIsRunning];
    [NSNotificationCenter.defaultCenter postNotificationName:@"ProgressPush" object:self];
    [self terminate];
    [self.keysFile setLabel:aLabel onAddress:anAddress];
    [self launch];
    [NSNotificationCenter.defaultCenter postNotificationName:@"ProgressPop" object:self];
    return YES;
}

- (void)launch
{
    if (self.isRunning)
    {
        NSLog(@"Attempted to launch BM server more than once.");
        return;
    }
    
    // Launch tor client
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"ProgressPush" object:self];
    
    if (self.useTor && !self.torProcess.isRunning)
    {
        [self.torProcess launch];

        if (!self.torProcess.isRunning)
        {
            [NSException raise:@"tor not running" format:nil];
        }
    }
    

    
    BOOL hasRunBefore = self.keysFile.doesExist;
    
    if (hasRunBefore)
    {
        [self setupKeysDat];
    }
    
    _pyBitmessageTask = [[NSTask alloc] init];
    _inpipe = [NSPipe pipe];
    NSDictionary *environmentDict = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary *environment = [NSMutableDictionary dictionaryWithDictionary:environmentDict];
    NSLog(@"%@", [environment valueForKey:@"PATH"]);
    
    // Set environment variables containing api username and password
    [environment setObject:self.username forKey:@"PYBITMESSAGE_USER"];
    [environment setObject:self.password forKey:@"PYBITMESSAGE_PASSWORD"];
    [environment setObject:self.dataPath forKey:@"BITMESSAGE_HOME"];
   /*
    self.host     = @"127.0.0.1";
    self.port     = 8444+10;
    self.apiPort  = 8442+10;
    self.username = @"bitmarket"; // this will get replaced with something random on startup
    self.password = @"87342873428901648473823"; // this will get replaced with something random on startup
 */
    
    [_pyBitmessageTask setEnvironment: environment];
    
    // Set the path to the python executable
    NSBundle *mainBundle = [NSBundle bundleForClass:self.class];
    NSString * pythonPath = [mainBundle pathForResource:@"python" ofType:@"exe" inDirectory: @"static-python"];
    NSString * pybitmessagePath = [mainBundle pathForResource:@"bitmessagemain" ofType:@"py" inDirectory: @"pybitmessage"];
    [_pyBitmessageTask setLaunchPath:pythonPath];
    
    [_pyBitmessageTask setStandardInput: (NSFileHandle *) _inpipe];
    
    if (self.debug)
    {
        [_pyBitmessageTask setStandardOutput:[NSFileHandle fileHandleWithStandardOutput]];
        [_pyBitmessageTask setStandardError:[NSFileHandle fileHandleWithStandardOutput]];
    }
    else
    {
        [_pyBitmessageTask setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
        [_pyBitmessageTask setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    }
    
    [_pyBitmessageTask setArguments:@[pybitmessagePath]];
   
    NSLog(@"*** launching _pyBitmessage ***");
    
    [_pyBitmessageTask launch];
    [NSNotificationCenter.defaultCenter postNotificationName:@"ProgressPop" object:self];
    
    if (!hasRunBefore)
    {
        NSLog(@"first launch - relaunching in 3 seconds to complete keys.dat setup...");
        sleep(3);
        [self terminate];
        sleep(3); // would be nice to wait for shutdown instead
        [self launch];
        return;
    }
    
    if (![_pyBitmessageTask isRunning])
    {
        NSLog(@"pybitmessage task not running after launch");
    }
    else
    {
        sleep(2);
        [self waitOnConnect];
    }
}

- (BOOL)waitOnConnect
{
    [NSNotificationCenter.defaultCenter postNotificationName:@"ProgressPush" object:self];
    
    for (int i = 0; i < 100; i ++)
    {
        if ([self canConnect])
        {
            NSLog(@"connected to server");
            [NSNotificationCenter.defaultCenter postNotificationName:@"ProgressPop" object:self];
            return YES;
        }
        
        NSLog(@"waiting to connect to server...");
        sleep(1);
    }
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"ProgressPop" object:self];
    
    return NO;
}

- (void)terminate
{
    NSLog(@"Killing pybitmessage process...");
    [_pyBitmessageTask terminate];
    self.pyBitmessageTask = nil;

    if (self.torProcess)
    {
        [self.torProcess terminate];
    }
}

- (BOOL)isRunning
{
    if (!_pyBitmessageTask.isRunning)
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
    [message setMethodName:@"helloWorld"];
    NSArray *params = [NSArray arrayWithObjects:@"hello", @"world", nil];
    [message setParameters:params];
    //message.debug = YES;
    [message sendSync];
    NSString *response = [message responseValue];
    return [response isEqualToString:@"hello-world"];
}

- (NSString *)serverDataFolder
{
    return self.dataPath;
}

@end
