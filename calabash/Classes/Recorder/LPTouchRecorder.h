//
//  LPTouchRecorder.h
//  calabash
//
//  Created by Austin Roos on 5/26/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIApplication.h>

UIView * initialView;
CGPoint startTouchPosition1;
CGPoint startTouchPosition2;
CGPoint previousTouchPosition1;
CGPoint previousTouchPosition2;
double startTouchTime;
NSMutableArray *items;
Class  lastTouch;

typedef enum
{
  GestureTypeTap,
  GestureTypeLongPress,
  GestureTypeSwipeRight,
  GestureTypeSwipeLeft,
  GestureTypeSwipeUp,
  GestureTypeSwipeDown,
  GestureTypePinchIn,
  GestureTypePinchOut,
  GestureTypeViewAppeared,
  GestureTypeBackButtonPressed,
  GestureTypePortrait,
  GestureTypePortraitUpsideDown,
  GestureTypeLandscapeLeft,
  GestureTypeLandscapeRight,
} GestureType;

typedef enum
{
  AppEventTypeTouch,
  AppEventTypeNavigation,
  AppEventTypeTextEntry,
  AppLoaded,
  AppRotation

}AppEventType;

CGFloat CGPointDist(CGPoint a,CGPoint b);
CGFloat CGPointLen(CGPoint a);
CGPoint CGPointSub(CGPoint a,CGPoint b);

@interface LPTouchRecorder : NSObject
+ (void)sendEvent:(id)event;
+ (void) viewWillDisappear:(id)viewController isAnimated:(bool)animated;
+ (NSArray *)Items;
+ (void) AddItem:(id)item;
+ (NSMutableDictionary*) CreateTouchEvent:(UIView*)view withTapCount:(int *)tapcount atLocation:(CGPoint) location;
+ (void) didMoveToParentViewController:(UIViewController *) viewController withParent:(UIViewController*)parent;
@end