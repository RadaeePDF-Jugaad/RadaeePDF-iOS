//
//  RDSelMenu.m
//  PDFViewer
//

#import "RDSelMenu.h"
#import "RDVGlobal.h"

@interface RDSelMenu ()
{
    void (^_callback)(RDSelMenuAction action);
}
@end

@implementation RDSelMenu

- (UIButton *)createButtonWithImageNames:(NSArray<NSString *> *)names titleFallback:(NSString *)title tag:(NSInteger)tag frame:(CGRect)frame
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = frame;
    UIImage *img = nil;
    for (NSString *name in names) {
        img = [[UIImage systemImageNamed:name] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        if (img) break;
    }
    if (img) {
        [btn setImage:img forState:UIControlStateNormal];
        btn.tintColor = RD_COLOR;
    } else {
        [btn setTitle:title forState:UIControlStateNormal];
        [btn setTitleColor:RD_COLOR forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
    }
    btn.tag = tag;
    [btn addTarget:self action:@selector(onTap:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)onTap:(UIButton *)sender
{
    if (_callback) {
        _callback((RDSelMenuAction)sender.tag);
    }
}

- (instancetype)initAtPoint:(CGPoint)pointInView
                    callback:(void (^)(RDSelMenuAction action))callback
{
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;
    _callback = [callback copy];

    CGFloat iconSize = 40.0;
    CGFloat padding = 8.0;
    CGFloat height = iconSize + padding * 2;
    CGFloat width = iconSize * 3;

    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat x = pointInView.x - width / 2.0;
    CGFloat y = pointInView.y - height - 6.0; // above the selection

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

    UIButton *highlightBtn = [self createButtonWithImageNames:@[@"highlighter", @"paintbrush.fill"] titleFallback:@"HGL" tag:RDSelMenuActionHighlight frame:CGRectMake(0, padding, iconSize, iconSize)];
    UIButton *underlineBtn = [self createButtonWithImageNames:@[@"underline"] titleFallback:@"UDL" tag:RDSelMenuActionUnderline frame:CGRectMake(iconSize, padding, iconSize, iconSize)];
    UIButton *strikeoutBtn = [self createButtonWithImageNames:@[@"strikethrough"] titleFallback:@"STR" tag:RDSelMenuActionStrikeout frame:CGRectMake(iconSize * 2, padding, iconSize, iconSize)];

    [self addSubview:highlightBtn];
    [self addSubview:underlineBtn];
    [self addSubview:strikeoutBtn];

    UIView *sep1 = [[UIView alloc] initWithFrame:CGRectMake(iconSize, padding + 4, 1, iconSize - 8)];
    UIView *sep2 = [[UIView alloc] initWithFrame:CGRectMake(iconSize * 2, padding + 4, 1, iconSize - 8)];
    for (UIView *sep in @[sep1, sep2]) {
        sep.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
        [self addSubview:sep];
    }

    return self;
}

@end
