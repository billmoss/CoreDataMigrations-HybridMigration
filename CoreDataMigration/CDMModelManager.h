//------------------------------------------------------------------------------
//
//  CDMModelManager.h
//  CoreDataMigration
//
//  Created by Bill Moss on 1/10/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

//------------------------------------------------------------------------------

@interface CDMModelManager : NSObject

@property (strong, nonatomic, readonly) NSManagedObjectContext              *mainManagedObjectContext;
@property (strong, nonatomic, readonly) NSManagedObjectModel                *managedObjectModel;
@property (strong, nonatomic, readonly) NSPersistentStoreCoordinator        *persistentStoreCoordinator;
@property (strong, nonatomic, readonly) NSURL                               *persistentStoreURL;
@property (strong, nonatomic, readonly) NSString                            *storeType;


- (NSPersistentStore*) addPersistentStoreWithOptions:(NSDictionary*)options error:(NSError**)error;

// Migration
- (BOOL) isMigrationNeeded;
- (BOOL) isMigrationPossible;
- (NSMappingModel*) inferredMappingModelForMigration;


// Utility and Helpers
- (NSManagedObjectModel*) persistentStoreManagedObjectModel;
- (BOOL) doesSamplePersistentStoreExist;
- (BOOL) createSamplePersistentStore:(NSError**)error;

@end

//------------------------------------------------------------------------------
