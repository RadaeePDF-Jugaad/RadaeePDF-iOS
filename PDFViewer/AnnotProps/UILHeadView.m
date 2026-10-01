//
//  UILHeadView.m
//  RDPDFReader
//
//  Created by Radaee Lou on 2020/5/7.
//

#import "UILHeadView.h"
#import "PDFDialog.h"
#import "UILShadowView.h"
#import "RDVGlobal.h"
#import "RDUtils.h"

const char *arrowType[] =
{
    "None",
    "Arrow",
    "Closed",
    "Square",
    "Circle",
    "Butt",
    "Diamond",
    "Reverted",
    "Reverted Closed",
    "Slash"
};

@implementation UILHeadView
-(id)init:(CGRect)frame :(func_lhead)callback
{
    self = [super initWithFrame:frame];
    if (self)
    {
        m_style = 0;
        m_callback = callback;
        self.backgroundColor = [UIColor whiteColor];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}
-(void)tapAction:(id)sendor
{
    if(m_callback)
        m_callback(m_style);
}
-(void)setStyle:(int)style
{
    m_style = style;
    [self setNeedsDisplay];
}
-(void)drawRect:(CGRect)rect
{
#define HEAD_LEN 5
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    CGFloat clrs[4] = {0.2, 0.2, 0.2, 1};
    CGContextSetStrokeColor(ctx, clrs);
    CGFloat clrf[4] = {0.8, 0.8, 0.8, 1};
    CGContextSetFillColor(ctx, clrf);
    
    CGContextSetLineWidth(ctx, 1);
    CGRect rc = self.bounds;
    CGFloat midy = rc.size.height * 0.5f;
    
    CGContextMoveToPoint(ctx, 8, midy);
    CGContextAddLineToPoint(ctx, rc.size.width - 8, midy);
    
    switch(m_style)
    {
    case 1:
        CGContextMoveToPoint(ctx, 10 + HEAD_LEN * 0.707f, midy - HEAD_LEN * 0.5f);
        CGContextAddLineToPoint(ctx, 10, midy);
        CGContextAddLineToPoint(ctx, 10 + HEAD_LEN * 0.707f, midy + HEAD_LEN * 0.5f);
        break;
    case 2:
        CGContextMoveToPoint(ctx, 10 + HEAD_LEN * 0.707f, midy - HEAD_LEN * 0.5f);
        CGContextAddLineToPoint(ctx, 10, midy);
        CGContextAddLineToPoint(ctx, 10 + HEAD_LEN * 0.707f, midy + HEAD_LEN * 0.5f);
        CGContextClosePath(ctx);
        break;
    case 3:
        CGContextAddRect(ctx, CGRectMake(10 - HEAD_LEN, midy - HEAD_LEN, HEAD_LEN * 2, HEAD_LEN * 2));
        break;
    case 4:
        CGContextAddEllipseInRect(ctx, CGRectMake(10 - HEAD_LEN, midy - HEAD_LEN, HEAD_LEN * 2, HEAD_LEN * 2));
        break;
    case 5:
        CGContextMoveToPoint(ctx, 10, midy - HEAD_LEN);
        CGContextAddLineToPoint(ctx, 10, midy + HEAD_LEN);
        break;
    case 6:
        CGContextMoveToPoint(ctx, 10 - HEAD_LEN, midy);
        CGContextAddLineToPoint(ctx, 10, midy - HEAD_LEN);
        CGContextAddLineToPoint(ctx, 10 + HEAD_LEN, midy);
        CGContextAddLineToPoint(ctx, 10, midy + HEAD_LEN);
        CGContextClosePath(ctx);
        break;
    case 7:
        CGContextMoveToPoint(ctx, 10 - HEAD_LEN * 0.707f, midy - HEAD_LEN * 0.5f);
        CGContextAddLineToPoint(ctx, 10, midy);
        CGContextAddLineToPoint(ctx, 10 - HEAD_LEN * 0.707f, midy + HEAD_LEN * 0.5f);
        break;
    case 8:
        CGContextMoveToPoint(ctx, 10 - HEAD_LEN * 0.707f, midy - HEAD_LEN * 0.5f);
        CGContextAddLineToPoint(ctx, 10, midy);
        CGContextAddLineToPoint(ctx, 10 - HEAD_LEN * 0.707f, midy + HEAD_LEN * 0.5f);
        CGContextClosePath(ctx);
        break;
    case 9:
        CGContextMoveToPoint(ctx, 10 + HEAD_LEN * 0.5f, midy - HEAD_LEN * 0.707f);
        CGContextAddLineToPoint(ctx, 10 - HEAD_LEN * 0.5f, midy + HEAD_LEN * 0.707f);
        break;
    }
    
    CGContextDrawPath(ctx, kCGPathFillStroke);
    CGContextRestoreGState(ctx);
}

@end

@implementation UILHeadBtn
-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        m_style = 0;
        m_temp_style = 0;
        m_vc = nil;
        m_styleViews = [[NSMutableArray alloc] init];
        self.backgroundColor = [UIColor whiteColor];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}
-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        m_style = 0;
        m_temp_style = 0;
        m_vc = nil;
        m_styleViews = [[NSMutableArray alloc] init];
        self.backgroundColor = [UIColor whiteColor];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}
-(void)tapAction:(id)sendor
{
#define LHEAD_HEIGHT 45
#define LHEAD_WIDTH 100
#define ROW_PADDING 8
#define SIDE_PADDING 12
#define ROW_INNER_PADDING 8
    // Find the PDFDialog view controller to present from
    UIViewController *presentingVC = m_vc;
    UIViewController *vc = m_vc;
    while (vc && ![vc isKindOfClass:[PDFDialog class]]) {
        vc = vc.presentedViewController;
    }
    if ([vc isKindOfClass:[PDFDialog class]]) {
        presentingVC = vc;
    }
    
    UIView *container = self;
    while (container && ![container isKindOfClass:[UILShadowView class]])
        container = container.superview;
    if (!container) container = self.superview;
    container.hidden = YES;
    
    CGRect frame = self.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    frame = [self convertRect:frame toView:presentingVC.view];
    frame.size.width = LHEAD_WIDTH;
    frame.size.height = LHEAD_HEIGHT * 10;
    CGRect rect = presentingVC.view.frame;
    if(frame.origin.y + frame.size.height > rect.origin.y + rect.size.height)
        frame.origin.y = rect.origin.y + rect.size.height - frame.size.height - 20;
    
    CGFloat labelWidth = 150;
    CGFloat popupWidth = LHEAD_WIDTH + SIDE_PADDING * 3 + labelWidth;
    CGFloat titleHeight = m_title ? 45 : 0;
    CGFloat buttonHeight = 50;
    CGFloat contentHeight = LHEAD_HEIGHT * 10 + ROW_PADDING * 11;
    UIScrollView *view = [[UIScrollView alloc] initWithFrame:CGRectMake(0, titleHeight, popupWidth, contentHeight)];
    view.contentSize = CGSizeMake(popupWidth - SIDE_PADDING * 2, contentHeight);
    view.scrollEnabled = YES;
    UILShadowView *bgView = [[UILShadowView alloc] initWithFrame:CGRectMake(container.frame.origin.x, container.frame.origin.y, popupWidth, contentHeight + titleHeight + buttonHeight)];
    [bgView addSubview:view];
    
    if (m_title) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, popupWidth, titleHeight - 10)];
        titleLabel.text = m_title;
        titleLabel.font = RD_TITLE_FONT(BIG_FONT_SIZE);
        titleLabel.textColor = RD_TEXT_GRAY;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.backgroundColor = [UIColor clearColor];
        [bgView addSubview:titleLabel];
    }
    
    bgView.center = container.center;
    pop = [[PDFPopupCtrl alloc] init:bgView];
    [pop setDismiss:^{ container.hidden = NO; }];
    
    // Store current selection as temporary
    m_temp_style = m_style;
    
    [m_styleViews removeAllObjects];
    UILHeadView *lv;
    UILHeadBtn *thiz = self;
    
    for (int i = 0; i < 10; i++) {
        // Create row container
        UIView *row = [[UIView alloc] initWithFrame:CGRectMake(SIDE_PADDING, ROW_PADDING + i * (LHEAD_HEIGHT + ROW_PADDING), popupWidth - SIDE_PADDING * 2, LHEAD_HEIGHT)];
        row.backgroundColor = [UIColor whiteColor];
        row.layer.borderWidth = 2;
        row.layer.borderColor = [UIColor clearColor].CGColor;
        [view addSubview:row];
        [m_styleViews addObject:row];
        
        lv = [[UILHeadView alloc] init:CGRectMake(ROW_INNER_PADDING, ROW_INNER_PADDING, LHEAD_WIDTH, LHEAD_HEIGHT - ROW_INNER_PADDING * 2) :^(int style) {
            [thiz selectStyle:style];
        }];
        [lv setStyle:i];
        [row addSubview:lv];
        
        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(ROW_INNER_PADDING * 2 + LHEAD_WIDTH, ROW_INNER_PADDING, labelWidth, LHEAD_HEIGHT - ROW_INNER_PADDING * 2)];
        lab.text = [NSString stringWithUTF8String:arrowType[i]];
        lab.font = RD_FONT(NORMAL_FONT_SIZE);
        lab.userInteractionEnabled = NO;
        [row addSubview:lab];
        
        UITapGestureRecognizer *tapRow = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRowTapped:)];
        [row addGestureRecognizer:tapRow];
    }
    
    // Add OK and Cancel buttons
    CGFloat buttonY = titleHeight + contentHeight;
    CGFloat buttonWidth = (popupWidth - SIDE_PADDING * 3) / 2;
    
    UIButton *okButton = [UIButton buttonWithType:UIButtonTypeSystem];
    okButton.frame = CGRectMake(SIDE_PADDING, buttonY + 10, buttonWidth, 40);
    [okButton setTitle:NSLocalizedString(@"OK", nil) forState:UIControlStateNormal];
    okButton.titleLabel.font = RD_FONT(NORMAL_FONT_SIZE);
    [okButton setTitleColor:RD_COLOR forState:UIControlStateNormal];
    [okButton addTarget:self action:@selector(onOkTapped) forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:okButton];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    cancelButton.frame = CGRectMake(SIDE_PADDING * 2 + buttonWidth, buttonY + 10, buttonWidth, 40);
    [cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    cancelButton.titleLabel.font = RD_FONT(NORMAL_FONT_SIZE);
    [cancelButton setTitleColor:RD_COLOR forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(onCancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:cancelButton];
    
    // Pre-select current style
    [self selectStyle:m_style];

    [presentingVC presentViewController:pop animated:NO completion:nil];
}
-(void)drawRect:(CGRect)rect
{
#define HEAD_LEN 5
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    CGFloat clrs[4] = {0.2, 0.2, 0.2, 1};
    CGContextSetStrokeColor(ctx, clrs);
    CGFloat clrf[4] = {0.8, 0.8, 0.8, 1};
    CGContextSetFillColor(ctx, clrf);
    
    CGContextSetLineWidth(ctx, 1);
    CGRect rc = self.bounds;
    CGFloat midy = rc.size.height * 0.5f;
    
    CGContextMoveToPoint(ctx, 8, midy);
    CGContextAddLineToPoint(ctx, rc.size.width - 8, midy);
    
    switch(m_style)
    {
    case 1:
        CGContextMoveToPoint(ctx, 10 + HEAD_LEN * 0.707f, midy - HEAD_LEN * 0.5f);
        CGContextAddLineToPoint(ctx, 10, midy);
        CGContextAddLineToPoint(ctx, 10 + HEAD_LEN * 0.707f, midy + HEAD_LEN * 0.5f);
        break;
    case 2:
        CGContextMoveToPoint(ctx, 10 + HEAD_LEN * 0.707f, midy - HEAD_LEN * 0.5f);
        CGContextAddLineToPoint(ctx, 10, midy);
        CGContextAddLineToPoint(ctx, 10 + HEAD_LEN * 0.707f, midy + HEAD_LEN * 0.5f);
        CGContextClosePath(ctx);
        break;
    case 3:
        CGContextAddRect(ctx, CGRectMake(10 - HEAD_LEN, midy - HEAD_LEN, HEAD_LEN * 2, HEAD_LEN * 2));
        break;
    case 4:
        CGContextAddEllipseInRect(ctx, CGRectMake(10 - HEAD_LEN, midy - HEAD_LEN, HEAD_LEN * 2, HEAD_LEN * 2));
        break;
    case 5:
        CGContextMoveToPoint(ctx, 10, midy - HEAD_LEN);
        CGContextAddLineToPoint(ctx, 10, midy + HEAD_LEN);
        break;
    case 6:
        CGContextMoveToPoint(ctx, 10 - HEAD_LEN, midy);
        CGContextAddLineToPoint(ctx, 10, midy - HEAD_LEN);
        CGContextAddLineToPoint(ctx, 10 + HEAD_LEN, midy);
        CGContextAddLineToPoint(ctx, 10, midy + HEAD_LEN);
        CGContextClosePath(ctx);
        break;
    case 7:
        CGContextMoveToPoint(ctx, 10 - HEAD_LEN * 0.707f, midy - HEAD_LEN * 0.5f);
        CGContextAddLineToPoint(ctx, 10, midy);
        CGContextAddLineToPoint(ctx, 10 - HEAD_LEN * 0.707f, midy + HEAD_LEN * 0.5f);
        break;
    case 8:
        CGContextMoveToPoint(ctx, 10 - HEAD_LEN * 0.707f, midy - HEAD_LEN * 0.5f);
        CGContextAddLineToPoint(ctx, 10, midy);
        CGContextAddLineToPoint(ctx, 10 - HEAD_LEN * 0.707f, midy + HEAD_LEN * 0.5f);
        CGContextClosePath(ctx);
        break;
    case 9:
        CGContextMoveToPoint(ctx, 10 + HEAD_LEN * 0.5f, midy - HEAD_LEN * 0.707f);
        CGContextAddLineToPoint(ctx, 10 - HEAD_LEN * 0.5f, midy + HEAD_LEN * 0.707f);
        break;
    }
    
    CGContextDrawPath(ctx, kCGPathFillStroke);
    CGContextRestoreGState(ctx);
}

-(void)updateStyle:(int)style
{
    m_style = style;
    [self setNeedsDisplay];
}

-(void)setStyle:(int)style :(UIViewController *)vc;
{
    m_vc = vc;
    [self updateStyle:style];
}
-(void)setTitle:(NSString *)title
{
    m_title = title;
}
-(int)style { return m_style; }

- (void)selectStyle:(int)style
{
    // Clear all borders
    for (UIView *row in m_styleViews) {
        row.layer.borderColor = [UIColor clearColor].CGColor;
    }
    
    // Store temporary selection
    m_temp_style = style;
    
    // Highlight selected style
    if (style >= 0 && style < m_styleViews.count) {
        UIView *row = m_styleViews[style];
        row.layer.borderColor = RD_COLOR.CGColor;
    }
}

- (void)onOkTapped
{
    // Apply the temporary selection
    m_style = m_temp_style;
    [self setNeedsDisplay];
    [pop dismiss];
}

- (void)onCancelTapped
{
    // Discard temporary selection
    [pop dismiss];
}

- (void)onRowTapped:(UITapGestureRecognizer *)tap
{
    UIView *row = tap.view;
    NSUInteger idx = [m_styleViews indexOfObject:row];
    if (idx != NSNotFound) {
        [self selectStyle:(int)idx];
    }
}

- (void)updateStyleFromGesture:(UITapGestureRecognizer *)tap
{
    CGPoint pt = [tap locationInView:[tap view]];
    [self updateStyle:pt.y / LHEAD_HEIGHT];
    [pop dismiss];
}

@end
