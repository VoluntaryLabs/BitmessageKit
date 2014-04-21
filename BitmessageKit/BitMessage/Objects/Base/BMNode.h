//
//  BMNode.h
//  Bitmarket
//
//  Created by Steve Dekorte on 1/31/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import <NavNodeKit/NavNodeKit.h>

@class BMClient;

@interface BMNode : NavNode

- (BMClient *)client;

@end
