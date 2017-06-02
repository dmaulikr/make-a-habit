//
//  MainTableViewController.m
//  Make A Habit
//
//  Created by Jordan Gardner on 7/19/14.
//  Copyright (c) 2014 Jordan Gardner. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "AppDelegate.h"
#import "MainTableViewController.h"
#import "CreateHabitViewController.h"
#import "HabitDetailsViewController.h"
#import "Habit.h"
#import "SWTableViewCell.h"
#import "HabitTableViewCell.h"

@interface MainTableViewController () <SWTableViewCellDelegate, HabitTableViewCellDelegate>

@property (strong, nonatomic) NSArray *habits;

@end

@implementation MainTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initial Setup
    [self loadHabits];
    
    // Set background color
    self.view.backgroundColor = RGBA(240, 83, 83, 1);
    
    // Set tableView items
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    [self.tableView setSeparatorColor:[UIColor whiteColor]];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Set observer to know when the view needs to update.
    // We need this to make sure the view gets updated if we
    // change values as a result of it being a new day.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViews) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)loadHabits
{
    // Get the managedObjectContext
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *managedObjectContext = appDelegate.managedObjectContext;
    
    // Get habits sorted by createDate
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Habit"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createDate" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    NSError *error = nil;
    self.habits = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    // Check for errors
    if (!self.habits)
    {
        NSLog(@"Unable to retrieve habits %@, %@", error, [error userInfo]);
    }
}

- (void)updateViews
{
    // Reload habits
    [self loadHabits];
    
    // Reload tableView
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Update views
    [self updateViews];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.habits.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The first cell is used to create new habits
    if (indexPath.row == 0)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"newHabitCell"];
        cell.backgroundColor = RGBA(240, 83, 83, 1);
        
        return cell;
    }
    
    // All other cells are HabitTableViewCells
    HabitTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"habitCell"];

    // Set the habit for this cell
    cell.habit = (Habit *)[self.habits objectAtIndex:indexPath.row - 1];
    
    // Set buttons to show when swiping the cell
    cell.rightUtilityButtons = [self rightButtons];
    
    // Set delegate
    cell.delegate = self;
    cell.secondaryDelegate = self;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Standard height for our cells
    return 80.0;
}

- (NSArray *)rightButtons
{
    // Return buttons to display on the right side of a swiped cell
    NSMutableArray *rightUtilityButtons = [[NSMutableArray alloc] init];
    
    // Delete button
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor whiteColor] title:@"Delete" titleColor:RGBA(240, 83, 83, 1) titleFont:[UIFont fontWithName:@"chalkboardSE-regular" size:20.0]];
    
    return rightUtilityButtons;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The first cell should display the CreateHabitViewController
    if (indexPath.row == 0)
    {
        // Create the view controller to display
        CreateHabitViewController *createHabitViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"createHabitViewController"];
        
        // Modally present the view controller
        createHabitViewController.modalPresentationStyle = UIModalTransitionStyleCoverVertical;
        [self presentViewController:createHabitViewController animated:YES completion:nil];
    }
    else
    {
        // Display HabitDetailsViewController
        HabitDetailsViewController *habitDetailsViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"habitDetailsViewController"];
        
        // Set the view controllers habit
        habitDetailsViewController.habit = (Habit *)[self.habits objectAtIndex:indexPath.row - 1];
        
        // Push onto the navigation controller
        [self.navigationController pushViewController:habitDetailsViewController animated:YES];
    }
}

#pragma mark - SWTableViewCell delegate methods

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state
{
    // Enable cells to swipe for buttons
    return YES;
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
{
    // Only show buttons for one cell at a time
    return YES;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    // Get the managedObjectContext
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *managedObjectContext = appDelegate.managedObjectContext;
    
    // Delete the habit from memory
    Habit *habitToDelete = [((HabitTableViewCell *)cell) habit];
    [managedObjectContext deleteObject:habitToDelete];
    
    // Save
    NSError *error = nil;
    if (![managedObjectContext save:&error])
    {
        NSLog(@"Error deleting habit %@, %@", error, [error userInfo]);
    }
    
    // Reload habits
    [self loadHabits];
    
    // Animate delete from tableView
    [self.tableView deleteRowsAtIndexPaths:@[[self.tableView indexPathForCell:cell]] withRowAnimation:UITableViewRowAnimationLeft];
}

#pragma mark - Status Bar

- (BOOL)prefersStatusBarHidden
{
    // Hide the status bar
    return YES;
}

#pragma mark - Motivation and Congratulations

- (void)displayMessageForHabit:(Habit *)habit;
{
    // This method is part of the HabitTableViewCellDelegate
    [MainTableViewController showMotivationalOrCongratulatoryMessageForHabit:habit];
}

// Congratulatory strings for making a new habit
static NSString * const GrandioseCongratulatoryMessageOne = @"Good habits are key to success. You've got another one down.";
static NSString * const GrandioseCongratulatoryMessageTwo = @"30 days!!! I knew you had it in you! I bet you could do it for 60 days in a row!";
static NSString * const GrandioseCongratulatoryMessageThree = @"You've made it 30 days in a row!!! This calls for a celebration.  Reward yourself!";
static NSString * const GrandioseCongratulatoryMessageFour = @"It's official! You've made it a habit.  Why not try starting another habit?!";
static NSString * const GrandioseCongratulatoryMessageFive = @"If you had a dollar for every day you worked on this habit, you'd have a LOT of dollars! The habit you've made is worth more than dollars though.";

// Congratulatory message strings
static NSString * const CongratulatoryMessageOneWeek = @"One week down! You're headed in the right direction!";
static NSString * const CongratulatoryMessageTwoWeeks = @"Two weeks already?! You'll be done in no time!";
static NSString * const CongratulatoryMessageThreeWeeks = @"Three weeks! According to science, you've almost created a habit!";
static NSString * const CongratulatoryMessageFourWeeks =  @"Four weeks in a row! Only three more days until this is officially a habit! Don't let up!";

// Congratulatory message strings when the
// user gets a new longest streak
static NSString * const LongestStreakCongratulatoryMessageOne = @"You just broke your longest streak! Keep it up!";
static NSString * const LongestStreakCongratulatoryMessageTwo = @"It's a new record!  Don't quit now!";
static NSString * const LongestStreakCongratulatoryMessageThree = @"You're moving up in the world!";
static NSString * const LongestStreakCongratulatoryMessageFour = @"Why not reward yourself?! You deserve it!";
static NSString * const LongestStreakCongratulatoryMessageFive = @"Give yourself a pat on the back!";

// Motivational message strings
static NSString * const MotivationalMessageOne = @"You're on the right track!";
static NSString * const MotivationalMessageTwo = @"Baby steps into the elevator! It's all about the little victories";
static NSString * const MotivationalMessageThree = @"A wise man once said, \"Don't ever forget to check off your habits!\"";
static NSString * const MotivationalMessageFour = @"Wahoo! Look at you go!";
static NSString * const MotivationalMessageFive = @"Well done! You're getting better each day!";
static NSString * const MotivationalMessageSix = @"Don't quit! You're making a better you!";
static NSString * const MotivationalMessageSeven = @"You're working towards success!";
static NSString * const MotivationalMessageEight = @"You can do it, yes you can! If you can't do it, no one can!";
static NSString * const MotivationalMessageNine = @"How does it feel?! ";
static NSString * const MotivationalMessageTen = @"Just keep swimming!";

// Congratulatory Milestone Markers
typedef NS_ENUM(NSInteger, CongratulatoryMileStoneMarkers) {
    CongratulatoryMileStoneMarkersOneWeek = 7,
    CongratulatoryMileStoneMarkersTwoWeeks = 14,
    CongratulatoryMileStoneMarkersThreeWeeks = 21,
    CongratulatoryMileStoneMarkersFourWeeks = 28,
    CongratulatoryMileStoneMarkersOneMonth = 30,
};

// This method displays an alert to the user as either
// motivation or congratulations if the user has reached
// a milestone in their streak.
// NOTE: I realize that by placing this here I'm violating
// MVC standards, but it seems to me that this is the most
// logical place for this method.  Shoot me...
+ (void)showMotivationalOrCongratulatoryMessageForHabit:(Habit *)habit
{
    // First display congratulatory message for currentStreak milestones
    int streak = [habit.currentStreak intValue];
    // One month complete!
    if (streak == CongratulatoryMileStoneMarkersOneMonth)
    {
        // Display grandiose congratulatory message
        NSArray *grandioseCongratulatoryMessages = @[GrandioseCongratulatoryMessageOne,
                                                     GrandioseCongratulatoryMessageTwo,
                                                     GrandioseCongratulatoryMessageThree,
                                                     GrandioseCongratulatoryMessageFour,
                                                     GrandioseCongratulatoryMessageFive];
        
        // Select random message
        NSString *messageTitle = @"It's A Habit";
        NSString *message = [grandioseCongratulatoryMessages objectAtIndex:(arc4random() % [grandioseCongratulatoryMessages count])];
        NSString *messageButtonTitle = @"Celebrate";
        
        // Create alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:messageTitle
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:messageButtonTitle
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    // Other milestones
    else if (streak == CongratulatoryMileStoneMarkersOneWeek || streak == CongratulatoryMileStoneMarkersTwoWeeks || streak == CongratulatoryMileStoneMarkersThreeWeeks || streak == CongratulatoryMileStoneMarkersFourWeeks)
    {
        // Display congratulatory message
        NSString *messageTitle = @"Milestone";
        NSString *message = @"";
        switch (streak)
        {
            case CongratulatoryMileStoneMarkersOneWeek:
                message = CongratulatoryMessageOneWeek;
                break;
            case CongratulatoryMileStoneMarkersTwoWeeks:
                message = CongratulatoryMessageTwoWeeks;
                break;
            case CongratulatoryMileStoneMarkersThreeWeeks:
                message = CongratulatoryMessageThreeWeeks;
                break;
            case CongratulatoryMileStoneMarkersFourWeeks:
                message = CongratulatoryMessageFourWeeks;
                break;
        }
        NSString *messageButtonTitle = @"Alright";
        
        // Create alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:messageTitle
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:messageButtonTitle
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // Occasionally display a message when the longestStreak has been broken
    // Check if the longest streak was broken
    if ([habit.currentStreak intValue] > [habit.previousLongestStreak intValue])
    {
        // Possibly display a message
        if ((arc4random() % 10) == 0 && [habit.currentStreak intValue] > 5)
        {
            // Display message
            NSArray *longestStreakCongratulatoryMessages = @[LongestStreakCongratulatoryMessageOne,
                                                             LongestStreakCongratulatoryMessageTwo,
                                                             LongestStreakCongratulatoryMessageThree,
                                                             LongestStreakCongratulatoryMessageFour,
                                                             LongestStreakCongratulatoryMessageFive];
            
            // Select random strings
            NSString *messageTitle = @"New Record";
            NSString *message = [longestStreakCongratulatoryMessages objectAtIndex:(arc4random() % [longestStreakCongratulatoryMessages count])];
            NSString *messageButtonTitle = @"Alright";
            
            // Create alert
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:messageTitle
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:messageButtonTitle
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    
    // If no other messages, occasionally display a motivational message
    if ((arc4random() % 10) == 0)
    {
        // Display message
        NSArray *motivationalMessages = @[MotivationalMessageOne,
                                          MotivationalMessageTwo,
                                          MotivationalMessageThree,
                                          MotivationalMessageFour,
                                          MotivationalMessageFive,
                                          MotivationalMessageSix,
                                          MotivationalMessageSeven,
                                          MotivationalMessageEight,
                                          MotivationalMessageNine,
                                          MotivationalMessageTen];
        
        // Select random strings
        NSString *messageTitle = @"Keep It Up";
        NSString *message = [motivationalMessages objectAtIndex:(arc4random() % [motivationalMessages count])];
        NSString *messageButtonTitle = @"OK";
        
        // Create alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:messageTitle
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:messageButtonTitle
                                              otherButtonTitles:nil];
        [alert show];
    }
    
}

@end
