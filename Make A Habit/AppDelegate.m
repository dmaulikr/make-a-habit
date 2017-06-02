//
//  AppDelegate.m
//  Make A Habit
//
//  Created by Jordan Gardner on 7/19/14.
//  Copyright (c) 2014 Jordan Gardner. All rights reserved.
//

#import "AppDelegate.h"
#import "Habit.h"

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

#pragma mark - AppDelegate methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Run at first launch
    if (![[NSUserDefaults standardUserDefaults] valueForKey:@"alreadyLaunched"])
    {
        // Set lastLaunchDate in standardUserDefaults to today
        [[NSUserDefaults standardUserDefaults] setObject:[self currentDate] forKey:@"lastLaunchDate"];
        
        // Set notifications
        [self setDailyNotifications];
        
        // Set key to prevent running again
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"alreadyLaunched"];
    }
    
    // Check date and update habits
    if ([self habitsNeedUpdating])
    {
        [self updateOrResetHabits];
    }
    
    // Update daily notification with a new reminder!
    [self updateDailyNotificationText];
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Check date and update habits
    if ([self habitsNeedUpdating])
    {
        [self updateOrResetHabits];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Update Habits

- (BOOL)habitsNeedUpdating
{
    // return YES if it has been a day or more
    BOOL needsUpdate = NO;
    
    if ([self numberOfDaysSinceLastOpen] >= 1)
    {
        needsUpdate = YES;
    }
    
    return needsUpdate;
}

- (void)updateOrResetHabits
{
    // Check how many days since the app was last opened.
    // If it's only been 1 day, we update the habits.
    // Otherwise we reset the habits.
    
    if ([self numberOfDaysSinceLastOpen] == 1)
    {
        // Update habits if it's only been one day
        [self updateHabits];
    }
    else if ([self numberOfDaysSinceLastOpen] > 1)
    {
        // Reset habits if it's been more than one day
        [self resetHabits];
    }
    
    // Set the last launched date to today
    [[NSUserDefaults standardUserDefaults] setObject:[self currentDate] forKey:@"lastLaunchDate"];
    
    // Only update if it's a new day
    if ([self numberOfDaysSinceLastOpen] > 0)
    {
        // Update notification fire date
        [[NSUserDefaults standardUserDefaults] setObject:[self currentDate] forKey:@"notificationFireDate"];
    }
}

- (void)updateHabits
{
    // This method fires whenever it's a new day.
    // We check our habits for any that are completed
    // from the previous day and update the info
    
    // Get habits
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Habit"];
    NSError *error = nil;
    NSArray *habits = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

    // Make sure no errors occurred
    if (!habits)
    {
        NSLog(@"Error retrieving habits to update %@, %@", error, [error userInfo]);
    }
    
    // Update each habit
    for (Habit *habit in habits)
    {
        [habit updateForNewDay];
    }
}

- (void)resetHabits
{
    // This method is called whenever it's been
    // more than one day since the app opened up.
    // Because habits should be done daily, if you miss
    // a day, all habits will reset their current streaks
    // to zero.
    
    // Get habits
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Habit"];
    NSError *error = nil;
    NSArray *habits = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    // Make sure no errors occurred
    if (!habits)
    {
        NSLog(@"Error retrieving habits to update %@, %@", error, [error userInfo]);
    }
    
    // Reset each habit
    for (Habit *habit in habits)
    {
        [habit resetHabit];
    }
}

- (NSInteger)numberOfDaysSinceLastOpen
{
    // Get calendar
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    // Set time zone
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    
    // Perform calculation with NSDateComponents
    NSDate *lastLaunchDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastLaunchDate"];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:lastLaunchDate toDate:[NSDate date] options:0];
    
    // Return the number of days since
    return [components day];
}

- (NSDate *)currentDate
{
    // Returns the current date without hours,
    // minutes, or seconds.  Only the user's time zone
    // is factored in.  We do this so that the reset
    // time is always Midnight in whatever time zone the
    // user is in.
    
    // Get calendar
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    [components setCalendar:calendar];
    
    // Return date
    return [components date];
}

- (void)createInitialHabits
{
    // Create new habits
    [Habit createHabitWithTitle:@"Exercise"];
    [Habit createHabitWithTitle:@"Study Spanish"];
    [Habit createHabitWithTitle:@"Read"];
}

#pragma mark - Notifications

// Constant strings used in Notifications section
static NSString * const LocalNotificationIdentifierKey = @"localNotificationIdentifier";
// We use these to identify the fire time of the notification
static NSString * const DailyReminderNotificationIdentifierMorning = @"morningNotification";
static NSString * const DailyReminderNotificationIdentifierNoon = @"noonNotification";
static NSString * const DailyReminderNotificationIdentifierAfternoon = @"afternoonNotification";
static NSString * const DailyReminderNotificationIdentifierEvening = @"eveningNotification";
static NSString * const DailyReminderNotificationIdentifierNight = @"nightNotification";
// Notification Text
static NSString * const DailyReminderMorningNotificationTextOne = @"Remember to work on your habits!";
static NSString * const DailyReminderMorningNotificationTextTwo = @"Make sure you keep improving with those habits!";
static NSString * const DailyReminderMorningNotificationTextThree = @"Don't forget you're making a better you!";
static NSString * const DailyReminderNoonNotificationText = @"Get those habits done!";
static NSString * const DailyReminderAfternoonNotificationText = @"Find some time to work on your habits!";
static NSString * const DailyReminderEveningNotificationText = @"It's getting late! Let's get some habits done!";
static NSString * const DailyReminderNightNotificationText = @"Only a few hours left in the day! Last chance to work on your habits!";


- (void)setDailyNotifications
{
    // Clear all notifications
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    // Get date to fire the daily notification
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit fromDate:[NSDate date]];
    [components setCalendar:calendar];
    
    // Create a morning notification
    [components setHour:6];
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [components date];
    localNotification.alertBody = DailyReminderMorningNotificationTextOne;
    localNotification.timeZone = [NSTimeZone systemTimeZone];
    localNotification.repeatInterval = NSDayCalendarUnit;
    localNotification.userInfo = @{LocalNotificationIdentifierKey: DailyReminderNotificationIdentifierMorning};
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    // Create a noon notification
    [components setHour:12];
    localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [components date];
    localNotification.alertBody = DailyReminderNoonNotificationText;
    localNotification.timeZone = [NSTimeZone systemTimeZone];
    localNotification.repeatInterval = NSDayCalendarUnit;
    localNotification.userInfo = @{LocalNotificationIdentifierKey: DailyReminderNotificationIdentifierMorning};
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    // Create an afternoon notification
    [components setHour:17];
    localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [components date];
    localNotification.alertBody = DailyReminderAfternoonNotificationText;
    localNotification.timeZone = [NSTimeZone systemTimeZone];
    localNotification.repeatInterval = NSDayCalendarUnit;
    localNotification.userInfo = @{LocalNotificationIdentifierKey: DailyReminderNotificationIdentifierMorning};
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    // Create an evening notification
    [components setHour:20];
    localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [components date];
    localNotification.alertBody = DailyReminderEveningNotificationText;
    localNotification.timeZone = [NSTimeZone systemTimeZone];
    localNotification.repeatInterval = NSDayCalendarUnit;
    localNotification.userInfo = @{LocalNotificationIdentifierKey: DailyReminderNotificationIdentifierMorning};
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    // Create a night notificiation
    [components setHour:22];
    localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [components date];
    localNotification.alertBody = DailyReminderNightNotificationText;
    localNotification.timeZone = [NSTimeZone systemTimeZone];
    localNotification.repeatInterval = NSDayCalendarUnit;
    localNotification.userInfo = @{LocalNotificationIdentifierKey: DailyReminderNotificationIdentifierMorning};
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    // Set the fire date in the user defaults for reference
    NSDateComponents *todayComponents = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    [todayComponents setCalendar:calendar];
    [[NSUserDefaults standardUserDefaults] setObject:[todayComponents date] forKey:@"notificationFireDate"];
}

- (void)updateDailyNotificationText
{
    // This method only changes the text of the morning notification.
    // Possible strings to display each morning
    NSArray *dailyReminderStrings = @[DailyReminderMorningNotificationTextOne, DailyReminderMorningNotificationTextTwo, DailyReminderMorningNotificationTextThree];
    
    // Get the morning notification
    UILocalNotification *dailyNotification = nil;
    for (UILocalNotification *notification in [[UIApplication sharedApplication] scheduledLocalNotifications])
    {
        if ([notification.userInfo objectForKey:LocalNotificationIdentifierKey] == DailyReminderNotificationIdentifierMorning)
        {
            dailyNotification = notification;
        }
    }
    
    // Get a random one and set the notification text
    if (dailyNotification)
    {
        dailyNotification.alertBody = dailyReminderStrings[(arc4random() % 3)];
    }
}

- (void)updateNotificationFireDates
{
    // This method updates the fire dates of all our daily notifications.
    // If all of the habits are completed for the day, we set the fire
    // dates to the next day.  We also need to set them back to today if
    // the user checks everything, but then unchecks something.
    
    // Get habits
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Habit"];
    NSArray *habits = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    
    // Find out if all habits are complete
    BOOL allHabitsComplete = NO;
    if (habits.count > 0)
    {
        // If any habit is not complete set to false and break out
        allHabitsComplete = YES;
        for (Habit *habit in habits)
        {
            if (![habit.complete boolValue])
            {
                allHabitsComplete = NO;
                break;
            }
        }
    }
    
    // If all habits are complete, set fireDate for tomorrow so
    // no more notifications display today.
    if (allHabitsComplete)
    {
        // Update fire date to tomorrow
        NSCalendar *calendar = [NSCalendar currentCalendar];
        [calendar setTimeZone:[NSTimeZone systemTimeZone]];
        NSDateComponents *offestComponents = [[NSDateComponents alloc] init];
        [offestComponents setDay:1];
        [offestComponents setCalendar:calendar];
        
        // Set system fire date
        NSDate *previousFireDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"notificationFireDate"];
        NSDate *newFireDate = [calendar dateByAddingComponents:offestComponents toDate:previousFireDate options:0];
        [[NSUserDefaults standardUserDefaults] setObject:newFireDate forKey:@"notificationFireDate"];
        
        // Update each notification
        for (UILocalNotification *notification in [[UIApplication sharedApplication] scheduledLocalNotifications])
        {
            previousFireDate = notification.fireDate;
            newFireDate = [calendar dateByAddingComponents:offestComponents toDate:previousFireDate options:0];
            notification.fireDate = newFireDate;
        }
    }
    else
    {
        // Check if the fireDate was moved to tomorrow.
        // If it was we need to set it back to today as there
        // are habits that need completing
        NSDate *currentDate = [self currentDate];
        NSDate *fireDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"notificationFireDate"];
        if ([fireDate compare:currentDate] == NSOrderedDescending)
        {
            // Set Calendar
            NSCalendar *calendar = [NSCalendar currentCalendar];
            [calendar setTimeZone:[NSTimeZone systemTimeZone]];

            // Set fire date back to today for all notifications
            for (UILocalNotification *notification in [[UIApplication sharedApplication] scheduledLocalNotifications])
            {
                NSDateComponents *previousDateComponents = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit fromDate:notification.fireDate];
                [previousDateComponents setCalendar:calendar];
                NSDateComponents *newDateComponents = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit fromDate:currentDate];
                [newDateComponents setCalendar:calendar];
                [newDateComponents setHour:[previousDateComponents hour]];
                notification.fireDate = [newDateComponents date];
            }
        }
        
        // Update notificiationFireDate in user defaults
        [[NSUserDefaults standardUserDefaults] setObject:[self currentDate] forKey:@"notificationFireDate"];
    }
    
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Make_A_Habit" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Make_A_Habit.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
