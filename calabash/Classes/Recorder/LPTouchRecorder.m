#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPTouchRecorder.h"
#import <UIKit/UIKit.h>
#import "OCMArg.h"
#import <Foundation/Foundation.h>
#import <objc/objc.h>

@implementation LPTouchRecorder

@synthesize initialView = _initialView;
@synthesize startTouchPosition1 = _startTouchPosition1;
@synthesize startTouchPosition2 = _startTouchPosition2;
@synthesize previousTouchPosition1 = _previousTouchPosition1;
@synthesize previousTouchPosition2 = _previousTouchPosition2;
@synthesize startTouchTime = _startTouchTime;
@synthesize items = _items;
@synthesize lastTouch = _lastTouch;

+ (LPTouchRecorder *) sharedRecorder {
  static LPTouchRecorder *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[LPTouchRecorder alloc] init_private];
  });
  return shared;
}

- (id) init_private {
  self = [super init];
  if (self) {
    _items = [NSMutableArray array];

    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowViewControllerNotification:) name:@"UINavigationControllerDidShowViewControllerNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTextFieldDidChangeNotification:) name:UITextFieldTextDidEndEditingNotification object:nil];
  }
  return self;
}

- (void) handleTextFieldDidChangeNotification:(NSNotification *) aNotification {
  UITextField *textField = (UITextField *)aNotification.object;
  CGPoint center = textField.center;
  NSMutableDictionary *event = [self CreateTouchEvent:textField withTapCount:0 atLocation:center];
  [event setValue:textField.nextResponder forKey:@"NextResponder"];
  [event setValue:textField.text forKey:@"Text"];
  [event setValue:textField.accessibilityIdentifier forKey:@"Id"];
  [event setValue:@(AppEventTypeTextEntry) forKey:@"EventType"];
  [self AddItem:event];
}

- (NSArray *)Items
{
  NSArray *array = [NSArray arrayWithArray:self.items];
  [self.items removeAllObjects];
  return array;
}

- (void) AddItem:(NSObject *)item
{
    [self.items addObject:item];
}

- (void)orientationChanged:(NSNotification *)notification
{
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  _lastTouch = nil;
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


  NSMutableDictionary *event = [NSMutableDictionary dictionary];
  [event setValue:@(AppRotation) forKey:@"EventType"];

  [event setValue:@(type) forKey:@"GestureType"];
  [_items addObject:event];
}

- (void) viewWillDisappear:(UIViewController *) viewController isAnimated:(bool)animated
{
  @try {
    if ([viewController.navigationController.viewControllers indexOfObject:viewController]==NSNotFound) {
      // back button was pressed.  We know this is true because self is no longer
      // in the navigation stack.
      NSMutableDictionary *event = [self CreateNavigationEvent:viewController];
      [event setValue:@(GestureTypeBackButtonPressed) forKey:@"GestureType"];
      [_items addObject:event];
    }
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception);
  }
}

- (void) didMoveToParentViewController:(UIViewController *) viewController withParent:(UIViewController*)parent
{
  @try {
    NSObject *last = _items.lastObject;
    BOOL isBack = NO;
    if(last) {
      Class lastClass = NSClassFromString([last valueForKey:@"ClassType"]);
      isBack = [lastClass isSubclassOfClass:[UINavigationBar class]];
      if(isBack) {
        [_items removeLastObject];
      }
    }
    else if(_lastTouch)
    {
      isBack = [_lastTouch isSubclassOfClass:[UINavigationBar class]];
    }
    if(![parent isEqual:viewController.parentViewController] && isBack){
      NSMutableDictionary *event = [self CreateNavigationEvent:viewController];
      [event setValue:@(GestureTypeBackButtonPressed) forKey:@"GestureType"];
      [_items addObject:event];
      _lastTouch = nil;
    }
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception.reason);
  }
}

- (void) sendEvent:(UIEvent *)event {
  @try {
    if (event.type == UIEventTypeTouches) {
      // NSLog(@"Touch event");
      NSSet *allTouches = [event allTouches];
      UITouch *touch = [allTouches anyObject];
      UIView *touchView = touch.view;

      if (touch.phase == UITouchPhaseBegan) {
        _initialView = touchView;
        _startTouchPosition1 = [touch locationInView:touch.window];
        _startTouchTime = touch.timestamp;

        if (allTouches.count > 1) {
          _startTouchPosition2 = [[allTouches allObjects][1] locationInView:touch.window];
          _previousTouchPosition1 = _startTouchPosition1;
          _previousTouchPosition2 = _startTouchPosition2;
        }
      } else if (touch.phase == UITouchPhaseMoved) {

      } else if (touch.phase == UITouchPhaseEnded) {
        CGPoint currentTouchPosition = [touch locationInView:touch.window];
        NSMutableDictionary *touchEvent = [self CreateTouchEvent:touch];
        if(touchEvent == nil) {
          touchEvent = [[NSMutableDictionary alloc] init];
        }
        // Check if it's a swipe
        if (fabs(_startTouchPosition1.x - currentTouchPosition.x) >= 10.0 &&
            fabs(_startTouchPosition1.x - currentTouchPosition.x) > fabs(_startTouchPosition1.y - currentTouchPosition.y) &&
            touch.timestamp - _startTouchTime < 0.7) {
          if (_startTouchPosition1.x < currentTouchPosition.x) {
            [touchEvent setValue:@((GestureTypeSwipeRight)) forKey:@"GestureType"];
          }
          else {
            [touchEvent setValue:@((GestureTypeSwipeLeft)) forKey:@"GestureType"];
          }
          //Create Touch horizontal swipe
        } else if (fabs(_startTouchPosition1.y - currentTouchPosition.y) >= 10.0 &&
                   fabs(_startTouchPosition1.y - currentTouchPosition.y) > fabs(_startTouchPosition1.x - currentTouchPosition.x) &&
                   touch.timestamp - _startTouchTime < 0.7) {
          //Create Touch vertical swipe
          if (_startTouchPosition1.y < currentTouchPosition.y)
            [touchEvent setValue:@(GestureTypeSwipeDown) forKey:@"GestureType"];
          else
            [touchEvent setValue:@(GestureTypeSwipeUp) forKey:@"GestureType"];
        } else {
          if (((double) touch.timestamp - _startTouchTime) > 1)
            [touchEvent setValue:@(GestureTypeLongPress) forKey:@"GestureType"];
          else
            [touchEvent setValue:@(GestureTypeTap) forKey:@"GestureType"];
        }


        NSMutableDictionary *point1 = [NSMutableDictionary dictionary];
        [point1 setValue:@(_startTouchPosition1.x) forKey:@"X"];
        [point1 setValue:@(_startTouchPosition1.y) forKey:@"Y"];


        NSMutableDictionary *point2 = [NSMutableDictionary dictionary];
        [point2 setValue:@(currentTouchPosition.x) forKey:@"X"];
        [point2 setValue:@(currentTouchPosition.y) forKey:@"Y"];

        NSArray *touches = [[NSMutableArray alloc] initWithObjects:point1, point2, nil];
        [touchEvent setValue:touches forKey:@"Touches"];

        [_items addObject:touchEvent];
        //NSLog([Recorder jsonStringWithPrettyPrint:YES]);
        _startTouchPosition1 = CGPointMake(-1, -1);
        _lastTouch =  touch.view.class;
        _initialView = nil;
      }

      else if (touch.phase == UITouchPhaseCancelled) {
        _initialView = nil;

      }


    }
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception.reason);
  }
}

- (void) didShowViewControllerNotification:(NSNotification*)notification
{
  @try
  {
    UIViewController *viewController = [[notification userInfo] objectForKey:@"UINavigationControllerNextVisibleViewController"];
    NSMutableDictionary *event = [self CreateNavigationEvent:viewController];
    [event setValue:@(GestureTypeViewAppeared) forKey:@"GestureType"];
    [_items addObject:event];
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception.reason);
  }
}

- (NSMutableDictionary*) CreateNavigationEvent:(UIViewController*) viewController{
  @try {
    NSString* className = NSStringFromClass([viewController class]);
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:className forKey:@"ClassType"];
    [dictionary setValue:@(AppEventTypeNavigation) forKey:@"EventType"];
    NSString *id = [self GetIdForViewController:viewController];
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

- (NSMutableDictionary*) CreateTouchEvent: (UITouch *) touch {
  @try {
    return [self CreateTouchEvent:touch.view withTapCount:touch.tapCount atLocation:[touch locationInView:touch.window]];
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception.reason);
  }
}

- (NSMutableDictionary*) CreateTouchEvent: (UIView *) view withTapCount:(NSUInteger)tapcount atLocation:(CGPoint) location{
  @try {
    if(!view)
      return nil;
    NSString* className = NSStringFromClass([view class]);
    if([className isEqualToString:@"UIWindow"] || [className isEqualToString:@"UITableViewCellContentView"]) {
      return [self CreateTouchEvent:(UIView *)view.nextResponder withTapCount: tapcount atLocation:location];
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:className forKey:@"ClassType"];
    [dictionary setValue:@(AppEventTypeTouch) forKey:@"EventType"];
    NSString *viewId = [self markForView:view];
    if(viewId.length > 0) {
      [dictionary setValue:viewId forKey:@"Id"];
    }
    NSString *marked = [self GetMarked:view];
    if(marked.length > 0) {
      [dictionary setValue:marked forKey:@"Marked"];
    }
    [dictionary setValue:@(tapcount) forKey:@"TapCount"];
    NSMutableDictionary *nextResponder = [self CreateTouchEvent:(UIView *)view.nextResponder withTapCount:tapcount atLocation:location];

    if(nextResponder) {
      [dictionary setValue:nextResponder forKey:@"NextResponder"];
    }
    NSMutableDictionary *point1 = [NSMutableDictionary dictionary];
    [point1 setValue:@(location.x) forKey:@"X"];
    [point1 setValue:@(location.y) forKey:@"Y"];
    [dictionary setValue:point1 forKey:@"TouchPoint"];

    return dictionary;
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception.reason);
  }
}

- (NSString *) GetMarked: (UIView*) view
{
  @try {
    NSString *name = [view accessibilityLabel];
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

- (NSString *) markForView: (UIView*) view
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

- (NSString*) GetIdForViewController: (UIViewController*)viewController
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

@end