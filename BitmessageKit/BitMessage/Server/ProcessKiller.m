//
//  ProcessKiller.m
//  BitmessageKit
//
//  Created by Steve Dekorte on 10/3/14.
//  Copyright (c) 2014 Adam Thorsen. All rights reserved.
//

#import "ProcessKiller.h"
#import "BMProcesses.h"

@implementation ProcessKiller

static ProcessKiller *sharedProcessKiller = nil;

+ (ProcessKiller *)sharedProcessKiller
{
    if (!sharedProcessKiller)
    {
        sharedProcessKiller = [[ProcessKiller alloc] init];
        [sharedProcessKiller killOldTasks];
    }
    
    return sharedProcessKiller;
}

- (NSString *)userDefaultsKey
{
    return @"ProcessKiller";
}

- (NSDictionary *)oldTasksDict
{
    NSDictionary *dict = [NSUserDefaults.standardUserDefaults dictionaryForKey:self.userDefaultsKey];
    
    if (dict)
    {
        return dict;
    }
    
    return [NSDictionary dictionary];
}

- (void)setOldTasksDict:(NSDictionary *)aDict
{
    [NSUserDefaults.standardUserDefaults setObject:aDict forKey:self.userDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)onRestartKillTask:(NSTask *)aTask
{
    NSString *processName = [aTask.launchPath lastPathComponent];
    NSNumber *processId = [NSNumber numberWithInt:aTask.processIdentifier];
    NSMutableDictionary *oldTasksDict = self.oldTasksDict.mutableCopy;
    
    // what to do about multiple processes with the same name?
    // index by processId?
    
    [oldTasksDict setObject:processId forKey:processName];
    
    [self setOldTasksDict:oldTasksDict];
}

- (void)killOldTasks
{
    NSDictionary *dict = self.oldTasksDict;
    NSMutableDictionary *newDict = self.oldTasksDict.mutableCopy;
    
    for (NSString *processName in dict.allKeys)
    {
        NSNumber *processId = [dict objectForKey:processName];
        
        BOOL processExists = [BMProcesses.sharedBMProcesses isProcessRunningWithName:processName pid:processId.intValue];
        
        if(processExists)
        {
            NSLog(@"killing old process '%@' with pid: %@", processName, processId);
            kill([processId intValue], SIGKILL);
        }
        else
        {
            [newDict removeObjectForKey:processName];
            continue;
        }
        
        processExists = [BMProcesses.sharedBMProcesses isProcessRunningWithName:processName pid:processId.intValue];
        
        if (processExists)
        {
            sleep(1);
            [NSException raise:@"Unable to kill process" format:nil];
        }
        else
        {
            [newDict removeObjectForKey:processName];
        }
    }
    
    [self setOldTasksDict:newDict];
}

@end
