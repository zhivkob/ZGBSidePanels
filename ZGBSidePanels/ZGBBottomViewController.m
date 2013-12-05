//
//  ZGBBottomViewController.m
//  ZGBSidePanels
//
//  Created by Zhivko Bogdanov on 11/27/13.
//  Copyright (c) 2013 Zhivko Bogdanov. All rights reserved.
//

#import "ZGBBottomViewController.h"
#import "ZGBSidePanelsController.h"

@implementation ZGBBottomViewController

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

- (IBAction)moveButtonPressed:(id)sender
{
    [self.panelsController moveWithDirection:ZGBRecognizedPanelSwipeDirectionDown
                                    duration:1.5f];
}

@end
