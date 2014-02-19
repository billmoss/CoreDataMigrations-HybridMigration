//------------------------------------------------------------------------------
//
//  CDMModelMigrationManager.m
//  CoreDataMigration
//
//  Created by Bill Moss on 1/10/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import "CDMModelMigrationManager.h"
#import "NSManagedObjectModel+ModelPaths.h"
#import "NSMappingModel+MappingModelPaths.h"

//------------------------------------------------------------------------------

@interface CDMModelMigrationManager ()

@property (strong, nonatomic) NSArray                   *modelPaths;
@property (strong, nonatomic) NSArray                   *mappingModelPaths;
@property (strong, nonatomic) NSDictionary              *modelsMappings;

@end


//------------------------------------------------------------------------------

@implementation CDMModelMigrationManager

//------------------------------------------------------------------------------

- (id) init
{
    self = [super init];
    if (nil != self)
    {
        // Gather up all the object models and mapping models we can find in our bundle.
        self.modelPaths = [NSManagedObjectModel allModelPaths];
        self.mappingModelPaths = [NSMappingModel allMappingModelPaths];
        [self createModelsMappingsDictionary];
    }
    
    return self;
}

//------------------------------------------------------------------------------

- (void) createModelsMappingsDictionary
{
    NSMutableDictionary *modelsMappingsDictionary = [[NSMutableDictionary alloc] initWithCapacity:self.modelPaths.count];
    for (NSString *sourceModelPath in self.modelPaths)
    {
        NSString *sourceModelName = [[sourceModelPath stringByDeletingPathExtension] lastPathComponent];
        NSMutableDictionary *sourceModelMappings = [[NSMutableDictionary alloc] initWithCapacity:5];
        NSDictionary *sourceModelInfo = @{@"path": sourceModelPath, @"mappings": sourceModelMappings};
        [modelsMappingsDictionary setValue:sourceModelInfo forKey:sourceModelName];
    }
    
    for (NSString *sourceToDestinationMappingModelPath in self.mappingModelPaths)
    {
        // Looking for mapping models with name pattern "<modelName>To<destinationModelName>.cdm" or
        // "<modelName>To<destinationModelName>-<part#>.cdm"
        
        NSArray *mappingModelPathComponents = [[[[[sourceToDestinationMappingModelPath stringByDeletingPathExtension] lastPathComponent] componentsSeparatedByString:@"-"] firstObject] componentsSeparatedByString:@"To"];
        NSString *sourceModelName = mappingModelPathComponents[0];
        NSDictionary *sourceModelInfo = [modelsMappingsDictionary valueForKey:sourceModelName];
        NSMutableDictionary *sourceModelMappings = [sourceModelInfo valueForKey:@"mappings"];
        
        NSMutableArray *mappingModelPaths = [sourceModelMappings valueForKey:mappingModelPathComponents[1]];
        if (nil == mappingModelPaths)
        {
            mappingModelPaths = [NSMutableArray arrayWithObject:sourceToDestinationMappingModelPath];
            [sourceModelMappings setValue:mappingModelPaths forKey:mappingModelPathComponents[1]];
        }
        else
        {
            [mappingModelPaths addObject:sourceToDestinationMappingModelPath];
        }
        
    }
    
    for (NSDictionary *sourceModelInfo in modelsMappingsDictionary.allValues)
    {
        NSMutableDictionary *sourceModelMappings = [sourceModelInfo valueForKey:@"mappings"];
        for (NSMutableArray *mappingModelPaths in sourceModelMappings.allValues)
        {
            // Sort the mapping model paths by part number.
            [mappingModelPaths sortUsingComparator:^NSComparisonResult(NSString* mapping1, NSString* mapping2)
             {
                 NSComparisonResult comparisonResult = [mapping1 compare:mapping2 options:NSNumericSearch];
                 return comparisonResult;
             }];
        }
    }

    self.modelsMappings = modelsMappingsDictionary;
}

//------------------------------------------------------------------------------

- (BOOL) migratePersistentStoreURL:(NSURL *)persistentStoreURL ofType:(NSString *)type finalDestinationModel:(NSManagedObjectModel *)finalDestinationModel error:(NSError **)error
{
    // Get info about the current persistent store.
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:type URL:persistentStoreURL error:error];
    if (nil == sourceMetadata)
    {
        // Arg, meta data error. All we can do is bail.
        return NO;
    }
    
    // Is the store already at the final model version?
    if (YES == [finalDestinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata])
    {
        if (NULL != error)
        {
            // Indicate no error to caller.
            *error = nil;
        }
        return YES;
    }
    
    // Migration is needed. Gather info on the persistent store current model.
    NSManagedObjectModel *sourceModel = [self sourceModelForSourceMetadata:sourceMetadata];
    
    // We will progressively migrate from current persistent store model to desired final model.
    NSManagedObjectModel *destinationModel;
    NSDictionary *mappingModels;
    
    if (NO == [self getMigrationSettingsToFinalDestinationModel:finalDestinationModel fromSourceModel:sourceModel destinationModel:&destinationModel mappingModels:&mappingModels error:error])
    {
        // No mapping for source model.
        return NO;
    }

    // We have the settings to use for migration to next destination model.

    NSString *destinationModelName = [destinationModel modelIdentifier];
    NSURL *destinationStoreURL = [self destinationStoreURLWithSourceStoreURL:persistentStoreURL modelName:destinationModelName];
    NSMigrationManager *migrationManager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel destinationModel:destinationModel];

    NSLog(@"Migration from %@ to %@ Started", [sourceModel modelIdentifier], destinationModelName);

    BOOL migrationSucceeded = NO;
    NSArray *mappingModelPaths = [mappingModels valueForKey:@"paths"];
    NSArray *mappingModelOrder = [mappingModels valueForKey:@"models"];
    for (NSMappingModel *mappingModel in mappingModelOrder)
    {
        NSLog(@"Using mapping model: %@", [mappingModelPaths objectAtIndex:[mappingModelOrder indexOfObject:mappingModel]]);
        migrationSucceeded = [migrationManager migrateStoreFromURL:persistentStoreURL type:type options:nil withMappingModel:mappingModel toDestinationURL:destinationStoreURL destinationType:type destinationOptions:nil error:error];
        if (NO == migrationSucceeded)
        {
            return NO;
        }
    }
    migrationManager = nil;
    
    // Migration was successful, move the files around to preserve the source in case things go bad.
    if (NO == [self cleanupMigrationForSourceStoreURL:persistentStoreURL movingDestinationStoreAtURL:destinationStoreURL error:error])
    {
        return NO;
    }

    NSLog(@"Migration Successful");

    // We may not be at the "current" model yet, so continue migration from the just migrated model to final model.
    return [self migratePersistentStoreURL:persistentStoreURL ofType:type finalDestinationModel:finalDestinationModel error:error];
}

//------------------------------------------------------------------------------

- (NSManagedObjectModel*) sourceModelForSourceMetadata:(NSDictionary *)sourceMetadata
{
    return [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]]
                                       forStoreMetadata:sourceMetadata];
}

//------------------------------------------------------------------------------

- (BOOL) getMigrationSettingsToFinalDestinationModel:(NSManagedObjectModel*)finalDestinationModel fromSourceModel:(NSManagedObjectModel *)sourceModel destinationModel:(NSManagedObjectModel **)destinationModel mappingModels:(NSDictionary **)mappingModels error:(NSError **)error
{
    
    BOOL migrationSettingsFound = NO;
    
    NSString *sourceModelName = [sourceModel modelIdentifier];
    NSString *finalDestinationModelName = [finalDestinationModel modelIdentifier];

    // Do we have any mapping models for the source model?
    NSDictionary *sourceModelInfo = [self.modelsMappings objectForKey:sourceModelName];
    NSDictionary *sourceModelMappings = [sourceModelInfo objectForKey:@"mappings"];
    if (sourceModelMappings.count > 0)
    {
        // Do we have a mapping to the final destination model?
        NSArray *sourceToDestinationMappingModelPaths = [sourceModelMappings valueForKey:finalDestinationModelName];
        if (sourceToDestinationMappingModelPaths.count > 0)
        {
            // We found mapping from source to final destination.
            *destinationModel = finalDestinationModel;
            migrationSettingsFound = YES;
        }
        else
        {
            // We don't have a mapping for the final destination model.
            
            // So, consider for example, source is Model4, and destination is Model10
            // Model4 has mappings to get to Model6 and Model8
            // We can't just migrate from Model4 to Model10, we need to pass through one of the Model6 or Model8 mappings or possibly use inferred mapping.
            
            // Why? Model4ToModel6 or Model4ToModel8 mappings have logic needing to run for valid migration path.
            
            // Scenarios for a Model4 to <some destination model> using Model4 mappings...
            // If the destination is Model7, we use Model4ToModel6 mappings
            // If the destination is Model9 or higher, we can skip Model4ToModel6 and use Model4ToModel8 mapping. This saves us a migration step.
            // If the destination is Model5, then we can't use Model4ToModel6 or Model4ToModel8...we'd resort to using an inferred mapping since a developer supplied one is not available.
            
            // Start the process by sorting the mappings by Model<version>
            NSMutableArray *destinationModelMappings = [NSMutableArray arrayWithArray:[sourceModelMappings allKeys]];
            [destinationModelMappings sortUsingComparator:^NSComparisonResult(NSString* destinationModelName1, NSString* destinationModelName2)
            {
                NSComparisonResult comparisonResult = [destinationModelName1 compare:destinationModelName2  options:NSNumericSearch];
                return comparisonResult;
            }];
            
            // Find mappings for highest model version that is less than or equal to final destination model
            NSString *candidateDestinationModelName = nil;
            for (NSString *modelName in destinationModelMappings)
            {
                NSComparisonResult comparisonResult = [finalDestinationModelName compare:modelName options:NSNumericSearch];
                if (comparisonResult == NSOrderedDescending)
                {
                    candidateDestinationModelName = modelName;
                }
            }

            if (nil != candidateDestinationModelName)
            {
                NSString *candidateDestinationModelPath = [[self.modelsMappings objectForKey:candidateDestinationModelName] objectForKey:@"path"];
                NSManagedObjectModel *candidateDestinationManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:candidateDestinationModelPath]];
                *destinationModel = candidateDestinationManagedObjectModel;
                sourceToDestinationMappingModelPaths = [sourceModelMappings valueForKey:candidateDestinationModelName];
                migrationSettingsFound = YES;
            }
        }

        if (YES == migrationSettingsFound)
        {
            // Load the mapping models.
            NSMutableArray *orderedMappingModels = [NSMutableArray arrayWithCapacity:sourceToDestinationMappingModelPaths.count];
            NSMutableArray *orderedMappingModelPaths = [NSMutableArray arrayWithCapacity:sourceToDestinationMappingModelPaths.count];
            NSDictionary *sourceToDestinationMappingModelsDictionary = @{@"models": orderedMappingModels, @"paths" : orderedMappingModelPaths};
            
            for (NSString *sourceToDestinationMappingModelPath in sourceToDestinationMappingModelPaths)
            {
                NSURL *mappingModelURL = [NSURL fileURLWithPath:sourceToDestinationMappingModelPath];
                NSMappingModel *mappingModel = [[NSMappingModel alloc] initWithContentsOfURL:mappingModelURL];
                [orderedMappingModels addObject:mappingModel];
                [orderedMappingModelPaths addObject:sourceToDestinationMappingModelPath];
                NSLog(@"Found mapping model %@", mappingModelURL.absoluteString);
                
            }
            *mappingModels = sourceToDestinationMappingModelsDictionary;
        }
    }
    
    
    if (NO == migrationSettingsFound)
    {
        // Did not find mapping from source model.
        
        // Attempt to build an inferred mapping to next destination model that has mappings.
        
        // Sort model names by version portion. Ex: Model1 < Model2 < Model3 < Model12 < Model42
        NSMutableArray *modelsMappingsNames = [NSMutableArray arrayWithArray:[self.modelsMappings allKeys]];
        [modelsMappingsNames sortUsingComparator:^NSComparisonResult(NSString* modelName1, NSString* modelName2)
         {
             NSComparisonResult comparisonResult = [modelName1 compare:modelName2 options:NSNumericSearch];
             return comparisonResult;
         }];
        
        BOOL finalDestinationModelReached = NO;
        NSString *candidateDestinationModelName = finalDestinationModelName;
        for (NSString *modelName in modelsMappingsNames)
        {
            NSComparisonResult comparisonResult = [finalDestinationModelName compare:modelName options:NSNumericSearch];
            if (comparisonResult == NSOrderedSame)
            {
                // We have reached the final destination model.
                finalDestinationModelReached = YES;
                break;
            }
            else
            {
                comparisonResult = [sourceModelName compare:modelName options:NSNumericSearch];
                if (comparisonResult == NSOrderedAscending)
                {
                    candidateDestinationModelName = modelName;
                    // We need to stop here if the destination model has mapping models to migrate it to the next model.
                    // Can't hop over custom migrations when attempting an inferred mapping.
                    NSDictionary *destinationModelInfo = [self.modelsMappings objectForKey:candidateDestinationModelName];
                    NSDictionary *destinationModelMappings = [destinationModelInfo objectForKey:@"mappings"];
                    if (destinationModelMappings.count > 0)
                    {
                        // Found mappings for this destination...so we can't go any further with inferred mapping.
                        break;
                    }
                }
            }
        }
        
        if (nil != candidateDestinationModelName)
        {
            NSManagedObjectModel *candidateDestinationManagedObjectModel;
            if (YES == finalDestinationModelReached)
            {
                candidateDestinationManagedObjectModel = finalDestinationModel;
            }
            else
            {
                NSString *candidateDestinationModelPath = [[self.modelsMappings objectForKey:candidateDestinationModelName] objectForKey:@"path"];
                candidateDestinationManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:candidateDestinationModelPath]];
            }
            
            NSMappingModel *inferredMappingModel = [NSMappingModel inferredMappingModelForSourceModel:sourceModel destinationModel:candidateDestinationManagedObjectModel error:error];
            if (nil != inferredMappingModel)
            {
                NSLog(@"Created inferred mapping model");
                *destinationModel = candidateDestinationManagedObjectModel;
                *mappingModels = @{@"models": @[inferredMappingModel], @"paths": @[@"Inferred mapping model"]};
                migrationSettingsFound = YES;
            }
        }
    }

    if (YES == migrationSettingsFound)
    {
        if(NULL != error)
        {
            // Indicate no error to caller.
            *error = nil;
        }
    }
    
    return migrationSettingsFound;
}

//------------------------------------------------------------------------------

- (NSURL*) destinationStoreURLWithSourceStoreURL:(NSURL *)sourceStoreURL modelName:(NSString *)modelName
{
    // We have a mapping model, time to migrate
    NSString *storeExtension = sourceStoreURL.path.pathExtension;
    NSString *storePath = sourceStoreURL.path.stringByDeletingPathExtension;
    
    // Build a path to write the new store
    storePath = [NSString stringWithFormat:@"%@.%@.%@", storePath, modelName, storeExtension];
    return [NSURL fileURLWithPath:storePath];
}

//------------------------------------------------------------------------------

- (BOOL) cleanupFilesForSourceStoreURL:(NSURL *)sourceStoreURL error:(NSError **)error
{
    BOOL cleanupSuccess = YES;
    
    // We have a mapping model, time to migrate
    NSString *storeExtension = sourceStoreURL.path.pathExtension;
    NSString *storePath = sourceStoreURL.path.stringByDeletingPathExtension;
    
    // Cleanup and SQLite support files we expect.
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *filePath = [NSString stringWithFormat:@"%@.%@-%@", storePath, storeExtension, @"wal"];
    if (YES == [fileManager fileExistsAtPath:filePath])
    {
        cleanupSuccess = [fileManager removeItemAtPath:filePath error:error];
    }

    filePath = [NSString stringWithFormat:@"%@.%@-%@", storePath, storeExtension, @"shm"];
    if (YES == [fileManager fileExistsAtPath:filePath])
    {
        cleanupSuccess = [fileManager removeItemAtPath:filePath error:error] && cleanupSuccess;
    }
    
    if (YES == cleanupSuccess)
    {
        if (NULL != error)
        {
            // Indicate no error to caller.
            *error = nil;
        }
    }
    return cleanupSuccess;
}

//------------------------------------------------------------------------------

- (BOOL) cleanupMigrationForSourceStoreURL:(NSURL *)sourceStoreURL movingDestinationStoreAtURL:(NSURL *)destinationStoreURL error:(NSError **)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *GUID = [[NSProcessInfo processInfo] globallyUniqueString];

    NSString *storeExtension = sourceStoreURL.path.pathExtension;
    NSString *storePath = sourceStoreURL.path.stringByDeletingPathExtension;

    NSString *filePath = [NSString stringWithFormat:@"%@.%@", GUID, storeExtension];
    NSString *backupPath = [NSTemporaryDirectory() stringByAppendingPathComponent:filePath];
    
    // Move source .sqlite file
    if (NO == [fileManager moveItemAtPath:sourceStoreURL.path toPath:backupPath error:error])
    {
        // Failed to move the source file to the backup temp area.
        return NO;
    }

    // Move wal file
    filePath = [NSString stringWithFormat:@"%@.%@-%@", storePath, storeExtension, @"wal"];
    if (YES == [fileManager fileExistsAtPath:filePath])
    {
        backupPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@-%@", GUID, storeExtension, @"wal"]];
        if (NO == [fileManager moveItemAtPath:filePath toPath:backupPath error:error])
        {
            // Failed to move the source file to the backup temp area.
            return NO;
        }
    }

    // Move shm file
    filePath = [NSString stringWithFormat:@"%@.%@-%@", storePath, storeExtension, @"shm"];
    if (YES == [fileManager fileExistsAtPath:filePath])
    {
        backupPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@-%@", GUID, storeExtension, @"shm"]];
        if (NO == [fileManager moveItemAtPath:filePath toPath:backupPath error:error])
        {
            // Failed to move the source file to the backup temp area.
            return NO;
        }
    }

    
    // Now, move the destination store to the source path
    NSString *destinationStoreExtension = destinationStoreURL.path.pathExtension;
    NSString *destinationStorePath = destinationStoreURL.path.stringByDeletingPathExtension;

    if (NO == [fileManager moveItemAtPath:destinationStoreURL.path toPath:sourceStoreURL.path error:error])
    {
        //Try to back out the source move first, no point in checking it for errors
        [fileManager moveItemAtPath:backupPath toPath:sourceStoreURL.path error:nil];
        return NO;
    }

    // Move destination wal file
    NSString *destinationFilePath = [NSString stringWithFormat:@"%@.%@-%@", destinationStorePath, destinationStoreExtension, @"wal"];
    if (YES == [fileManager fileExistsAtPath:destinationFilePath])
    {
        filePath = [NSString stringWithFormat:@"%@.%@-%@", storePath, storeExtension, @"wal"];
        if (NO == [fileManager moveItemAtPath:destinationFilePath toPath:filePath error:error])
        {
            // Failed to move the source file to the backup temp area.
            return NO;
        }
    }
    
    // Move destination wal file
    destinationFilePath = [NSString stringWithFormat:@"%@.%@-%@", destinationStorePath, destinationStoreExtension, @"shm"];
    if (YES == [fileManager fileExistsAtPath:destinationFilePath])
    {
        filePath = [NSString stringWithFormat:@"%@.%@-%@", storePath, storeExtension, @"shm"];
        if (NO == [fileManager moveItemAtPath:destinationFilePath toPath:filePath error:error])
        {
            // Failed to move the source file to the backup temp area.
            return NO;
        }
    }

    if (NULL != error)
    {
        // Indicate no error to caller.
        *error = nil;
    }
    return YES;
}

//------------------------------------------------------------------------------

#pragma mark - Policy Helpers

//------------------------------------------------------------------------------


//------------------------------------------------------------------------------

@end

//------------------------------------------------------------------------------
