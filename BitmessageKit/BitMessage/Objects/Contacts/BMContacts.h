//
//  BMContacts.h
//  Bitmarket
//
//  Created by Steve Dekorte on 1/31/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMNode.h"
#import "BMContact.h"

@interface BMContacts : BMNode

- (void)fetch;
- (BMContact *)justAdd;

@end
