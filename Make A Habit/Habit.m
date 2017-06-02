//
//  Habit.m
//  Make A Habit
//
//  Created by Jordan Gardner on 7/19/14.
//  Copyright (c) 2014 Jordan Gardner. All rights reserved.
//

#import "AppDelegate.h"
#import "Habit.h"

@implementation Habit

@dynamic habitTitle;
@dynamic currentStreak;
@dynamic longestStreak;
@dynamic previousLongestStreak;
@dynamic complete;
@dynamic pending;
@dynamic createDate;

+ (void)createHabitWithTitle:(NSString *)habitTitle
{
    // Get managedObjectContext
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *managedObjectContext = appDelegate.managedObjectContext;
    
    // Create the new habit
    Habit *newHabit = [NSEntityDescription insertNewObjectForEntityForName:@"Habit" inManagedObjectContext:managedObjectContext];
    newHabit.habitTitle = habitTitle;
    newHabit.createDate = [NSDate date];
    
    // Save
    NSError *error = nil;
    if (![managedObjectContext save:&error])
    {
        NSLog(@"Error saving changes %@, %@", error, [error userInfo]);
    }
}

- (void)toggleComplete
{
    // Set self.habit.complete
    self.complete = [NSNumber numberWithBool:![self.complete boolValue]];
    
    // Adjust the currentStreak up if the habit is complete
    if ([self.complete boolValue])
    {
        // Adjust currentStreak
        self.currentStreak = [NSNumber numberWithInt:[self.currentStreak intValue] + 1];
        
        // Check if greater than longestStreak
        if ([self.currentStreak intValue] > [self.longestStreak intValue])
        {
            // Set previousLongest Streak
            self.previousLongestStreak = self.longestStreak;
            // Set new longestStreak
            self.longestStreak = self.currentStreak;
        }
        
        // Set as pending
        self.pending = [NSNumber numberWithBool:YES];
    }
    // Otherwise we decrease the streak
    else
    {
        // Check if currentStreak is longestStreak
        if ([self.currentStreak intValue] > [self.previousLongestStreak intValue])
        {
            // Decrease longestStreak as well
            self.longestStreak = [NSNumber numberWithInt:[self.longestStreak intValue] - 1];
        }
        
        // Adjust currentStreak
        self.currentStreak = [NSNumber numberWithInt:[self.currentStreak intValue] - 1];
        
        // Set pending to false
        self.pending = [NSNumber numberWithBool:NO];
    }
    
    // Save
    [self save];
}

- (void)updateForNewDay
{
    // Check if the habit was completed
    if ([self.pending boolValue])
    {
        // Reset complete
        self.complete = [NSNumber numberWithBool:NO];
        
        // Reset pending
        self.pending = [NSNumber numberWithBool:NO];
        
        return;
    }
    
    // If it wasn't completed, reset the current streak
    self.currentStreak = [NSNumber numberWithInt:0];
    
    // Save
    [self save];
}

- (void)resetHabit
{
    // Check if the habit was completed
    if ([self.pending boolValue])
    {
        // Reset complete
        self.complete = [NSNumber numberWithBool:NO];
        
        // Reset pending
        self.pending = [NSNumber numberWithBool:NO];
    }
    
    // If it wasn't completed, reset the current streak
    self.currentStreak = [NSNumber numberWithInt:0];
    
    // Save
    [self save];
}

- (void)save
{
    // Save changes in appDelegates managedObjectContext
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *managedObjectContext = appDelegate.managedObjectContext;
    NSError *error = nil;
    if (![managedObjectContext save:&error])
    {
        NSLog(@"Error saving changes %@, %@", error, [error userInfo]);
    }
}

@end
