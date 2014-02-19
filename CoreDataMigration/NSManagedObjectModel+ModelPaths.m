//------------------------------------------------------------------------------
//
//  NSManagedObjectModel+ModelPaths.m
//  CoreDataMigration
//
//  Created by Bill Moss on 1/10/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import "NSManagedObjectModel+ModelPaths.h"

//------------------------------------------------------------------------------

@implementation NSManagedObjectModel (ModelPaths)

//------------------------------------------------------------------------------

+ (NSArray*) allModelPaths
{
    NSMutableArray *modelPaths = [NSMutableArray array];

    //Find all of the mom and momd files in the Resources directory
    NSArray *momdArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"momd" inDirectory:nil];
    for (NSString *momdPath in momdArray)
    {
        NSString *resourceSubpath = [momdPath lastPathComponent];
        NSArray *array = [[NSBundle mainBundle] pathsForResourcesOfType:@"mom" inDirectory:resourceSubpath];
        [modelPaths addObjectsFromArray:array];
    }
    
    NSArray *otherModels = [[NSBundle mainBundle] pathsForResourcesOfType:@"mom" inDirectory:nil];
    [modelPaths addObjectsFromArray:otherModels];
    
    return modelPaths;
}

//------------------------------------------------------------------------------

- (NSString*) modelIdentifier
{
    NSSet *versionIdentifers = self.versionIdentifiers;
    NSAssert(versionIdentifers.count == 1, @"Multiple model version identifiers are not supported at this time.");
    return [versionIdentifers.allObjects firstObject];
}

//------------------------------------------------------------------------------

@end

//------------------------------------------------------------------------------
