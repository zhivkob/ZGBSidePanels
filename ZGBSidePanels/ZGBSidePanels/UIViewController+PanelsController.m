//
//  UIViewController+PanelsController.m
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

#import <objc/runtime.h>
#import "UIViewController+PanelsController.h"
#import "ZGBSidePanelsController.h"

@implementation UIViewController (PanelsController)

- (ZGBSidePanelsController *)panelsController
{
    UIViewController *viewController = self.parentViewController;
    if ([viewController isKindOfClass:[ZGBSidePanelsController class]])
        return (ZGBSidePanelsController *)viewController;
    
    return nil;
}

- (void)setAllowedSwipeDirections:(ZGBPanelAllowedSwipeDirection)allowedSwipeDirections
{
    objc_setAssociatedObject(self, &kAllowedSwipeDirectionsKey, @(allowedSwipeDirections), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (ZGBPanelAllowedSwipeDirection)allowedSwipeDirections
{
    return [objc_getAssociatedObject(self, &kAllowedSwipeDirectionsKey) integerValue];
}

- (UIImage *)screenshot
{
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.view.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
