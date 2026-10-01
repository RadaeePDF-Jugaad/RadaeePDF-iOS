#import <UIKit/UIKit.h>
#import "UILElement.h"
@class RDAnnotPickerViewController;

@interface UIColorBtn : UILElement
{
    unsigned int m_color;
    Boolean m_has_enable;
    UIViewController *m_vc;
}

-(id)initWithCoder:(NSCoder *)aDecoder;
-(id)initWithFrame:(CGRect)frame;
-(void)setColor:(unsigned int)color :(Boolean)has_enable :(UIViewController *)vc;
-(void)setColor:(unsigned int)color :(Boolean)has_enable;
-(void)showViews;
-(int)color;
@end
