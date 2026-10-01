#import "UIColorBtn.h"
#import "PDFPopupCtrl.h"
#import "RDAnnotPickerViewController.h"
#import "UILShadowView.h"

@implementation UIColorBtn
-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
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
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (UIViewController *)owningViewController
{
    UIResponder *responder = self;
    while (responder)
    {
        responder = [responder nextResponder];
        if ([responder isKindOfClass:[UIViewController class]])
        {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

- (UIViewController *)presentingController
{
    UIViewController *controller = m_vc ? m_vc : [self owningViewController];
    UIViewController *presenter = controller;
    while (presenter.presentedViewController)
    {
        presenter = presenter.presentedViewController;
    }
    return presenter;
}

-(void)tapAction:(id)sendor
{
    UIViewController *presenter = [self presentingController];
    if (!presenter)
        return;
    
    // Hide the container view (similar to UILHeadView)
    UIView *container = self;
    while (container && ![container isKindOfClass:[UILShadowView class]])
        container = container.superview;
    if (!container) container = self.superview;
    container.hidden = YES;
    
    RDAnnotPickerViewController *pickerViewController = [[RDAnnotPickerViewController alloc] initWithNibName:@"RDAnnotPickerViewController" bundle:nil];
    pickerViewController.colorBtn = self;
    pickerViewController.containerView = container;
    [pickerViewController.view setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.2f]];
    pickerViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    pickerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [presenter presentViewController:pickerViewController animated:YES completion:nil];
}

- (void)showViews
{
    if (!m_vc) {
        return;
    }
    // Ensure the hosting dialog stays visible when presenting the picker
    if (m_vc.view.hidden) {
        m_vc.view.hidden = NO;
    }
}

- (void)setColor:(unsigned int)color :(Boolean)has_enable
{
    [self showViews];
    [self setColor:color :has_enable :m_vc];
}

-(void)setColor:(unsigned int)color :(Boolean)has_enable :(UIViewController *)vc
{
    m_color = color;
    m_has_enable = has_enable;
    m_vc = vc;
    CGFloat clr[4];
    clr[0] = ((color >> 16) & 0xff) / 255.0f;
    clr[1] = ((color >> 8) & 0xff) / 255.0f;
    clr[2] = (color & 0xff) / 255.0f;
    clr[3] = ((m_color >> 24) & 0xff) / 255.0f;
    if (self.tag == 1) {
        clr[3] = (((m_color >> 24) & 0xff) == 0) ? 0.0f : 1.0f;
    }
    self.backgroundColor = [UIColor colorWithRed:clr[0] green:clr[1] blue:clr[2] alpha:clr[3]];
    // Manage alpha overlay icon: show only when enabled AND not a fill color (tag != 1)
    const NSInteger kAlphaOverlayTag = 987654;
    UIImageView *alphaIcon = (UIImageView *)[self viewWithTag:kAlphaOverlayTag];
    if (!alphaIcon) {
        alphaIcon = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"circle.lefthalf.filled"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        alphaIcon.contentMode = UIViewContentModeCenter;
        alphaIcon.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
        alphaIcon.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        alphaIcon.tag = kAlphaOverlayTag;
        [self addSubview:alphaIcon];
    }
    alphaIcon.hidden = !(has_enable && self.tag != 1);
}
-(int)color { return m_color; }
@end
