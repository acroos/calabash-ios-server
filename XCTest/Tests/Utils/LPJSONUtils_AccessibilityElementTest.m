#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPJSONUtils.h"

@interface LPJSONUtils (LPXCTEST)

+(NSMutableDictionary*)jsonifyAccessibilityElement:(id)object;

@end

@interface LPTestAccessibilityElement : NSObject

- (NSString *) accessibilityLabel;
// Don't implement this because jsonifyAccessibilityElement sets this directly.
//- (BOOL) accessibilityElement;
- (NSString *) accessibilityIdentifier;
- (NSString *) accessibilityHint;
- (NSString *) accessibilityValue;
- (CGRect) accessibilityFrame;
- (NSString *) text;
// Don't implement this because jsonifyAccessibilityElement sets this directly.
//- (BOOL) visible;
- (BOOL) isSelected;
- (BOOL) isEnabled;
- (CGFloat) alpha;
- (NSString *) description;

@end

@implementation LPTestAccessibilityElement

- (NSString *) accessibilityLabel { return @"label"; }
- (NSString *) accessibilityIdentifier { return @"id"; }
- (NSString *) accessibilityHint { return @"hint"; }
- (NSString *) accessibilityValue { return @"value"; }
- (CGRect) accessibilityFrame { return CGRectZero; }
- (NSString *) text { return @"text"; }
- (BOOL) isSelected { return YES; }
- (BOOL) isEnabled { return YES; }
- (CGFloat) alpha { return 1.0; }
- (NSString *) description { return @"description"; }

@end

@interface LPDoesNotRespondTo : NSObject

@property (assign, nonatomic) SEL selector;
@property (copy, nonatomic) NSString *selectorString;

- (id) initWithSelector:(SEL) selector;

@end

@implementation LPDoesNotRespondTo


- (id) initWithSelector:(SEL)selector {
  self = [super init];
  if (self) {
    self.selector = selector;
    self.selectorString = NSStringFromSelector(_selector);
  }
  return self;
}

- (BOOL) respondsToSelector:(SEL)aSelector {
  NSString *other = NSStringFromSelector(aSelector);
  if ([self.selectorString isEqualToString:other]) {
    return NO;
  } else {
    return [super respondsToSelector:aSelector];
  }
}

@end

@interface LPRaisesOnAccessibilityFrame : NSObject

@end

@implementation LPRaisesOnAccessibilityFrame

- (CGRect) accessibilityFrame {
  @throw [NSException exceptionWithName:NSInvalidArgumentException
                                 reason:@"Something in the call chain raises an exception" userInfo:nil];
}

@end

SpecBegin(LPJSONUtilsAccessibilityElement)

describe(@".jsonifyAccessibilityElement:", ^{

  describe(@"LPTestAccessibilityElement instance", ^{
    it(@"returns dictionary with correct key/value pairs", ^{
      LPTestAccessibilityElement *obj = [LPTestAccessibilityElement new];
      NSDictionary *dict = [LPJSONUtils jsonifyAccessibilityElement:obj];

      expect(dict.count).to.equal(13);
      for (NSString *key in [dict allKeys]) {
        id value = dict[key];
        if ([key isEqualToString:@"class"]) {
          expect(value).to.equal(NSStringFromClass([obj class]));
        } else if ([key isEqualToString:@"rect"]) {
          expect(value).to.beAKindOf([NSDictionary class]);
          for (NSString *frameKey in [value allKeys]) {
            expect(value[frameKey]).to.equal(@(0));
          }
        } else if ([key isEqualToString:@"selected"] ||
                   [key isEqualToString:@"enabled"]  ||
                   [key isEqualToString:@"accessibilityElement"]  ||
                   [key isEqualToString:@"visible"]) {
          expect(value).to.equal(@(1));
        } else if ([key isEqualToString:@"alpha"]) {
          expect(value).to.equal(@(1.0));
        } else {
          expect(value).to.equal(key);
        }
      }
    });
  });

  describe(@"finding the frame rect", ^{
    it(@"can handle DNRTS accessibilityFrame", ^{
      LPDoesNotRespondTo *obj = [[LPDoesNotRespondTo alloc]
                                 initWithSelector:@selector(accessibilityFrame)];

      NSDictionary *dict = [LPJSONUtils jsonifyAccessibilityElement:obj];
      expect(dict.count).to.equal(10);
      expect(dict[@"rect"]).to.equal([NSNull null]);
    });

    it(@"can handle accessibilityFrame raising an exception", ^{
      LPRaisesOnAccessibilityFrame *obj = [LPRaisesOnAccessibilityFrame new];
      NSDictionary *dict = [LPJSONUtils jsonifyAccessibilityElement:obj];
      expect(dict.count).to.equal(10);
      expect(dict[@"rect"]).to.equal([NSNull null]);
    });
  });

  it(@"NSOject instance", ^{
    id obj = [NSObject new];
    NSDictionary *dict = [LPJSONUtils jsonifyAccessibilityElement:obj];
    expect(dict.count).to.equal(10);
  });

  it(@"UIView instance", ^{
    id obj = [[UIView alloc] initWithFrame:CGRectZero];
    NSDictionary *dict = [LPJSONUtils jsonifyAccessibilityElement:obj];
    expect(dict.count).to.equal(12);
  });

  fit(@"UIControl instance", ^{
    id obj = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    NSDictionary *dict = [LPJSONUtils jsonifyAccessibilityElement:obj];
    expect(dict.count).to.equal(13);
  });
});

SpecEnd