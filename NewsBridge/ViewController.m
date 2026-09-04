#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle];
    titleLabel.text = @"News Bridge";

    UILabel *instructionsLabel = [[UILabel alloc] init];
    instructionsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    instructionsLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    instructionsLabel.textColor = UIColor.secondaryLabelColor;
    instructionsLabel.numberOfLines = 0;
    instructionsLabel.text = @"This application lets you go from a share sheet over to Apple News. It's useful for reading paywalled articles if you're not going from Safari.";

    UILabel *disclaimerLabel = [[UILabel alloc] init];
    disclaimerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    disclaimerLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    disclaimerLabel.textColor = UIColor.tertiaryLabelColor;
    disclaimerLabel.numberOfLines = 0;
    disclaimerLabel.text = @"Unofficial interoperability utility. Not affiliated with or endorsed by Apple. Uses undocumented iOS behavior that may stop working after an update.";

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        titleLabel,
        instructionsLabel,
        disclaimerLabel,
    ]];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 14;
    [self.view addSubview:stack];

    UILayoutGuide *guide = self.view.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
}

@end
