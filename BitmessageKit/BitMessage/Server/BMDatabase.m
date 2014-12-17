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
    if ([self.dict objectForKey:messageId] == nil)
    {
        NSNumber *d = [NSNumber numberWithLong:[[NSDate date] timeIntervalSinceReferenceDate]];
        [self.dict setObject:d forKey:messageId];
        [self write];
    }
}

- (void)unmark:(NSString *)messageId
{
    if ([self.dict objectForKey:messageId] != nil)
    {
        [self.dict removeObjectForKey:messageId];
        [self write];
    }
}

- (BOOL)hasMarked:(NSString *)messageId
{
    NSNumber *d = [self.dict objectForKey:messageId];
    return d != nil;
}

- (void)removeOldKeys
{
    for (NSString *key in self.dict.allKeys)
    {
        NSNumber *d = [self.dict objectForKey:key];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[d longLongValue]];
        int secondsInDay = 60 * 60 * 24;
        
        if ([date timeIntervalSinceNow] > secondsInDay * self.daysToCache)
        {
            [self.dict removeObjectForKey:key];
        }
    }
    [self write];
}

@end
