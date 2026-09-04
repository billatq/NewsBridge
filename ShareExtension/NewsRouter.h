#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NewsRouter : NSObject

+ (BOOL)openURL:(NSURL *)URL title:(NSString *)title error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
