//
//  UIApplication-Recorder.h
//  calabash
//
//  Created by Austin Roos on 5/26/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIApplication.h>

void recorderSendEvent(id self, SEL _cmd, id event);

@interface UIApplication (Recorder)
@end