//
//  AssetManagerTestAppDelegate.m
//  AssetManagerTest
//
//  Created by Marcus S. Zarra on 3/17/11.
//  Copyright 2011 Zarra Studios LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.

#import "AppDelegate.h"
#import "ZSURLConnectionDelegate.h"

#define kFeedHREF @"http://api.flickr.com/services/feeds/groups_pool.gne?id=1621520@N24&lang=en-us&format=rss_200"

@interface AppDelegate ()
@property (readwrite, retain) GDataXMLDocument *document;
@end

@implementation AppDelegate

@synthesize assetManager;
@synthesize window;

@synthesize document;

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
  window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
  [window setBackgroundColor:[UIColor greenColor]];
  
  RootViewController *root = [[RootViewController alloc] init];
  
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:root];
  MCRelease(root);
  [[self window] setRootViewController:navigationController];
  
  [[self window] addSubview:[navigationController view]];
  MCRelease(navigationController);
  
  [[self window] makeKeyAndVisible];
  
  NSURL *feedURL = [NSURL URLWithString:kFeedHREF];
    
	ZSURLConnectionDelegate *delegate = [[ZSURLConnectionDelegate alloc] initWithURL:feedURL 
											successBlock:^(ZSURLConnectionDelegate *delegate) {
												DLog(@"success!");
												
												NSError *error = nil;
												document = [[GDataXMLDocument alloc] initWithData:[delegate data] options:0 error:&error];
												ZAssert(!error || document, @"Error parsing xml: %@", error);
												
												DLog(@"document %@", document);
												
												GDataXMLElement *channel = [[[document rootElement] elementsForName:@"channel"] lastObject];
												NSArray *items = [channel elementsForName:@"item"];
												
												NSMutableSet *cacheRequest = [[NSMutableSet alloc] init];
												for (GDataXMLElement *item in items) {
													GDataXMLElement *mediaContent = [[item elementsForName:@"media:content"] lastObject];
													ZAssert(mediaContent, @"Failed to find media:content: %@", item);
													
													NSString *urlString = [[mediaContent attributeForName:@"url"] stringValue];
													NSURL *url = [NSURL URLWithString:urlString];
													ZAssert(url, @"Bad url: %@", urlString);
													[cacheRequest addObject:url];
													
													GDataXMLElement *mediaThumbnail = [[item elementsForName:@"media:thumbnail"] lastObject];
													ZAssert(mediaThumbnail, @"Failed to find media thumbnail: %@", item);
													
													NSString *thumbnailURLString = [[mediaThumbnail attributeForName:@"url"] stringValue];
													NSURL *thumbnailURL = [NSURL URLWithString:thumbnailURLString];
													ZAssert(thumbnailURL, @"Bad URL: %@", thumbnailURLString);
													[cacheRequest addObject:thumbnailURL];
												}
												
												[assetManager queueAssetsForRetrievalFromURLSet:cacheRequest];
												MCRelease(cacheRequest);
												
												id navController = [[self window] rootViewController];
												id root = [[navController viewControllers] objectAtIndex:0];
												[root populateWithXMLItems:items];
											} 
											failureBlock:^(ZSURLConnectionDelegate *error) {
												ALog(@"Failure: %@", error);
											}];
	[[NSOperationQueue mainQueue] addOperation:delegate];
	MCRelease(delegate);
	
	assetManager = [[ZSAssetManager alloc] init];
	[root setAssetManager:assetManager];
	
	return YES;
}

- (void)dealloc
{
  MCRelease(document);
  [super dealloc];
}
@end
