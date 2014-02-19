//------------------------------------------------------------------------------
//
//  CDMTopicsViewController.h
//  CoreDataMigration
//
//  Created by William Moss on 1/15/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

//------------------------------------------------------------------------------

@interface CDMTopicsViewController : UITableViewController

@property (strong, nonatomic) NSManagedObject    *topicList;

@end

//------------------------------------------------------------------------------
