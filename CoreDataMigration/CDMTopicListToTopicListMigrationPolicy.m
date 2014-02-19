//------------------------------------------------------------------------------
//
//  CDMTopicToTopicMigrationPolicy.m
//  CoreDataMigration
//
//  Created by William Moss on 1/14/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import "CDMTopicListToTopicListMigrationPolicy.h"

//------------------------------------------------------------------------------
@implementation CDMTopicListToTopicListMigrationPolicy
//------------------------------------------------------------------------------

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    BOOL result = [super createDestinationInstancesForSourceInstance:sInstance entityMapping:mapping manager:manager error:error];
    NSLog(@"TopicList - createDestinationInstancesForSourceInstance: %@", [sInstance valueForKey:@"title"]);
    return result;
}


//------------------------------------------------------------------------------

- (BOOL)createRelationshipsForDestinationInstance:(NSManagedObject *)dInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    BOOL result = [super createRelationshipsForDestinationInstance:dInstance entityMapping:mapping manager:manager error:error];
    NSLog(@"TopicList - createRelationshipsForDestinationInstance: %@", [dInstance valueForKey:@"title"]);
    return result;
}

//------------------------------------------------------------------------------
@end
//------------------------------------------------------------------------------
