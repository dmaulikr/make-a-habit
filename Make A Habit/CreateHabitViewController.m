//
//  CreateHabitViewController.m
//  Make A Habit
//
//  Created by Jordan Gardner on 7/19/14.
//  Copyright (c) 2014 Jordan Gardner. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "CreateHabitViewController.h"
#import "Habit.h"

@interface CreateHabitViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *habitTitleTextField;

@end

@implementation CreateHabitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set background color
    self.view.backgroundColor = RGBA(240, 83, 83, 1);
    
    // Style the habitTitleTextField
    self.habitTitleTextField.backgroundColor = RGBA(255, 255, 255, 0.3);
    self.habitTitleTextField.layer.cornerRadius = 10.0;
}

- (void)viewDidAppear:(BOOL)animated
{
    // Show keyboard
    [self.habitTitleTextField becomeFirstResponder];
}

- (IBAction)backButtonTapped
{
    // Dismiss this view controller
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)createNewHabitButtonTapped
{
    // Check that the text field isn't empty
    if ([self.habitTitleTextField.text isEqualToString:@""])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops..."
                                                        message:@"You forgot to enter a habit!  Try again."
                                                       delegate:self
                                              cancelButtonTitle:@"My bad..."
                                              otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    // Create new habit
    [Habit createHabitWithTitle:self.habitTitleTextField.text];
    
    // Dismiss view controller
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Dismiss keyboard
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Animate the view up above the keyboard
    [UIView animateWithDuration:0.2
                     animations:^
                         {
                             CGRect frameRect = self.view.frame;
                             frameRect.origin.y -= (0.125 * self.view.frame.size.height);
                             self.view.frame = frameRect;
                         }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Return the view to its original position
    [UIView animateWithDuration:0.2
                     animations:^
                         {
                             CGRect frameRect = self.view.frame;
                             frameRect.origin.y += (0.125 * self.view.frame.size.height);
                             self.view.frame = frameRect;
                         }];
}

#pragma mark - Status Bar

- (BOOL)prefersStatusBarHidden
{
    // Hide status bar
    return YES;
}

@end
