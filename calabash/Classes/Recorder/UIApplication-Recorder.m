//
//  UIApplication-Recorder.m
//  calabash
//
//  Created by Austin Roos on 5/26/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIApplication.h>
#import <objc/runtime.h>
#import "LPTouchRecorder.h"
#import "UIApplication-Recorder.h"
#import <QuartzCore/QuartzCore.h>

static IMP __original_SendEventMethod_Imp;
void recorderSendEvent(id self, SEL _cmd, id event)
{
  @try {
    [LPTouchRecorder sendEvent:event];
    ((void(*)(id,SEL,id))__original_SendEventMethod_Imp)(self,_cmd,event);
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception);
  }
}

@implementation UIApplication (Recorder)

+ (void)load {
  @try {
    if (self == [UIApplication class]) {
      static dispatch_once_t onceToken;
      dispatch_once(&onceToken, ^{
        Class class = [self class];

        Method sendEventMethod = class_getInstanceMethod(class, @selector(sendEvent:));
        __original_SendEventMethod_Imp =  method_setImplementation(sendEventMethod, (IMP)recorderSendEvent);
      });
    }
  }
  @catch (NSException *exception) {
    NSLog(@"CALABASH - %@", exception);
  }
}

@end