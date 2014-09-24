//
//  BMClient.m
//  Bitmarket
//
//  Created by Steve Dekorte on 1/31/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMClient.h"
#import "BMAddressed.h"
#import "BMArchive.h"

@implementation BMClient

static BMClient *sharedBMClient;

+ (BMClient *)sharedBMClient
{
    if (!sharedBMClient)
    {
        sharedBMClient = [BMClient alloc];
        sharedBMClient = [sharedBMClient init];
    }
    
    return sharedBMClient;
}


- (id)init
{
    self = [super init];
    self.refreshInterval = 3;
    [self startServer];
    
    self.shouldSortChildren = NO;
    
    self.identities    = [[BMIdentities alloc] init];
    self.contacts      = [[BMContacts alloc] init];
    self.messages      = [[BMMessages alloc] init];
    self.subscriptions = [[BMSubscriptions alloc] init];
    self.channels      = [[BMChannels alloc] init];
    
    [self addChild:self.messages.received];
    [self addChild:self.messages.sent];
    [self addChild:self.contacts];
    [self addChild:self.identities];
    [self addChild:self.channels];
    [self addChild:self.subscriptions];

    self.readMessagesDB = [[BMDatabase alloc] init];
    [self.readMessagesDB setName:@"readMessagesDB"];
    
    self.deletedMessagesDB = [[BMDatabase alloc] init];
    [self.deletedMessagesDB setName:@"deletedMessagesDB"];
    

    // fetch these addresses first so we can filter messages
    // when we fetch them
    
    [self.identities fetch];
    [self.channels fetch];
    [self.subscriptions fetch];
    
    [self deepFetch];

    [self registerForNotifications];
    [self.messages.received changedUnreadCount];
    
    return self;
}

- (void)registerForNotifications
{
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(stopServer)
                                               name:NSApplicationWillTerminateNotification
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(unreadCountChanged:)
                                               name:@"BMReceivedMessagesUnreadCountChanged"
                                             object:self.messages.received];
}

- (void)unreadCountChanged:(NSNotification *)aNote
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:@(self.messages.received.unreadCount) forKey:@"number"];
    
    [NSNotificationCenter.defaultCenter
        postNotificationName:@"NavDocTileUpdate"
        object:self
        userInfo:aNote.userInfo];
}

- (CGFloat)nodeSuggestedWidth
{
    return 150.0;
}

- (NSString *)labelForAddress:(NSString *)addressString
{
    for (BMAddressed *child in self.allAddressed)
    {
        //NSLog(@"child.label '%@' '%@'", child.label, child.address);
        if ([child.address isEqualToString:addressString])
        {
            return child.label;
        }
    }
    
    return addressString;
}

- (NSString *)addressForLabel:(NSString *)labelString // returns nil if none found
{
    for (BMAddressed *child in self.allAddressed)
    {
        if ([child.label isEqualToString:labelString])
        {
            return child.address;
        }
    }
    
    return nil;
}

- (NSSet *)identityAddressLabels
{
    return self.identities.childrenLabelSet;
}

- (NSSet *)fromAddressLabels
{
    NSMutableSet *fromLabels = [NSMutableSet set];
    [fromLabels unionSet:self.identities.childrenLabelSet];
    [fromLabels unionSet:self.subscriptions.childrenLabelSet];
    [fromLabels unionSet:self.channels.childrenLabelSet];
    return fromLabels;
}

- (NSSet *)allAddressed
{
    NSMutableSet *results = [NSMutableSet setWithSet:[self nonIdentityAddressed]];
    [results addObjectsFromArray:self.identities.children];
    return results;
}

- (NSSet *)nonIdentityAddressed
{
    NSMutableSet *results = [NSMutableSet set];
    [results addObjectsFromArray:self.contacts.children];
    [results addObjectsFromArray:self.subscriptions.children];
    [results addObjectsFromArray:self.channels.children];
    return results;
}

- (NSSet *)toAddressLabels
{
    NSMutableSet *toLabels = [NSMutableSet set];
    
    for (BMAddressed *child in self.nonIdentityAddressed)
    {
        [toLabels addObject:child.label];
    }
    
    return toLabels;
}

- (NSSet *)allAddressLabels
{
    NSMutableSet *allLabels = [NSMutableSet set];
    [allLabels unionSet:self.fromAddressLabels];
    [allLabels unionSet:self.toAddressLabels];
    return allLabels;
}

- (BOOL)hasNoIdentites
{
    return [self.identities.children count] == 0;
}

// --- server --------------------------

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [self stopServer];
}

- (void)startServer
{
    self.server = [BMServerProcess sharedBMServerProcess];
    [self.server launch];
    [self startRefreshTimer];
    
}

- (void)stopServer
{
    [self stopRefreshTimer];
    [self.server terminate];
}

// timer

- (void)startRefreshTimer
{
    [self.refreshTimer invalidate];
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval
                                                         target:self
                                                       selector:@selector(refresh)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)stopRefreshTimer
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (void)refresh
{
    if (_server == nil || !_server.isRunning)
    {
        [NSException raise:@"Bitmessage server down" format:nil];
    }
    
    //NSLog(@"refresh received");
    [self.messages.received refresh];
    //NSLog(@"refresh sent");
    [self.messages.sent refresh];
    //NSLog(@"refresh done");
}

/*
- (void)fetchAll
{
    for (BMNode *child in self.children)
    {
        [child fetch];
    }
}
*/

// archive

- (NSString *)archiveSuffix
{
    return @"bmbox";
}

- (void)archiveToUrl:(NSURL *)url
{
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    
    NSString *archivedPath = [[url path] stringByAppendingPathComponent:
                              [NSString stringWithFormat:@"bitmessage.%i.%@",
                               (int)timeStamp, self.archiveSuffix]];
    [self stopServer];
    NSString *serverFolder = [[BMServerProcess sharedBMServerProcess] serverDataFolder];
    [[[BMArchive alloc] init] archiveFromPath:serverFolder toPath:archivedPath];
    [self startServer];
}

- (void)unarchiveFromUrl:(NSURL *)url
{
    [self stopServer];
    NSString *serverFolder = [[BMServerProcess sharedBMServerProcess] serverDataFolder];
    [[[BMArchive alloc] init] unarchiveFromPath:[url path] toPath:serverFolder];
    [self startServer];
    [self deepFetch];
}

// addresses

- (NSSet *)receivingAddressSet
{
    NSMutableSet *set = [NSMutableSet set];

    /*
    NSLog(@"self.identities.childrenAddressSet = %@", self.identities.childrenAddressSet);
    NSLog(@"subscriptions = %@", self.subscriptions.childrenAddressSet);
    NSLog(@"channels = %@", self.channels.childrenAddressSet);
    */
    
    [set unionSet:self.identities.childrenAddressSet];
    [set unionSet:self.channels.childrenAddressSet];
    [set unionSet:self.subscriptions.childrenAddressSet];
    
    return set;
}


@end
