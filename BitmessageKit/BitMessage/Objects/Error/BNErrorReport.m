//
//  BNErrorReport.m
//  BitmessageKit
//
//  Created by Steve Dekorte on 12/15/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//
// example use:
//
// when app starts, set your error report address, e.g.:
//
//   BNErrorReport.sharedBNErrorReport.reportAddress = @"BM-2cXnWu868ux2P71UVJsZVxnv9zjKWv2xPW"
//
// on exception call:
//
//   [BNErrorReport.sharedBNErrorReport reportException:anException];
//

#import "BNErrorReport.h"
#import <BitmessageKit/BitmessageKit.h>

@implementation BNErrorReport

static BNErrorReport *sharedBNErrorReport = nil;

+ (BNErrorReport *)sharedBNErrorReport
{
    if (!sharedBNErrorReport)
    {
        sharedBNErrorReport = [[BNErrorReport alloc] init];
    }
    
    return sharedBNErrorReport;
}

- (void)reportException:(NSException *)anException
{
    self.exception = anException;
    
    if (!self.isOpen)
    {
        if (self.reportAddress)
        {
            [self askUserToSend];
        }
        else
        {
            [self justShowError];
        }
    }
}

- (id)init
{
    self = [super init];
    //self.reportAddress = @"BM-2cXnWu868ux2P71UVJsZVxnv9zjKWv2xPW";
    self.debug = YES;
    return self;
}

- (NSString *)errorQuestion
{
    return [NSString stringWithFormat:@"A ('%@') error occurred. Would you like to send an error report to voluntary.net?", self.exception.name];
}

- (BOOL)isOpen
{
    return _alert != nil;
}


- (void)justShowError
{
    _alert = [[NSAlert alloc] init];
    [_alert setMessageText:[NSString stringWithFormat:@"A ('%@') error occurred.", self.exception.name]];
    [_alert addButtonWithTitle: @"OK"];
    
    [_alert beginSheetModalForWindow:NSApplication.sharedApplication.mainWindow
                       modalDelegate:self
                      didEndSelector:@selector(showAlertDone:returnCode:contextInfo:)
                         contextInfo:nil];
}

- (void)showAlertDone:(NSAlert *)alert
           returnCode:(NSInteger)returnCode
          contextInfo:(void *)contextInfo
{
    _alert = nil;
}

- (void)askUserToSend
{
    _alert = [[NSAlert alloc] init];
    [_alert setMessageText:self.errorQuestion];
    [_alert addButtonWithTitle: @"Send"];
    [_alert addButtonWithTitle: @"Don't Send"];
    
    //NSWindow *window = [(NSApplication *)[NSApplication sharedApplication] mainWindow];
    NSWindow *window = [[(NSApplication *)[NSApplication sharedApplication] windows] firstObject];
    
    [_alert beginSheetModalForWindow:window
                       modalDelegate:self
                      didEndSelector:@selector(sendAlertDone:returnCode:contextInfo:)
                         contextInfo:nil];
}
    
- (void)sendAlertDone:(NSAlert *)alert
            returnCode:(NSInteger)returnCode
           contextInfo:(void *)contextInfo
{
    if (returnCode == 1000)
    {
        @try
        {
            [self send];
        }
        @catch (NSException *exception)
        {
            NSLog(@"%@ exception sending report", exception);
        }
    }
    
    _alert = nil;
}

- (NSString *)reportString
{
    return self.exception.fullDescription;
}

- (BMIdentity *)tmpIdentity
{
    BMIdentities *identities = BMClient.sharedBMClient.identities;
    NSString *tmpLabel = [NSString stringWithFormat:@"tmp-%@", [[NSUUID UUID] UUIDString]];
    [identities createRandomAddressWithLabel:tmpLabel];
    return [identities identityWithLabel:tmpLabel];
}

- (BOOL)send
{
    BMMessage *m = [[BMMessage alloc] init];
    [m setToAddress:self.reportAddress];
    
    BMIdentity *tmpIdentity = self.tmpIdentity;
    
    [m setFromAddress:tmpIdentity.address];
    [m setSubject:@"Error report"];
    [m setMessage:self.reportString];
    
    if(self.debug)
    {
        [m show];
    }
    
    [m send];
    
    if(!m.ackData)
    {
        NSLog(@"unable to send error report");
    }
    
    [tmpIdentity delete];
    
    return m.ackData != nil;
}

@end
