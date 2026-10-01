//
//  PDFPopupCtrl.m
//  RDPDFReader
//
//  Created by Radaee Lou on 2020/5/5.
//

#import "PDFPopupCtrl.h"

@implementation PDFPopupBG
- (id)init:(UIView *)child :(id)notifier :(SEL)dismiss
{
    self = [super initWithFrame:CGRectZero];
    if(self)
    {
        Notifier = notifier;
        OnDismiss = dismiss;
        m_child = child;
        self.backgroundColor = [[UIColor alloc] initWithRed:0 green:0 blue:0 alpha:0];
        [self addSubview:m_child];
    }
    return self;
}

-(BOOL)touchHitsChild:(CGPoint)point
{
    // Check if point is inside the child's frame
    if (CGRectContainsPoint(m_child.frame, point)) return YES;
    // Also check if any subview of m_child (which may extend beyond its bounds) contains the point
    CGPoint ptInChild = [self convertPoint:point toView:m_child];
    for (UIView *sub in m_child.subviews) {
        CGPoint ptInSub = [m_child convertPoint:ptInChild toView:sub];
        if ([sub pointInside:ptInSub withEvent:nil]) return YES;
    }
    return NO;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSSet *allTouches = [event allTouches];
    UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
    CGPoint point = [touch locationInView:self];
    if(Notifier && ![self touchHitsChild:point])
        [Notifier performSelector:OnDismiss withObject:self afterDelay:0];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSSet *allTouches = [event allTouches];
    UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
    CGPoint point = [touch locationInView:self];
    if(Notifier && ![self touchHitsChild:point])
        [Notifier performSelector:OnDismiss withObject:self afterDelay:0];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    // Check subviews of m_child that may extend beyond its bounds (e.g. resize overlay)
    CGPoint ptInChild = [self convertPoint:point toView:m_child];
    for (UIView *sub in [m_child.subviews reverseObjectEnumerator]) {
        CGPoint ptInSub = [m_child convertPoint:ptInChild toView:sub];
        UIView *hit = [sub hitTest:ptInSub withEvent:event];
        if (hit) return hit;
    }
    // Default behavior
    return [super hitTest:point withEvent:event];
}
@end

@implementation PDFPopupCtrl
- (id)init:(UIView *)view
{
    self = [super init];
    if(self)
    {
        m_view = view;
        m_rect = m_view.frame;
        m_dismiss = nil;
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    }
    return self;
}
- (void)viewDidLayoutSubviews
{
    if(m_rect.size.width > 0 && m_rect.size.height > 0)
        m_view.frame = m_rect;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    m_back = [[PDFPopupBG alloc] init:m_view :self :@selector(onDismiss:)];
    self.view = m_back;
}

- (void)viewDidAppear:(BOOL)animated {
    if ([m_view isKindOfClass:[UITextField class]] || [m_view isKindOfClass:[UITextView class]]) {
        [m_view becomeFirstResponder];
    } else {
        UIView *input = [self findTextInputInView:m_view];
        if (input) [input becomeFirstResponder];
    }
}

- (void)setDismiss:(func_pop_dismiss)dismiss { m_dismiss = dismiss; }

- (void)onDismiss :(PDFPopupBG *)bg
{
    [self dismissViewControllerAnimated:NO completion:nil];
    if (m_dismiss) m_dismiss();
}
- (void)dismiss
{
    [self dismissViewControllerAnimated:NO completion:nil];
    if (m_dismiss) m_dismiss();
}

- (UIView *)findTextInputInView:(UIView *)view
{
    if (!view) return nil;
    if ([view isKindOfClass:[UITextField class]] || [view isKindOfClass:[UITextView class]]) return view;
    for (UIView *sub in view.subviews) {
        UIView *match = [self findTextInputInView:sub];
        if (match) return match;
    }
    return nil;
}
@end
