// AppDelegate.m
//
// Copyright (c) 2012 Mattt Thompson (http://mattt.me/)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AppDelegate.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED

#import "PublicTimelineViewController.h"

#import "AFNetworkActivityIndicatorManager.h"

#import "AFObjectsRequestOperation.h"
#import "Tweet.h"
#import "User.h"

@implementation AppDelegate
@synthesize window = _window;
@synthesize navigationController = _navigationController;

- (BOOL)application:(UIApplication *)application 
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{
    
#if 1 //TEST
    
    AFObjectMapper* userMapper = [[AFObjectMapper alloc] initWithClass:[User class]];
    [userMapper mapKeyPath:@"id" toAttribute:@"userID"];
    [userMapper mapKeyPath:@"screen_name" toAttribute:@"username"];
    [userMapper mapKeyPath:@"profile_image_url_https" toAttribute:@"_profileImageURLString"];
    
    AFObjectMapper* tweetMapper = [[AFObjectMapper alloc] initWithClass:[Tweet class]];
    [tweetMapper mapKeyPath:@"id" toAttribute:@"tweetID"];
    [tweetMapper mapKeyPath:@"text" toAttribute:@"text"];
    [tweetMapper mapKeyPath:@"user" toAttribute:@"user" withMapper:userMapper];
    
    [AFObjectsRequestOperation addObjectMapper:tweetMapper forPath:@"statuses/public_timeline.json"];
    
    AFObjectsRequestOperation* operation = [[AFObjectsRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"statuses/public_timeline.json"]]];
    NSArray* timeline = @[  @{
                                @"id" : @1,
                                @"text" : @"messaggio 1",
                                @"user" : @[ @{
                                            @"id" : @11,
                                            @"screen_name" : @"crino",
                                            @"profile_image_url_https" : @"profile.png"
                                            },
    @{
    @"id" : @12,
    @"screen_name" : @"fabio",
    @"profile_image_url_https" : @"profile.png"
    }]
                            },
    @{
    @"id" : @2,
    @"text" : @"messaggio 2",
    @"user" : @[ @{
    @"id" : @21,
    @"screen_name" : @"crino",
    @"profile_image_url_https" : @"profile.png"
    },
    @{
    @"id" : @22,
    @"screen_name" : @"fabio",
    @"profile_image_url_https" : @"profile.png"
    }]
    }
                        ];
    NSMutableArray* tweets = [NSMutableArray array];
    [timeline enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL *stop) {
        id object =  [operation performSelector:@selector(processDictionary:) withObject:obj];
        if (object) {
            [tweets addObject:object];
        }
    }];
    
   
    
    
    
#endif
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024 diskCapacity:20 * 1024 * 1024 diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    UITableViewController *viewController = [[PublicTimelineViewController alloc] initWithStyle:UITableViewStylePlain];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.navigationController.navigationBar.tintColor = [UIColor darkGrayColor];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end

#else

#import "Tweet.h"
#import "User.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize tableView = _tableView;
@synthesize tweetsArrayController = _tweetsArrayController;

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024 diskCapacity:20 * 1024 * 1024 diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
    
    [self.window makeKeyAndOrderFront:self];
    
    [Tweet publicTimelineTweetsWithBlock:^(NSArray *tweets, NSError *error) {
        if (error) {
            [[NSAlert alertWithMessageText:NSLocalizedString(@"Error", nil) defaultButton:NSLocalizedString(@"OK", nil) alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@",[error localizedDescription]] runModal];
        }
        
        self.tweetsArrayController.content = tweets;
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kUserProfileImageDidLoadNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
        [self.tableView reloadData];
    }];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)application 
                    hasVisibleWindows:(BOOL)flag 
{
    [self.window makeKeyAndOrderFront:self];
    
    return YES;
}

@end

#endif