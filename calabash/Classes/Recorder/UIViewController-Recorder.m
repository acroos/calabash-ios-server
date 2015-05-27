//
//  UIViewController-Recorder.m
//  calabash
//
//  Created by Austin Roos on 5/26/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIViewController-Recorder.h"
#import "LPTouchRecorder.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIApplication.h>
#import <objc/runtime.h>


IMP __original_didMoveToParentViewController_Imp;
void recorderDidMoveToParentViewController(id self, SEL _cmd, id parent)
{
  @try {
    assert([NSStringFromSelector(_cmd) isEqualToString:@"didMoveToParentViewController:"]);
    [[LPTouchRecorder sharedRecorder] didMoveToParentViewController:self withParent:parent];
    ((void(*)(id,SEL,id)) __original_didMoveToParentViewController_Imp)(self,_cmd, parent);
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception);
  }
}

@implementation UIViewController(Recorder)

+ (void)load {
  @try {
    if (self == [UIViewController class]) {
      Class class = [self class];
      Method sendEventMethod =  class_getInstanceMethod(class, @selector(didMoveToParentViewController:));
      __original_didMoveToParentViewController_Imp = method_setImplementation(sendEventMethod, (IMP) recorderDidMoveToParentViewController);
    }
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception);
  }
}
@end