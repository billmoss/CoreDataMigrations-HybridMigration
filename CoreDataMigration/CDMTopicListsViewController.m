//------------------------------------------------------------------------------
//
//  CDMTopicListsViewController.m
//  CoreDataMigration
//
//  Created by William Moss on 1/15/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import "CDMTopicListsViewController.h"
#import "CDMAppDelegate.h"
#import "CDMTopicsViewController.h"

//------------------------------------------------------------------------------

@interface CDMTopicListsViewController () <NSFetchedResultsControllerDelegate>

@end

//------------------------------------------------------------------------------

@implementation CDMTopicListsViewController

//------------------------------------------------------------------------------

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

//------------------------------------------------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.topicListsFetchController.delegate = self;
    
    NSError *error = nil;
    [self.topicListsFetchController performFetch:&error];
    if (nil != error)
    {
        [CDMAppDelegate handleApplicationError:error alertUser:YES alertTitle:@"Fetch Failed"];
    }
    else
    {
        [self.tableView reloadData];
    }
}

//------------------------------------------------------------------------------

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//------------------------------------------------------------------------------

#pragma mark - Navigation

//------------------------------------------------------------------------------

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (YES == [segue.identifier isEqualToString:@"ShowTopicsSegue"])
    {
        [self handleShowTopicsSeque:segue];
    }
}

//------------------------------------------------------------------------------

#pragma mark - UITableViewDataSource

//------------------------------------------------------------------------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.topicListsFetchController.sections.count;
}

//------------------------------------------------------------------------------

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.topicListsFetchController.sections objectAtIndex:section];
    return sectionInfo.numberOfObjects;
}

//------------------------------------------------------------------------------

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *topicList = [self.topicListsFetchController objectAtIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TopicListCell"];
    cell.textLabel.text = [topicList valueForKey:@"title"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d topics", [[topicList valueForKey:@"topics"] count]];
    return cell;
}

//------------------------------------------------------------------------------

#pragma mark - Segue Handling

//------------------------------------------------------------------------------

- (void) handleShowTopics
{
    [self performSegueWithIdentifier:@"ShowTopicsSegue" sender:self];
}

//------------------------------------------------------------------------------

- (void) handleShowTopicsSeque:(UIStoryboardSegue *)segue
{
    NSIndexPath *selection = [self.tableView indexPathForSelectedRow];
    NSManagedObject *topicList = [self.topicListsFetchController objectAtIndexPath:selection];
    CDMTopicsViewController *topicsViewController = (CDMTopicsViewController*) segue.destinationViewController;
    topicsViewController.topicList = topicList;
}

//------------------------------------------------------------------------------

@end

//------------------------------------------------------------------------------
