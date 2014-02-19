//------------------------------------------------------------------------------
//
//  CDMModelMigrationManager.h
//  CoreDataMigration
//
//  Created by Bill Moss on 1/10/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


//------------------------------------------------------------------------------

@class CDMModelMigrationManager;

//------------------------------------------------------------------------------

@protocol CDMModelMigrationManagerDelegate <NSObject>

@optional

- (void) modelMigrationManager:(CDMModelMigrationManager *)modelMigrationManager progress:(CGFloat)progress;
- (NSArray *) modelMigrationManager:(CDMModelMigrationManager *)modelMigrationManager mappingModelsForSourceModel:(NSManagedObjectModel *)sourceModel;

@end


//------------------------------------------------------------------------------

@interface CDMModelMigrationManager : NSObject

@property (nonatomic, weak) id<CDMModelMigrationManagerDelegate> delegate;


- (BOOL) migratePersistentStoreURL:(NSURL *)persistentStoreURL ofType:(NSString *)type finalDestinationModel:(NSManagedObjectModel *)finalDestinationModel error:(NSError **)error;


// Policy helpers

@end

//------------------------------------------------------------------------------
