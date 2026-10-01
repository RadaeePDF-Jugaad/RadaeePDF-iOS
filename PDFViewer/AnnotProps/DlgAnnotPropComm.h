//
//  DlgAnnotPropComm.h
//  PDFViewer
//
//  Ported from reference project dialog for Rect/Ellipse and other common annots
//

#pragma once
#import <UIKit/UIKit.h>
#import "PDFObjc.h"
#import "UILStyleView.h"
#import "UIColorBtn.h"
#import "UILShadowView.h"
@interface DlgAnnotPropComm : UILShadowView
{
    RDPDFAnnot *m_annot;
    UIViewController *m_vc;
    BOOL m_has_fill;
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
    __weak IBOutlet UISlider *mAlpha;
    __weak IBOutlet UISwitch *mLocked;
    __weak IBOutlet UILabel *mLLock;
    __weak IBOutlet UILabel *mLEnableFill;
    __weak IBOutlet UISwitch *mEnableFill;
}
-(id)initWithFrame:(CGRect)frame;
-(id)initWithCoder:(NSCoder *)aDecoder;
-(void)setAnnot:(RDPDFAnnot *)annot :(UIViewController *)vc;
-(void)setTitle:(NSString *)title;
-(void)hasFill:(BOOL)has;
-(void)updateAnnot;
-(IBAction)OnAlphaChanged:(id)sender;
-(IBAction)OnLock:(id)sender;
-(IBAction)OnEnableFillChanged:(id)sender;
@end
