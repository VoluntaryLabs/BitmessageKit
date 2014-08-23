//
//  BMServerProcess.m
//  Bitmessage
//
//  Created by Steve Dekorte on 2/17/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
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
    
    // Get custom ports to prevent conflicts between bit* apps
    NSBundle *mainBundle = [NSBundle mainBundle];
    self.port    = [[mainBundle objectForInfoDictionaryKey:@"BitmessagePort"] intValue];
    self.apiPort = [[mainBundle objectForInfoDictionaryKey:@"BitmessageAPIPort"] intValue];
    self.host     = @"127.0.0.1";
    self.username = @"bitmarket"; // this will get replaced with something random on startup
    self.password = @"87342873428901648473823"; // this will get replaced with something random on startup
    
    self.dataPath =
        [NSString stringWithString:[[NSFileManager defaultManager] applicationSupportDirectory]];

    _torProcess = [[BMTorProcess alloc] init];
    _torProcess.torPort = [mainBundle objectForInfoDictionaryKey:@"TorPort"];
    _torProcess.serverDataFolder = self.serverDataFolder;
    
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
    [self.keysFile setupForTor];
    [self.keysFile setSOCKSPort: _torProcess.torPort];
    [self.keysFile setApiPort:self.apiPort];
    [self.keysFile setPort:self.port];
    [self randomizeLogin];
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

/*
- (void)launchTor
{
    // Check for pre-existing process
    NSString *torPidFilePath = [[[self serverDataFolder] stringByAppendingPathComponent:@"tor"] stringByAppendingPathExtension:@"pid"];
    NSString *torPid = [[NSString alloc] initWithContentsOfFile:torPidFilePath encoding:NSUTF8StringEncoding error:NULL];
    
    if (nil != torPid)
    {
        BOOL processExists = [BMProcesses.sharedBMProcesses isProcessRunningWithName:@"tor" pid:[torPid intValue]];
        if(processExists)
        {
            NSLog(@"killing old tor process with pid: %@", torPid);

            // Kill process
            kill( [torPid intValue], SIGKILL);
        }
    }
    
    _torTask = [[NSTask alloc] init];
    _inpipe = [NSPipe pipe];
    
    // Set the path to the python executable
    NSBundle *mainBundle = [NSBundle bundleForClass:self.class];
    NSString * torPath = [mainBundle pathForResource:@"tor" ofType:@"" inDirectory: @"tor"];
    NSString * torConfigPath = [mainBundle pathForResource:@"torrc" ofType:@"" inDirectory: @"tor"];
    NSString * torDataDirectory = [[self serverDataFolder] stringByAppendingPathComponent: @".tor"];
    [_torTask setLaunchPath:torPath];
    
    NSFileHandle *nullFileHandle = [NSFileHandle fileHandleWithNullDevice];
    [_torTask setStandardOutput:nullFileHandle];
    [_torTask setStandardInput: (NSFileHandle *) _inpipe];
    [_torTask setStandardError:nullFileHandle];
    
    [_torTask setArguments:@[ @"-f", torConfigPath, @"--DataDirectory", torDataDirectory, @"--PidFile", torPidFilePath, @"--SOCKSPort", self.torPort ]];
    
    [_torTask launch];
    
    if (![_torTask isRunning])
    {
        NSLog(@"tor task not running after launch");
    }
}
*/

- (void)launch
{
    if (self.isRunning)
    {
        NSLog(@"Attempted to launch BM server more than once.");
        return;
    }
    
    // Launch tor client
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"ProgressPush" object:self];
    
    [self.torProcess launch];
    
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
    
    NSFileHandle *nullFileHandle = [NSFileHandle fileHandleWithNullDevice];
    [_pyBitmessageTask setStandardOutput:nullFileHandle];
    [_pyBitmessageTask setStandardInput: (NSFileHandle *) _inpipe];
    [_pyBitmessageTask setStandardError:nullFileHandle];
    
    [_pyBitmessageTask setArguments:@[ pybitmessagePath ]];
   
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
    //[self.keysFile setupForNonDaemon];
    //[self.keysFile setupForNonTor];

    [self.torProcess terminate];
}

- (BOOL)isRunning
{
    return (_pyBitmessageTask && [_pyBitmessageTask isRunning]);
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
