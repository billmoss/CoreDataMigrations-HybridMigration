//------------------------------------------------------------------------------
//
//  CDMTopicTableViewCell.h
//  CoreDataMigration
//
//  Created by William Moss on 2/9/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------

@interface CDMTopicTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailsLabel;
@property (weak, nonatomic) IBOutlet UIImageView *presenterImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailsLabelLeadingConstraint;

@end

//------------------------------------------------------------------------------
