//
//  BMClient.h
//  Bitmarket
//
//  Created by Steve Dekorte on 1/31/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMNode.h"
#import "BMServerProcess.h"
#import <FoundationCategoriesKit/FoundationCategoriesKit.h>

// groups

#import "BMIdentities.h"
#import "BMContacts.h"
#import "BMMessages.h"
#import "BMSubscriptions.h"
#import "BMChannels.h"
#import "BMDatabase.h"

// objects

#import "BMMessage.h"
#import "BMChannel.h"
#import "BMSubscription.h"
#import "BMContact.h"
#import "BMIdentity.h"
#import "BMAddress.h"

@interface BMClient : BMNode

@property (strong, nonatomic) BMServerProcess *server;
@property (strong, nonatomic) NSTimer *refreshTimer;
@property (assign, nonatomic) NSTimeInterval refreshInterval;

@property (strong, nonatomic) BMIdentities *identities;
@property (strong, nonatomic) BMContacts *contacts;
@property (strong, nonatomic) BMMessages *messages;
@property (strong, nonatomic) BMSubscriptions *subscriptions;
@property (strong, nonatomic) BMChannels *channels;
@property (strong, nonatomic) BMDatabase *readMessagesDB;
@property (strong, nonatomic) BMDatabase *deletedMessagesDB;
@property (strong, nonatomic) NavInfoNode *nodeAbout;


+ (BMClient *)sharedBMClient;

- (void)refresh;

// labels and addresses

- (NSString *)labelForAddress:(NSString *)addressString; // returns address if none found
- (NSString *)addressForLabel:(NSString *)labelString; // returns address if none found

- (NSSet *)fromAddressLabels;
- (NSSet *)toAddressLabels;
- (NSSet *)allAddressLabels;

- (NSSet *)receivingAddressSet;

- (BOOL)hasNoIdentites;

// server

- (void)stopServer; // call when app quits

/*
// archive
- (NSString *)archiveSuffix;
- (void)archiveToUrl:(NSURL *)url;
- (void)unarchiveFromUrl:(NSURL *)url;
*/

@end
