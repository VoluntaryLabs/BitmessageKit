//
//  BMMessage.m
//  Bitmarket
//
//  Created by Steve Dekorte on 1/25/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import "BMMessage.h"
#import "BMProxyMessage.h"
#import "BMClient.h"
#import "NSMutableAttributedString+extra.h"

@implementation BMMessage

- (id)init
{
    self = [super init];
    self.actions = [NSMutableArray arrayWithObjects:@"reply", @"forward", @"delete", nil];
    return self;
}

- (NSUInteger)hash
{
    return [_msgid hash];
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[BMMessage class]])
    {
        return NO;
    }

    return [_msgid isEqual:[(BMMessage *)object msgid]];
}

+ (BMMessage *)withDict:(NSDictionary *)dict
{
    id instance = [[[self class] alloc] init];
    [instance setDict:dict];
    return instance;
}

- (NSDictionary *)dict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:self.encodingType forKey:@"encodingType"];
    [dict setObject:self.toAddress forKey:@"toAddress"];
    [dict setObject:self.msgid forKey:@"msgid"];
    [dict setObject:self.message forKey:@"message"];
    [dict setObject:self.fromAddress forKey:@"fromAddress"];
    [dict setObject:self.receivedTime forKey:@"receivedTime"];
    [dict setObject:self.lastActionTime forKey:@"lastActionTime"];
    [dict setObject:self.subject forKey:@"subject"];
    //[dict setObject:self.status forKey:@"status"];
    [dict setObject:[NSNumber numberWithBool:self.read] forKey:@"read"];
    return dict;
}

- (void)setDict:(NSDictionary *)dict
{
    self.encodingType = [dict objectForKey:@"encodingType"];
    self.toAddress = [dict objectForKey:@"toAddress"];
    self.msgid = [dict objectForKey:@"msgid"];
    self.message = [dict objectForKey:@"message"];
    self.fromAddress = [dict objectForKey:@"fromAddress"];
    self.receivedTime = [dict objectForKey:@"receivedTime"];
    self.lastActionTime = [dict objectForKey:@"lastActionTime"];
    self.subject = [dict objectForKey:@"subject"];
    self.read = [[dict objectForKey:@"read"] boolValue];
    self.status = [dict objectForKey:@"status"];
    self.ackData = [dict objectForKey:@"ackData"];
}

- (NSString *)subjectString
{
    return [self.subject decodedBase64];
}

- (NSString *)messageString
{
    return [self.message decodedBase64];
}

- (NSString *)nodeTitle
{
    return self.fromAddressLabel;
}

- (NSString *)nodeSubtitle
{
    return self.subjectString;
}

- (NSString *)fromAddressLabel
{
    NSString *label = [self.client labelForAddress:self.fromAddress];

    if (label)
    {
        return label;
    }
    
    return self.fromAddress;
}

- (NSString *)toAddressLabel
{
    NSString *label = [self.client labelForAddress:self.toAddress];
    
    if (label)
    {
        return label;
    }
    
    return self.toAddress;
}

- (NSDate *)date
{
    NSInteger unixTime = 0;
    
    if (self.receivedTime)
    {
        unixTime = [self.receivedTime integerValue];
    }
    
    if (self.lastActionTime)
    {
        unixTime = [self.lastActionTime integerValue];
    }

    if (unixTime)
    {
        return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)unixTime];
    }
    
    return nil;
}

// -----------------------

- (void)send
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"sendMessage"];
    
    // subject and message in base64
    NSArray *params = [NSArray arrayWithObjects:self.toAddress, self.fromAddress, self.subject.encodedBase64, self.message.encodedBase64, nil];
    //message.debug = YES;
    [message setParameters:params];
    [message sendSync];
    
    //id result = [message parsedResponseValue];
    //NSLog(@"send result %@", result);
}

- (void)broadcast
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"sendBroadcast"];
    
    // subject and message in base64
    NSArray *params = [NSArray arrayWithObjects:self.fromAddress, self.subject, self.message, nil];
    
    [message setParameters:params];
    [message sendSync];
    
    id result =  [message parsedResponseValue];
    NSLog(@"broadcast result %@", result);
}

- (void)justDelete
{
    [self.client.deletedMessagesDB mark:self.msgid];
    
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"trashMessage"];
    NSArray *params = [NSArray arrayWithObjects:self.msgid, nil];
    [message setParameters:params];
    [message sendSync];
}

- (void)delete
{
    [self.nodeParent removeChild:self];

    [self justDelete];
    //id result = [message parsedResponseValue];
    //NSLog(@"delete result %@", result);

    //[self postParentChanged];
}

- (void)setReadState:(BOOL)isRead
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"getInboxMessageByID"];
    NSArray *params = [NSArray arrayWithObjects:self.msgid, [NSNumber numberWithBool:isRead], nil];
    //NSArray *params = [NSArray arrayWithObjects:self.msgid, [NSNumber numberWithInt:isRead], nil];
    [message setParameters:params];
    //message.debug = YES;
    [message sendSync];
    
    NSDictionary *response = [message parsedResponseValue];
    NSArray *items = [response objectForKey:@"inboxMessage"];
    NSDictionary *dict = [items firstObject];
    if (dict)
    {
        [self setDict:dict];
    }

    //NSLog(@"set read state %@", response);
    //_read = isRead;
}

- (BOOL)read
{
    return (_read || [self.client.readMessagesDB hasMarked:self.msgid]);
}

- (BOOL)isRead
{
    return self.read;
}


- (void)markAsRead
{
    if (!self.read)
    {
        NSLog(@"markAsRead");
        [self.client.readMessagesDB mark:self.msgid];
        [self setReadState:YES];
        [(BMMessageGroup *)self.nodeParent decrementUnreadCount];
        //[self postParentChanged];
        //[[NSNotificationCenter defaultCenter]
        //    postNotificationName:@"BMReceivedMessagesUnreadCountChanged" object:self.parentNode];
    }
}

- (void)markAsUnread
{
    if (self.read)
    {
        [self setReadState:NO];
        [self postParentChanged];
    }
}

- (NSMutableAttributedString *)messageStringWithAttributes:(NSDictionary *)attributes
{
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
    //NSMutableArray *attributedStrings = [[NSMutableArray alloc] init];
    NSString *aString = [NSString stringWithString: self.messageString];
    
    //NSString *startString = @"<attachment alt = \"mOnbTBG.jpg\" src='data:file/mOnbTBG.jpg;base64,";
    NSString *startString = @"base64,";
    //NSString *endString = @"\'";
    NSString *endString = @"\"";
    
    while (YES)
    {
        // extract image
        // spliting isn't efficient, but simple and good enough for reasonably sized messages
        
        NSMutableArray *parts = [aString splitBetweenFirst:startString andString:endString];
        
        if (parts.count < 3)
        {
            [result appendAttributedString:[[NSAttributedString alloc] initWithString:aString attributes:attributes]];
            break;
        }
        
        NSString *before = [parts objectAtIndex:0];
        [result appendAttributedString:[[NSAttributedString alloc] initWithString:before attributes:attributes]];
        NSString *middle = [parts objectAtIndex:1];
        NSString *after  = [parts objectAtIndex:2];
        
        NSData *data = middle.decodedBase64Data;
        //[data writeToFile:[@"~/test_image.jpg" stringByExpandingTildeInPath] atomically:YES];
        NSImage *image = [[NSImage alloc] initWithData:data];
        
        NSSize size = image.size;
        CGFloat maxWidth = 600.0;
        if (size.width > maxWidth)
        {
            CGFloat scale = maxWidth/size.width;
            size.width *= scale;
            size.height *= scale;
            image.size = size;
        }
        
        NSTextAttachmentCell *attachmentCell = [[NSTextAttachmentCell alloc] initImageCell:image];
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        [attachment setAttachmentCell: attachmentCell];
        NSAttributedString *attributedString = [NSAttributedString  attributedStringWithAttachment: attachment];
        [result appendAttributedString:attributedString];
        aString = after;
    }

    return result;
}

- (BOOL)nodeMatchesSearch:(NSString *)aString
{
    return [super nodeMatchesSearch:aString] ||
        [self.messageString containsCaseInsensitiveString:aString] ||
        [self.fromAddressLabel containsCaseInsensitiveString:aString] ||
        [self.toAddressLabel containsCaseInsensitiveString:aString];
    
}


@end
