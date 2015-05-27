//
//  LPRecorderAllRoute.m
//  calabash
//
//  Created by Austin Roos on 5/26/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//

#import "LPRecorderAllRoute.h"
#import "LPTouchRecorder.h"
#import "asl.h"

@implementation LPRecorderAllRoute : NSObject

- (BOOL) supportsMethod:(NSString *)method atPath:(NSString *)path {
  return [method isEqualToString:@"GET"];
}

- (NSDictionary *) JSONResponseForMethod:(NSString *)method URI:(NSString *)path data:(NSDictionary *)data {
  return [NSDictionary dictionaryWithObjectsAndKeys:[[LPTouchRecorder sharedRecorder] Items], @"results", @"SUCCESS", @"outcome", nil];
}

@end