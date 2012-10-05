//
//  AFObjectsRequestOperation.h
//  AFNetworking iOS Example
//
//  Created by Cristiano Severini on 26/09/12.
//  Copyright (c) 2012 Gowalla. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperation.h"

@interface AFObjectMapper : NSObject

@property (nonatomic, readonly) Class objectClass;

-(id)initWithClass:(Class)objectClass;

-(void)mapKeyPath:(NSString*)keyPath toAttribute:(NSString*)attribute;

-(void)mapKeyPath:(NSString*)keyPath toAttribute:(NSString *)attribute withMapper:(AFObjectMapper*)mapper;

@end



@interface AFObjectsRequestOperation : AFHTTPRequestOperation

@property (readonly, nonatomic) NSArray* responseObjects;

+ (void)addObjectMapper:(AFObjectMapper*)mapper forPath:(NSString*)path;
+ (void)removeObjectMapper:(AFObjectMapper*)mapper;
+ (void)removeObjectMapperForPath:(NSString*)path;
+ (void)removeAllObjectMappers;

+ (AFObjectsRequestOperation *)ObjectsRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                          success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSArray* objects))success
                                                          failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSArray* objects))failure;

@end
