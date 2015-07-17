//
//  LPTouchRecorder.h
//  calabash
//
//  Created by Austin Roos on 5/26/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIApplication.h>

typedef enum
{
  AppEventTypeTap = 0,
  AppEventTypeLongPress,
  AppEventTypeDoubleTap,
  AppEventTypeSwipeLeft,
  AppEventTypeSwipeRight,
  AppEventTypeScrollUp,
  AppEventTypeScrollDown,
  AppEventTypeBackButtonPressed,
  AppEventTypeMenuButtonPressed,
  AppEventTypeEnterKeyPressed,
  AppEventTypeOrientationPortrait,
  AppEventTypeOrientationLandscape,
  AppEventTypeEnterText,
  AppEventTypeClearText,
  AppEventTypeScreenshot
} AppEventType;

@interface LPTouchRecorder : NSObject

@property(strong, nonatomic) UIView *initialView;
@property(assign, nonatomic) CGPoint startTouchPosition1;
@property(assign, nonatomic) CGPoint startTouchPosition2;
@property(assign, nonatomic) CGPoint previousTouchPosition1;
@property(assign, nonatomic) CGPoint previousTouchPosition2;
@property(assign, nonatomic) double startTouchTime;
@property(strong, nonatomic) NSMutableArray *items;
@property(strong, nonatomic) Class lastTouch;
@property(nonatomic) BOOL textEntered;
@property(strong, nonatomic) NSString *currentTextEntered;
@property(strong, nonatomic) NSMutableDictionary *currentTextEvent;

+ (LPTouchRecorder *) sharedRecorder;
- (void) shouldSendTextEntry;
- (void) sendEvent:(id)event;
- (void) viewWillDisappear:(id)viewController isAnimated:(bool)animated;
- (NSArray *) Items;
- (void) AddItem:(id)item;
- (void) didMoveToParentViewController:(UIViewController *) viewController withParent:(UIViewController*)parent;
- (NSMutableDictionary *)CreateTouchEvent:(UIView*)view withTapCount:(NSUInteger)tapcount atLocation:(CGPoint) location;

@end