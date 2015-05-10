//
//  SPLAppDelegate.m
//  SPLPing
//
//  Created by CocoaPods on 05/10/2015.
//  Copyright (c) 2015 Oliver Letterer. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];

    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[ViewController alloc] init] ];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
