#import "NewsRouter.h"
#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <objc/message.h>

static NSString * const NewsRouterErrorDomain = @"NewsBridge.NewsRouter";
static NSString * const NewsExtensionIdentifier = @"com.apple.news.openinnews";

typedef NS_ENUM(NSInteger, NewsRouterErrorCode) {
    NewsRouterErrorUnsupportedSystem = 1,
    NewsRouterErrorNewsUnavailable = 2,
    NewsRouterErrorOptInFailed = 3,
    NewsRouterErrorActivityUnavailable = 4,
    NewsRouterErrorInvocationFailed = 5,
};

static id PendingNewsActivity;

static NSError *NewsRouterError(NewsRouterErrorCode code, NSString *description) {
    return [NSError errorWithDomain:NewsRouterErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: description}];
}

@implementation NewsRouter

+ (BOOL)openURL:(NSURL *)URL title:(NSString *)title error:(NSError **)error {
    @try {
    Class extensionClass = NSClassFromString(@"NSExtension");
    SEL lookupSelector = NSSelectorFromString(@"extensionWithIdentifier:error:");
    if (extensionClass == Nil || ![extensionClass respondsToSelector:lookupSelector]) {
        if (error) {
            *error = NewsRouterError(NewsRouterErrorUnsupportedSystem,
                                     @"This version of iOS does not expose the News bridge.");
        }
        return NO;
    }

    NSError *lookupError = nil;
    id (*lookupExtension)(id, SEL, NSString *, NSError **) = (void *)objc_msgSend;
    id extension = lookupExtension(extensionClass, lookupSelector, NewsExtensionIdentifier, &lookupError);
    if (!extension) {
        if (error) {
            *error = lookupError ?: NewsRouterError(NewsRouterErrorNewsUnavailable,
                                                     @"Apple News is unavailable.");
        }
        return NO;
    }

    SEL plugInSelector = NSSelectorFromString(@"_plugIn");
    SEL userElectionSelector = NSSelectorFromString(@"userElection");
    SEL optInSelector = NSSelectorFromString(@"attemptOptIn:");
    if ([extension respondsToSelector:plugInSelector] && [extension respondsToSelector:optInSelector]) {
        id (*sendObject)(id, SEL) = (void *)objc_msgSend;
        NSInteger (*sendInteger)(id, SEL) = (void *)objc_msgSend;
        id plugIn = sendObject(extension, plugInSelector);
        if ([plugIn respondsToSelector:userElectionSelector] && sendInteger(plugIn, userElectionSelector) == 0) {
            NSError *optInError = nil;
            BOOL (*attemptOptIn)(id, SEL, NSError **) = (void *)objc_msgSend;
            if (!attemptOptIn(extension, optInSelector, &optInError)) {
                if (error) {
                    *error = optInError ?: NewsRouterError(NewsRouterErrorOptInFailed,
                                                           @"Apple News could not be enabled.");
                }
                return NO;
            }
        }
    }

    NSString *sharedTitle = title.length > 0 ? title : URL.absoluteString;
    NSItemProvider *titleProvider = [[NSItemProvider alloc] initWithItem:sharedTitle
                                                          typeIdentifier:UTTypePlainText.identifier];
    NSItemProvider *URLProvider = [[NSItemProvider alloc] initWithItem:URL
                                                        typeIdentifier:UTTypeURL.identifier];
    NSExtensionItem *item = [[NSExtensionItem alloc] init];
    item.userInfo = @{
        @"FRItemHasRSSFeed": @NO,
        NSExtensionItemAttachmentsKey: @[titleProvider, URLProvider],
    };

    Class activityClass = NSClassFromString(@"UIApplicationExtensionActivity");
    SEL initializer = NSSelectorFromString(@"initWithApplicationExtension:");
    SEL prepareSelector = @selector(prepareWithActivityItems:);
    SEL performSelector = @selector(performActivity);
    if (activityClass == Nil || ![activityClass instancesRespondToSelector:initializer]) {
        if (error) {
            *error = NewsRouterError(NewsRouterErrorActivityUnavailable,
                                     @"This version of iOS cannot launch the News bridge.");
        }
        return NO;
    }

    id (*allocate)(id, SEL) = (void *)objc_msgSend;
    id (*initialize)(id, SEL, id) = (void *)objc_msgSend;
    void (*sendItems)(id, SEL, NSArray *) = (void *)objc_msgSend;
    void (*sendVoid)(id, SEL) = (void *)objc_msgSend;
    id activity = initialize(allocate(activityClass, @selector(alloc)), initializer, extension);
    if (!activity || ![activity respondsToSelector:prepareSelector] || ![activity respondsToSelector:performSelector]) {
        if (error) {
            *error = NewsRouterError(NewsRouterErrorActivityUnavailable,
                                     @"The News bridge could not be started.");
        }
        return NO;
    }

    sendItems(activity, prepareSelector, @[item]);
    PendingNewsActivity = activity;
    sendVoid(activity, performSelector);
    return YES;
    } @catch (NSException *exception) {
        if (error) {
            *error = NewsRouterError(NewsRouterErrorInvocationFailed,
                                     exception.reason ?: @"The News bridge failed unexpectedly.");
        }
        return NO;
    }
}

@end
