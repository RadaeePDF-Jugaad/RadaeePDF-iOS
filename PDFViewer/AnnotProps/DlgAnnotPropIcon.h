//
//  DlgAnnotPropIcon.h
//  RDPDFReader
//
//  Created by Radaee Lou on 2020/5/13.
//  Copyright © 2020 Radaee. All rights reserved.
//

#pragma once
#import <UIKit/UIKit.h>
#import "PDFObjc.h"
#import "UIColorBtn.h"
#import "UIIconView.h"
#import "UILShadowView.h"
@interface DlgAnnotPropIcon : UILShadowView
{
    RDPDFAnnot *m_annot;
    UIViewController *m_vc;
    __weak IBOutlet UILabel *mTitle;
    __weak IBOutlet UIIconBtn *mIcon;
    __weak IBOutlet UILabel *mLIcon;
    __weak IBOutlet UIColorBtn *mFColor;
    __weak IBOutlet UILabel *mLFColor;
    __weak IBOutlet UISlider *mAlpha;
    __weak IBOutlet UILabel *mLAlpha;
    __weak IBOutlet UILabel *mLLock;
    __weak IBOutlet UISwitch *mLocked;
    __weak IBOutlet UILabel *mLEnableFill;
    __weak IBOutlet UISwitch *mEnableFill;
}

-(IBAction)OnAlphaChanged:(id)sender;
-(IBAction)OnLock:(id)sender;
-(IBAction)OnEnableFillChanged:(id)sender;
-(void)setAnnot:(RDPDFAnnot *)annot :(UIViewController *)vc;
-(void)setTitle:(NSString *)title;
-(void)updateAnnot;
@end
