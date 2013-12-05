//
//  ZGBSidePanelsController.h
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
#import <QuartzCore/QuartzCore.h>
#import "UIViewController+PanelsController.h"
#import "CAAnimationGroup+Bounce.h"

@interface ZGBNonInterpolatedLayer : CALayer

- (void)setOpacity:(float)opacity animated:(BOOL)animated;

// The animation duration after you release your finger off a view
@property (nonatomic, assign) CGFloat animationDuration;

@end

typedef NS_ENUM(NSUInteger, ZGBRecognizedPanelSwipeDirection) {
    ZGBRecognizedPanelSwipeDirectionNone,
    ZGBRecognizedPanelSwipeDirectionLeft,
    ZGBRecognizedPanelSwipeDirectionRight,
    ZGBRecognizedPanelSwipeDirectionUp,
    ZGBRecognizedPanelSwipeDirectionDown
};

@protocol ZGBSidePanelsDelegate <NSObject>

@optional

/** Called before the beginning of each transition after the finger has been released and the next view controller will get pushed.
 *  The view controller that is going to be pushed on top will be the `invisible` one in that case!
 *
 *  @param      automaticAnimation      Parameter if an animation was played during the switch.
 *
 */
- (void)willChangeViewControllerOnTopWithAutomaticAnimation:(BOOL)automaticAnimation;

/**
 *  Called whenever the view controller is fully visible on top of every other view controller and the transition is fully finished.
 *  Here you can change your allowed swiping directions.
 *
 *  @param      automaticAnimation      Parameter if an animation was played during the switch.
 *
 */
- (void)didChangeViewControllerOnTopWithAutomaticAnimation:(BOOL)automaticAnimation;

/**
 *  This method gets called whenever a gesture recognizer will begin. You can exclude gestures from getting
 *  recognized in a specific view.
 *
 *  @param      gr      The gesture recognizer.
 *
 */
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gr;

/**
 *  This method gets called whenever the gesture recognizer receives a touch.
 *
 *  @param      gr      The gesture recognizer.
 *  @param      touch   The received touch.
 *
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gr shouldReceiveTouch:(UITouch *)touch;

@end

@interface ZGBSidePanelsController : UIViewController <UIGestureRecognizerDelegate>

// References to both panels
@property (nonatomic, weak, readonly) UIViewController<ZGBSidePanelsDelegate> *visiblePanel;
@property (nonatomic, weak, readonly) UIViewController<ZGBSidePanelsDelegate> *invisiblePanel;

// View controllers (panels)
@property (nonatomic, strong) UIViewController<ZGBSidePanelsDelegate> *centerPanel;
@property (nonatomic, strong) UIViewController<ZGBSidePanelsDelegate> *leftPanel;
@property (nonatomic, strong) UIViewController<ZGBSidePanelsDelegate> *rightPanel;
@property (nonatomic, strong) UIViewController<ZGBSidePanelsDelegate> *topPanel;
@property (nonatomic, strong) UIViewController<ZGBSidePanelsDelegate> *bottomPanel;

// The minimum percentage of total screen width for a pan gesture to succeed
@property (nonatomic, assign) CGFloat minimumMovePercentage;

// The percentage the view below is smaller than the view above (the values go from 0.0 to 1.0;
// 0.0 meaning the view below will be 100% of the size of the view above and 1.0 meaning the view below will be
// 0% of the view above
@property (nonatomic, assign) CGFloat bottomViewSizePercentage;

// The dim layer's initial opacity (that is the layer between the visible and invisible views)
@property (nonatomic, assign) CGFloat minimumDimLayerOpacity;

// The animation duration after you release your finger off a view
@property (nonatomic, assign) CGFloat restoreAnimationDuration;

// A multiplier value used to darken dim layer
@property (nonatomic, assign) CGFloat dimValueMultiplier;

// The corner radius of each panel
@property (nonatomic, assign) CGFloat cornerRadius;

// A boolean variable to enable/disable the user interaction on the top most view
@property (nonatomic, assign, getter = isUserInteractionEnabled) BOOL userInteractionEnabled;

// A boolean variable to make the dim layer between the visible and the invisible view controllers visible
@property (nonatomic, assign, getter = isDimLayerVisible) BOOL dimLayerVisible;

// Returns the swiping direction
@property (nonatomic, assign, readonly) ZGBRecognizedPanelSwipeDirection swipeDirection;

/**
 *  Bounce back the currently visible view and show the invisible view underneath.
 *
 *  @param      direction       The bouncing direction.
 *  @param      duration        The animation duration.
 *  @param      offset          The bouncing offset. [0.0, 1.0]
 *  @param      bounces         The number of bounces the animation sequence should play.
 *
 */
- (void)bounceBackWithDirection:(ZGBPanelBounceDirection)direction duration:(NSTimeInterval)duration offset:(CGFloat)offset bounces:(NSInteger)bounces;

/**
 *  Move the currently visible view aside and show the invisible view underneath.
 *
 *  @param      direction       The movement direction.
 *  @param      duration        The animation duration.
 *
 */
- (void)moveWithDirection:(ZGBRecognizedPanelSwipeDirection)direction duration:(NSTimeInterval)duration;

@end
