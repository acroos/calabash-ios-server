//
//  LPTouchRecorder.m
//  calabash
//
//  Created by Austin Roos on 5/26/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//

#import "LPTouchRecorder.h"
#import <UIKit/UIKit.h>
#import "OCMArg.h"
#import <Foundation/Foundation.h>
#import <objc/objc.h>

@implementation LPTouchRecorder

+ (void)load {
  items = [NSMutableArray array];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowViewControllerNotification:) name:@"UINavigationControllerDidShowViewControllerNotification" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTextFieldDidChangeNotification:) name:UITextFieldTextDidEndEditingNotification object:nil];
}

- (void) handleTextFieldDidChangeNotification:(NSNotification *) aNotification {
  UITextField *textField = (UITextField *)aNotification.object;
  CGPoint center = textField.center;
  NSMutableDictionary *event = [LPTouchRecorder CreateTouchEvent:textField withTapCount:0 atLocation:center];
  [event setValue:textField.nextResponder forKey:@"NextResponder"];
  [event setValue:textField.text forKey:@"Text"];
  [event setValue:textField.accessibilityIdentifier forKey:@"Id"];
  [event setValue:@(AppEventTypeTextEntry) forKey:@"EventType"];
  [LPTouchRecorder AddItem:event];
}

+ (NSArray *)Items
{
  @try {
    NSArray *array = [NSArray arrayWithArray:items];
    [items removeAllObjects];
    return array;
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception);
  }
}

+ (void) AddItem:(NSObject *)item
{
  @try {
    [items addObject:item];
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception);
  }
}

+ (void)orientationChanged:(NSNotification *)notification
{
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  lastTouch = nil;
  GestureType type;
  if(orientation == UIInterfaceOrientationLandscapeLeft) {
    type = GestureTypeLandscapeLeft;
  } else if(orientation == UIInterfaceOrientationLandscapeRight) {
    type = GestureTypeLandscapeRight;
  }else if(orientation == UIInterfaceOrientationPortrait) {
    type = GestureTypePortrait;
  }else {
    type = GestureTypePortraitUpsideDown;
  }
  if (UIInterfaceOrientationIsLandscape(orientation))
  {
    NSLog(@"Landscape");
  } else
  {
    NSLog(@"Portrait");
  }


  NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
  [event setValue:@(AppRotation) forKey:@"EventType"];

  [event setValue:@(type) forKey:@"GestureType"];
  [items addObject:event];

}

+ (void) viewWillDisappear:(UIViewController *) viewController isAnimated:(bool)animated
{
  @try {
    if ([viewController.navigationController.viewControllers indexOfObject:viewController]==NSNotFound) {
      // back button was pressed.  We know this is true because self is no longer
      // in the navigation stack.
      NSMutableDictionary *event = [LPTouchRecorder CreateNavigationEvent:viewController];
      [event setValue:@(GestureTypeBackButtonPressed) forKey:@"GestureType"];
      [items addObject:event];
    }
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception);
  }
}

+ (void) didMoveToParentViewController:(UIViewController *) viewController withParent:(UIViewController*)parent
{
  @try {
    NSObject *last = items.lastObject;
    bool isBack = NO;
    if(last) {
      Class lastClass = NSClassFromString([last valueForKey:@"ClassType"]);
      isBack = [lastClass isSubclassOfClass:[UINavigationBar class]];
      if(isBack) {
        [items removeLastObject];
      }
    }
    else if(lastTouch)
    {
      isBack = [lastTouch isSubclassOfClass:[UINavigationBar class]];
    }
    if(![parent isEqual:viewController.parentViewController] && isBack){
      NSMutableDictionary *event = [LPTouchRecorder CreateNavigationEvent:viewController];
      [event setValue:@(GestureTypeBackButtonPressed) forKey:@"GestureType"];
      [items addObject:event];
      lastTouch = nil;
    }
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception.reason);
  }
}

+(NSString*) jsonStringWithPrettyPrint: (BOOL) prettyPrint {
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:items options:NSJSONWritingPrettyPrinted error:&error];
  if (!jsonData) {
    NSLog(@"bv_jsonStringWithPrettyPrint: error: %@", error.localizedDescription);
    return @"{}";
  } else {
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
}

+ (void) sendEvent:(UIEvent *)event {
  @try {
    if (event.type == UIEventTypeTouches) {
      // NSLog(@"Touch event");
      NSSet *allTouches = [event allTouches];
      UITouch *touch = [allTouches anyObject];
      UIView *touchView = touch.view;

      if (touch.phase == UITouchPhaseBegan) {
        initialView = touchView;
        startTouchPosition1 = [touch locationInView:touch.window];
        startTouchTime = touch.timestamp;

        if (allTouches.count > 1) {
          startTouchPosition2 = [[allTouches allObjects][1] locationInView:touch.window];
          previousTouchPosition1 = startTouchPosition1;
          previousTouchPosition2 = startTouchPosition2;
        }
      } else if (touch.phase == UITouchPhaseMoved) {

      } else if (touch.phase == UITouchPhaseEnded) {
        CGPoint currentTouchPosition = [touch locationInView:touch.window];
        NSMutableDictionary *touchEvent = [LPTouchRecorder CreateTouchEvent:touch];
        if(touchEvent == nil) {
          touchEvent = [[NSMutableDictionary alloc] init];
        }
        // Check if it's a swipe
        if (fabs(startTouchPosition1.x - currentTouchPosition.x) >= 10.0 &&
            fabs(startTouchPosition1.x - currentTouchPosition.x) > fabs(startTouchPosition1.y - currentTouchPosition.y) &&
            touch.timestamp - startTouchTime < 0.7) {
          if (startTouchPosition1.x < currentTouchPosition.x) {
            [touchEvent setValue:@((GestureTypeSwipeRight)) forKey:@"GestureType"];
          }
          else {
            [touchEvent setValue:@((GestureTypeSwipeLeft)) forKey:@"GestureType"];
          }
          //Create Touch horizontal swipe
        } else if (fabs(startTouchPosition1.y - currentTouchPosition.y) >= 10.0 &&
                   fabs(startTouchPosition1.y - currentTouchPosition.y) > fabs(startTouchPosition1.x - currentTouchPosition.x) &&
                   touch.timestamp - startTouchTime < 0.7) {
          //Create Touch vertical swipe
          if (startTouchPosition1.y < currentTouchPosition.y)
            [touchEvent setValue:@(GestureTypeSwipeDown) forKey:@"GestureType"];
          else
            [touchEvent setValue:@(GestureTypeSwipeUp) forKey:@"GestureType"];
        } else {
          if (((double) touch.timestamp - startTouchTime) > 1)
            [touchEvent setValue:@(GestureTypeLongPress) forKey:@"GestureType"];
          else
            [touchEvent setValue:@(GestureTypeTap) forKey:@"GestureType"];
        }


        NSMutableDictionary *point1 = [[NSMutableDictionary alloc] init];
        [point1 setValue:@(startTouchPosition1.x) forKey:@"X"];
        [point1 setValue:@(startTouchPosition1.y) forKey:@"Y"];


        NSMutableDictionary *point2 = [[NSMutableDictionary alloc] init];
        [point2 setValue:@(currentTouchPosition.x) forKey:@"X"];
        [point2 setValue:@(currentTouchPosition.y) forKey:@"Y"];

        NSArray *touches = [[NSMutableArray alloc] initWithObjects:point1, point2, nil];
        [touchEvent setValue:touches forKey:@"Touches"];

        [items addObject:touchEvent];
        //NSLog([Recorder jsonStringWithPrettyPrint:YES]);
        startTouchPosition1 = CGPointMake(-1, -1);
        lastTouch =  touch.view.class;
        initialView = nil;
      }

      else if (touch.phase == UITouchPhaseCancelled) {
        initialView = nil;

      }


    }
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception.reason);
  }
}

+ (void) didShowViewControllerNotification:(NSNotification*)notification
{
  @try
  {
    UIViewController *viewController = [[notification userInfo] objectForKey:@"UINavigationControllerNextVisibleViewController"];
    NSMutableDictionary *event = [LPTouchRecorder CreateNavigationEvent:viewController];
    [event setValue:@(GestureTypeViewAppeared) forKey:@"GestureType"];
    [items addObject:event];
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception.reason);
  }
}

+ (NSMutableDictionary*) CreateNavigationEvent:(UIViewController*) viewController{
  @try {
    NSString* className = NSStringFromClass([viewController class]);
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue:className forKey:@"ClassType"];
    [dictionary setValue:@(AppEventTypeNavigation) forKey:@"EventType"];
    NSString *id = [LPTouchRecorder GetIdForViewController:viewController];
    if(id.length > 0) {
      [dictionary setValue:id forKey:@"Id"];
    }

    NSString *marked = [viewController title];
    if(marked.length > 0) {
      [dictionary setValue:marked forKey:@"Marked"];
    }
    
    return dictionary;
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception.reason);
  }
}

+ (NSMutableDictionary*) CreateTouchEvent: (UITouch *) touch {
  @try {
      return [LPTouchRecorder CreateTouchEvent:touch.view withTapCount:(int *)touch.tapCount atLocation:[touch locationInView:touch.window]];
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception.reason);
  }
}

+ (NSMutableDictionary*) CreateTouchEvent: (UIView *) view withTapCount:(int *)tapcount atLocation:(CGPoint) location{
  @try {
    if(view == nil)
      return nil;
    NSString* className = NSStringFromClass([view class]);
    if([className isEqualToString:@"UIWindow"] || [className isEqualToString:@"UITableViewCellContentView"])
      return [LPTouchRecorder CreateTouchEvent:(UIView*)view.nextResponder withTapCount: tapcount atLocation:location];

    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue:className forKey:@"ClassType"];
    [dictionary setValue:@(AppEventTypeTouch) forKey:@"EventType"];
    NSString *id = [LPTouchRecorder GetId:view];
    if(id.length > 0) {
      [dictionary setValue:id forKey:@"Id"];
    }
    NSString *marked = [LPTouchRecorder GetMarked:view];
    if(marked.length > 0) {
      [dictionary setValue:marked forKey:@"Marked"];
    }
    [dictionary setValue:[NSNumber numberWithInt:*tapcount] forKey:@"TapCount"];
    NSMutableDictionary *nextResponder = [LPTouchRecorder CreateTouchEvent:(UIView *)view.nextResponder withTapCount:tapcount atLocation:location];
    if(nextResponder != nil) {
      [dictionary setValue:nextResponder forKey:@"NextResponder"];
    }
    NSMutableDictionary *point1 = [[NSMutableDictionary alloc] init];
    [point1 setValue:@(location.x) forKey:@"X"];
    [point1 setValue:@(location.y) forKey:@"Y"];
    [dictionary setValue:point1 forKey:@"TouchPoint"];
    
    return dictionary;
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception.reason);
  }
}

+ (NSString*) GetMarked: (UIView*) view
{
  @try {
    NSString *name = view.accessibilityLabel;
    if(name.length != 0)
      return name;

    if([view isKindOfClass:[UITableViewCell class]])
    {
      UITableViewCell *cell = (UITableViewCell *)view;
      name = cell.accessibilityLabel;
      if(name.length != 0)
        return name;
      name = cell.textLabel.text;
      if(name.length != 0)
        return name;

    }
    if([view isKindOfClass:[UIButton class]])
    {
      UIButton *button = (UIButton*)view;
      name = [button titleForState:UIControlStateNormal];
      if(name.length != 0)
        return name;
    }
    return name;
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception.reason);
  }
}

+ (NSString*) GetId: (UIView*) view
{
  @try {
    NSString *name = view.accessibilityIdentifier;
    if(name.length != 0)
      return name;
    name = view.accessibilityLabel;
    if(name.length != 0)
      return name;
    if([NSStringFromClass([view class]) isEqualToString:@"UITableViewCellContentView"])
    {
      UITableViewCell *cell = (UITableViewCell *)view.nextResponder;
      name = view.accessibilityIdentifier;
      if(name.length != 0)
        return name;
      name = cell.accessibilityLabel;
      if(name.length != 0)
        return name;
      name = cell.textLabel.text;
      if(name.length != 0)
        return name;
    }
    return name;
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception.reason);
  }
}

+ (NSString*) GetIdForViewController: (UIViewController*)viewController
{
  @try {
    NSString *name = [viewController view].accessibilityIdentifier;
    if(name.length != 0)
      return name;
    name = [viewController view].accessibilityLabel;
    if(name.length != 0)
      return name;
    return name;
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception.reason);
  }
}


CGPoint CGPointSub(CGPoint a,CGPoint b) {
  CGPoint c = {a.x-b.x,a.y-b.y};
  return c;
}

CGFloat CGPointLen(CGPoint a) {
  return sqrtf(a.x*a.x+a.y*a.y);
}

CGFloat CGPointDist(CGPoint a,CGPoint b) {
  CGPoint c = CGPointSub(a,b);
  return CGPointLen(c);
}

@end