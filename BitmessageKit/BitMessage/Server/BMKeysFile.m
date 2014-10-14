//
//  BMKeysFile.m
//  Bitmessage
//
//  Created by Steve Dekorte on 2/22/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMKeysFile.h"
#import <FoundationCategoriesKit/FoundationCategoriesKit.h>
#import "BMServerProcess.h"


@implementation BMKeysFile

- (NSString *)folder
{
    return [[BMServerProcess sharedBMServerProcess] bundleDataPath];
}

- (NSString *)path
{
    return [self.folder stringByAppendingPathComponent:@"keys.dat"];
}

- (void)checkServer
{
    if ([[BMServerProcess sharedBMServerProcess] isRunning])
    {
        [NSException raise:@"Unsafe Request" format:@"Attempt to write keys.day while server running."];
    }
}

- (NSString *)readString
{
    [self checkServer];

    NSError *error;
    NSStringEncoding encoding;
    NSString *data = [NSString stringWithContentsOfFile:[NSURL fileURLWithPath:self.path]
                                           usedEncoding:&encoding error:&error];
    return data;
}

- (void)writeString:(NSString *)data
{
    [self checkServer];
    NSError *error;
    [data writeToFile:self.path atomically:YES encoding:NSUTF8StringEncoding error:&error];
}

- (void)read
{
    NSArray *lines = [[self readString] componentsSeparatedByString:@"\n"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *subDict = nil;
    
    for (NSString *line in lines)
    {
        //NSLog(@"line : '%@'", line);
        
        if ([line hasPrefix:@"["])
        {
            subDict = [NSMutableDictionary dictionary];
            [dict setObject:subDict forKey:line];
        }
        else
        {
            if ([[line strip] length])
            {
                NSArray *parts = [line componentsSeparatedByString:@"="];
                NSString *key = [[parts objectAtIndex:0] strip];
                NSString *value = @"";
                if (parts.count > 1)
                {
                    value = [[parts objectAtIndex:1] strip];
                }
                [subDict setObject:value forKey:key];
            }
        }
    }
    
    //NSLog(@"read keys: %@", dict);
    
    self.dict = dict;
}

- (void)write
{
    NSMutableString *data = [NSMutableString string];
    
    NSDictionary *settings = [self.dict objectForKey:self.settingsKey];
    assert(settings != nil);
    
    if (settings)
    {
//        NSLog(@"will write %lu settings", (unsigned long)settings.allKeys.count);
    }
    
    for (NSString *key in [self.dict allKeys])
    {
        NSDictionary *subDict = [self.dict objectForKey:key];
        [data appendString:@"\n"];
        [data appendString:key];
        //printf(">%s", key.UTF8String);
        [data appendString:@"\n"];
        
        for (NSString *subKey in [subDict allKeys])
        {
            NSDictionary *subValue = [subDict objectForKey:subKey];
            NSString *pair = [NSString stringWithFormat:@"%@ = %@\n", subKey, subValue];
            [data appendString:pair];
            //printf(">    %s", pair.UTF8String);

        }
    }
    
    //printf("\n\n----------------------------------------------------------\n\n");
    //printf("    '%s", data.UTF8String);

    [self writeString:data];
}

- (NSString *)settingsKey
{
    return @"[bitmessagesettings]";
}

- (NSMutableDictionary *)settings
{
    NSMutableDictionary *settings = [self.dict objectForKey:self.settingsKey];
    
    if (!settings)
    {
        settings = [NSMutableDictionary dictionary];
        [self.dict setObject:settings forKey:self.settingsKey];
    }
    
    return settings;
}

// --- setting ----

- (void)setSettingsNumber:(NSNumber *)value forKey:(NSString *)aKey
{
    [self read];
    
    if (value == nil)
    {
        value = @0;
    }
    
    [self.settings setObject:value forKey:aKey];
    [self write];
}

- (void)setSettingsObject:(NSString *)value forKey:(NSString *)aKey
{
    [self read];
    
    if (value == nil)
    {
        value = @"";
    }
    
    [self.settings setObject:value forKey:aKey];
    [self write];
}

- (void)setupForDaemon
{
    [self setSettingsObject:@"true" forKey:@"daemon"];
    [self setSettingsNumber:@8442 forKey:@"apiport"];
    [self setSettingsObject:@"true" forKey:@"apienabled"];
    [self setSettingsObject:@"false" forKey:@"startonlogon"];
    //[self setSettingsObject:@"true" forKey:@"keysencrypted"];
    //[self setSettingsObject:@"true" forKey:@"messagesencrypted"];
}

- (void)setupForNonDaemon
{
    [self setSettingsObject:@"false" forKey:@"daemon"];
}



- (void)setupForNonTor
{
    [self setSettingsObject:@"" forKey:@"sockshostname"];
    [self setSettingsObject:@"none" forKey:@"socksproxytype"];
    [self setSOCKSPort:nil];
}

- (void)setupForTor
{
    [self setSettingsObject:@"127.0.0.1" forKey:@"sockshostname"];
    [self setSettingsObject:@"SOCKS5" forKey:@"socksproxytype"];
    //[self setSOCKSPort:@""]; // should be set elsewhere to match tor
}

- (NSNumber *)getSettingsNumber:(NSString *)key
{
    NSString *value = [self.settings objectForKey:key];
    return [NSNumber numberWithInt:value.intValue];
}

// socksport

- (void)setSOCKSPort:(NSNumber *)aNumber
{
    if (aNumber == nil)
    {
        aNumber = @0;
    }
    
    [self setSettingsNumber:aNumber forKey:@"socksport"];
}

- (NSNumber *)socksport
{
    return [self getSettingsNumber:@"socksport"];
}

// apiusername

- (void)setApiUsername:(NSString *)aString
{
    [self setSettingsObject:aString forKey:@"apiusername"];
}

- (NSString *)apiusername
{
    return [self.settings objectForKey:@"apiusername"];
}

// apipassword

- (void)setApiPassword:(NSString *)aString
{
    [self setSettingsObject:aString forKey:@"apipassword"];
}

- (NSString *)apipassword
{
    return [self.settings objectForKey:@"apipassword"];
}

// apiport

- (void)setApiPort:(NSNumber *)aPort
{
    [self setSettingsNumber:aPort forKey:@"apiport"];
}

- (NSNumber *)apiport
{
    return [self getSettingsNumber:@"apiport"];
}

// port

- (void)setPort:(NSNumber *)aPort
{
    [self setSettingsNumber:aPort forKey:@"port"];
}

- (NSNumber *)port
{
    return [self getSettingsNumber:@"port"];
}

// defaultnoncetrialsperbyte

- (void)setDefaultnoncetrialsperbyte:(NSNumber *)aPow
{
    [self setSettingsNumber:aPow forKey:@"defaultnoncetrialsperbyte"];
}

- (NSNumber *)defaultnoncetrialsperbyte
{
    return [self getSettingsNumber:@"defaultnoncetrialsperbyte"];
}


- (BOOL)setLabel:(NSString *)aLabel onAddress:(NSString *)anAddress
{
    [self read];

    NSString *key = [NSString stringWithFormat:@"[%@]", anAddress];
    NSMutableDictionary *addressDict = [self.dict objectForKey:key];
    
    if (!addressDict)
    {
        return NO;
    }
    
    if ([addressDict objectForKey:@"label"] == nil)
    {
        return NO;
    }
    
    [addressDict setObject:aLabel forKey:@"label"];

    [self write];
    return YES;
}

- (BOOL)doesExist
{
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&isDir];
    return exists;
}

// backup

- (NSString *)newBackupPath
{
    char buffer[50];
    unsigned long t = [[NSDate date] timeIntervalSince1970];
    sprintf(buffer, "%lu", t);
    NSString *fileName = [NSString stringWithFormat:@"%s.backup", buffer];
    return [self.backupFolder stringByAppendingPathComponent:fileName];
}

- (NSString *)backupFolder
{
    return [self.folder stringByAppendingPathComponent:@"keys_backups"];
}


- (void)createBackupFolderIfNeeded
{
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:self.backupFolder isDirectory:&isDir];
    
    if (!exists)
    {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:self.backupFolder withIntermediateDirectories:YES attributes:nil error:&error];
    }
}

- (NSArray *)backupUrls
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:self.backupFolder isDirectory:YES]
                                   includingPropertiesForKeys:@[]
                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        error:nil];
    return contents;
}

- (void)backup
{
    [self createBackupFolderIfNeeded];
    
    NSString *data = [self readString];
    
    if (data)
    {
        NSError *error;
        NSString *path = self.newBackupPath;
        
        [data writeToFile:path
               atomically:YES
                 encoding:NSUTF8StringEncoding
                    error:&error];
        
        if (error)
        {
            [NSException raise:@"backup error" format:@"%@", error];
        }
    }
}

@end
