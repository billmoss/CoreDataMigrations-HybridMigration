//------------------------------------------------------------------------------
//
//  CDMModelManager.m
//  CoreDataMigration
//
//  Created by Bill Moss on 1/10/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import "CDMModelManager.h"
#import "CDMAppDelegate.h"

//------------------------------------------------------------------------------

@interface CDMModelManager ()

@property (strong, nonatomic) NSManagedObjectContext            *mainManagedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel              *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator      *persistentStoreCoordinator;

@end

//------------------------------------------------------------------------------

@implementation CDMModelManager

//------------------------------------------------------------------------------


//------------------------------------------------------------------------------

- (NSManagedObjectContext*) mainManagedObjectContext
{
    // Returns the managed object context for the application.
    // If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
    
    if (_mainManagedObjectContext != nil) {
        return _mainManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        _mainManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
//        [_mainManagedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
        [_mainManagedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _mainManagedObjectContext;
}


//------------------------------------------------------------------------------

- (NSManagedObjectModel*) managedObjectModel
{
    // Returns the managed object model for the application.
    // If the model doesn't already exist, it is created from the application's model.
    
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    
    
    NSString *momPath = [[NSBundle mainBundle] pathForResource:@"Model"
                                                         ofType:@"momd"];
    
    if (!momPath)
    {
        momPath = [[NSBundle mainBundle] pathForResource:@"Model"
                                                   ofType:@"mom"];
    }
    
    NSURL *modelURL = [NSURL fileURLWithPath:momPath];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    //NSDictionary *entityHashes = [_managedObjectModel entityVersionHashesByName];
    
    return _managedObjectModel;
}


//------------------------------------------------------------------------------

- (NSManagedObjectModel*) persistentStoreManagedObjectModel
{
    NSError *error = nil;
    NSDictionary *sourceMetadata = [self sourceMetadata:&error];
    if (nil != error)
    {
        [CDMAppDelegate handleApplicationError:error alertUser:YES alertTitle:@"persistentStoreManagedObjectModel"];
        return nil;
    }
    
    return [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]]
                                       forStoreMetadata:sourceMetadata];
}

//------------------------------------------------------------------------------

- (NSString*) storeType
{
    return NSSQLiteStoreType;
}


//------------------------------------------------------------------------------

- (NSDictionary*) sourceMetadata:(NSError **)error
{
    return [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:[self storeType] URL:[self persistentStoreURL] error:error];
}


//------------------------------------------------------------------------------

- (NSURL*) persistentStoreURL
{
    NSString *filename = @"topics.sqlite";
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:filename];
}

//------------------------------------------------------------------------------

- (NSPersistentStoreCoordinator*) persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }

    // Init our persistent store coordinator
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    return _persistentStoreCoordinator;
}

//------------------------------------------------------------------------------

- (NSPersistentStore*) addPersistentStoreWithOptions:(NSDictionary*)options error:(NSError**)error
{
    NSURL *storeURL = [self persistentStoreURL];
    
    NSPersistentStore *persistentStore = [self.persistentStoreCoordinator addPersistentStoreWithType:[self storeType] configuration:nil URL:storeURL options:options error:error];
    return persistentStore;
}

//------------------------------------------------------------------------------

- (void) deletePersistentStoreURL:(NSURL*)storeURL
{
    NSError *error = nil;
    if (NO == [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error])
    {
        [CDMAppDelegate handleApplicationError:error alertUser:YES alertTitle:@"deletePersistentStoreURL"];
    }
}

//------------------------------------------------------------------------------

- (void) deletePersistentStore
{
    [self deletePersistentStoreURL:[self persistentStoreURL]];
}


//------------------------------------------------------------------------------
#pragma mark - Application's Documents directory
//------------------------------------------------------------------------------

// Returns the URL to the application's Documents directory.
- (NSURL *) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


//------------------------------------------------------------------------------
#pragma mark - Public Methods
//------------------------------------------------------------------------------

- (BOOL) doesSamplePersistentStoreExist
{
    NSURL *storeURL = [self persistentStoreURL];
    return [[NSFileManager defaultManager] fileExistsAtPath:storeURL.path];
}

//------------------------------------------------------------------------------

- (BOOL) createSamplePersistentStore:(NSError**)error
{
    NSAssert(NO == [self doesSamplePersistentStoreExist], @"Sample persistent store already exists.");
    
    BOOL success = YES;
    
    if (nil != [self addPersistentStoreWithOptions:nil error:error])
    {
        NSManagedObjectContext *managedObjectContext = [self mainManagedObjectContext];
        success = [self createSampleData:managedObjectContext];
    }
    
    return success;
}


//------------------------------------------------------------------------------
#pragma mark - Data Migration
//------------------------------------------------------------------------------

- (BOOL) isMigrationNeeded
{
    BOOL migrationNeeded = NO;
    NSError *error = nil;
    
    // Check if we need to migrate
    NSDictionary *sourceMetadata = [self sourceMetadata:&error];
    if (nil != error)
    {
        [CDMAppDelegate handleApplicationError:error alertUser:YES alertTitle:@"sourceMetadata"];
        return migrationNeeded;
    }
    
    if (nil != sourceMetadata)
    {
        NSManagedObjectModel *destinationModel = [self managedObjectModel];
        
        // Migration is needed if destinationModel is NOT compatible
        migrationNeeded = ![destinationModel isConfiguration:nil
                                    compatibleWithStoreMetadata:sourceMetadata];
    }
    
    return migrationNeeded;
}

//------------------------------------------------------------------------------

- (BOOL) isMigrationPossible
{
    return YES;
}

//------------------------------------------------------------------------------

- (NSMappingModel*) inferredMappingModelForMigration
{
    NSError *error = nil;
    NSMappingModel *mappingModel = nil;
    
    NSManagedObjectModel *currentStoreModel = [self persistentStoreManagedObjectModel];
    NSManagedObjectModel *newStoreModel = [self managedObjectModel];
    
    if (nil != currentStoreModel && nil != newStoreModel)
    {
        mappingModel = [NSMappingModel inferredMappingModelForSourceModel:currentStoreModel destinationModel:newStoreModel error:&error];
    }
    return mappingModel;
}

                                
//------------------------------------------------------------------------------
#pragma mark - Sample Data
//------------------------------------------------------------------------------

- (BOOL) createSampleData:(NSManagedObjectContext*)managedObjectContext
{
//    NSArray *topicListTitles = @[@"alpha", @"bravo", @"charlie", @"delta", @"echo", @"foxtrot", @"golf", @"hotel", @"india", @"juliett", @"kilo",
//                          @"lima", @"mike", @"november", @"oscar", @"papa", @"quebec", @"romeo", @"sierra", @"tango", @"uniform", @"victor",
//                          @"whiskey", @"xray", @"yankee", @"zulu",
//                          @"Alpha", @"Bravo", @"Charlie", @"Delta", @"Echo", @"Foxtrot", @"Golf", @"Hotel", @"India", @"Juliett", @"Kilo",
//                          @"Lima", @"Mike", @"November", @"Oscar", @"Papa", @"Quebec", @"Romeo", @"Sierra", @"Tango", @"Uniform", @"Victor",
//                          @"Whiskey", @"Xray", @"Yankee", @"Zulu"];

    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SampleData" ofType:@"plist"];
    NSDictionary *sampleDataDictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    NSArray *topicLists = [sampleDataDictionary valueForKey:@"topicLists"];

    for (NSDictionary *topicListDictionary in topicLists)
    {
        NSString *topicListTitle = [topicListDictionary valueForKey:@"title"];
        NSManagedObject *topicList = [NSEntityDescription insertNewObjectForEntityForName:@"TopicList" inManagedObjectContext:managedObjectContext];
        [topicList setValue:topicListTitle forKey:@"title"];
        
        
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Topic" inManagedObjectContext:managedObjectContext];
        NSDictionary *properties = [entityDescription propertiesByName];
        BOOL hasTimeBudget = (nil != [properties valueForKey:@"timeBudget"]);
        
        NSArray *topics = [topicListDictionary valueForKey:@"topics"];

        for (NSDictionary *topicDictionary in topics)
        {
            NSManagedObject *topic = [NSEntityDescription insertNewObjectForEntityForName:@"Topic" inManagedObjectContext:managedObjectContext];
            [topic setValue:[NSDate date] forKeyPath:@"dateCreated"];

            NSString *content = [topicDictionary valueForKey:@"content"];
            [topic setValue:content forKey:@"content"];

            NSString *presenter = [topicDictionary valueForKey:@"presenterName"];
            [topic setValue:presenter forKey:@"presenterName"];

            NSString *presenterEmail = [topicDictionary valueForKey:@"presenterEmail"];
            [topic setValue:presenterEmail forKey:@"presenterEmail"];

            if (YES == hasTimeBudget)
            {
                NSNumber *timeBudget = [topicDictionary valueForKey:@"timeBudget"];
                [topic setValue:timeBudget forKey:@"timeBudget"];
            }
            
            [topic setValue:topicList forKey:@"topicList"];
        }
    }

    NSError *error;
    BOOL success = [managedObjectContext save:&error];
    if (nil != error)
    {
        [CDMAppDelegate handleApplicationError:error alertUser:YES alertTitle:@"createSampleData"];
    }
    
    return success;
}

//------------------------------------------------------------------------------
@end
//------------------------------------------------------------------------------
