//
//  BMNode.m
//  Bitmarket
//
//  Created by Steve Dekorte on 1/31/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMNode.h"
#import "BMClient.h"

@implementation BMNode

- (BMClient *)client
{
    return BMClient.sharedBMClient;
}

// --- merging --------------------------------


- (void)prepareToMergeChildren
{
    for (BMNode *node in self.children)
    {
        [node prepareToMergeChildren];
    }
}

- (BOOL)mergeChild:(BMNode *)aChild
{
    for (BMNode *node in self.children)
    {
        if([node mergeChild:aChild])
        {
            return YES;
        }
    }
    
    return NO;
}

- (void)completeMergeChildren
{
    for (BMNode *node in self.children)
    {
        [node completeMergeChildren];
    }
}

// --- addresses ---

- (NSSet *)childrenAddressSet
{
    NSMutableSet *set = [NSMutableSet set];
    
    for (BMIdentity *identity in self.children)
    {
        [set addObject:identity.address];
    }
    
    return set;
}

@end
