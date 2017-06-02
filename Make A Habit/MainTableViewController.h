//
//  MainTableViewController.h
//  Make A Habit
//
//  Created by Jordan Gardner on 7/19/14.
//  Copyright (c) 2014 Jordan Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Habit;

@interface MainTableViewController : UITableViewController

+ (void)showMotivationalOrCongratulatoryMessageForHabit:(Habit *)habit;

@end
