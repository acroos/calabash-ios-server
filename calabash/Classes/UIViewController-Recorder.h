//
//  UIViewController-Recorder.h
//  calabash
//
//  Created by Austin Roos on 5/26/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIApplication.h>

void recorderDidMoveToParentViewController(id self, SEL _cmd, id parent);

@interface UIViewController (Recorder)

@end