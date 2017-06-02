//
//  Habit.h
//  Make A Habit
//
//  Created by Jordan Gardner on 7/19/14.
//  Copyright (c) 2014 Jordan Gardner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Habit : NSManagedObject

@property (nonatomic, retain) NSString * habitTitle;
@property (nonatomic, retain) NSNumber * currentStreak;
@property (nonatomic, retain) NSNumber * longestStreak;
@property (nonatomic, retain) NSNumber * previousLongestStreak;
@property (nonatomic, retain) NSNumber * complete;
@property (nonatomic, retain) NSNumber * pending;
@property (nonatomic, retain) NSDate * createDate;

// This method creates a new habit with the given title
// and inserts it into core data.  I supposed it would be
// helpful to have a single method that does this instead of
// doing it multiple places throughout the project.
+ (void)createHabitWithTitle:(NSString *)title;

// The method to call when the user marks a habit as complete/incomplete
- (void)toggleComplete;

// The method to call to update the habit's values each new day
// It checks whether the habit was completed the day before and,
// if necessary, resets the currentStreak
- (void)updateForNewDay;

// The method to call when it's been more than one day since the user
// last opened the app.  Because habits should be done daily, if it's been
// more than one day, we know that the habits need to reset their current
// streaks to zero.  The only difference between this method and updateForNewDay
// is that all habits have their currentStreak reset to zero.
- (void)resetHabit;

@end
