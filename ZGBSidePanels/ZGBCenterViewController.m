//
//  ZGBCenterViewController.m
//  ZGBSidePanels
//
//  Created by Zhivko Bogdanov on 11/28/13.
//  Copyright (c) 2013 Zhivko Bogdanov. All rights reserved.
//

#import "ZGBCenterViewController.h"
#import "ZGBSidePanelsController.h"

@interface ZGBCenterViewController ()
{
    
}

@end

@implementation ZGBCenterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UILabel *label = (UILabel *)[cell viewWithTag:1];
    
    // Don't do this in a table view where the cells are actually going to be reused!! This is suitable for this application though
    // and it's simple enough.
    UISlider *slider = (UISlider *)[cell viewWithTag:2];
    slider.tag = indexPath.row;

    switch (indexPath.row) {
        case 0:
            slider.minimumValue = 0.15f;
            slider.maximumValue = 0.75f;
            slider.value = self.panelsController.minimumMovePercentage;
            label.text = [NSString stringWithFormat:@"Minimum offset: %.2f%%", slider.value];
            break;
            
        case 1:
            slider.minimumValue = 0.05f;
            slider.maximumValue = 0.8f;
            slider.value = self.panelsController.bottomViewSizePercentage;
            label.text = [NSString stringWithFormat:@"Bottom view size: %.2f%%", slider.value];
            break;
            
        case 2:
            slider.minimumValue = 0.0f;
            slider.maximumValue = 1.0f;
            slider.value = self.panelsController.minimumDimLayerOpacity;
            label.text = [NSString stringWithFormat:@"Dim layer opacity: %.2f%%", slider.value];
            break;
            
        case 3:
            slider.minimumValue = 0.125f;
            slider.maximumValue = 2.0f;
            slider.value = self.panelsController.restoreAnimationDuration;
            label.text = [NSString stringWithFormat:@"Restore animation: %.2fs", slider.value];
            break;
            
        case 4:
            slider.minimumValue = 0.5f;
            slider.maximumValue = 3.0f;
            slider.value = self.panelsController.dimValueMultiplier;
            label.text = [NSString stringWithFormat:@"Dim layer multiplier: %.2f", slider.value];
            break;
            
        case 5:
            slider.minimumValue = 1.0f;
            slider.maximumValue = 20.0f;
            slider.value = self.panelsController.cornerRadius;
            label.text = [NSString stringWithFormat:@"Corner radius: %.0f", slider.value];
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gr shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UISlider class]])
        return NO;
    
    return YES;
}

- (IBAction)sliderValueChanged:(UISlider *)sender
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:sender.tag inSection:0]];
    UILabel *label = (UILabel *)[cell viewWithTag:1];
    
    switch (sender.tag) {
        case 0:
            self.panelsController.minimumMovePercentage = sender.value;
            label.text = [NSString stringWithFormat:@"Minimum offset: %.2f%%", sender.value];
            break;
        case 1:
            self.panelsController.bottomViewSizePercentage = sender.value;
            label.text = [NSString stringWithFormat:@"Bottom view size: %.2f%%", sender.value];
            break;
        case 2:
            self.panelsController.minimumDimLayerOpacity = sender.value;
            label.text = [NSString stringWithFormat:@"Dim layer opacity: %.2f%%", sender.value];
            break;
        case 3:
            self.panelsController.restoreAnimationDuration = sender.value;
            label.text = [NSString stringWithFormat:@"Restore animation: %.2fs", sender.value];
            break;
        case 4:
            self.panelsController.dimValueMultiplier = sender.value;
            label.text = [NSString stringWithFormat:@"Dim layer multiplier: %.2f", sender.value];
            break;
        case 5:
            self.panelsController.cornerRadius = roundf(sender.value);
            label.text = [NSString stringWithFormat:@"Corner radius: %.0f", sender.value];
            break;
        default:
            break;
    }
}

@end
