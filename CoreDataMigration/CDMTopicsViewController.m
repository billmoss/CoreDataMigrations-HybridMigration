//------------------------------------------------------------------------------
//
//  CDMTopicsViewController.m
//  CoreDataMigration
//
//  Created by William Moss on 1/15/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import "CDMTopicsViewController.h"
#import "CDMAppDelegate.h"
#import "CDMTopicTableViewCell.h"
#import "NSManagedObjectModel+ModelPaths.h"

//------------------------------------------------------------------------------

@interface CDMTopicsViewController ()

@property (strong) NSString *modelVersion;

@end

//------------------------------------------------------------------------------

@implementation CDMTopicsViewController

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

    self.navigationItem.title = [self.topicList valueForKey:@"title"];
    self.modelVersion = [[self.topicList.entity.managedObjectModel.versionIdentifiers allObjects] firstObject];

    [self.tableView reloadData];
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

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//}

//------------------------------------------------------------------------------

#pragma mark - UITableViewDataSource

//------------------------------------------------------------------------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

//------------------------------------------------------------------------------

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.topicList valueForKey:@"topics"] count];
}

//------------------------------------------------------------------------------

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSSet *topics = [self.topicList valueForKey:@"topics"];
    NSManagedObject *topic = [[topics allObjects] objectAtIndex:indexPath.row];
    NSDictionary *attributes = topic.entity.attributesByName;
    NSDictionary *relationships = topic.entity.relationshipsByName;

    CDMTopicTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TopicCell"];
    
    // Demo includes renaming the content property.
    if (nil != [attributes valueForKey:@"content"])
    {
        cell.titleLabel.text = [topic valueForKey:@"content"];
    }
    else if (nil != [attributes valueForKey:@"title"])
    {
        cell.titleLabel.text = [topic valueForKey:@"title"];
    }

    // Details info. Presenter name + time budget
    NSMutableString *detailsText = [NSMutableString stringWithCapacity:42];
    NSString *firstName = nil;
    NSInteger numTopicsForPresenter = 0;
    
    if (nil != [relationships valueForKey:@"presenter"])
    {
        firstName = [topic valueForKeyPath:@"presenter.firstName"];
        numTopicsForPresenter = [[topic valueForKeyPath:@"presenter.topics.@count"] integerValue];
    }
    else if (nil != [attributes valueForKey:@"presenterName"])
    {
        firstName = [topic valueForKeyPath:@"presenterName"];
    }

    if (nil != firstName && 0 != firstName.length)
    {
        cell.detailsLabelLeadingConstraint.constant = CGRectGetMaxX(cell.presenterImageView.frame) + 8;
        [detailsText appendString:firstName];
        UIImage *presenterImage = [UIImage imageNamed:firstName];
        cell.presenterImageView.image = presenterImage;
    }
    else
    {
        cell.detailsLabelLeadingConstraint.constant = CGRectGetMinX(cell.presenterImageView.frame);
    }
    
    // Include number of topics this presenter has assigned to them.
    if (0 != numTopicsForPresenter)
    {
        [detailsText appendFormat:@"(%d)", numTopicsForPresenter];
    }
    
    // Time budget
    NSAttributeDescription *timeBudgetAttribute = [attributes valueForKey:@"timeBudget"];
    if (nil != timeBudgetAttribute)
    {
        // We changed the units of timeBudget to seconds in Model4.
        NSComparisonResult comparisonResult = [[topic.entity.managedObjectModel modelIdentifier] compare:@"Model4" options:NSNumericSearch];
        BOOL unitsAreMinutes = NSOrderedAscending == comparisonResult;
        
        NSNumber *timeBudget = [topic valueForKey:@"timeBudget"];
        if (nil != timeBudget)
        {
            [detailsText appendString:@", "];
            double timeInMinutes = 0;
            
            if (YES == unitsAreMinutes)
            {
                // Prior to Model4, timeBudget units were minutes.
                timeInMinutes = [timeBudget doubleValue];
                if (timeInMinutes > 1)
                {
                    [detailsText appendString:[NSString stringWithFormat:@"%.0f minutes", timeInMinutes]];
                }
                else if (timeInMinutes > 0)
                {
                    [detailsText appendString:@"1 minute"];
                }
            }
            else
            {
                // Model 4+: timeBudget units changed to seconds.
                double timeInSeconds = [timeBudget doubleValue];
                if (timeInSeconds > 1)
                {
                    [detailsText appendString:[NSString stringWithFormat:@"%.0f seconds", timeInSeconds]];
                }
                else if (timeInSeconds > 0)
                {
                    [detailsText appendString:@"1 second"];
                }
            }
            
        }
    }

    cell.detailsLabel.text = detailsText;
    
    return cell;
}

//------------------------------------------------------------------------------

@end

//------------------------------------------------------------------------------
