//------------------------------------------------------------------------------
//
//  NSMappingModel+MappingModelPaths.m
//  CoreDataMigration
//
//  Created by Bill Moss on 1/10/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import "NSMappingModel+MappingModelPaths.h"

//------------------------------------------------------------------------------

@implementation NSMappingModel (MappingModelPaths)

//------------------------------------------------------------------------------

+ (NSArray*) allMappingModelPaths
{
    NSArray *mappingModelPaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"cdm" inDirectory:nil];
    return mappingModelPaths;
}

//------------------------------------------------------------------------------

@end

//------------------------------------------------------------------------------
