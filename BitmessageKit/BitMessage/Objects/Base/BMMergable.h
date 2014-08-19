//
//  BMMergable.h
//  BitmessageKit
//
//  Created by Steve Dekorte on 8/15/14.
//  Copyright (c) 2014 Adam Thorsen. All rights reserved.
//

#import "BMAddressed.h"
#import "BMMessage.h"

@interface BMMergable : BMAddressed

@property (retain, nonatomic) NSMutableArray *mergingChildren;

- (void)prepareToMergeChildren;
- (BOOL)mergeChild:(BMMessage *)aMessage;
- (void)completeMergeChildren;

- (void)deleteAllChildren;

@end
