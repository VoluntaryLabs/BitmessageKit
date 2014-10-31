//
//  BitmessageKit.m
//  BitmessageKit
//
//  Created by Steve Dekorte on 10/28/14.
//  Copyright (c) 2014 Adam Thorsen. All rights reserved.
//

#import "BitmessageKit.h"
#import "BMClient.h"

@implementation BitmessageKit

+ nodeRoot
{
    return BMClient.sharedBMClient;
}

@end
