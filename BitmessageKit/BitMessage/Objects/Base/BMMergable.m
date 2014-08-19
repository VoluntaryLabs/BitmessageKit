//
//  BMMergable.m
//  BitmessageKit
//
//  Created by Steve Dekorte on 8/15/14.
//  Copyright (c) 2014 Adam Thorsen. All rights reserved.
//

#import "BMMergable.h"

@implementation BMMergable


- (SEL)mergeAttributeSelector
{
    return nil;
}

- (void)prepareToMergeChildren
{
    self.mergingChildren = [NSMutableArray array];
}

- (BOOL)mergeChild:(BMMessage *)aMessage
{
    SEL mergeAttributeSelector = self.mergeAttributeSelector;
    
    if (mergeAttributeSelector)
    {
        NSString *attribute = [aMessage performSelector:mergeAttributeSelector];
        
        /*
        if ([self.label isEqualToString:@"Time Service"])
        {
            NSLog(@"Time Service check! %@ =?= %@", self.address, attribute);
        }
        */
        
        if ([attribute isEqualToString:self.address])
        {
            [self.mergingChildren addObject:aMessage];
            return YES;
    }
    }
    
    return NO;
}

- (void)completeMergeChildren
{
    [self.children mergeWith:self.mergingChildren];
    [self setChildren:self.children]; // so node parents set
    [self sortChildren];
    [self updateUnreadCount];
    [self postSelfChanged];
    self.mergingChildren = nil;
}

- (void)deleteAllChildren
{
    for (BMMessage *msg in self.children.copy)
    {
        [msg delete];
    }
    
    [self postParentChanged];
}

@end
