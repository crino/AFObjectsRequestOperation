//
//  AFObjectsRequestOperation.m
//  AFNetworking iOS Example
//
//  Created by Cristiano Severini on 26/09/12.
//  Copyright (c) 2012 Gowalla. All rights reserved.
//

#import "AFObjectsRequestOperation.h"


@interface AFObjectMapper ()
@property (readwrite, nonatomic) Class objectClass;
@property (readwrite, nonatomic) NSMutableArray* mapping;

-(id)process:(NSDictionary*)attributes;

@end


@implementation AFObjectMapper

-(id)initWithClass:(Class)objectClass {
    self = [super init];
    if (self) {
        self.objectClass = objectClass;
        self.mapping = [NSMutableArray arrayWithCapacity:5];
    }
    return self;
}

-(void)mapKeyPath:(NSString*)keyPath toAttribute:(NSString *)attribute {
    NSDictionary* simpleMap = [NSDictionary dictionaryWithObjectsAndKeys:
                               keyPath, @"k",
                               attribute, @"a", nil];
    [self.mapping addObject:simpleMap];
}

-(void)mapKeyPath:(NSString*)keyPath toAttribute:(NSString *)attribute withMapper:(AFObjectMapper*)mapper {
    NSDictionary* relMap = [NSDictionary dictionaryWithObjectsAndKeys:
                               keyPath, @"k",
                               attribute, @"a",
                               mapper, @"m", nil];
    [self.mapping addObject:relMap];
}

-(id)process:(NSDictionary*)attributes {
    id instance = [[self.objectClass alloc] init];
    [self.mapping enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idxMapping, BOOL *stopMapping) {
        if ([obj objectForKey:@"m"]) {
            // recursive
            AFObjectMapper* mapper = [obj objectForKey:@"m"];
            id child = nil;
            id childAttributes = [attributes valueForKeyPath:[obj objectForKey:@"k"]];
            if ([childAttributes isKindOfClass:[NSArray class]]) {
                child = [NSMutableArray arrayWithCapacity:[childAttributes count]];
                [childAttributes enumerateObjectsUsingBlock:^(NSDictionary* childAttribute, NSUInteger idxChildAttributes, BOOL *stopChildAttributes) {
                    id subChild = [mapper process:childAttribute];
                    if (subChild) {
                        [child addObject:subChild];
                    }
                }];
            } else if ([childAttributes isKindOfClass:[NSDictionary class]]) {
                child = [mapper process:[attributes valueForKeyPath:[obj objectForKey:@"k"]]];
            }
            if (child) {
                [instance setValue:child forKey:[obj objectForKey:@"a"]];
            }
        } else {
           [instance setValue:[attributes valueForKeyPath:[obj objectForKey:@"k"]] forKey:[obj objectForKey:@"a"]];
        }
    }];
    return instance;
}

@end



static dispatch_queue_t af_objects_request_operation_processing_queue;
static dispatch_queue_t objects_request_operation_processing_queue() {
    if (af_objects_request_operation_processing_queue == NULL) {
        af_objects_request_operation_processing_queue = dispatch_queue_create("com.alamofire.networking.objects-request.processing", 0);
    }
    return af_objects_request_operation_processing_queue;
}

static NSMutableDictionary* objects_mapper;

@interface AFObjectsRequestOperation ()
@property (readwrite, nonatomic) id JSONObject;
@property (readwrite, nonatomic) NSArray *responseObjects;
@property (readwrite, nonatomic) NSError *JSONError;
@end

@implementation AFObjectsRequestOperation
@synthesize responseObjects = _responseObjects;

+ (void)addObjectMapper:(AFObjectMapper *)mapper forPath:(NSString*)path {
    if (!objects_mapper) {
        objects_mapper = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    [objects_mapper setObject:mapper forKey:path];
}

+ (void)removeObjectMapper:(AFObjectMapper*)mapper {
    __block id keyToRemove = nil;
    [objects_mapper enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isEqual:mapper]) {
            keyToRemove = key;
            *stop = YES;
        }
    }];
    if (keyToRemove) {
        [objects_mapper removeObjectForKey:keyToRemove];
    }
}

+ (void)removeObjectMapperForPath:(NSString*)path {
    [objects_mapper removeObjectForKey:path];
}

+ (void)removeAllObjectMappers {
    [objects_mapper removeAllObjects];
}


+ (AFObjectsRequestOperation *)ObjectsRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                          success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSArray* objects))success
                                                          failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSArray* objects))failure
{
    AFObjectsRequestOperation *requestOperation = [[self alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation.request, operation.response, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error, [(AFObjectsRequestOperation *)operation responseObjects]);
        }
    }];
    
    return requestOperation;
}

#pragma mark - AFHTTPRequestOperation

+ (NSSet *)acceptableContentTypes {
    return [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[[request URL] pathExtension] isEqualToString:@"json"] || [super canProcessRequest:request];
}

- (id)JSONObject {
    if (!_JSONObject && [self.responseData length] > 0 && [self isFinished] && !self.JSONError) {
        NSError *error = nil;
        
        if ([self.responseData length] == 0) {
            self.JSONObject = nil;
        } else {
            self.JSONObject = [NSJSONSerialization JSONObjectWithData:self.responseData options:0 error:&error];
        }
        
        self.JSONError = error;
    }
    
    return _JSONObject;
}

- (NSError *)error {
    if (_JSONError) {
        return _JSONError;
    } else {
        return [super error];
    }
}

- (id)processDictionary:(NSDictionary*)dictionary {
    NSString* url = [self.request.URL absoluteString];

    __block id object = nil;
    [objects_mapper enumerateKeysAndObjectsUsingBlock:^(NSString* key, AFObjectMapper* obj, BOOL *stop) {
        NSString* regExpPattern = [NSString stringWithFormat:@"(.*?)%@(.*?)", key];
        NSArray* matches = [[NSRegularExpression regularExpressionWithPattern:regExpPattern
                                                                      options:NSRegularExpressionCaseInsensitive
                                                                        error:NULL]
                            matchesInString:url
                                    options:NSMatchingReportCompletion
                                    range:NSMakeRange(0, url.length)];
        if (matches) {
            object = [obj process:dictionary];
        }
    }];
    return object;
}

- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    self.completionBlock = ^ {
        if ([self isCancelled]) {
            return;
        }
        
        if (self.error) {
            if (failure) {
                dispatch_async(self.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
                    failure(self, self.error);
                });
            }
        } else {
            dispatch_async(objects_request_operation_processing_queue(), ^{
                id JSON = self.JSONObject;

                if (self.JSONError) {
                    if (failure) {
                        dispatch_async(self.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
                            failure(self, self.error);
                        });
                    }
                } else {
                    NSMutableArray* objects = [NSMutableArray array];
                    if ([JSON isKindOfClass:[NSArray class]]) {
                        [JSON enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL *stop) {
                            id object = [self processDictionary:obj];
                            if (object) {
                                [objects addObject:object];
                            }
                        }];
                    } else  if ([JSON isKindOfClass:[NSDictionary class]]) {
                        id object = [self processDictionary:JSON];
                        if (object) {
                            [objects addObject:object];
                        }
                    } else {
                        // NOT HANDLED
                    }
                    if (success) {
                        dispatch_async(self.successCallbackQueue ?: dispatch_get_main_queue(), ^{
                            success(self, objects);
                        });
                    }
                }
            });
        }
    };
#pragma clang diagnostic pop
}

@end
