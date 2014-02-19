//------------------------------------------------------------------------------
//
//  CDMRootViewController.m
//  CoreDataMigration
//
//  Created by Bill Moss on 1/10/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import "CDMRootViewController.h"
#import "CDMModelManager.h"
#import "CDMAppDelegate.h"
#import "CDMTopicListsViewController.h"
#import "CDMModelMigrationManager.h"
#import "NSManagedObjectModel+ModelPaths.h"

//------------------------------------------------------------------------------

@interface CDMRootViewController ()

@property (strong, nonatomic) CDMModelManager       *modelManager;

@property (weak, nonatomic) IBOutlet UIButton       *storeOpenMigrateButton;
@property (weak, nonatomic) IBOutlet UILabel        *storeModelVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel        *appModelVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel        *storeAndAppCompatibleLabel;
@property (weak, nonatomic) IBOutlet UILabel        *inferredModelIsAvailableLabel;

@property (nonatomic) BOOL                          storeAndAppAreCompatible;
@end

//------------------------------------------------------------------------------
@implementation CDMRootViewController
//------------------------------------------------------------------------------

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
    }
    return self;
}

//------------------------------------------------------------------------------

- (void) viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.storeAndAppCompatibleLabel.text = nil;
    self.inferredModelIsAvailableLabel.text = nil;

    // Create sample store if we don't have one.
    NSError *error = nil;
    self.modelManager = [CDMModelManager new];
    if (NO == [self.modelManager doesSamplePersistentStoreExist])
    {
        [self.modelManager createSamplePersistentStore:&error];
        if (nil != error)
        {
            [CDMAppDelegate handleApplicationError:error alertUser:YES alertTitle:@"Create Store Failed"];
        }
        else
        {
            self.storeAndAppAreCompatible = YES;
            self.storeAndAppCompatibleLabel.text = @"✓ Models are compatible.";
            [CDMAppDelegate handleApplicationAlertWithTitle:@"Sample Store was Created" message:nil];
            [self.storeOpenMigrateButton setTitle:@"View Store Data" forState:UIControlStateNormal];
            [self.storeOpenMigrateButton addTarget:self action:@selector(handleShowTopicLists) forControlEvents:UIControlEventTouchUpInside];
            [self handleShowTopicLists];
        }
    }
    else
    {
        if (YES == [self.modelManager isMigrationNeeded])
        {
            self.storeAndAppAreCompatible = NO;
            self.storeAndAppCompatibleLabel.text = @"✕ Models are incompatible.";

            NSMappingModel *inferredMappingModel = [self.modelManager inferredMappingModelForMigration];
            BOOL inferredMappingModelAvailable = nil != inferredMappingModel;
            self.inferredModelIsAvailableLabel.text = inferredMappingModelAvailable ? @"✓ Lightweight migration available." : @"✕ Can't infer mapping model.";
        }
        else
        {
            self.storeAndAppAreCompatible = YES;
            self.storeAndAppCompatibleLabel.text = @"✓ Models are compatible.";
        }

        [self.storeOpenMigrateButton setTitle:@"Open Persistent Store" forState:UIControlStateNormal];
        [self.storeOpenMigrateButton addTarget:self action:@selector(handleOpenPersistentStore:) forControlEvents:UIControlEventTouchUpInside];
    }

    [self updateStoreModelVersionLabel];
    
    NSManagedObjectModel *appModel = [self.modelManager managedObjectModel];
    NSSet *versionIdentifers = appModel.versionIdentifiers;
    self.appModelVersionLabel.text = [versionIdentifers.allObjects firstObject];
}

//------------------------------------------------------------------------------

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//------------------------------------------------------------------------------

#pragma mark - Navigation

//------------------------------------------------------------------------------

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (YES == [segue.identifier isEqualToString:@"ShowTopicListsSegue"])
    {
        [self handleShowTopicListsSeque:segue];
    }
}


//------------------------------------------------------------------------------

#pragma mark - Store Handling

//------------------------------------------------------------------------------

- (void) updateStoreModelVersionLabel
{
    NSManagedObjectModel *storeModel = [self.modelManager persistentStoreManagedObjectModel];
    NSSet *versionIdentifers = storeModel.versionIdentifiers;
    NSString *modelVersion = [versionIdentifers.allObjects firstObject];
    self.storeModelVersionLabel.text = modelVersion != nil ? modelVersion : @"?";
}


//------------------------------------------------------------------------------

- (IBAction) handleOpenPersistentStore:(id)sender
{
    #pragma mark Enable Hybrid/Progressive Migration
    
    if (NO == self.storeAndAppAreCompatible)
    {
        NSError *error = nil;
        
        NSLog(@"Migration Started");
        CDMModelMigrationManager *migrationManager = [[CDMModelMigrationManager alloc] init];
        BOOL migrationSucceeded = [migrationManager migratePersistentStoreURL:self.modelManager.persistentStoreURL ofType:self.modelManager.storeType finalDestinationModel:self.modelManager.managedObjectModel error:&error];
        
        if (NO == migrationSucceeded)
        {
            [CDMAppDelegate handleApplicationError:error alertUser:YES alertTitle:@"Migration Failed"];
            return;
        }
    }
    
    // Open the store now...for progressive migration...we dont have migration options.
    NSError *error = nil;
    NSPersistentStore *store = [self.modelManager addPersistentStoreWithOptions:nil error:&error];
    if (nil != error)
    {
        [CDMAppDelegate handleApplicationError:error alertUser:YES alertTitle:@"Open Store Failed"];
    }
    else if (nil != store)
    {
        [CDMAppDelegate handleApplicationAlertWithTitle:@"Open Store Successful" message:nil];
        [self.storeOpenMigrateButton setTitle:@"View Store Data" forState:UIControlStateNormal];
        [self.storeOpenMigrateButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        [self.storeOpenMigrateButton addTarget:self action:@selector(handleShowTopicLists) forControlEvents:UIControlEventTouchUpInside];
        [self handleShowTopicLists];
        [self updateStoreModelVersionLabel];
        self.storeAndAppCompatibleLabel.text = @"✓ Models are compatible.";
        self.inferredModelIsAvailableLabel.text = nil;
    }
    else
    {
        [CDMAppDelegate handleApplicationAlertWithTitle:@"Open Store Failed" message:@"NSPersistentStore is nil."];
    }
}

//------------------------------------------------------------------------------

#pragma mark - Segue Handling

//------------------------------------------------------------------------------

- (void) handleShowTopicLists
{
    [self performSegueWithIdentifier:@"ShowTopicListsSegue" sender:self];
}

//------------------------------------------------------------------------------

- (void) handleShowTopicListsSeque:(UIStoryboardSegue *)segue
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"TopicList"];
    NSArray *sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
    fetchRequest.sortDescriptors = sortDescriptors;
    
    NSFetchedResultsController *topicListsFetchController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.modelManager.mainManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    CDMTopicListsViewController *topicListsViewController = (CDMTopicListsViewController*) segue.destinationViewController;
    topicListsViewController.topicListsFetchController = topicListsFetchController;
}

//------------------------------------------------------------------------------
@end
//------------------------------------------------------------------------------
