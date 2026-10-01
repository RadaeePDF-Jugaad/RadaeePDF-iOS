//
//  UILHeadView.h
//  RDPDFReader
//
//  Created by Radaee Lou on 2020/5/7.
//

#pragma once
#import <UIKit/UIKit.h>
#import "UILElement.h"
#import "PDFPopupCtrl.h"
typedef void(^func_lhead)(int);
@interface UILHeadView : UIView
{
    int m_style;
    func_lhead m_callback;
}
-(id)init:(CGRect)frame :(func_lhead)callback;
-(void)setStyle:(int)style;
@end

@interface UILHeadBtn : UILElement
{
    int m_style;
    UIViewController *m_vc;
    PDFPopupCtrl *pop;
    NSString *m_title;
    int m_temp_style;
    NSMutableArray *m_styleViews;
}
-(id)initWithCoder:(NSCoder *)aDecoder;
-(id)initWithFrame:(CGRect)frame;
-(void)setStyle:(int)style :(UIViewController *)vc;
-(void)setTitle:(NSString *)title;
-(int)style;
@end
