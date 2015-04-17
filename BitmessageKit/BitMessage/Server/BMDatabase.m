//
//  BMDatabase.m
//  Bitmessage
//
//  Created by Steve Dekorte on 2/23/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMDatabase.h"

@implementation BMDatabase

- (id)init
{
    self = [super init];
    self.daysToCache = 5;
    return self;
}

- (void)read
{
    [super read];
    [self removeOldKeys];
}

// --- mark ---

- (void)mark:(NSString *)messageId
{
    if ([self objectForKey:messageId] == nil)
    {
        NSNumber *d = [NSNumber numberWithLong:[[NSDate date] timeIntervalSinceReferenceDate]];
        [self setObject:d forKey:messageId];
        [self writeIfDirty];
    }
}

- (void)unmark:(NSString *)messageId
{
    [self removeObjectForKey:messageId];
    [self writeIfDirty];
}

- (BOOL)hasMarked:(NSString *)messageId
{
    NSNumber *d = [self objectForKey:messageId];
    return d != nil;
}

- (void)removeOldKeys
{
    for (NSString *key in self.allKeys)
    {
        NSNumber *d = [self objectForKey:key];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[d longLongValue]];
        int secondsInDay = 60 * 60 * 24;
        
        if ([date timeIntervalSinceNow] > secondsInDay * self.daysToCache)
        {
            [self removeObjectForKey:key];
        }
    }
    
    [self writeIfDirty];
}

@end
