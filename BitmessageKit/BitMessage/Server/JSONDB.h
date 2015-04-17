//
//  JSONDB.h
//  Bitmessage
//
//  Created by Steve Dekorte on 3/17/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import <Foundation/Foundation.h>

#define JSONDB_IN_SERVER_FOLDER      @"JSONDB_IN_SERVER_FOLDER"
#define JSONDB_IN_APP_WRAPPER        @"JSONDB_IN_APP_WRAPPER"
#define JSONDB_IN_APP_SUPPORT_FOLDER @"JSONDB_IN_APP_SUPPORT_FOLDER"

@interface JSONDB : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSMutableDictionary *dict;
@property (strong, nonatomic) NSString *location;
@property (assign, nonatomic) BOOL isDirty;

- (void)read;
- (void)write;
- (void)writeIfDirty;


- (void)setObject:aValue forKey:aKey;
- (void)removeObjectForKey:aKey;
- (id)objectForKey:aKey;
- (NSArray *)allKeys;

@end
