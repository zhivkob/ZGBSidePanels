//
//  CAAnimationGroup+Bounce.m
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

#import "CAAnimationGroup+Bounce.h"

@implementation CAAnimationGroup (Bounce)

+ (CAAnimationGroup *)bounceView:(UIView *)view
                   withDirection:(ZGBPanelBounceDirection)direction
                        duration:(NSTimeInterval)duration
                          offset:(CGFloat)offset
                       withValue:(NSString *)value
                          forKey:(NSString *)key
                     bounceCount:(NSInteger)bounceCount
{
    NSMutableArray *animationsArray = [NSMutableArray array];
    CGPoint bouncePeak, fromPoint, bouncePoint;
    CGFloat base, peak;
    
    switch (direction) {
        case ZGBPanelBounceDirectionLeft: {
            //
            // Bouncing animation
            bouncePeak = CGPointMake(view.bounds.size.width * (0.5f - offset), view.bounds.size.height / 2.0f);
            fromPoint = CGPointMake(view.bounds.size.width / 2.0f, view.bounds.size.height / 2.0f);
            base = fromPoint.x;
            peak = bouncePeak.x - fromPoint.x;
            bouncePoint = CGPointMake(base + peak, fromPoint.y);
            
            break;
        }
        case ZGBPanelBounceDirectionRight:
            //
            // Bouncing animation
            bouncePeak = CGPointMake(view.bounds.size.width * (0.5f + offset), view.bounds.size.height / 2.0f);
            fromPoint = CGPointMake(view.bounds.size.width / 2.0f, view.bounds.size.height / 2.0f);
            base = fromPoint.x;
            peak = bouncePeak.x - fromPoint.x;
            bouncePoint = CGPointMake(base + peak, fromPoint.y);
            
            break;
        case ZGBPanelBounceDirectionUp: {
            //
            // Bouncing animation
            bouncePeak = CGPointMake(view.bounds.size.width / 2.0f, (0.5f + offset) * view.bounds.size.height);
            fromPoint = CGPointMake(view.bounds.size.width / 2.0f, view.bounds.size.height / 2.0f);
            base = fromPoint.y;
            peak = bouncePeak.y - fromPoint.y;
            bouncePoint = CGPointMake(fromPoint.x, base + peak);
            break;
        }
        case ZGBPanelBounceDirectionDown:
            //
            // Bouncing animation
            bouncePeak = CGPointMake(view.bounds.size.width / 2.0f, offset * view.bounds.size.height);
            fromPoint = CGPointMake(view.bounds.size.width / 2.0f, view.bounds.size.height / 2.0f);
            base = fromPoint.y;
            peak = bouncePeak.y - fromPoint.y;
            bouncePoint = CGPointMake(fromPoint.x, base + peak);
            break;
    }
    
    CGFloat bounceTime = duration;
    CGFloat beginTime = 0.0f;
    CGFloat animationDuration = 0.0f;
    
    for ( int i = 0; i < bounceCount; i++ ) {
        CABasicAnimation *bounceAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        [bounceAnimation setFromValue:[NSValue valueWithCGPoint:fromPoint]];
        [bounceAnimation setToValue:[NSValue valueWithCGPoint:bouncePoint]];
        bounceAnimation.fillMode = kCAFillModeForwards;
        bounceAnimation.removedOnCompletion = YES;
        bounceAnimation.autoreverses = YES;
        bounceAnimation.duration = bounceTime;
        bounceAnimation.beginTime = beginTime;
        bounceAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        animationDuration += 2 * bounceTime;
        
        beginTime += 2 * bounceTime;
        bounceTime *= 0.8f;
        peak *= 0.5f;
        
        switch (direction) {
            case ZGBPanelBounceDirectionLeft:
            case ZGBPanelBounceDirectionRight:
                bouncePoint.x = base + peak;
                break;
            case ZGBPanelBounceDirectionUp:
            case ZGBPanelBounceDirectionDown:
                bouncePoint.y = base + peak;
                break;
        }
        
        [animationsArray addObject:bounceAnimation];
    }
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.fillMode = kCAFillModeForwards;
    group.removedOnCompletion = YES;
    group.duration = animationDuration;
    group.animations = animationsArray;
    
    return group;
}

@end
