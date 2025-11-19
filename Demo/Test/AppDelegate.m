//
//  AppDelegate.m
//  Test
//
//  Created by test on 2025/5/13.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _window.rootViewController = [ViewController new];
    _window.backgroundColor = [UIColor whiteColor];
    [_window makeKeyAndVisible];
    
    return YES;
}

@end
