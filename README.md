AFObjectsRequestOperation
=========================

AFNetworking Extension for RestAPI - converts response to objects directly

## Example Usage

``` objective-c
    AFObjectMapper* userMapper = [[AFObjectMapper alloc] initWithClass:[User class]];
    [userMapper mapKeyPath:@"id" toAttribute:@"userID"];
    [userMapper mapKeyPath:@"screen_name" toAttribute:@"username"];
    [userMapper mapKeyPath:@"profile_image_url_https" toAttribute:@"_profileImageURLString"];
    
    AFObjectMapper* tweetMapper = [[AFObjectMapper alloc] initWithClass:[Tweet class]];
    [tweetMapper mapKeyPath:@"id" toAttribute:@"tweetID"];
    [tweetMapper mapKeyPath:@"text" toAttribute:@"text"];
    [tweetMapper mapKeyPath:@"user" toAttribute:@"user" withMapper:userMapper];
    
    [AFObjectsRequestOperation addObjectMapper:tweetMapper forPath:@"statuses/public_timeline.json"];

	AFObjectsRequestOperation *operation = [AFObjectsRequestOperation ObjectsRequestOperationWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/public_timeline.json"]] success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSArray* objects) {
      NSLog(@"Tweets: %@", objects);
  } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSArray* objects) {
      NSLog(@"Failure!");
}];

[operation start];
```

## License

AFObjectsRequestOperation is available under the MIT license. See the LICENSE file for more info.