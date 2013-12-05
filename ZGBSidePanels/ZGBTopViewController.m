//
//  ZGBTopViewController.m
//  ZGBSidePanels
//
//  Created by Zhivko Bogdanov on 11/27/13.
//  Copyright (c) 2013 Zhivko Bogdanov. All rights reserved.
//

#import "ZGBTopViewController.h"
#import "ZGBSidePanelsController.h"

@implementation ZGBTopViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)bounceButtonPressed:(id)sender
{
    [self.panelsController bounceBackWithDirection:ZGBPanelBounceDirectionUp
                                          duration:0.25f
                                            offset:0.25f
                                           bounces:6];
}

@end
