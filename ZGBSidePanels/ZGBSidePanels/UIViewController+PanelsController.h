//
//  UIViewController+PanelsController.h
//
//  Copyright 2013 Zhivko Bogdanov
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import <UIKit/UIKit.h>

@class ZGBSidePanelsController;

static const char kAllowedSwipeDirectionsKey;

typedef NS_OPTIONS(NSUInteger, ZGBPanelAllowedSwipeDirection) {
    ZGBAllowedPanelSwipeDirectionNone = 0,
    ZGBAllowedPanelSwipeDirectionLeft = (1 << 0),
    ZGBAllowedPanelSwipeDirectionRight = (1 << 1),
    ZGBAllowedPanelSwipeDirectionUp = (1 << 2),
    ZGBAllowedPanelSwipeDirectionDown = (1 << 3),
    ZGBAllowedPanelSwipeDirectionAll = 15
};

@interface UIViewController (PanelsController)

// The property provides an easy way to access the currentl owner of the view controller
@property (nonatomic, weak, readonly) ZGBSidePanelsController *panelsController;

// The property saves the allowed directions of scroll for a certain view controller
@property (nonatomic, assign) ZGBPanelAllowedSwipeDirection allowedSwipeDirections;

// Returns a screenshot of the current view of that view controller
@property (nonatomic, strong, readonly) UIImage *screenshot;

@end
