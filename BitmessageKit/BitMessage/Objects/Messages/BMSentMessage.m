//
//  BMSentMessage.m
//  Bitmessage
//
//  Created by Steve Dekorte on 2/19/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMSentMessage.h"
#import "BMProxyMessage.h"
#import "BMClient.h"
#import "BMDatabase.h"

@implementation BMSentMessage

- (NSString *)nodeTitle
{
    return [NSString stringWithFormat:@"to %@", self.toAddressLabel];
}

/*
+ (BMMessage *)withDict:(NSDictionary *)dict
{
    NSLog(@"sent dict %@", dict);
    return [super withDict:dict];
}
*/

/*
- (NSDictionary *)shortStatusDict
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"not found", @"notfound",
            @"queued", @"msgqueued",
            @"broadcast queued", @"broadcastqueued",
            @"broadcast sent", @"broadcastsent",
            @"doing public key proof of work", @"doingpubkeypow",
            @"awaiting public key", @"awaitingpubkey",
            @"doing message proof of work", @"doingmsgpow",
            @"force proof of work", @"forcepow",
            @"sent but unacknowledged", @"msgsent",
            @"sent, no acknowledge expected", @"msgsentnoackexpected",
            @"received", @"ackreceived", nil];
}
*/

- (NSDictionary *)statusDict
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"not found", @"notfound",
            @"queued", @"msgqueued",
            @"broadcast queued", @"broadcastqueued",
            @"broadcast sent", @"broadcastsent",
            @"doing public key proof of work", @"doingpubkeypow",
            @"awaiting public key", @"awaitingpubkey",
            @"doing message proof of work", @"doingmsgpow",
            @"force proof of work", @"forcepow",
            @"sent but unacknowledged", @"msgsent",
            @"sent, no acknowledge expected", @"msgsentnoackexpected",
            @"received", @"ackreceived", nil];
}

- (BOOL)notFound
{
    return [self.getStatus isEqualToString:@"notfound"];
}

- (BOOL)wasSent
{
    if (!_isSent)
    {
        _isSent = [self.getHumanReadbleStatus containsCaseInsensitiveString:@"sent"];
    }
    
    return _isSent;
}


/*
 - (NSArray *)unreadStates
 {
 return [NSArray arrayWithObjects:@"doingpubkeypow", @"awaitingpubkey", @"doingmsgpow", @"forcepow", nil];
 }
 */

- (NSArray *)readStates
{
    return [NSArray arrayWithObjects:@"msgsentnoackexpected", @"ackreceived", @"broadcastsent", @"msgsent", nil];
}

- (NSArray *)powStates
{
    return [NSArray arrayWithObjects:@"doingpubkeypow", @"doingmsgpow", nil];
}

- (BOOL)isDoingPOW
{
    NSString *status = [self getStatus];
    return [self.powStates containsObject:status];
}

- (BOOL)hasReadState
{
    NSString *status = [self getStatus];
    return [self.readStates containsObject:status];
}

- (void)markAsRead
{
    // ignore - we are only using the sent state on sent messages
}

- (void)markAsSent
{
    [self.client.sentMessagesDB mark:self.msgid];
}

- (BOOL)isMarkedAsSent
{
    return [self.client.sentMessagesDB hasMarked:self.msgid];
}

- (void)delete
{
    [self.client.sentMessagesDB unmark:self.msgid];
    [super delete];
}

- (BOOL)isSent
{
    if (!_isSent)
    {
        _isSent = self.isMarkedAsSent;
        
        if (!_isSent)
        {
            _isSent = self.hasReadState;
            
            if (_isSent)
            {
                [self markAsSent];
            }
        }
        
    }
    
    return _isSent;
}

- (BOOL)isRead
{
    return [self isSent];
}



- (NSString *)getHumanReadbleStatus
{
    NSString *status = self.getStatus;
    status = [self.statusDict objectForKey:status];
    return status;
}

- (NSString *)getStatus
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"getStatus"];
    NSArray *params = [NSArray arrayWithObjects:self.ackData, nil];
    [message setParameters:params];
    //message.debug = YES;
    [message sendSync];
    id result = [message responseValue];
    //NSLog(@"getStatus result %@", result);
    
    /* 
     responses: 
     
     notfound, 
     msgqueued, 
     broadcastqueued, 
     broadcastsent, 
     doingpubkeypow, 
     awaitingpubkey, 
     doingmsgpow, 
     forcepow, 
     msgsent, 
     msgsentnoackexpected, 
     ackreceived
     */
    
    return result;
}

@end
