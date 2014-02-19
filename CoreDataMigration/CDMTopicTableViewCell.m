//------------------------------------------------------------------------------
//
//  CDMTopicTableViewCell.m
//  CoreDataMigration
//
//  Created by William Moss on 2/9/14.
//  Copyright (c) 2014 Bill Moss. All rights reserved.
//
//------------------------------------------------------------------------------

#import "CDMTopicTableViewCell.h"

//------------------------------------------------------------------------------

@implementation CDMTopicTableViewCell

//------------------------------------------------------------------------------

- (void) awakeFromNib
{
    [super awakeFromNib];
    self.presenterImageView.layer.cornerRadius = self.presenterImageView.frame.size.width / 2.0;
}


//------------------------------------------------------------------------------

@end

//------------------------------------------------------------------------------
