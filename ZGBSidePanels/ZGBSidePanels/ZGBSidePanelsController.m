//
//  ZGBSidePanelsController.m
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

#import "ZGBSidePanelsController.h"

@interface ZGBNonInterpolatedLayer ()

@property (nonatomic, assign) BOOL animated;

@end

@implementation ZGBNonInterpolatedLayer

- (id<CAAction>)actionForKey:(NSString *)event
{
    // Disable the implicit animation of the opacity when desired
    if([event isEqualToString:@"opacity"]) {
        if (_animated) {
            CATransition *basicAnimation = [CATransition animation];
            basicAnimation.type = kCATransitionFade;
            basicAnimation.duration = _animationDuration;
            return basicAnimation;
        }
        else
            return nil;
    }
    
    return [super actionForKey:event];
}

- (void)setOpacity:(float)opacity animated:(BOOL)animated
{
    _animated = animated;
    [self setOpacity:opacity];
}

@end

@interface ZGBSidePanelsController ()
{
    @private
    
    // Variable to indicate whether the method has been already called once
    BOOL didLayoutViews;
    
    // Is the automatic animation currently being played
    BOOL isAutomaticAnimationPlaying;
    
    // Variable to save the initial location of the view to be translated
    CGPoint initialLocation;
    
    // The last pan offset
    CGFloat lastDifference;
    
    // The dim layer above every invisible view
    ZGBNonInterpolatedLayer *dimLayer;
    
    // The gesture recognizer to recognize pans and change between the views
    UIPanGestureRecognizer *panGestureRecognizer;
}

// Locks the scrolling direction after a gesture has been recognized
@property (nonatomic, assign) ZGBRecognizedPanelSwipeDirection swipeDirection;

// References to both panels
@property (nonatomic, weak) UIViewController<ZGBSidePanelsDelegate> *visiblePanel;
@property (nonatomic, weak) UIViewController<ZGBSidePanelsDelegate> *invisiblePanel;

@end

@implementation ZGBSidePanelsController

- (id)init
{
    if (self = [super init]) {
        [self _init];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self _init];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self _init];
    }
    
    return self;
}

- (void)_init
{
    // Configure the initial values
    didLayoutViews = NO;
    _dimLayerVisible = YES;
    _restoreAnimationDuration = 0.25f;
    _minimumMovePercentage = 0.25f;
    _minimumDimLayerOpacity = 0.8f;
    _bottomViewSizePercentage = 0.2f;
    _dimValueMultiplier = 1.2f;
    _swipeDirection = ZGBRecognizedPanelSwipeDirectionNone;
    
    // Create the pan gesture recognizer
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    // Add the gesture recognizer
    panGestureRecognizer.delegate = self;
    panGestureRecognizer.minimumNumberOfTouches = 1;
    panGestureRecognizer.maximumNumberOfTouches = 1;
    [self.view addGestureRecognizer:panGestureRecognizer];
    
    // Configure the allowed swipe directions
    NSUInteger centerPanelSwipeDirections = 0;
    if (_leftPanel)
        centerPanelSwipeDirections |= ZGBAllowedPanelSwipeDirectionRight;
    if (_rightPanel)
        centerPanelSwipeDirections |= ZGBAllowedPanelSwipeDirectionLeft;
    if (_topPanel)
        centerPanelSwipeDirections |= ZGBAllowedPanelSwipeDirectionDown;
    if (_bottomPanel)
        centerPanelSwipeDirections |= ZGBAllowedPanelSwipeDirectionUp;
    
    _centerPanel.allowedSwipeDirections = centerPanelSwipeDirections;
    
    if ([_leftPanel isEqual:_rightPanel]) {
        _leftPanel.allowedSwipeDirections = (ZGBAllowedPanelSwipeDirectionLeft | ZGBAllowedPanelSwipeDirectionRight);
        _rightPanel.allowedSwipeDirections = (ZGBAllowedPanelSwipeDirectionLeft | ZGBAllowedPanelSwipeDirectionRight);
    }
    else {
        _leftPanel.allowedSwipeDirections = ZGBAllowedPanelSwipeDirectionLeft;
        _rightPanel.allowedSwipeDirections = ZGBAllowedPanelSwipeDirectionRight;
    }
    
    if ([_topPanel isEqual:_bottomPanel]) {
        _topPanel.allowedSwipeDirections = (ZGBAllowedPanelSwipeDirectionUp | ZGBAllowedPanelSwipeDirectionDown);
        _bottomPanel.allowedSwipeDirections = (ZGBAllowedPanelSwipeDirectionUp | ZGBAllowedPanelSwipeDirectionDown);
    }
    else {
        _topPanel.allowedSwipeDirections = ZGBAllowedPanelSwipeDirectionUp;
        _bottomPanel.allowedSwipeDirections = ZGBAllowedPanelSwipeDirectionDown;
    }
}

- (BOOL)shouldAutorotate
{
    return _visiblePanel.shouldAutorotate;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return _visiblePanel.supportedInterfaceOrientations;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([_visiblePanel respondsToSelector:@selector(gestureRecognizerShouldBegin:)])
        return [_visiblePanel gestureRecognizerShouldBegin:gestureRecognizer];
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([_visiblePanel respondsToSelector:@selector(gestureRecognizer:shouldReceiveTouch:)])
        return [_visiblePanel gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
    
    return YES;
}

- (void)viewDidLayoutSubviews
{
    if (!didLayoutViews) {
        [self addChildViewController:_centerPanel];
        [self.view addSubview:_centerPanel.view];
        [_centerPanel didMoveToParentViewController:self];
        _visiblePanel = _centerPanel;
        self.cornerRadius = 12.0f;
        
        didLayoutViews = YES;
    }
    
    [super.view layoutSubviews];
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    _cornerRadius = cornerRadius;
    
    // Configure the panels' looks
    [self configureLayoutForViewController:_centerPanel];
    if (_leftPanel)
        [self configureLayoutForViewController:_leftPanel];
    if (_rightPanel)
        [self configureLayoutForViewController:_rightPanel];
    if (_topPanel)
        [self configureLayoutForViewController:_topPanel];
    if (_bottomPanel)
        [self configureLayoutForViewController:_bottomPanel];
}

/**
 *  This method configures the layout for a given view controller.
 *
 *  @param      viewController      The view controller to configure the layout of.
 *
 */
- (void)configureLayoutForViewController:(UIViewController *)viewController
{
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:viewController.view.bounds cornerRadius:_cornerRadius];
    viewController.view.frame = CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, self.view.bounds.size.height);
    viewController.view.layer.cornerRadius = _cornerRadius;
    viewController.view.layer.shadowPath = shadowPath.CGPath;
    viewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    viewController.view.layer.shadowRadius = 10.0f;
    viewController.view.layer.shadowOpacity = 0.75f;
    viewController.view.clipsToBounds = NO;
    
    // Handle the case when the view controller is a subclass of UITableViewController or when it contains a table view
    if ([viewController isKindOfClass:[UITableViewController class]]) {
        UITableViewController *tableViewController = (UITableViewController *)viewController;
        tableViewController.tableView.layer.cornerRadius = _cornerRadius;
        tableViewController.tableView.clipsToBounds = YES;
    }
    else {
        for (UIView *view in viewController.view.subviews) {
            if ([view isKindOfClass:[UITableView class]]) {
                view.layer.cornerRadius = _cornerRadius;
                view.clipsToBounds = YES;
            }
        }
    }
}

/**
 *  This method adds a view controller behind the visible one.
 *
 *  @param      viewController      A view controller to add, that might confirm to the ZGBSidePanelsDelegate protocol.
 *
 */
- (void)addInvisibleViewController:(UIViewController<ZGBSidePanelsDelegate> *)viewController
{
    [self addChildViewController:viewController];
    
    // Try to reset the frame of the view
    do {
        viewController.view.transform = CGAffineTransformIdentity;
        viewController.view.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
    } while (viewController.view.frame.origin.x != 0.0f && viewController.view.frame.origin.y != 0.0f);
    
    // Scale down the view
    viewController.view.transform = CGAffineTransformMakeScale(1.0f - _bottomViewSizePercentage, 1.0f - _bottomViewSizePercentage);
    
    [self.view insertSubview:viewController.view belowSubview:_visiblePanel.view];
    [viewController didMoveToParentViewController:self];
    _invisiblePanel = viewController;
    
    // Initialize and add the dim layer
    if (_dimLayerVisible) {
        if (!dimLayer) {
            dimLayer = [ZGBNonInterpolatedLayer layer];
            dimLayer.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
            dimLayer.backgroundColor = [UIColor blackColor].CGColor;
        }
        
        [dimLayer setOpacity:_minimumDimLayerOpacity animated:NO];
        [self.view.layer insertSublayer:dimLayer below:_visiblePanel.view.layer];
    }
}

/**
 *  This method removes the invisible view controller behind.
 *
 */
- (void)removeInvisibleViewController
{
    // Remove the invisible view from the child view controllers of the current view controller
    [_invisiblePanel willMoveToParentViewController:nil];
    [_invisiblePanel.view removeFromSuperview];
    [_invisiblePanel removeFromParentViewController];
}

/**
 *  This method overrides the standard setter method.
 *  
 *  @param      userInteractionEnabled      Parameter if the user interaction should get enabled.
 *
 */
- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    self.view.userInteractionEnabled = userInteractionEnabled;
    panGestureRecognizer.enabled = userInteractionEnabled;
}

/**
 *  This method handles the pan gestures.
 *
 *  @param      gr      The gesture recognizer.
 *
 */
- (void)handlePan:(UIPanGestureRecognizer *)gr
{
    if (gr.state == UIGestureRecognizerStateBegan) {
        _swipeDirection = ZGBRecognizedPanelSwipeDirectionNone;
        initialLocation = [gr locationInView:self.view];
    }
    else if (gr.state == UIGestureRecognizerStateChanged) {
        //
        // Check out if we are past the middle in the other direction.
        // If that is the case, remove the view underneath and set the direction to NONE
        //
        // Calculate the location
        CGPoint location = [gr locationInView:self.view];
        CGFloat difference = 0.0f;
        
        switch (_swipeDirection) {
            case ZGBRecognizedPanelSwipeDirectionRight:
            case ZGBRecognizedPanelSwipeDirectionLeft: {
                difference = location.x - initialLocation.x;
                
                break;
            }
            case ZGBRecognizedPanelSwipeDirectionDown:
            case ZGBRecognizedPanelSwipeDirectionUp: {
                difference = location.y - initialLocation.y;
                
                break;
            }
            default:
                break;
        }

        // If we are past the middle
        if ((lastDifference < 0.0f && difference > 0.0f) || (lastDifference > 0.0f && difference < 0.0f))
            _swipeDirection = ZGBRecognizedPanelSwipeDirectionNone;
        
        // Save the last difference
        lastDifference = difference;
        BOOL pastMiddle = (lastDifference < 0.0f && difference > 0.0f) || (lastDifference > 0.0f && difference < 0.0f);
        if (pastMiddle)
            _swipeDirection = ZGBRecognizedPanelSwipeDirectionNone;
        
        // If the swiping direction is not locked
        if (_swipeDirection == ZGBRecognizedPanelSwipeDirectionNone) {
            CGPoint velocity = [gr velocityInView:self.view];
            
            if (fabsf(velocity.x) > fabsf(velocity.y)) {
                if (velocity.x < 0.0f) {
                    // If the desired swipe direction is disallowed, just save the location as an initial one and return
                    if (!(_visiblePanel.allowedSwipeDirections & ZGBAllowedPanelSwipeDirectionLeft)) {
                        initialLocation = [gr locationInView:self.view];
                        return;
                    }
                    
                    _swipeDirection = ZGBRecognizedPanelSwipeDirectionLeft;
                    
                    // Add the new view controller underneath the visible view controller
                    if ([_visiblePanel isEqual:_centerPanel])
                        [self addInvisibleViewController:_rightPanel];
                    else
                        [self addInvisibleViewController:_centerPanel];
                }
                else {
                    // If the desired swipe direction is disallowed, just save the location as an initial one and return
                    if (!(_visiblePanel.allowedSwipeDirections & ZGBAllowedPanelSwipeDirectionRight)) {
                        initialLocation = [gr locationInView:self.view];
                        return;
                    }
                    
                    _swipeDirection = ZGBRecognizedPanelSwipeDirectionRight;
                    
                    // Add the new view underneath
                    if ([_visiblePanel isEqual:_centerPanel])
                        [self addInvisibleViewController:_leftPanel];
                    else
                        [self addInvisibleViewController:_centerPanel];
                }
            }
            else {
                if (velocity.y >= 0.0f) {
                    // If the desired swipe direction is disallowed, just save the location as an initial one and return
                    if (!(_visiblePanel.allowedSwipeDirections & ZGBAllowedPanelSwipeDirectionDown)) {
                        initialLocation = [gr locationInView:self.view];
                        return;
                    }
                    
                    _swipeDirection = ZGBRecognizedPanelSwipeDirectionDown;
                    
                    // Add the new view underneath
                    if ([_visiblePanel isEqual:_centerPanel])
                        [self addInvisibleViewController:_topPanel];
                    else
                        [self addInvisibleViewController:_centerPanel];
                }
                else {
                    // If the desired swipe direction is disallowed, just save the location as an initial one and return
                    if (!_bottomPanel || !(_visiblePanel.allowedSwipeDirections & ZGBAllowedPanelSwipeDirectionUp)) {
                        initialLocation = [gr locationInView:self.view];
                        return;
                    }
                    
                    _swipeDirection = ZGBRecognizedPanelSwipeDirectionUp;
                    
                    // Add the new view underneath
                    if ([_visiblePanel isEqual:_centerPanel])
                        [self addInvisibleViewController:_bottomPanel];
                    else
                        [self addInvisibleViewController:_centerPanel];
                }
            }
        }
        
        switch (_swipeDirection) {
            case ZGBRecognizedPanelSwipeDirectionRight:
            case ZGBRecognizedPanelSwipeDirectionLeft: {
                //
                // Calculate the difference between the pan positions and the increase in the size of the invisible view
                CGFloat difference = location.x - initialLocation.x;
                CGFloat factor = fabsf(difference) / self.view.frame.size.width;
                CGFloat sizeIncrease = _bottomViewSizePercentage * factor;
                
                // Change the size of the invisible view
                _invisiblePanel.view.transform = CGAffineTransformMakeScale(1.0f - _bottomViewSizePercentage + sizeIncrease, 1.0f - _bottomViewSizePercentage + sizeIncrease);
                
                // Change the alpha of the dim view
                // Multiply the factor for a slower speed
                if (_dimLayerVisible) {
                    CGFloat dimLayerOpacity = 1.0f - fabsf(difference) / (_dimValueMultiplier * self.view.frame.size.width);
                    [dimLayer setOpacity:dimLayerOpacity animated:NO];
                }
                
                // Animate the frame position of the current view
                CGRect frame = _visiblePanel.view.frame;
                frame.origin.x = difference;
                _visiblePanel.view.frame = frame;
                
                break;
            }
            case ZGBRecognizedPanelSwipeDirectionDown:
            case ZGBRecognizedPanelSwipeDirectionUp: {
                //
                // Calculate the difference between the pan positions and the increase in the size of the invisible view
                CGFloat difference = location.y - initialLocation.y;
                CGFloat factor = fabsf(difference) / self.view.frame.size.height;
                CGFloat sizeIncrease = _bottomViewSizePercentage * factor;
                CGFloat scale = 1.0f - _bottomViewSizePercentage + sizeIncrease;
                
                // Change the size of the invisible view
                _invisiblePanel.view.transform = CGAffineTransformMakeScale(scale, scale);
                
                // Change the alpha of the dim view
                if (_dimLayerVisible) {
                    CGFloat dimLayerOpacity = 1.0f - fabsf(difference) / (_dimValueMultiplier * self.view.frame.size.height);
                    [dimLayer setOpacity:dimLayerOpacity animated:NO];
                }
                
                // Animate the frame position of the current view
                CGRect frame = _visiblePanel.view.frame;
                frame.origin.y = difference;
                _visiblePanel.view.frame = frame;
                
                break;
            }
            default:
                break;
        }
    }
    else {
        switch (_swipeDirection) {
            case ZGBRecognizedPanelSwipeDirectionRight:
            case ZGBRecognizedPanelSwipeDirectionLeft: {
                //
                // Calculate the location and the difference between the first and last
                CGPoint location = [gr locationInView:self.view];
                CGFloat difference = location.x - initialLocation.x;
                
                //
                // If we didn't pan long enough we remove the view underneath after the animation to restore the currently visible view
                if (fabsf(difference) < _minimumMovePercentage * self.view.frame.size.width)
                    [self restoreViewControllerWithScrollDirection:_swipeDirection willGoInvisible:NO duration:_restoreAnimationDuration];
                else
                    [self restoreViewControllerWithScrollDirection:_swipeDirection willGoInvisible:YES duration:_restoreAnimationDuration];
                
                break;
            }
            case ZGBRecognizedPanelSwipeDirectionDown:
            case ZGBRecognizedPanelSwipeDirectionUp: {
                //
                // Calculate the location and the difference between the first and last
                CGPoint location = [gr locationInView:self.view];
                CGFloat difference = location.y - initialLocation.y;
                
                if (fabsf(difference) < _minimumMovePercentage * self.view.frame.size.height)
                    [self restoreViewControllerWithScrollDirection:_swipeDirection willGoInvisible:NO duration:_restoreAnimationDuration];
                else
                    [self restoreViewControllerWithScrollDirection:_swipeDirection willGoInvisible:YES duration:_restoreAnimationDuration];
                
                break;
            }
            case ZGBRecognizedPanelSwipeDirectionNone: {
                [self restoreViewControllerWithScrollDirection:_swipeDirection willGoInvisible:NO duration:_restoreAnimationDuration];
                
                break;
            }
        }
    }
}

/**
 *  This method restores a view controller for a given swipe direction. It removes the currently invisible one and sets
 *  the one on top as visible.
 *
 *  @param      scrollDir       The scrolling direction.
 *  @param      goInvisible     Decides if the view controller will go invisible.
 *  @param      duration        The animation duration.
 *
 */
- (void)restoreViewControllerWithScrollDirection:(ZGBRecognizedPanelSwipeDirection)scrollDir willGoInvisible:(BOOL)goInvisible duration:(CGFloat)duration
{
    [UIView animateWithDuration:duration
                     animations:^{
                         // Disable the user interaction while animating
                         self.view.userInteractionEnabled = NO;
                         
                         if (!goInvisible) {
                             _visiblePanel.view.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
                         }
                         else {
                             // Send a message about the change of the view controller on top
                             if ([_visiblePanel respondsToSelector:@selector(willChangeViewControllerOnTopWithAutomaticAnimation:)])
                                 [_visiblePanel willChangeViewControllerOnTopWithAutomaticAnimation:isAutomaticAnimationPlaying];
                             
                             // Restore the view above according to the scroll direction
                             switch (scrollDir) {
                                 case ZGBRecognizedPanelSwipeDirectionRight: {
                                     _visiblePanel.view.frame = CGRectMake(_visiblePanel.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
                                     
                                     break;
                                 }
                                 case ZGBRecognizedPanelSwipeDirectionLeft: {
                                     _visiblePanel.view.frame = CGRectMake(-_visiblePanel.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
                                     
                                     break;
                                 }
                                 case ZGBRecognizedPanelSwipeDirectionUp: {
                                     _visiblePanel.view.frame = CGRectMake(0.0f, -_visiblePanel.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
                                     
                                     break;
                                 }
                                 case ZGBRecognizedPanelSwipeDirectionDown: {
                                     _visiblePanel.view.frame = CGRectMake(0.0f, _visiblePanel.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
                                     
                                     break;
                                 }
                                 case ZGBRecognizedPanelSwipeDirectionNone:
                                     break;
                             }
                             
                             // Restore the view underneath
                             _invisiblePanel.view.transform = CGAffineTransformIdentity;
                             
                             // Restore the opacity of the dim layer
                             [dimLayer setOpacity:0.0f animated:YES];
                         }
                     }
                     completion:^(BOOL finished) {
                         // Restore the dim view
                         if (goInvisible) {
                             UIViewController<ZGBSidePanelsDelegate> *tempViewController = _visiblePanel;
                             _visiblePanel = _invisiblePanel;
                             _invisiblePanel = tempViewController;
                             
                             // Make the visible panel standard size
                             [self.view bringSubviewToFront:_visiblePanel.view];
                             
                             // Send a message about the change of the view controller on top
                             if ([_visiblePanel respondsToSelector:@selector(didChangeViewControllerOnTopWithAutomaticAnimation:)])
                                 [_visiblePanel didChangeViewControllerOnTopWithAutomaticAnimation:isAutomaticAnimationPlaying];
                         }
                         
                         [self removeInvisibleViewController];
                         
                         // Enable the user interaction after animating
                         self.view.userInteractionEnabled = YES;
                         isAutomaticAnimationPlaying = NO;
                     }];
}


/**
 *  Bounce back the currently visible view and show the invisible view underneath.
 *
 *  @param      direction       The bouncing direction.
 *  @param      duration        The animation duration.
 *  @param      offset          The bouncing offset.
 *  @param      bounces         The number of bounces the animation sequence should play.
 *
 */
- (void)bounceBackWithDirection:(ZGBPanelBounceDirection)direction duration:(NSTimeInterval)duration offset:(CGFloat)offset bounces:(NSInteger)bounces
{
    // Disable the user interaction while animating
    self.view.userInteractionEnabled = NO;
    
    //
    // First we add the new view underneath
    switch (direction) {
        case ZGBPanelBounceDirectionLeft: {
            if (!_leftPanel)
                return;
            
            // Add the new view underneath
            if (_visiblePanel == _leftPanel)
                [self addInvisibleViewController:_centerPanel];
            else
                [self addInvisibleViewController:_leftPanel];
            
            break;
        }
        case ZGBPanelBounceDirectionRight: {
            if (!_rightPanel)
                return;
            
            // Add the new view underneath
            if (_visiblePanel == _rightPanel)
                [self addInvisibleViewController:_centerPanel];
            else
                [self addInvisibleViewController:_rightPanel];
            
            break;
        }
        case ZGBPanelBounceDirectionDown: {
            if (!_topPanel)
                return;
            
            // Add the new view underneath
            if (_visiblePanel == _topPanel)
                [self addInvisibleViewController:_centerPanel];
            else
                [self addInvisibleViewController:_topPanel];
            
            break;
        }
        case ZGBPanelBounceDirectionUp: {
            if (!_bottomPanel)
                return;
            
            // Add the new view underneath
            if (_visiblePanel == _bottomPanel)
                [self addInvisibleViewController:_centerPanel];
            else
                [self addInvisibleViewController:_bottomPanel];
            
            break;
        }
    }
    
    CAAnimationGroup *animation = [CAAnimationGroup bounceView:_visiblePanel.view
                                                 withDirection:direction
                                                      duration:duration
                                                        offset:offset
                                                     withValue:@"animation"
                                                        forKey:@"id"
                                                   bounceCount:bounces];
    
    animation.delegate = self;
    [animation setValue:@"bounceAnimation" forKey:@"id"];
    [_visiblePanel.view.layer addAnimation:animation forKey:@"bounceAnimation"];
}

/**
 *  Move the currently visible view aside and show the invisible view underneath.
 *
 *  @param      direction       The movement direction.
 *  @param      duration        The animation duration.
 *
 */
- (void)moveWithDirection:(ZGBRecognizedPanelSwipeDirection)direction duration:(NSTimeInterval)duration
{
    // Disable the user interaction while animating
    self.view.userInteractionEnabled = NO;
    isAutomaticAnimationPlaying = YES;
    
    //
    // First we add the new view underneath
    switch (direction) {
        case ZGBRecognizedPanelSwipeDirectionLeft: {
            if (!_leftPanel)
                return;
            
            // Add the new view underneath
            if (_visiblePanel == _leftPanel)
                [self addInvisibleViewController:_centerPanel];
            else
                [self addInvisibleViewController:_leftPanel];
            
            break;
        }
        case ZGBRecognizedPanelSwipeDirectionRight: {
            if (!_rightPanel)
                return;
            
            // Add the new view underneath
            if (_visiblePanel == _rightPanel)
                [self addInvisibleViewController:_centerPanel];
            else
                [self addInvisibleViewController:_rightPanel];
            
            break;
        }
        case ZGBRecognizedPanelSwipeDirectionUp: {
            if (!_topPanel)
                return;
            
            // Add the new view underneath
            if (_visiblePanel == _topPanel)
                [self addInvisibleViewController:_centerPanel];
            else
                [self addInvisibleViewController:_topPanel];
            
            break;
        }
        case ZGBRecognizedPanelSwipeDirectionDown: {
            if (!_bottomPanel)
                return;
            
            // Add the new view underneath
            if (_visiblePanel == _bottomPanel)
                [self addInvisibleViewController:_centerPanel];
            else
                [self addInvisibleViewController:_bottomPanel];
            
            break;
        }
        case ZGBRecognizedPanelSwipeDirectionNone: {
            break;
        }
    }
    
    [self restoreViewControllerWithScrollDirection:direction willGoInvisible:YES duration:duration];
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    NSString *animationId = [theAnimation valueForKey:@"id"];
    
    if ([animationId isEqualToString:@"bounceAnimation"]) {
        _visiblePanel.view.transform = CGAffineTransformIdentity;
        [self removeInvisibleViewController];
        
        // Enable the user interaction after animating
        self.view.userInteractionEnabled = YES;
    }
}

@end
