//------------------------------------------------------------------------------
//
//  CDMTopicToTopicMigrationPolicy.m
//  CoreDataMigration
//
//  Created by William Moss on 1/14/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import "CDMTopicToTopicMigrationPolicy.h"
#import "NSManagedObjectModel+ModelPaths.h"

//------------------------------------------------------------------------------

@interface CDMTopicToTopicMigrationPolicy ()
@end

//------------------------------------------------------------------------------

@implementation CDMTopicToTopicMigrationPolicy

//------------------------------------------------------------------------------

- (BOOL)beginEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    NSLog(@"Topic - beginEntityMapping");
    return [super beginEntityMapping:mapping manager:manager error:error];
}

//------------------------------------------------------------------------------

- (BOOL) createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    if (nil != [sInstance.entity.attributesByName valueForKey:@"content"])
    {
        NSLog(@"Topic - createDestinationInstance: %@", [sInstance valueForKey:@"content"]);
    }
    else if (nil != [sInstance.entity.attributesByName valueForKey:@"title"])
    {
        NSLog(@"Topic - createDestinationInstance: %@", [sInstance valueForKey:@"title"]);
    }

    BOOL result = [super createDestinationInstancesForSourceInstance:sInstance entityMapping:mapping manager:manager error:error];
    if (YES == result)
    {
        NSManagedObject *dInstance = [[manager destinationInstancesForEntityMappingNamed:mapping.name sourceInstances:@[sInstance]] firstObject];

        if (YES == [[manager.sourceModel modelIdentifier] isEqualToString:@"Model1"])
        {
            // Set timeBudget as minutes...based on length of the topic content.
            NSString *content = [dInstance valueForKey:@"content"];
            double numMinutes = ceil(content.length * 0.1);
            
            NSString *lowercaseContent = [content lowercaseString];
            NSRange range = [lowercaseContent rangeOfString:@"brainstorm"];
            if (range.length > 0)
            {
                numMinutes += 15;
            }
            
            range = [lowercaseContent rangeOfString:@"legal"];
            if (range.length > 0)
            {
                numMinutes += 15;
            }
            
            NSInteger numSeconds = numMinutes * 60;
            
            NSNumber *timeBudget = [NSNumber numberWithInteger:numSeconds];
            [dInstance setValue:timeBudget forKeyPath:@"timeBudget"];
        }
    }

    return result;
}

//------------------------------------------------------------------------------

- (BOOL) endInstanceCreationForEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    NSLog(@"Topic - endInstanceCreationForEntityMapping");
    return [super endInstanceCreationForEntityMapping:mapping manager:manager error:error];
}

//------------------------------------------------------------------------------

- (BOOL) createRelationshipsForDestinationInstance:(NSManagedObject *)dInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    if (nil != [dInstance.entity.attributesByName valueForKey:@"content"])
    {
        NSLog(@"Topic - createRelationships: %@", [dInstance valueForKey:@"content"]);
    }
    else if (nil != [dInstance.entity.attributesByName valueForKey:@"title"])
    {
        NSLog(@"Topic - createRelationships: %@", [dInstance valueForKey:@"title"]);
    }

    BOOL result = [super createRelationshipsForDestinationInstance:dInstance entityMapping:mapping manager:manager error:error];
    if (YES == result)
    {
        if (YES == [[manager.sourceModel modelIdentifier] isEqualToString:@"Model4"])
        {
            NSManagedObject *sInstance = [[manager sourceInstancesForEntityMappingNamed:mapping.name destinationInstances:@[dInstance]] firstObject];
            NSString *presenterName = [sInstance valueForKey:@"presenterName"];
            NSString *presenterEmail = [sInstance valueForKey:@"presenterEmail"];
            
            NSFetchRequest *memberFetch = [[NSFetchRequest alloc] initWithEntityName:@"Member"];
            NSPredicate *memberFilter = [NSPredicate predicateWithFormat:@"firstName == %@", presenterName];
            [memberFetch setPredicate:memberFilter];
            
            NSArray *members = [manager.destinationContext executeFetchRequest:memberFetch error:error];
            if (nil != error)
            {
                if (nil == members || 0 == members.count)
                {
                    // Need to create a new member entity in the destination
                    NSManagedObject *member = [NSEntityDescription insertNewObjectForEntityForName:@"Member" inManagedObjectContext:manager.destinationContext];
                    [member setValue:presenterName forKey:@"firstName"];
                    [member setValue:presenterEmail forKey:@"email"];
                    [dInstance setValue:member forKeyPath:@"presenter"];
                    NSLog(@"Added Member named: %@", presenterName);
                }
                else
                {
                    [dInstance setValue:[members firstObject] forKeyPath:@"presenter"];
                }
            }
            else
            {
                result = NO;
            }
        }
    }

    return result;
}

//------------------------------------------------------------------------------

- (BOOL) endRelationshipCreationForEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    NSLog(@"Topic - endRelationshipCreationForEntityMapping");
    return [super endRelationshipCreationForEntityMapping:mapping manager:manager error:error];
}


//------------------------------------------------------------------------------

- (BOOL) performCustomValidationForEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    NSLog(@"Topic - performCustomValidationForEntityMapping");

    BOOL result = [super performCustomValidationForEntityMapping:mapping manager:manager error:error];
    
    if (YES == result && YES == [[manager.sourceModel modelIdentifier] isEqualToString:@"Model4"])
    {
        // Fetch all the topics we migrated this round.
        NSMutableDictionary *context = [[NSMutableDictionary alloc] initWithDictionary:@{@"manager": manager}];
        NSArray *sourceTopicsMigrated = [mapping.sourceExpression expressionValueWithObject:nil context:context];
        NSArray *topicsToValidate = [manager destinationInstancesForEntityMappingNamed:mapping.name sourceInstances:sourceTopicsMigrated];
        for (NSManagedObject *topic in topicsToValidate)
        {
            if (nil == [topic valueForKey:@"presenter"])
            {
                NSLog(@"Topic - failed custom validation: %@", [topic valueForKey:@"title"]);
                result = NO;
                break;
            }
        }
    }
    
    return result;
}


//------------------------------------------------------------------------------

- (BOOL)endEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    NSLog(@"Topic - endEntityMapping");
    return [super endEntityMapping:mapping manager:manager error:error];
}


//------------------------------------------------------------------------------
@end
//------------------------------------------------------------------------------
