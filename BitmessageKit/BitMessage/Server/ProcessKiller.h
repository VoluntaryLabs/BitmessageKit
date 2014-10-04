//
//  ProcessKiller.h
//  BitmessageKit
//
//  Created by Steve Dekorte on 10/3/14.
//  Copyright (c) 2014 Adam Thorsen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProcessKiller : NSObject

+ (ProcessKiller *)sharedProcessKiller;

- (void)onRestartKillTask:(NSTask *)aTask;

@end
