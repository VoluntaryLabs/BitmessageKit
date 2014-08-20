//
//  BMMessageGroup.h
//  Bitmessage
//
//  Created by Steve Dekorte on 3/25/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import "BMNode.h"
#import "BMMessage.h"
#import "BMUnreadCountable.h"

@interface BMMessageGroup : BMUnreadCountable


- (void)deleteAll;

@end
