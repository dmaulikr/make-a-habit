//
//  HabitTableViewCell.m
//  Make A Habit
//
//  Created by Jordan Gardner on 7/19/14.
//  Copyright (c) 2014 Jordan Gardner. All rights reserved.
//

#import "AppDelegate.h"
#import "HabitTableViewCell.h"
#import "HabitDetailsViewController.h"
#import "Habit.h"

@implementation HabitTableViewCell

- (void)setHabit:(Habit *)habit
{
    // Set habit
    _habit = habit;
    
    // Update views
    [self updateViews];
}

- (void)updateViews
{
    // Update label
    self.habitTitleLabel.text = self.habit.habitTitle;
    
    // Update checkbox image
    [self.checkbox setImage:[self imageForCheckbox] forState:UIControlStateNormal];
    
    // Update background color
    self.backgroundColor = RGBA(240, 83, 83, 1);
}

- (UIImage *)imageForCheckbox
{
    return [self.habit.complete boolValue] ? [UIImage imageNamed:@"checkbox_complete"] : [UIImage imageNamed:@"checkbox"];
}

- (IBAction)checkboxTapped
{
    // Toggle the habit's complete status
    [self.habit toggleComplete];
    
    // Update views
    [self updateViews];
    
    // Update notifications if necessary
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate updateNotificationFireDates];
    
    // Possibly display a message
    if ([self.habit.complete boolValue])
    {
        [self.secondaryDelegate displayMessageForHabit:self.habit];
    }
}

@end
