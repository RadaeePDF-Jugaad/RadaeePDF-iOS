//
//  RDAnnotMenu.m
//  PDFViewer
//

#import "RDAnnotMenu.h"
#import "PDFObjc.h"
#import "RDVGlobal.h"

@interface RDAnnotMenu ()
{
    __weak RDPDFAnnot *_annot;
    void (^_callback)(RDAnnotMenuAction action);
}
@end

@implementation RDAnnotMenu

- (UIButton *)createButtonWithImageName:(NSString *)name titleFallback:(NSString *)title tag:(NSInteger)tag frame:(CGRect)frame
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = frame;
    UIImage *img = nil;
    if (name && name.length > 0) {
        img = [[UIImage systemImageNamed:name] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    if (img) {
        [btn setImage:img forState:UIControlStateNormal];
        btn.tintColor = RD_COLOR;
    } else {
        [btn setTitle:title forState:UIControlStateNormal];
        [btn setTitleColor:RD_COLOR forState:UIControlStateNormal];
        CGFloat tsize = 12.0;
        if (tag == RDAnnotMenuActionIncreaseFont || tag == RDAnnotMenuActionDecreaseFont) {
            tsize = 24.0; // larger text for A+ / A−
        }
        btn.titleLabel.font = [UIFont systemFontOfSize:tsize weight:UIFontWeightSemibold];
    }
    btn.tag = tag;
    [btn addTarget:self action:@selector(onTap:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)onTap:(UIButton *)sender
{
    if (_callback) {
        _callback((RDAnnotMenuAction)sender.tag);
    }
}

- (instancetype)initWithAnnot:(RDPDFAnnot *)annot
                      atPoint:(CGPoint)pointInView
                     callback:(void (^)(RDAnnotMenuAction action))callback
{
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;
    _annot = annot;
    _callback = [callback copy];

    CGFloat iconSize = 40.0;
    CGFloat padding = 8.0;
    CGFloat height = iconSize + padding * 2;
    BOOL isEditText = (annot && [annot type] == 3);
    // Highlight/Underline/Squiggly/StrikeOut markup has no settings dialog, so just offer Delete.
    int atype = annot ? [annot type] : 0;
    BOOL isMarkup = (atype == 9 || atype == 10 || atype == 11 || atype == 12);
    CGFloat width = iconSize * (isEditText ? 4 : (isMarkup ? 1 : 2));

    // Default frame near tap
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat x = pointInView.x;
    CGFloat y = pointInView.y - height - 6.0; // above the tap

    // Keep inside screen
    if (x + width > CGRectGetWidth(screenBounds)) x = CGRectGetWidth(screenBounds) - width - 8.0;
    if (x < 8.0) x = 8.0;
    if (y < 8.0) y = MIN(pointInView.y + 6.0, CGRectGetHeight(screenBounds) - height - 8.0);

    self.frame = CGRectMake(x, y, width, height);
    self.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.layer.cornerRadius = 8.0;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowRadius = 6.0;
    self.layer.shadowOffset = CGSizeMake(0, 2);

    // Buttons
    if (isEditText) {
        UIButton *incBtn = [self createButtonWithImageName:nil titleFallback:@"A+" tag:RDAnnotMenuActionIncreaseFont frame:CGRectMake(0, padding, iconSize, iconSize)];
        UIButton *decBtn = [self createButtonWithImageName:nil titleFallback:@"A-" tag:RDAnnotMenuActionDecreaseFont frame:CGRectMake(iconSize, padding, iconSize, iconSize)];
        UIButton *propBtn = [self createButtonWithImageName:@"gearshape" titleFallback:@"Property" tag:RDAnnotMenuActionSettings frame:CGRectMake(iconSize * 2, padding, iconSize, iconSize)];
        UIButton *deleteBtn = [self createButtonWithImageName:@"trash" titleFallback:@"Delete" tag:RDAnnotMenuActionDelete frame:CGRectMake(iconSize * 3, padding, iconSize, iconSize)];
        [self addSubview:incBtn];
        [self addSubview:decBtn];
        [self addSubview:propBtn];
        [self addSubview:deleteBtn];
    } else if (isMarkup) {
        UIButton *deleteBtn = [self createButtonWithImageName:@"trash" titleFallback:@"Delete" tag:RDAnnotMenuActionDelete frame:CGRectMake(0, padding, iconSize, iconSize)];
        [self addSubview:deleteBtn];
    } else {
        UIButton *deleteBtn = [self createButtonWithImageName:@"trash" titleFallback:@"Delete" tag:RDAnnotMenuActionDelete frame:CGRectMake(0, padding, iconSize, iconSize)];
        UIButton *settingsBtn = [self createButtonWithImageName:@"gearshape" titleFallback:@"Settings" tag:RDAnnotMenuActionSettings frame:CGRectMake(iconSize, padding, iconSize, iconSize)];
        [self addSubview:deleteBtn];
        [self addSubview:settingsBtn];
    }

    return self;
}

@end
