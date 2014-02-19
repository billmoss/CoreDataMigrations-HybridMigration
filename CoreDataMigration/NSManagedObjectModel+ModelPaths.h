//------------------------------------------------------------------------------
//
//  NSManagedObjectModel+ModelPaths.h
//  CoreDataMigration
//
//  Created by Bill Moss on 1/10/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import <CoreData/CoreData.h>

//------------------------------------------------------------------------------

@interface NSManagedObjectModel (ModelPaths)

+ (NSArray*) allModelPaths;
- (NSString*) modelIdentifier;

@end

//------------------------------------------------------------------------------
