//
//  BMAboutNode.m
//  Bitmessage
//
//  Created by Steve Dekorte on 7/29/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "BMAboutNode.h"
#import <BitmessageKit/BitmessageKit.h>
#import <NavKit/NavKit.h>

@implementation BMAboutNode

- (id)init
{
    self = [super init];
    
    if (self)
    {
        [self setup];
    }
    
    return self;
}

- (NSString *)versionString
{
    NSDictionary *info = [NSBundle bundleForClass:[self class]].infoDictionary;
    NSString *versionString = [info objectForKey:@"CFBundleVersion"];
    //return versionString;
    return [NSString stringWithFormat:@"version %@", versionString];
}

- (void)setup
{
    NavInfoNode *about = self;
    about.nodeShouldSortChildren = @NO;
    about.nodeTitle = @"BitmessageKit";
    about.nodeSubtitle = self.versionString;
    about.nodeSuggestedWidth = @150;
    
    
    /*
    NavInfoNode *version = [[NavInfoNode alloc] init];
    [about addChild:version];
    version.nodeTitle = @"Version";
    version.nodeSubtitle = self.versionString;
    version.nodeSuggestedWidth = @200;
    */
    
    NavInfoNode *contributors = [[NavInfoNode alloc] init];
    [about addChild:contributors];
    contributors.nodeTitle = @"Credits";
    contributors.nodeSuggestedWidth = @200;
    contributors.nodeShouldSortChildren = @NO;
    
    {
        NavInfoNode *contributor = [[NavInfoNode alloc] init];
        contributor.nodeTitle = @"Steve Dekorte";
        contributor.nodeSubtitle = @"Lead & UI Developer";
        [contributors addChild:contributor];
    }
    
    {
        NavInfoNode *contributor = [[NavInfoNode alloc] init];
        contributor.nodeTitle = @"Chris Robinson";
        contributor.nodeSubtitle = @"Designer";
        [contributors addChild:contributor];
    }
    
    {
        NavInfoNode *contributor = [[NavInfoNode alloc] init];
        contributor.nodeTitle = @"Adam Thorsen";
        contributor.nodeSubtitle = @"Tor, Bitmessage integration";
        [contributors addChild:contributor];
    }
    
    {
        NavInfoNode *contributor = [[NavInfoNode alloc] init];
        contributor.nodeTitle = @"Dru Nelson";
        contributor.nodeSubtitle = @"Unix Guru";
        [contributors addChild:contributor];
    }
    
    
    
    NavInfoNode *others = [[NavInfoNode alloc] init];
    [contributors addChild:others];
    others.nodeTitle = @"3rd Party";
    others.nodeSuggestedWidth = @200;
    others.nodeShouldSortChildren = @NO;
    
    
    {
        NavInfoNode *package = [[NavInfoNode alloc] init];
        package.nodeTitle = @"Bitmessage";
        package.nodeSubtitle = @"bitmessage.org";
        package.nodeResourceName = @"licenses/bitmessage_license.txt";
        package.nodeViewClass = NavResourceView.class;
        [others addChild:package];
    }
    
    {
        NavInfoNode *package = [[NavInfoNode alloc] init];
        package.nodeTitle = @"Open Sans";
        package.nodeSubtitle = @"Steve Matteson, Google fonts";
        package.nodeResourceName = @"licenses/opensans_license.txt";
        package.nodeViewClass = NavResourceView.class;
        [others addChild:package];
    }
    
    {
        NavInfoNode *package = [[NavInfoNode alloc] init];
        package.nodeTitle = @"Python";
        package.nodeSubtitle = @"python.org";
        package.nodeResourceName = @"licenses/python_license.txt";
        package.nodeViewClass = NavResourceView.class;
        [others addChild:package];
    }
    
    {
        NavInfoNode *package = [[NavInfoNode alloc] init];
        package.nodeTitle = @"Tor";
        package.nodeSubtitle = @"torproject.org";
        package.nodeResourceName = @"licenses/tor_license.txt";
        package.nodeViewClass = NavResourceView.class;
        [others addChild:package];
    }
    
    {
        NavInfoNode *package = [[NavInfoNode alloc] init];
        package.nodeTitle = @"XmlRPC";
        package.nodeSubtitle = @"Eric Czarny";
        package.nodeResourceName = @"licenses/xmlrpc_license.txt";
        package.nodeViewClass = NavResourceView.class;
        [others addChild:package];
    }
    
    /*
    {
        NavInfoNode *package = [[NavInfoNode alloc] init];
        package.nodeTitle = @"ZipKit";
        package.nodeSubtitle = @"Karl Moskowski";
        [others addChild:package];
    }
    */
    
    
    {
        NavInfoNode *help = [[NavInfoNode alloc] init];
        help.nodeTitle = @"Help";
        //what.nodeSubtitle = @"Designer";
        //[about addChild:help];
 
        
        {
            NavInfoNode *how = [[NavInfoNode alloc] init];
            how.nodeTitle = @"What's this app for?";
            //what.nodeSubtitle = @"Designer";
            [help addChild:how];
        }
        
        {
            NavInfoNode *how = [[NavInfoNode alloc] init];
            how.nodeTitle = @"How does Bitmessage work?";
            //what.nodeSubtitle = @"Designer";
            [help addChild:how];
        }
        
        {
            NavInfoNode *how = [[NavInfoNode alloc] init];
            how.nodeTitle = @"Protecting your privacy";
            //what.nodeSubtitle = @"Designer";
            [help addChild:how];
        }
        
        {
            NavInfoNode *how = [[NavInfoNode alloc] init];
            how.nodeTitle = @"How to contribute";
            //what.nodeSubtitle = @"Designer";
            [help addChild:how];
        }
    }
    
    NavInfoNode *status = [[NavInfoNode alloc] init];
    [about addChild:status];
    status.nodeTitle = @"Status";
    status.nodeSuggestedWidth = @200;
    status.nodeShouldSortChildren = @NO;
    
    {
        {
            NavInfoNode *nonce = [[NavInfoNode alloc] init];
            nonce.nodeTitle = @"Pybitmessage Version";
            nonce.nodeSubtitle = [NSString stringWithFormat:@"%@", BMClient.sharedBMClient.server.pybitmessageVersion];
            [status addChild:nonce];
        }
        
        {
            NavInfoNode *nonce = [[NavInfoNode alloc] init];
            nonce.nodeTitle = @"Python Version";
            nonce.nodeSubtitle = [NSString stringWithFormat:@"%@", BMClient.sharedBMClient.server.pyhtonBinaryVersion];
            [status addChild:nonce];
        }
                
        {
            NavInfoNode *nonce = [[NavInfoNode alloc] init];
            nonce.nodeTitle = @"Proof of work";
            nonce.nodeSubtitle = [NSString stringWithFormat:@"%@ trials/byte", BMClient.sharedBMClient.server.keysFile.defaultnoncetrialsperbyte];
            [status addChild:nonce];
        }
        
        {
            NavInfoNode *nonce = [[NavInfoNode alloc] init];
            nonce.nodeTitle = @"Max cores for POW";
            nonce.nodeSubtitle = [NSString stringWithFormat:@"%@", BMClient.sharedBMClient.server.keysFile.maxCores];
            [status addChild:nonce];
        }
        
        {
            NavInfoNode *nonce = [[NavInfoNode alloc] init];
            nonce.nodeTitle = @"Port";
            
            if (BMClient.sharedBMClient.server.useTor)
            {
                nonce.nodeSubtitle = @"routing via tor";
            }
            else
            {
                nonce.nodeSubtitle = [NSString stringWithFormat:@"%@", BMClient.sharedBMClient.server.port];
            }
            
            [status addChild:nonce];
        }
        
        {
            NavInfoNode *nonce = [[NavInfoNode alloc] init];
            nonce.nodeTitle = @"API Port";
            nonce.nodeSubtitle = [NSString stringWithFormat:@"%@", BMClient.sharedBMClient.server.apiPort];
            [status addChild:nonce];
        }
        
        {
            NavInfoNode *nonce = [[NavInfoNode alloc] init];
            nonce.nodeTitle = @"Tor";
            nonce.nodeSubtitle = BMClient.sharedBMClient.server.useTor ? @"enabled" : @"disabled";
            [status addChild:nonce];
        }
        
        {
            NavInfoNode *nonce = [[NavInfoNode alloc] init];
            nonce.nodeTitle = @"Tor Socks Port";
            nonce.nodeSubtitle = [NSString stringWithFormat:@"%@", BMClient.sharedBMClient.server.torProcess.torSocksPort];
            [status addChild:nonce];
        }
        
        {
            NavInfoNode *torVersion = [[NavInfoNode alloc] init];
            torVersion.nodeTitle = @"Tor Version";
            torVersion.nodeSubtitle = [NSString stringWithFormat:@"%@", BMClient.sharedBMClient.server.torProcess.binaryVersion];
            [status addChild:torVersion];
        }
    }
}

@end
