#import "ShareViewController.h"
#import "NewsRouter.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface ShareViewController ()
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation ShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.preferredContentSize = CGSizeMake(320, 140);

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [spinner startAnimating];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.text = @"Opening in News...";

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[spinner, self.statusLabel]];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 14;
    [self.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor],
        [stack.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
        [stack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];

    [self loadSharedURL];
}

- (void)loadSharedURL {
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *provider in item.attachments) {
            if ([provider hasItemConformingToTypeIdentifier:UTTypeURL.identifier]) {
                NSString *title = item.attributedTitle.string;
                [provider loadItemForTypeIdentifier:UTTypeURL.identifier
                                            options:nil
                                  completionHandler:^(id<NSSecureCoding> value, NSError *loadError) {
                    NSURL *URL = [(NSObject *)value isKindOfClass:NSURL.class] ? (NSURL *)value : nil;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self routeURL:URL title:title loadError:loadError];
                    });
                }];
                return;
            }
        }
    }

    [self showError:@"No web URL was shared."];
}

- (void)routeURL:(NSURL *)URL title:(NSString *)title loadError:(NSError *)loadError {
    if (!URL || ![self isValidWebURL:URL]) {
        [self showError:loadError.localizedDescription ?: @"The shared item is not a valid web URL."];
        return;
    }

    NSError *routingError = nil;
    if (![NewsRouter openURL:URL title:title error:&routingError]) {
        [self showError:routingError.localizedDescription ?: @"The URL could not be opened in News."];
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    });
}

- (BOOL)isValidWebURL:(NSURL *)URL {
    NSString *scheme = URL.scheme.lowercaseString;
    return ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) && URL.host.length > 0;
}

- (void)showError:(NSString *)message {
    self.statusLabel.text = message;
    self.statusLabel.textColor = UIColor.systemRedColor;

    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [closeButton setTitle:@"Close" forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    [NSLayoutConstraint activateConstraints:@[
        [closeButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [closeButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-12],
    ]];
}

- (void)close {
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:NSUserCancelledError
                                     userInfo:nil];
    [self.extensionContext cancelRequestWithError:error];
}

@end
