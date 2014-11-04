//
//  BitmessageKit.h
//  BitmessageKit
//
//  Created by Steve Dekorte
//  Copyright (c) 2014 Voluntary.net. All rights reserved.
//

#import "BitmessageKit.h"
#import "BMClient.h"

@implementation BitmessageKit

+ (id)nodeRoot
{
    return [BMClient sharedBMClient];
}

- nodeAbout
{
    return [[BMAboutNode alloc] init];
}

@end