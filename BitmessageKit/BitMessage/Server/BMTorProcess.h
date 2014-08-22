//
//  BMTorProcess.h
//  BitmessageKit
//
//  Created by Steve Dekorte on 8/22/14.
//  Copyright (c) 2014 Adam Thorsen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMTorProcess : NSObject

@property (strong) NSTask *torTask;
@property (strong) NSString *serverDataFolder;
@property (retain, nonatomic) NSString *torPort;
@property (strong) NSPipe *inpipe;

- (void)launch;
- (void)terminate;
- (BOOL)isRunning;

@end
