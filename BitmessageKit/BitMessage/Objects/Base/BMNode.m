//
//  BMNode.m
//  Bitmarket
//
//  Created by Steve Dekorte on 1/31/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import "BMNode.h"
#import "BMClient.h"

@implementation BMNode

- (BMClient *)client
{
    return [BMClient sharedBMClient];
}

@end
