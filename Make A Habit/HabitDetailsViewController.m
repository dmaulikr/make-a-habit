//
//  HabitDetailsViewController.m
//  Make A Habit
//
//  Created by Jordan Gardner on 7/19/14.
//  Copyright (c) 2014 Jordan Gardner. All rights reserved.
//

#import "AppDelegate.h"
#import "HabitDetailsViewController.h"
#import "MainTableViewController.h"
#import "Habit.h"

@interface HabitDetailsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *habitTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkbox;
@property (weak, nonatomic) IBOutlet UILabel *currentStreakLabel;
@property (weak, nonatomic) IBOutlet UILabel *longestStreakLabel;

@end

@implementation HabitDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set background color
    self.view.backgroundColor = RGBA(240, 83, 83, 1);
    
    // Update views
    [self updateViews];
    
    // Set observer to know when the view needs to update.
    // We need this to make sure the view gets updated if we
    // change values as a result of it being a new day.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViews) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)updateViews
{
    // Update habitTitleLabel
    self.habitTitleLabel.text = self.habit.habitTitle;
    
    // Update checkbox
    [self.checkbox setImage:[self imageForCheckbox] forState:UIControlStateNormal];
    
    // Update currentStreak
    self.currentStreakLabel.text = [self.habit.currentStreak stringValue];
    
    // Update longestStreak
    self.longestStreakLabel.text = [self.habit.longestStreak stringValue];
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
        [MainTableViewController showMotivationalOrCongratulatoryMessageForHabit:self.habit];
    }
}

- (IBAction)backButtonTapped
{
    // Dismiss view controller
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)userSwipedRight:(UISwipeGestureRecognizer *)sender
{
    // Return to the previous screen
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Status Bar

- (BOOL)prefersStatusBarHidden
{
    // Hide status bar
    return YES;
}

@end
