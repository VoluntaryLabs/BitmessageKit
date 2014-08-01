//
//  BMServerProcess.m
//  Bitmessage
//
//  Created by Steve Dekorte on 2/17/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import "BMServerProcess.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#include <unistd.h>
#include <errno.h>
#import <FoundationCategoriesKit/FoundationCategoriesKit.h>
#import "BMProxyMessage.h"

@implementation BMServerProcess

static BMServerProcess *shared = nil;

typedef struct kinfo_proc kinfo_proc;

static int GetBSDProcessList(kinfo_proc **procList, size_t *procCount)
// Returns a list of all BSD processes on the system.  This routine
// allocates the list and puts it in *procList and a count of the
// number of entries in *procCount.  You are responsible for freeing
// this list (use "free" from System framework).
// On success, the function returns 0.
// On error, the function returns a BSD errno value.
{
    int                 err;
    kinfo_proc *        result;
    bool                done;
    static const int    name[] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    // Declaring name as const requires us to cast it when passing it to
    // sysctl because the prototype doesn't include the const modifier.
    size_t              length;
    
    assert( procList != NULL);
    assert(*procList == NULL);
    assert(procCount != NULL);
    
    *procCount = 0;
    
    // We start by calling sysctl with result == NULL and length == 0.
    // That will succeed, and set length to the appropriate length.
    // We then allocate a buffer of that size and call sysctl again
    // with that buffer.  If that succeeds, we're done.  If that fails
    // with ENOMEM, we have to throw away our buffer and loop.  Note
    // that the loop causes use to call sysctl with NULL again; this
    // is necessary because the ENOMEM failure case sets length to
    // the amount of data returned, not the amount of data that
    // could have been returned.
    
    result = NULL;
    done = false;
    do {
        assert(result == NULL);
        
        // Call sysctl with a NULL buffer.
        
        length = 0;
        err = sysctl( (int *) name, (sizeof(name) / sizeof(*name)) - 1,
                     NULL, &length,
                     NULL, 0);
        if (err == -1) {
            err = errno;
        }
        
        // Allocate an appropriately sized buffer based on the results
        // from the previous call.
        
        if (err == 0) {
            result = malloc(length);
            if (result == NULL) {
                err = ENOMEM;
            }
        }
        
        // Call sysctl again with the new buffer.  If we get an ENOMEM
        // error, toss away our buffer and start again.
        
        if (err == 0) {
            err = sysctl( (int *) name, (sizeof(name) / sizeof(*name)) - 1,
                         result, &length,
                         NULL, 0);
            if (err == -1) {
                err = errno;
            }
            if (err == 0) {
                done = true;
            } else if (err == ENOMEM) {
                assert(result != NULL);
                free(result);
                result = NULL;
                err = 0;
            }
        }
    } while (err == 0 && ! done);
    
    // Clean up and establish post conditions.
    
    if (err != 0 && result != NULL) {
        free(result);
        result = NULL;
    }
    *procList = result;
    if (err == 0) {
        *procCount = length / sizeof(kinfo_proc);
    }
    
    assert( (err == 0) == (*procList != NULL) );
    
    return err;
}



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
    NSBundle* mainBundle = [NSBundle mainBundle];
    self.torPort = [mainBundle objectForInfoDictionaryKey:@"TorPort"];
    self.port = [[mainBundle objectForInfoDictionaryKey:@"BitmessagePort"] intValue];
    self.apiPort = [[mainBundle objectForInfoDictionaryKey:@"BitmessageAPIPort"] intValue];
    self.host     = @"127.0.0.1";
    self.username = @"bitmarket"; // this will get replaced with something random on startup
    self.password = @"87342873428901648473823"; // this will get replaced with something random on startup
    
    self.dataPath =
        [NSString stringWithString:[[NSFileManager defaultManager] applicationSupportDirectory]];

    
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
    [self.keysFile setSOCKSPort: self.torPort];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ProgressPush" object:self];
    [self terminate];
    [self.keysFile setLabel:aLabel onAddress:anAddress];
    [self launch];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ProgressPop" object:self];
    return YES;
}

- (void)launchTor
{
    // Check for pre-existing process
    NSString *torPidFilePath = [[[self serverDataFolder] stringByAppendingPathComponent: @"tor"] stringByAppendingPathExtension: @"pid"];
    NSString *torPid = [[NSString alloc] initWithContentsOfFile: torPidFilePath encoding: NSUTF8StringEncoding error:NULL];
    
    if(nil != torPid) {
        BOOL processExists = [self isProcessRunningWithName:@"tor" pid:[torPid intValue]];
        if(processExists) {
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

- (BOOL)isProcessRunningWithName:(NSString *)name pid:(pid_t)pid;
{
    kinfo_proc *mylist = NULL;
    size_t mycount = 0;
    GetBSDProcessList(&mylist, &mycount);
    int k;
    for(k = 0; k < mycount; k++) {
        kinfo_proc *proc = NULL;
        proc = &mylist[k];
        if(proc->kp_proc.p_pid == pid) {
            NSString *fullName = [[self infoForPID:proc->kp_proc.p_pid] objectForKey:(id)kCFBundleNameKey];
            if (fullName == nil) fullName = [NSString stringWithFormat:@"%s",proc->kp_proc.p_comm];
            if([fullName isEqualToString:name]) {
                free(mylist);
                return YES;
            }
        }
    }
    free(mylist);
    return NO;
}



- (NSDictionary *)infoForPID:(pid_t)pid
{
    NSDictionary *ret = nil;
    ProcessSerialNumber psn = { kNoProcess, kNoProcess };
    if (GetProcessForPID(pid, &psn) == noErr) {
        CFDictionaryRef cfDict = ProcessInformationCopyDictionary(&psn,kProcessDictionaryIncludeAllInformationMask);
        ret = [NSDictionary dictionaryWithDictionary:(__bridge NSDictionary *)cfDict];
        CFRelease(cfDict);
    }
    return ret;
}

- (void)launch
{
    if (self.isRunning)
    {
        NSLog(@"Attempted to launch BM server more than once.");
        return;
    }
    
    // Launch tor client
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ProgressPush" object:self];
    [self launchTor];
    
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ProgressPop" object:self];
    
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ProgressPush" object:self];
    
    for (int i = 0; i < 100; i ++)
    {
        if ([self canConnect])
        {
            NSLog(@"connected to server");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ProgressPop" object:self];
            return YES;
        }
        
        NSLog(@"waiting to connect to server...");
        sleep(1);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ProgressPop" object:self];
    
    return NO;
}

- (void)terminate
{
    NSLog(@"Killing pybitmessage process...");
    [_pyBitmessageTask terminate];
    self.pyBitmessageTask = nil;
    //[self.keysFile setupForNonDaemon];
    //[self.keysFile setupForNonTor];

    NSLog(@"Killing tor process...");
    [_torTask terminate];
    self.torTask = nil;
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
