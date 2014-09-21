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
    return [[BMServerProcess sharedBMServerProcess] serverDataFolder];
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
    
    for (NSString *key in [self.dict allKeys])
    {
        NSDictionary *subDict = [self.dict objectForKey:key];
        [data appendString:@"\n"];
        [data appendString:key];
        [data appendString:@"\n"];
        
        for (NSString *subKey in [subDict allKeys])
        {
            NSDictionary *subValue = [subDict objectForKey:subKey];
            [data appendString:[NSString stringWithFormat:@"%@ = %@\n", subKey, subValue]];
        }
    }
    
    [self writeString:data];
}

- (NSMutableDictionary *)settings
{
    NSMutableDictionary *settings = [self.dict objectForKey:@"[bitmessagesettings]"];
    
    if (!settings)
    {
        settings = [NSMutableDictionary dictionary];
    }
    
    return settings;
}

// --- setting ----

- (void)setupForDaemon
{
    [self read];
    [self.settings setObject:@"true" forKey:@"daemon"];
    [self.settings setObject:@"8442" forKey:@"apiport"];
    [self.settings setObject:@"true" forKey:@"apienabled"];
    [self.settings setObject:@"false" forKey:@"startonlogon"];
    //[self.settings setObject:@"true" forKey:@"keysencrypted"];
    //[self.settings setObject:@"true" forKey:@"messagesencrypted"];
    [self write];
}

- (void)setupForNonDaemon
{
    [self read];
    [self.settings setObject:@"false" forKey:@"daemon"];
    [self write];
}

- (void)setupForNonTor
{
    [self read];
    [self.settings setObject:@"" forKey:@"socksport"];
    [self setSOCKSPort:@""];
    //[self.settings setObject:@"" forKey:@"socksproxytype"];
    [self.settings setObject:@"none" forKey:@"socksproxytype"];
    [self write];
}

- (void)setupForTor
{
    [self read];
    [self.settings setObject:@"SOCKS5" forKey:@"socksproxytype"];
    //[self.settings setObject:@"True" forKey:@"socksproxytype"];
    [self write];
}

- (BOOL)setSOCKSPort:(NSString *)aString
{
    [self read];
    [self.settings setObject:aString forKey:@"socksport"];;
    [self write];
    return YES;
}

- (BOOL)setApiUsername:(NSString *)aString
{
    [self read];
    [self.settings setObject:aString forKey:@"apiusername"];
    [self write];
    return YES;
}

- (BOOL)setApiPassword:(NSString *)aString
{
    [self read];
    [self.settings setObject:aString forKey:@"apipassword"];
    [self write];
    return YES;
}

- (BOOL)setApiPort:(NSUInteger)aPort
{
    [self read];
    [self.settings setObject:[NSString stringWithFormat:@"%i", (int)aPort] forKey:@"apiport"];
    [self write];
    return YES;
}

- (BOOL)setPort:(NSUInteger)aPort
{
    [self read];
    [self.settings setObject:[NSString stringWithFormat:@"%i", (int)aPort] forKey:@"port"];
    [self write];
    return YES;
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
