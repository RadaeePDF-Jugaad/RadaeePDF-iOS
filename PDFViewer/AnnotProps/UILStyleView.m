//
//  UILStyleView.m
//  RDPDFReader
//
//  Created by Radaee Lou on 2020/5/7.
//

#import "UILStyleView.h"
#import "PDFPopupCtrl.h"
#import "PDFDialog.h"
#import "UILShadowView.h"
#import "RDVGlobal.h"
#import "RDUtils.h"

const char *lineType[] =
{
    "Straight line",
    "Dotted line",
    "Dashed line (short)",
    "Dashed line (medium)",
    "Dashed line (medium + short)",
    "Dashed line (long + medium)"
};

@implementation UILStyleView
-(id)init:(CGRect)frame :(func_lstyle)callback
{
    self = [super initWithFrame:frame];
    if(self)
    {
        m_dashs_cnt = 0;
        m_callback = callback;
        self.backgroundColor = [UIColor whiteColor];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

-(void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    if(m_dashs_cnt > 0) CGContextSetLineDash(ctx, 0, m_dashs, m_dashs_cnt);
    CGContextSetLineWidth(ctx, 1);
    CGRect rc = self.bounds;
    CGFloat midy = rc.size.height * 0.5f;
    CGContextMoveToPoint(ctx, 2, midy);
    CGContextAddLineToPoint(ctx, rc.size.width - 2, midy);
    CGContextDrawPath(ctx, kCGPathStroke);
    
    CGContextRestoreGState(ctx);
}

-(void)tapAction:(id)sendor
{
    if(m_callback)
        m_callback(m_dashs, m_dashs_cnt);
}

-(void)setDash:(const CGFloat *)dash :(int)dash_cnt
{
    if(dash)
    {
        memcpy(m_dashs, dash, sizeof(CGFloat) * dash_cnt);
        m_dashs_cnt = dash_cnt;
    }
    else
        m_dashs_cnt = 0;
    [self setNeedsDisplay];
}
@end

@implementation UILStyleBtn
-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        m_dashs_cnt = 0;
        m_temp_dashs_cnt = 0;
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
        m_dashs_cnt = 0;
        m_temp_dashs_cnt = 0;
        m_vc = nil;
        m_styleViews = [[NSMutableArray alloc] init];
        self.backgroundColor = [UIColor whiteColor];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

-(void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    if(m_dashs_cnt > 0) CGContextSetLineDash(ctx, 0, m_dashs, m_dashs_cnt);
    CGContextSetLineWidth(ctx, 1);
    CGRect rc = self.bounds;
    CGFloat midy = rc.size.height * 0.5f;
    CGContextMoveToPoint(ctx, 8, midy);
    CGContextAddLineToPoint(ctx, rc.size.width - 8, midy);
    CGContextDrawPath(ctx, kCGPathStroke);
    
    CGContextRestoreGState(ctx);
}

-(void)setDash:(const CGFloat *)dash :(int)dash_cnt :(UIViewController *)vc
{
    m_vc = vc;
    [self update:dash :dash_cnt];
}
-(void)setTitle:(NSString *)title
{
    m_title = title;
}
-(const CGFloat *)dash { return m_dashs; }
-(int)dashCnt { return m_dashs_cnt; }
-(void)update:(const CGFloat *)dash :(int)dash_cnt
{
    if(dash)
    {
        memcpy(m_dashs, dash, sizeof(CGFloat) * dash_cnt);
        m_dashs_cnt = dash_cnt;
    }
    else
        m_dashs_cnt = 0;
    [self setNeedsDisplay];
}
-(void)tapAction:(id)sendor
{
#define LSTYLE_HEIGHT 45
#define LSTYLE_WIDTH 100
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
    frame.size.width = LSTYLE_WIDTH;
    frame.size.height = LSTYLE_HEIGHT * 6;
    CGRect rect = presentingVC.view.frame;
    if(frame.origin.y + frame.size.height > rect.origin.y + rect.size.height)
        frame.origin.y = rect.origin.y + rect.size.height - frame.size.height;
    
    CGFloat labelWidth = 200; // width for descriptive labels
    CGFloat popupWidth = LSTYLE_WIDTH + SIDE_PADDING * 3 + labelWidth; // content width + side padding + label width
    CGFloat titleHeight = m_title ? 45 : 0;
    CGFloat buttonHeight = 50;
    CGFloat contentHeight = LSTYLE_HEIGHT * 6 + ROW_PADDING * 7;
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
    if (m_dashs_cnt > 0) {
        memcpy(m_temp_dashs, m_dashs, sizeof(CGFloat) * m_dashs_cnt);
    }
    m_temp_dashs_cnt = m_dashs_cnt;
    
    [m_styleViews removeAllObjects];
    UILStyleView *lv;
    UILStyleBtn *thiz = self;
    CGFloat tdash[4];
    
    // Row 0 - Straight line
    UIView *row0 = [[UIView alloc] initWithFrame:CGRectMake(SIDE_PADDING, ROW_PADDING, popupWidth - SIDE_PADDING * 2, LSTYLE_HEIGHT)];
    row0.backgroundColor = [UIColor whiteColor];
    row0.layer.borderWidth = 2;
    row0.layer.borderColor = [UIColor clearColor].CGColor;
    [view addSubview:row0];
    [m_styleViews addObject:row0];

    lv = [[UILStyleView alloc] init:CGRectMake(ROW_INNER_PADDING, ROW_INNER_PADDING, LSTYLE_WIDTH, LSTYLE_HEIGHT - ROW_INNER_PADDING * 2) :^(const CGFloat *dash, int dash_cnt) {
        [thiz selectStyle:dash :dash_cnt];
    }];
    [row0 addSubview:lv];

    UILabel *lab0 = [[UILabel alloc] initWithFrame:CGRectMake(ROW_INNER_PADDING * 2 + LSTYLE_WIDTH, ROW_INNER_PADDING, labelWidth, LSTYLE_HEIGHT - ROW_INNER_PADDING * 2)];
    lab0.text = [NSString stringWithUTF8String:lineType[0]];
    lab0.font = RD_FONT(NORMAL_FONT_SIZE);
    lab0.userInteractionEnabled = NO;
    [row0 addSubview:lab0];
    
    UITapGestureRecognizer *tap0 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRowTapped:)];
    [row0 addGestureRecognizer:tap0];

    // Row 1 - Dotted line
    UIView *row1 = [[UIView alloc] initWithFrame:CGRectMake(SIDE_PADDING, ROW_PADDING * 2 + LSTYLE_HEIGHT, popupWidth - SIDE_PADDING * 2, LSTYLE_HEIGHT)];
    row1.backgroundColor = [UIColor whiteColor];
    row1.layer.borderWidth = 2;
    row1.layer.borderColor = [UIColor clearColor].CGColor;
    [view addSubview:row1];
    [m_styleViews addObject:row1];

    lv = [[UILStyleView alloc] init:CGRectMake(ROW_INNER_PADDING, ROW_INNER_PADDING, LSTYLE_WIDTH, LSTYLE_HEIGHT - ROW_INNER_PADDING * 2) :^(const CGFloat *dash, int dash_cnt) {
        [thiz selectStyle:dash :dash_cnt];
    }];
    tdash[0] = 1; tdash[1] = 1; [lv setDash:tdash :2];
    [row1 addSubview:lv];

    UILabel *lab1 = [[UILabel alloc] initWithFrame:CGRectMake(ROW_INNER_PADDING * 2 + LSTYLE_WIDTH, ROW_INNER_PADDING, labelWidth, LSTYLE_HEIGHT - ROW_INNER_PADDING * 2)];
    lab1.text = [NSString stringWithUTF8String:lineType[1]];
    lab1.font = RD_FONT(NORMAL_FONT_SIZE);
    lab1.userInteractionEnabled = NO;
    [row1 addSubview:lab1];
    
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRowTapped:)];
    [row1 addGestureRecognizer:tap1];

    // Row 2 - Dashed line (short)
    UIView *row2 = [[UIView alloc] initWithFrame:CGRectMake(SIDE_PADDING, ROW_PADDING * 3 + LSTYLE_HEIGHT * 2, popupWidth - SIDE_PADDING * 2, LSTYLE_HEIGHT)];
    row2.backgroundColor = [UIColor whiteColor];
    row2.layer.borderWidth = 2;
    row2.layer.borderColor = [UIColor clearColor].CGColor;
    [view addSubview:row2];
    [m_styleViews addObject:row2];
    
    lv = [[UILStyleView alloc] init:CGRectMake(ROW_INNER_PADDING, ROW_INNER_PADDING, LSTYLE_WIDTH, LSTYLE_HEIGHT - ROW_INNER_PADDING * 2) :^(const CGFloat *dash, int dash_cnt) {
        [thiz selectStyle:dash :dash_cnt];
    }];
    tdash[0] = 2; tdash[1] = 2; [lv setDash:tdash :2];
    [row2 addSubview:lv];

    UILabel *lab2 = [[UILabel alloc] initWithFrame:CGRectMake(ROW_INNER_PADDING * 2 + LSTYLE_WIDTH, ROW_INNER_PADDING, labelWidth, LSTYLE_HEIGHT - ROW_INNER_PADDING * 2)];
    lab2.text = [NSString stringWithUTF8String:lineType[2]];
    lab2.font = RD_FONT(NORMAL_FONT_SIZE);
    lab2.userInteractionEnabled = NO;
    [row2 addSubview:lab2];
    
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRowTapped:)];
    [row2 addGestureRecognizer:tap2];

    // Row 3 - Dashed line (medium)
    UIView *row3 = [[UIView alloc] initWithFrame:CGRectMake(SIDE_PADDING, ROW_PADDING * 4 + LSTYLE_HEIGHT * 3, popupWidth - SIDE_PADDING * 2, LSTYLE_HEIGHT)];
    row3.backgroundColor = [UIColor whiteColor];
    row3.layer.borderWidth = 2;
    row3.layer.borderColor = [UIColor clearColor].CGColor;
    [view addSubview:row3];
    [m_styleViews addObject:row3];
    
    lv = [[UILStyleView alloc] init:CGRectMake(ROW_INNER_PADDING, ROW_INNER_PADDING, LSTYLE_WIDTH, LSTYLE_HEIGHT - ROW_INNER_PADDING * 2) :^(const CGFloat *dash, int dash_cnt) {
        [thiz selectStyle:dash :dash_cnt];
    }];
    tdash[0] = 4; tdash[1] = 4; [lv setDash:tdash :2];
    [row3 addSubview:lv];

    UILabel *lab3 = [[UILabel alloc] initWithFrame:CGRectMake(ROW_INNER_PADDING * 2 + LSTYLE_WIDTH, ROW_INNER_PADDING, labelWidth, LSTYLE_HEIGHT - ROW_INNER_PADDING * 2)];
    lab3.text = [NSString stringWithUTF8String:lineType[3]];
    lab3.font = RD_FONT(NORMAL_FONT_SIZE);
    lab3.userInteractionEnabled = NO;
    [row3 addSubview:lab3];
    
    UITapGestureRecognizer *tap3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRowTapped:)];
    [row3 addGestureRecognizer:tap3];

    // Row 4 - Dashed line (medium + short)
    UIView *row4 = [[UIView alloc] initWithFrame:CGRectMake(SIDE_PADDING, ROW_PADDING * 5 + LSTYLE_HEIGHT * 4, popupWidth - SIDE_PADDING * 2, LSTYLE_HEIGHT)];
    row4.backgroundColor = [UIColor whiteColor];
    row4.layer.borderWidth = 2;
    row4.layer.borderColor = [UIColor clearColor].CGColor;
    [view addSubview:row4];
    [m_styleViews addObject:row4];
    
    lv = [[UILStyleView alloc] init:CGRectMake(ROW_INNER_PADDING, ROW_INNER_PADDING, LSTYLE_WIDTH, LSTYLE_HEIGHT - ROW_INNER_PADDING * 2) :^(const CGFloat *dash, int dash_cnt) {
        [thiz selectStyle:dash :dash_cnt];
    }];
    tdash[0] = 4; tdash[1] = 2; tdash[2] = 2; tdash[3] = 2; [lv setDash:tdash :4];
    [row4 addSubview:lv];

    UILabel *lab4 = [[UILabel alloc] initWithFrame:CGRectMake(ROW_INNER_PADDING * 2 + LSTYLE_WIDTH, ROW_INNER_PADDING, labelWidth, LSTYLE_HEIGHT - ROW_INNER_PADDING * 2)];
    lab4.text = [NSString stringWithUTF8String:lineType[4]];
    lab4.font = RD_FONT(NORMAL_FONT_SIZE);
    lab4.userInteractionEnabled = NO;
    [row4 addSubview:lab4];
    
    UITapGestureRecognizer *tap4 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRowTapped:)];
    [row4 addGestureRecognizer:tap4];

    // Row 5 - Dashed line (long + medium)
    UIView *row5 = [[UIView alloc] initWithFrame:CGRectMake(SIDE_PADDING, ROW_PADDING * 6 + LSTYLE_HEIGHT * 5, popupWidth - SIDE_PADDING * 2, LSTYLE_HEIGHT)];
    row5.backgroundColor = [UIColor whiteColor];
    row5.layer.borderWidth = 2;
    row5.layer.borderColor = [UIColor clearColor].CGColor;
    [view addSubview:row5];
    [m_styleViews addObject:row5];
    
    lv = [[UILStyleView alloc] init:CGRectMake(ROW_INNER_PADDING, ROW_INNER_PADDING, LSTYLE_WIDTH, LSTYLE_HEIGHT - ROW_INNER_PADDING * 2) :^(const CGFloat *dash, int dash_cnt) {
        [thiz selectStyle:dash :dash_cnt];
    }];
    tdash[0] = 12; tdash[1] = 2; tdash[2] = 4; tdash[3] = 2; [lv setDash:tdash :4];
    [row5 addSubview:lv];

    UILabel *lab5 = [[UILabel alloc] initWithFrame:CGRectMake(ROW_INNER_PADDING * 2 + LSTYLE_WIDTH, ROW_INNER_PADDING, labelWidth, LSTYLE_HEIGHT - ROW_INNER_PADDING * 2)];
    lab5.text = [NSString stringWithUTF8String:lineType[5]];
    lab5.font = RD_FONT(NORMAL_FONT_SIZE);
    lab5.userInteractionEnabled = NO;
    [row5 addSubview:lab5];
    
    UITapGestureRecognizer *tap5 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRowTapped:)];
    [row5 addGestureRecognizer:tap5];
    
    // Add OK and Cancel buttons
    CGFloat buttonY = titleHeight + contentHeight;
    CGFloat buttonWidth = (popupWidth - SIDE_PADDING * 3) / 2;
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    cancelButton.frame = CGRectMake(SIDE_PADDING * 2 + buttonWidth, buttonY + 10, buttonWidth, 40);
    [cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    cancelButton.titleLabel.font = RD_FONT(NORMAL_FONT_SIZE);
    [cancelButton setTitleColor:RD_COLOR forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(onCancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:cancelButton];
    
    UIButton *okButton = [UIButton buttonWithType:UIButtonTypeSystem];
    okButton.frame = CGRectMake(SIDE_PADDING, buttonY + 10, buttonWidth, 40);
    [okButton setTitle:NSLocalizedString(@"OK", nil) forState:UIControlStateNormal];
    okButton.titleLabel.font = RD_FONT(NORMAL_FONT_SIZE);
    [okButton setTitleColor:RD_COLOR forState:UIControlStateNormal];
    [okButton addTarget:self action:@selector(onOkTapped) forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:okButton];

    // Pre-select current style
    [self selectStyle:m_dashs :m_dashs_cnt];

    [presentingVC presentViewController:pop animated:NO completion:nil];
}

- (void)selectStyle:(const CGFloat *)dash :(int)dash_cnt
{
    // Clear all borders
    for (UIView *row in m_styleViews) {
        row.layer.borderColor = [UIColor clearColor].CGColor;
    }
    
    // Store temporary selection
    if (dash && dash_cnt > 0) {
        memcpy(m_temp_dashs, dash, sizeof(CGFloat) * dash_cnt);
        m_temp_dashs_cnt = dash_cnt;
    } else {
        m_temp_dashs_cnt = 0;
    }
    
    // Highlight selected style
    for (UIView *row in m_styleViews) {
        BOOL isMatch = NO;
        NSUInteger idx = [m_styleViews indexOfObject:row];
        
        if (dash_cnt == 0 && idx == 0) {
            isMatch = YES; // First item is straight line (no dash)
        } else if (dash_cnt > 0) {
            // Compare dash patterns
            if (idx == 1 && dash_cnt == 2 && dash[0] == 1 && dash[1] == 1) isMatch = YES;
            else if (idx == 2 && dash_cnt == 2 && dash[0] == 2 && dash[1] == 2) isMatch = YES;
            else if (idx == 3 && dash_cnt == 2 && dash[0] == 4 && dash[1] == 4) isMatch = YES;
            else if (idx == 4 && dash_cnt == 4 && dash[0] == 4 && dash[1] == 2 && dash[2] == 2 && dash[3] == 2) isMatch = YES;
            else if (idx == 5 && dash_cnt == 4 && dash[0] == 12 && dash[1] == 2 && dash[2] == 4 && dash[3] == 2) isMatch = YES;
        }
        
        if (isMatch) {
            row.layer.borderColor = RD_COLOR.CGColor;
        }
    }
}

- (void)onOkTapped
{
    // Apply the temporary selection
    if (m_temp_dashs_cnt > 0) {
        memcpy(m_dashs, m_temp_dashs, sizeof(CGFloat) * m_temp_dashs_cnt);
    }
    m_dashs_cnt = m_temp_dashs_cnt;
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
    
    CGFloat tdash[4];
    const CGFloat *dash = NULL;
    int cnt = 0;
    
    switch (idx) {
        case 0:
            dash = NULL; cnt = 0; break;
        case 1:
            tdash[0] = 1; tdash[1] = 1; dash = tdash; cnt = 2; break;
        case 2:
            tdash[0] = 2; tdash[1] = 2; dash = tdash; cnt = 2; break;
        case 3:
            tdash[0] = 4; tdash[1] = 4; dash = tdash; cnt = 2; break;
        case 4:
            tdash[0] = 4; tdash[1] = 2; tdash[2] = 2; tdash[3] = 2; dash = tdash; cnt = 4; break;
        case 5:
            tdash[0] = 12; tdash[1] = 2; tdash[2] = 4; tdash[3] = 2; dash = tdash; cnt = 4; break;
    }
    
    [self selectStyle:dash :cnt];
}

- (UILabel *)getLineLabelAtIdx:(int)idx
{
    UIFont *font = [UIFont systemFontOfSize:15];
    UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(16 + LSTYLE_WIDTH, 8 + idx * LSTYLE_HEIGHT, 120, LSTYLE_HEIGHT)];
    lab.tag = 0;
    lab.text = [NSString stringWithUTF8String:lineType[idx]];
    [lab setFont:font];
    return lab;
}

- (void)updateStyleFromGesture:(UITapGestureRecognizer *)tap
{
    CGPoint pt = [tap locationInView:[tap view]];
    int idx = (int)(pt.y / 40);
    CGFloat tdash[4];
    const CGFloat *dash = NULL;
    int cnt = 0;
    switch (idx) {
        case 0:
            dash = NULL; cnt = 0; break;
        case 1:
            tdash[0] = 1; tdash[1] = 1; dash = tdash; cnt = 2; break;
        case 2:
            tdash[0] = 2; tdash[1] = 2; dash = tdash; cnt = 2; break;
        case 3:
            tdash[0] = 4; tdash[1] = 4; dash = tdash; cnt = 2; break;
        case 4:
            tdash[0] = 4; tdash[1] = 2; tdash[2] = 2; tdash[3] = 2; dash = tdash; cnt = 4; break;
        default:
            tdash[0] = 12; tdash[1] = 2; tdash[2] = 4; tdash[3] = 2; dash = tdash; cnt = 4; break;
    }
    [self update:dash :cnt];
    [pop dismiss];
}
@end
