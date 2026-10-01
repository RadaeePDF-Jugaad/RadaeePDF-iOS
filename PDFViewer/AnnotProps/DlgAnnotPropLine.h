//
//  DlgAnnotPropLine.h
//  PDFViewer
//
//  Ported from reference project dialog for Line/Arrow styles
//

#pragma once
#import <UIKit/UIKit.h>
#import "PDFObjc.h"
#import "UILStyleView.h"
#import "UILHeadView.h"
#import "UIColorBtn.h"
#import "UILShadowView.h"
@interface DlgAnnotPropLine : UILShadowView
{
    RDPDFAnnot *m_annot;
    UIViewController *m_vc;
    unsigned int m_original_stroke_color;
    __weak IBOutlet UILabel *mTitle;
    __weak IBOutlet UITextField *mLWidth;
    __weak IBOutlet UILabel *mLLWidth;
    __weak IBOutlet UILStyleBtn *mLStyle;
    __weak IBOutlet UILabel *mLLStyle;
    __weak IBOutlet UIColorBtn *mLColor;
    __weak IBOutlet UILabel *mLLColor;
    __weak IBOutlet UIColorBtn *mFColor;
    __weak IBOutlet UILabel *mLFColor;
    __weak IBOutlet UILHeadBtn *mLStart;
    __weak IBOutlet UILabel *mLLStart;
    __weak IBOutlet UILHeadBtn *mLEnd;
    __weak IBOutlet UILabel *mLLEnd;
    __weak IBOutlet UISlider *mAlpha;
    __weak IBOutlet UILabel *mLLock;
    __weak IBOutlet UISwitch *mLocked;
    __weak IBOutlet UILabel *mLEnableFill;
    __weak IBOutlet UISwitch *mEnableFill;
}
-(id)initWithFrame:(CGRect)frame;
-(id)initWithCoder:(NSCoder *)aDecoder;
-(void)setAnnot:(RDPDFAnnot *)annot :(UIViewController *)vc;
-(void)setTitle:(NSString *)title;
-(void)updateAnnot;
-(IBAction)OnAlphaChanged:(id)sender;
-(IBAction)OnLock:(id)sender;
-(IBAction)OnEnableFillChanged:(id)sender;
@end
