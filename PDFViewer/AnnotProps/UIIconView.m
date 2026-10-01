//
//  UIIconView.m
//  RDPDFReader
//
//  Created by Radaee Lou on 2020/5/13.
//  Copyright © 2020 Radaee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIIconView.h"
#import "PDFPopupCtrl.h"
#import "PDFDialog.h"
#import "RDVGlobal.h"
#import "RDUtils.h"

const char *g_note_icon_names[] =
{
    "Note",
    "Comment",
    "Key",
    "Help",
    "NewParagraph",
    "Paragraph",
    "Insert",
    "Check",
    "Circle",
    "Cross",
    "CrossHairs",
    "RightArrow",
    "RightPointer",
    "Star",
    "UpArrow",
    "UpLeftArrow"
};

const char *g_attach_icon_names[] =
{
    "PushPin",
    "Graph",
    "Paperclip",
    "Tag"
};

@implementation UIIconBtn
-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        m_icon = 0;
        m_temp_icon = 0;
        m_vc = nil;
        m_iconViews = [[NSMutableArray alloc] init];
        self.userInteractionEnabled = YES;
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
        m_icon = 0;
        m_temp_icon = 0;
        m_vc = nil;
        m_iconViews = [[NSMutableArray alloc] init];
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor whiteColor];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

-(void)updateIcon:(int)icon
{
    m_icon = icon;
    m_dib = [[RDPDFDIB alloc] init:48 :48];
    [m_dib erase:-1];
    Global_drawAnnotIcon(m_atype, m_icon, [m_dib handle]);
    self.image = [[UIImage alloc] initWithCGImage:[m_dib image]];
}

-(void)setIcon:(RDPDFAnnot *)annot :(UIViewController *)vc
{
    m_atype = [annot type];
    m_vc = vc;
    [self updateIcon:[annot getIcon]];
}

-(int)icon
{
    return m_icon;
}

#define ICON_WIDTH 150
#define ICON_HEIGHT 45
#define ROW_PADDING 8
#define SIDE_PADDING 12
#define ROW_INNER_PADDING 8

-(void)tapAction:(id)sendor
{
    UIView *container = [(PDFDialog *)m_vc popView];
    container.hidden = YES;
    
    int items_cnt = 0;
    if(m_atype == 1)
        items_cnt = 16;
    else if(m_atype == 17)
        items_cnt = 4;
    
    CGFloat labelWidth = 150;
    CGFloat popupWidth = ICON_HEIGHT + SIDE_PADDING * 3 + labelWidth;
    CGFloat titleHeight = 45; // "Icon" title
    CGFloat buttonHeight = 50;
    CGFloat fullContentHeight = ICON_HEIGHT * items_cnt + ROW_PADDING * (items_cnt + 1);
    CGFloat maxScrollHeight = 400; // Maximum height for scroll view
    CGFloat scrollViewHeight = MIN(fullContentHeight, maxScrollHeight);
    
    UIScrollView *view = [[UIScrollView alloc] initWithFrame:CGRectMake(0, titleHeight, popupWidth, scrollViewHeight)];
    view.contentSize = CGSizeMake(popupWidth - SIDE_PADDING * 2, fullContentHeight);
    view.scrollEnabled = YES;
    view.showsVerticalScrollIndicator = YES;
    UILShadowView *bgView = [[UILShadowView alloc] initWithFrame:CGRectMake(container.frame.origin.x, container.frame.origin.y, popupWidth, scrollViewHeight + titleHeight + buttonHeight)];
    [bgView addSubview:view];
    
    // Add title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, popupWidth, titleHeight - 10)];
    titleLabel.text = @"Icon";
    titleLabel.font = RD_TITLE_FONT(BIG_FONT_SIZE);
    titleLabel.textColor = RD_TEXT_GRAY;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.backgroundColor = [UIColor clearColor];
    [bgView addSubview:titleLabel];
    
    bgView.center = container.center;
    m_popup = [[PDFPopupCtrl alloc] init:bgView];
    [m_popup setDismiss:^{ container.hidden = NO; }];

    // Store current selection as temporary
    m_temp_icon = m_icon;
    
    [m_iconViews removeAllObjects];
    m_dibs = [[NSMutableArray alloc] init];
    UIIconBtn *thiz = self;
    
    const char **icon_names = (m_atype == 1) ? g_note_icon_names : g_attach_icon_names;
    
    for(int cur = 0; cur < items_cnt; cur++)
    {
        // Create row container
        UIView *row = [[UIView alloc] initWithFrame:CGRectMake(SIDE_PADDING, ROW_PADDING + cur * (ICON_HEIGHT + ROW_PADDING), popupWidth - SIDE_PADDING * 2, ICON_HEIGHT)];
        row.backgroundColor = [UIColor whiteColor];
        row.layer.borderWidth = 2;
        row.layer.borderColor = [UIColor clearColor].CGColor;
        [view addSubview:row];
        [m_iconViews addObject:row];
        
        // Icon image
        UIImageView *lv = [[UIImageView alloc] initWithFrame:CGRectMake(ROW_INNER_PADDING, ROW_INNER_PADDING, ICON_HEIGHT - ROW_INNER_PADDING * 2, ICON_HEIGHT - ROW_INNER_PADDING * 2)];
        RDPDFDIB *dib = [[RDPDFDIB alloc] init:48 :48];
        [dib erase:-1];
        Global_drawAnnotIcon(m_atype, cur, [dib handle]);
        [m_dibs addObject:dib];
        lv.image = [[UIImage alloc] initWithCGImage:[dib image]];
        [row addSubview:lv];
        
        // Icon label
        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(ICON_HEIGHT + ROW_INNER_PADDING, ROW_INNER_PADDING, labelWidth, ICON_HEIGHT - ROW_INNER_PADDING * 2)];
        lab.text = [NSString stringWithUTF8String:icon_names[cur]];
        lab.font = RD_FONT(NORMAL_FONT_SIZE);
        lab.textColor = RD_TEXT_BLACK;
        [row addSubview:lab];
        
        // Add tap gesture to row
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRowTapped:)];
        [row addGestureRecognizer:tap];
    }
    
    // Add OK and Cancel buttons
    UIButton *okButton = [[UIButton alloc] initWithFrame:CGRectMake(SIDE_PADDING, scrollViewHeight + titleHeight + 10, 100, 30)];
    [okButton setTitle:@"OK" forState:UIControlStateNormal];
    [okButton setTitleColor:RD_COLOR forState:UIControlStateNormal];
    okButton.titleLabel.font = RD_FONT(NORMAL_FONT_SIZE);
    [okButton addTarget:self action:@selector(onOkTapped) forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:okButton];
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(popupWidth - SIDE_PADDING - 100, scrollViewHeight + titleHeight + 10, 100, 30)];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton setTitleColor:RD_COLOR forState:UIControlStateNormal];
    cancelButton.titleLabel.font = RD_FONT(NORMAL_FONT_SIZE);
    [cancelButton addTarget:self action:@selector(onCancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:cancelButton];
    
    // Pre-select current icon
    [self selectIcon:m_icon];
    
    [m_vc presentViewController:m_popup animated:NO completion:nil];
}

- (void)selectIcon:(int)icon
{
    // Clear all borders
    for (UIView *row in m_iconViews) {
        row.layer.borderColor = [UIColor clearColor].CGColor;
    }
    
    // Store temporary selection
    m_temp_icon = icon;
    
    // Highlight selected icon
    if (icon >= 0 && icon < m_iconViews.count) {
        UIView *row = m_iconViews[icon];
        row.layer.borderColor = RD_COLOR.CGColor;
    }
}

- (void)onOkTapped
{
    // Apply the temporary selection
    [self updateIcon:m_temp_icon];
    [m_popup dismiss];
}

- (void)onCancelTapped
{
    // Discard temporary selection
    [m_popup dismiss];
}

- (void)onRowTapped:(UITapGestureRecognizer *)tap
{
    UIView *row = tap.view;
    NSUInteger idx = [m_iconViews indexOfObject:row];
    if (idx != NSNotFound) {
        [self selectIcon:(int)idx];
    }
}
@end
