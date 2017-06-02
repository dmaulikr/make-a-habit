//
//  HabitTableViewCell.h
//  Make A Habit
//
//  Created by Jordan Gardner on 7/19/14.
//  Copyright (c) 2014 Jordan Gardner. All rights reserved.
//

#import "SWTableViewCell.h"

@class Habit;

@protocol HabitTableViewCellDelegate <NSObject>

// Tell the delegate to display a congratulatory/motivational message 
- (void)displayMessageForHabit:(Habit *)habit;

@end

@interface HabitTableViewCell : SWTableViewCell

// SWTableViewCell already declares delegate, but we need another one of type id<HabitTableViewCellDelegate>
@property (weak, nonatomic) id<HabitTableViewCellDelegate> secondaryDelegate;
@property (weak, nonatomic) Habit *habit;
@property (weak, nonatomic) IBOutlet UILabel *habitTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkbox;

@end
