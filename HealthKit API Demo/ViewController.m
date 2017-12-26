//
//  ViewController.m
//  HealthKit API Demo
//
//  The MIT License (MIT)
//
//  Copyright (c) 2017 Zhi-Wei Cai
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

#import "ViewController.h"
#import <HealthKit/HealthKit.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *button;

@property (strong, nonatomic) HKHealthStore *healthStore;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _button.layer.borderColor = _button.tintColor.CGColor;
    _button.layer.borderWidth = 1.f;
    _button.layer.cornerRadius = 4.f;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self getHealthKit];
}

#pragma mark - HealthKit Store

- (void)getHealthKit
{
    if (NSClassFromString(@"HKHealthStore") &&
        [HKHealthStore isHealthDataAvailable])
    {
        _healthStore = [HKHealthStore new];
        
        NSSet *shareTypes
        = [NSSet setWithObjects:
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyFatPercentage],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureSystolic],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureDiastolic],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRateVariabilitySDNN],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
           [HKObjectType characteristicTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],
           [HKObjectType characteristicTypeForIdentifier:HKCategoryTypeIdentifierAppleStandHour],
           nil];
        
        NSSet *readTypes
        = [NSSet setWithObjects:
           [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth],
           [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyFatPercentage],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureSystolic],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureDiastolic],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRateVariabilitySDNN],
           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
           [HKObjectType characteristicTypeForIdentifier:HKCategoryTypeIdentifierAppleStandHour],
           [HKObjectType characteristicTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],
           nil];
        
        [_healthStore requestAuthorizationToShareTypes:shareTypes
                                             readTypes:readTypes
                                            completion:^(BOOL success,
                                                         NSError *error)
         {
             
             if (success) {
                 // 'success' here means we did successfully ask for
                 // authorization, does not mean we were authorized!
                 [self clearTextView];
                 [self getBirthday];
                 [self getBiologicalSex];
                 [self getHeight];
                 [self getWeight];
                 [self getStepCount];
                 [self getHeartRate];
             } else if (error) {
                 [self addText:[error localizedDescription]];
             }
         }];
    } else {
        [self clearTextView];
        [self addText:@"HealthKit is not available."];
    }
}

- (BOOL)getWriteAuthorizationStatusForType:(HKObjectType *)type
                                     label:(NSString *)label
{
    if (!_healthStore || !type) {
        return NO;
    }
    
    if (!label) {
        label = @"Undefined";
    }
    
    NSString *message = nil;
    
    // authorizationStatusForType: only works for write types.
    // For read types, if sharing was deined, it will simple returns as no data.
    switch ([_healthStore authorizationStatusForType:type]) {
        case HKAuthorizationStatusNotDetermined:
            message = @"Not Determined";
            break;
        case HKAuthorizationStatusSharingDenied:
            message = @"Sharing Denied";
            break;
        case HKAuthorizationStatusSharingAuthorized:
            return YES;
        default:
            break;
    }
    message = [NSString stringWithFormat:@"%@: %@",
               label,
               message];
    
    [self addText:message];
    
    return NO;
}

#pragma mark Birthday

- (void)getBirthday
{
    NSError *error;
    NSDateComponents *birthdayComponents
    = [_healthStore dateOfBirthComponentsWithError:&error];
    
    if (!error) {
        
        if (birthdayComponents) {
            NSDate *birthday = [birthdayComponents date];
            if (birthday) {
                NSDateFormatter *dateFormatter = [NSDateFormatter new];
                [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
                [dateFormatter setDateFormat:@"'Birthday: 'yyyy-MM-dd"];
                [self addText:[dateFormatter stringFromDate:birthday]];
            }
        } else {
            [self addText:@"Birthday: Not Set (or Sharing Denied)"];
        }
        
    } else {
        [self addText:[NSString stringWithFormat:@"Birthday: %@",
                       [error localizedDescription]]];
    }
}

#pragma mark Bio Sex

- (void)getBiologicalSex
{
    NSError *error;
    HKBiologicalSexObject *bioSex
    = [_healthStore biologicalSexWithError:&error];
    
    NSString *message = nil;
    
    if (!error) {
        switch (bioSex.biologicalSex) {
            case HKBiologicalSexNotSet:
                message = @"Not Set (or Sharing Denied)";
                break;
            case HKBiologicalSexFemale:
                message = @"Female";
                break;
            case HKBiologicalSexMale:
                message = @"Male";
                break;
            case HKBiologicalSexOther:
                message = @"Other";
                break;
            default:
                message = @"Error";
                break;
        }
        
        if (message) {
            message = [NSString stringWithFormat:@"Sex: %@",
                       message];
            [self addText:message];
        }
        
    } else {
        [self addText:[NSString stringWithFormat:@"Sex: %@",
                       [error localizedDescription]]];
    }
}

#pragma mark Height

- (void)getHeight
{
//    NSCalendar *calendar = [NSCalendar currentCalendar];
//    NSDateComponents *components =
//    [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
//                fromDate:[NSDate date]];
//    NSDate *startDate = [calendar dateFromComponents:components];
//    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay
//                                           value:1
//                                          toDate:startDate
//                                         options:0];
//    NSPredicate *predicate =
//    [HKQuery predicateForSamplesWithStartDate:startDate
//                                      endDate:endDate
//                                      options:HKQueryOptionNone];
    
    [self getSampleQueryWithTypeIdentifier:HKQuantityTypeIdentifierHeight
                                     label:@"Height"
                                 predicate:nil
                                     limit:HKObjectQueryNoLimit
                                 ascending:NO];
}

#pragma mark Weight

- (void)getWeight
{
    [self getSampleQueryWithTypeIdentifier:HKQuantityTypeIdentifierBodyMass
                                     label:@"Weight"
                                 predicate:nil
                                     limit:HKObjectQueryNoLimit
                                 ascending:NO];
}

#pragma mark Step Count

- (void)getStepCount
{
    [self getSampleQueryWithTypeIdentifier:HKQuantityTypeIdentifierStepCount
                                     label:@"Step Count (Last 10)"
                                 predicate:nil
                                     limit:10
                                 ascending:NO];
}

#pragma mark Heart Rate

- (void)getHeartRate
{
    [self getSampleQueryWithTypeIdentifier:HKQuantityTypeIdentifierHeartRate
                                     label:@"Heart Rate (Last 10)"
                                 predicate:nil
                                     limit:10
                                 ascending:NO];
}

#pragma mark - Utils

- (void)getSampleQueryWithTypeIdentifier:(HKQuantityTypeIdentifier)identifier
                                   label:(NSString *)label
                               predicate:(NSPredicate *)predicate
                                   limit:(NSUInteger)limit
                               ascending:(BOOL)ascending
{
    if (!_healthStore || !identifier) {
        return;
    }
    
    if (!label) {
        label = identifier;
    }
    
    NSSortDescriptor *dateDescriptor =
    [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate
                                ascending:ascending];
    
    HKSampleType *sampleType =
    [HKSampleType quantityTypeForIdentifier:identifier];
    
    HKSampleQuery *query =
    [[HKSampleQuery alloc] initWithSampleType:sampleType
                                    predicate:predicate
                                        limit:limit
                              sortDescriptors:@[dateDescriptor]
                               resultsHandler:^(HKSampleQuery *query,
                                                NSArray *results,
                                                NSError *error)
     {
         if (error) {
             NSLog(@"%@: %@",
                   label,
                   [error localizedDescription]);
             [self addText:[NSString stringWithFormat:@"%@: %@",
                            label,
                            [error localizedDescription]]];
             return;
         }
         
         if (results) {
             if (results.count) {
                 NSMutableArray *array = [NSMutableArray new];
                 
                 NSDateFormatter *dateFormatter = [NSDateFormatter new];
                 [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
                 [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                 
                 for (HKQuantitySample *sample in results) {
                     [array addObject:[NSString stringWithFormat:@"> %@ (%@ - %@)",
                                       sample.quantity,
                                       [dateFormatter stringFromDate:sample.startDate],
                                       [dateFormatter stringFromDate:sample.endDate]]];
                 }
                 NSString *message = [NSString stringWithFormat:@"%@:\n%@",
                                      label,
                                      [array componentsJoinedByString:@",\n"]];
                 [self addText:message];
             } else {
                 [self addText:[NSString stringWithFormat:@"%@: No Data",
                                label]];
             }
             
         }
     }];
    
    [_healthStore executeQuery:query];
}

#pragma mark - Text View

- (void)clearTextView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _textView.text = @"";
    });
}

- (void)addText:(NSString *)string
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _textView.text = [NSString stringWithFormat:@"%@\n%@",
                          _textView.text,
                          string];
    });
}

#pragma mark - IBActions

- (IBAction)getHealthData:(id)sender
{
    [self getHealthKit];
}

@end
