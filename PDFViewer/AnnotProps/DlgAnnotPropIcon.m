//
//  DlgAnnotPropIcon.m
//  RDPDFReader
//
//  Created by Radaee Lou on 2020/5/13.
//  Copyright © 2020 Radaee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DlgAnnotPropIcon.h"
#import "RDVGlobal.h"
#import "RDUtils.h"

@implementation DlgAnnotPropIcon

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
    }
    return self;
}
-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
    }
    return self;
}
-(IBAction)OnAlphaChanged:(id)sender
{
    // Removed: no fill/opacity control for icon dialog
}
-(IBAction)OnLock:(id)sender
{
    // UISwitch handles state automatically
}

-(IBAction)OnEnableFillChanged:(id)sender
{
    // Removed: no Enable Fill for icon dialog
}

-(void)setAnnot:(RDPDFAnnot *)annot :(UIViewController *)vc
{
    m_vc = vc;
    m_annot = annot;
    [mIcon setIcon:m_annot :m_vc];
    // Ensure fill color preview appears as enabled with full opacity
    if (mFColor) {
        mFColor.tag = 1;
        unsigned int fcolor = [m_annot getFillColor];
        unsigned int fcolorOpaque = (fcolor & 0x00FFFFFF) | 0xFF000000; // force alpha = 1
        [mFColor setColor:fcolorOpaque :YES :m_vc];
    }
    // Hide removed controls
    if (mFColor) mFColor.hidden = NO;
    if (mLFColor) mLFColor.hidden = NO;
    if (mEnableFill) mEnableFill.hidden = YES;
    if (mLEnableFill) mLEnableFill.hidden = YES;
    if (mAlpha) mAlpha.hidden = YES;
    if (mLAlpha) mLAlpha.hidden = YES;
    mLocked.on = [m_annot isLocked];
    mLIcon.text = NSLocalizedString(@"Icon", nil);
    mLLock.text = NSLocalizedString(@"Lock", nil);
    mLocked.onTintColor = RD_COLOR;
    UIFont *buttonFont = RD_FONT(NORMAL_FONT_SIZE);
    self.okButton.titleLabel.font = buttonFont;
    [self.okButton setTitleColor:RD_COLOR forState:UIControlStateNormal];
    [self.okButton setTitleColor:RD_COLOR forState:UIControlStateHighlighted];
    [self.okButton setTitleColor:RD_COLOR forState:UIControlStateSelected];
    self.okButton.tintColor = RD_COLOR;
    self.cancelButton.titleLabel.font = buttonFont;
    [self.cancelButton setTitleColor:RD_COLOR forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:RD_COLOR forState:UIControlStateHighlighted];
    [self.cancelButton setTitleColor:RD_COLOR forState:UIControlStateSelected];
    self.cancelButton.tintColor = RD_COLOR;
}

-(void)setTitle:(NSString *)title
{
    if (mTitle) {
        mTitle.text = title;
        mTitle.font = RD_TITLE_FONT(BIG_FONT_SIZE);
        mTitle.textColor = RD_TEXT_GRAY;
    }
}

-(void)updateAnnot
{
    // Update icon
    [m_annot setIcon:[mIcon icon]];
    // Apply fill color from picker, force alpha = 1
    if (mFColor) {
        unsigned int fcolor0 = mFColor.color;
        unsigned int fnew = (fcolor0 & 0x00FFFFFF) | 0xFF000000;
        [m_annot setFillColor:fnew];
    }
    // Set locked state last
    [m_annot setLocked:mLocked.on];
}

@end
