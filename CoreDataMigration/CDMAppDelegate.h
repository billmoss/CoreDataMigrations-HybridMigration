//------------------------------------------------------------------------------
//
//  CDMAppDelegate.h
//  CoreDataMigration
//
//  Created by Bill Moss on 1/10/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------

@interface CDMAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;


+ (void) handleApplicationError:(NSError*) error alertUser:(BOOL) alertUser alertTitle:(NSString*)alertTitle;
+ (void) handleApplicationAlertWithTitle:(NSString*)title message:(NSString*)message;

@end

//------------------------------------------------------------------------------
