//------------------------------------------------------------------------------
//
//  CDMFetchExpressionTests.m
//  CoreDataMigration
//
//  Created by William Moss on 1/23/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import <XCTest/XCTest.h>

//------------------------------------------------------------------------------

@interface CDMFetchExpressionTests : XCTestCase

@end

//------------------------------------------------------------------------------

@implementation CDMFetchExpressionTests

//------------------------------------------------------------------------------

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

//------------------------------------------------------------------------------

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//------------------------------------------------------------------------------

- (void)testFetchInAlphaGroupsExpression
{
    NSArray *testData = @[@"alpha", @"bravo", @"charlie", @"delta", @"echo", @"foxtrot", @"golf", @"hotel", @"india", @"juliett", @"kilo",
                          @"lima", @"mike", @"november", @"oscar", @"papa", @"quebec", @"romeo", @"sierra", @"tango", @"uniform", @"victor",
                          @"whiskey", @"xray", @"yankee", @"zulu",
                          @"Alpha", @"Bravo", @"Charlie", @"Delta", @"Echo", @"Foxtrot", @"Golf", @"Hotel", @"India", @"Juliett", @"Kilo",
                          @"Lima", @"Mike", @"November", @"Oscar", @"Papa", @"Quebec", @"Romeo", @"Sierra", @"Tango", @"Uniform", @"Victor",
                          @"Whiskey", @"Xray", @"Yankee", @"Zulu"];
    
    NSPredicate *ahFilter = [NSPredicate predicateWithFormat:@"SELF MATCHES '[a-hA-H].*'"];
    NSPredicate *ipFilter = [NSPredicate predicateWithFormat:@"SELF MATCHES '[i-pI-P].*'"];
    NSPredicate *qzFilter = [NSPredicate predicateWithFormat:@"SELF MATCHES '[q-zQ-Z].*'"];
    
    NSArray *ahMatches = [testData filteredArrayUsingPredicate:ahFilter];
    NSArray *ipMatches = [testData filteredArrayUsingPredicate:ipFilter];
    NSArray *qzMatches = [testData filteredArrayUsingPredicate:qzFilter];
    XCTAssertTrue(ahMatches.count == 16,);
    XCTAssertTrue(ipMatches.count == 16,);
    XCTAssertTrue(qzMatches.count == 20,);

}

//------------------------------------------------------------------------------
@end
//------------------------------------------------------------------------------
