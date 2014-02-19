//------------------------------------------------------------------------------
//
//  CDMAppDelegate.m
//  CoreDataMigration
//
//  Created by Bill Moss on 1/10/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import "CDMAppDelegate.h"

//------------------------------------------------------------------------------
@implementation CDMAppDelegate
//------------------------------------------------------------------------------

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    return YES;
}
							
//------------------------------------------------------------------------------

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

//------------------------------------------------------------------------------

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

//------------------------------------------------------------------------------

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

//------------------------------------------------------------------------------

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

//------------------------------------------------------------------------------

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

//------------------------------------------------------------------------------
#pragma mark - Class Methods
//------------------------------------------------------------------------------

+ (void) handleApplicationError:(NSError*) error alertUser:(BOOL) alertUser alertTitle:(NSString*)alertTitle
{
    NSString *errorString;
    NSString *reasonString;
    NSString *logString;
    NSString *underlyingErrorString;
    
    if (nil != error)
    {
        errorString = error.localizedDescription;
        reasonString = [error.userInfo valueForKey:@"reason"];
        logString = errorString;
        NSError *underlyingError = [error.userInfo valueForKey:NSUnderlyingErrorKey];
        if (nil != underlyingError)
        {
            underlyingErrorString = underlyingError.debugDescription;
        }
        
        if (nil != reasonString && reasonString.length > 0)
        {
            logString = [NSString stringWithFormat:@"error: %@ reason: %@.", errorString, reasonString];
            errorString = [NSString stringWithFormat:@"error: %@\n\nreason: %@.", errorString, reasonString];
        }


        // Present Error Alert
        if ((YES == alertUser) && (nil != errorString))
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                                 message:errorString
                                                                delegate:nil
                                                       cancelButtonTitle:NSLocalizedString(@"OK", )
                                                       otherButtonTitles:nil];
            [alertView show];
        }
        
        NSLog(@"handleApplicationError: %@", logString);
        if (nil != underlyingErrorString && underlyingErrorString.length > 0)
        {
            NSLog(@"handleApplicationError: underlyingError: %@", underlyingErrorString);
        }
    }
}


//------------------------------------------------------------------------------

+ (void) handleApplicationAlertWithTitle:(NSString*)title message:(NSString*)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", )
                                              otherButtonTitles:nil];
    [alertView show];

    if (nil != message && 0 != message.length)
    {
        NSLog(@"%@: %@", title, message);
    }
    else
    {
        NSLog(@"%@", title);
    }
}

//------------------------------------------------------------------------------
@end
//------------------------------------------------------------------------------
