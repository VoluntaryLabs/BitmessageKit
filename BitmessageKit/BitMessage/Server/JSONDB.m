//
//  JSONDB.m
//  Bitmessage
//
//  Created by Steve Dekorte on 3/17/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "JSONDB.h"
#import <FoundationCategoriesKit/FoundationCategoriesKit.h>
#import "BMServerProcess.h" // remove this dependency by moving path setting up to server

@implementation JSONDB

/*
+ (NSMutableDictionary *)readDictWithName:(NSString *)aName
{
    JSONDB *db = [[JSONDB alloc] init];
    [db setName:aName];
    return [db dict];
}

+ (void)writeDict:(NSMutableDictionary *)dict withName:(NSString *)aName
{
    JSONDB *db = [[JSONDB alloc] init];
    [db setName:aName];
    [db setDict:dict];
    [db write];
}
*/


- (id)init
{
    self = [super init];
    _name = @"default";
    self.location = JSONDB_IN_SERVER_FOLDER;
    return self;
}

- (void)setName:(NSString *)name
{
    _name = name;
}

- (NSString *)path
{
    NSString *fileName = [NSString stringWithFormat:@"%@.json", self.name];
    
    if ([_location isEqualToString:JSONDB_IN_APP_WRAPPER])
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:self.name ofType:nil];
        return path;
    }
    else if ([_location isEqualToString:JSONDB_IN_SERVER_FOLDER])
    {
        NSString *folder = [[BMServerProcess sharedBMServerProcess] bundleDataPath];
        NSString *path = [folder stringByAppendingPathComponent:fileName];
        return path;
    }
    else if ([_location isEqualToString:JSONDB_IN_APP_SUPPORT_FOLDER])
    {
        NSString *folder = [[NSFileManager defaultManager] applicationSupportDirectory];
        NSString *path = [folder stringByAppendingPathComponent:fileName];
        return path;
    }

    [NSException raise:@"Invalid location" format:@"unknown location setting '%@'", _location];
    return nil;
}

- (NSDictionary *)dict
{
    if (!_dict)
    {
        [self read];
    }
    
    return _dict;
}

- (void)read
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.path])
    {
        self.dict = [NSMutableDictionary dictionary];
        _isDirty = NO;
        return;
    }
    
    NSData *jsonData = [NSData dataWithContentsOfFile:self.path];
    NSError *error;
    
    id jsonObject = [NSJSONSerialization
                     JSONObjectWithData:jsonData
                     options:NSJSONReadingMutableContainers
                     error:&error];
    
    if (error)
    {
        NSLog(@"JSON Parse Error: %@", [[error userInfo] objectForKey:@"NSDebugDescription"]);
        [NSException raise:@"JSON Parse Error" format:@""];
    }
    else
    {
        self.dict = (NSMutableDictionary *)jsonObject;
        _isDirty = NO;
    }
}

- (void)writeIfDirty
{
    if (_isDirty)
    {
        [self write];
    }
}

- (void)write
{
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.dict
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
    
    if (error)
    {
        NSLog(@"JSON Error: %@", [[error userInfo] objectForKey:@"NSDebugDescription"]);
        [NSException raise:@"JSON Error" format:@""];
    }
    else
    {
        if([data writeToFile:self.path atomically:YES])
        {
            _isDirty = NO;
        }
    }
}

- (void)setObject:aValue forKey:aKey
{
    //id oldValue = [self.dict objectForKey:aKey];
    
    //if (!oldValue || ![oldValue isEqual:aValue])
    {
        [self.dict setObject:aValue forKey:aKey];
        _isDirty = YES;
    }
}

- (void)removeObjectForKey:aKey
{
   if ([self.dict objectForKey:aKey])
   {
       [self.dict removeObjectForKey:aKey];
       _isDirty = YES;
    }
}

- (NSArray *)allKeys
{
    return self.dict.allKeys;
}

- (id)objectForKey:aKey
{
    return [self.dict objectForKey:aKey];
}

@end
