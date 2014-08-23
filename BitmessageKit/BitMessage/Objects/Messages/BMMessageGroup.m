//
//  BMMessageGroup.m
//  Bitmessage
//
//  Created by Steve Dekorte on 3/25/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMMessageGroup.h"
#import <FoundationCategoriesKit/FoundationCategoriesKit.h>

@implementation BMMessageGroup

- (void)deleteAll
{
    for (BMMessage *msg in self.children)
    {
        [msg delete];
    }
}

- (BOOL)canSearch
{
    return YES;
}

@end
