#import "DlgAnnotPropComm.h"
#import "RDVGlobal.h"
#import "RDUtils.h"
#import "RDUtils.h"

@implementation DlgAnnotPropComm

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        m_has_fill = YES;
    }
    return self;
}
-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        m_has_fill = YES;
    }
    return self;
}
-(IBAction)OnAlphaChanged:(id)sender
{
    // Update fill color preview with new opacity
    if (mFColor && mAlpha && m_has_fill) {
        unsigned int fcolor = mFColor.color;
        float a = (mEnableFill && !mEnableFill.on) ? 0.0f : mAlpha.value;
        unsigned int ia = 255 * a;
        unsigned int newColor = (fcolor & 0x00FFFFFF) | (ia << 24);
        [mFColor setColor:newColor :YES :m_vc];
    }
    // Update stroke color preview with slider alpha
    if (mLColor && mAlpha) {
        unsigned int scolor = mLColor.color;
        unsigned int ia_s = 255 * mAlpha.value;
        unsigned int snew = (scolor & 0x00FFFFFF) | (ia_s << 24);
        [mLColor setColor:snew :NO :m_vc];
    }
}
-(IBAction)OnLock:(id)sender
{
    // UISwitch handles state automatically
}

-(void)setAnnot:(RDPDFAnnot *)annot :(UIViewController *)vc
{
    m_annot = annot;
    m_vc = vc;
    m_original_stroke_color = [m_annot getStrokeColor];
    mLWidth.text = [NSString stringWithFormat:@"%.2f",[m_annot getStrokeWidth]];
    mLWidth.font = [UIFont systemFontOfSize:15];
    mLWidth.textAlignment = NSTextAlignmentCenter;
    [mLWidth addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventEditingDidEndOnExit];
    // Preselect current dash style from the annotation
    CGFloat gdash[16];
    float fdash[16];
    int dcnt = [m_annot getStrokeDash:fdash :16];
    for (int i = 0; i < dcnt && i < 16; i++) gdash[i] = (CGFloat)fdash[i];
    
    // Validate dash pattern against known styles, default to straight line if invalid
    BOOL isValidStyle = NO;
    if (dcnt == 0) {
        isValidStyle = YES; // Straight line
    } else if (dcnt == 2) {
        // Check for dotted [1,1], short dash [2,2], or medium dash [4,4]
        if ((gdash[0] == 1 && gdash[1] == 1) ||
            (gdash[0] == 2 && gdash[1] == 2) ||
            (gdash[0] == 4 && gdash[1] == 4)) {
            isValidStyle = YES;
        }
    } else if (dcnt == 4) {
        // Check for medium+short [4,2,2,2] or long+medium [12,2,4,2]
        if ((gdash[0] == 4 && gdash[1] == 2 && gdash[2] == 2 && gdash[3] == 2) ||
            (gdash[0] == 12 && gdash[1] == 2 && gdash[2] == 4 && gdash[3] == 2)) {
            isValidStyle = YES;
        }
    }
    
    // If pattern doesn't match any predefined style, default to straight line
    const CGFloat *dashPtr = (isValidStyle && dcnt > 0) ? gdash : NULL;
    int validDcnt = isValidStyle ? dcnt : 0;
    [mLStyle setDash:dashPtr :validDcnt :m_vc];
    [mLStyle setTitle:NSLocalizedString(@"Line style", nil)];
    unsigned int lcolor = [m_annot getStrokeColor];
    [mLColor setColor: lcolor:NO :m_vc];
    // Allow continuous alpha preview for fill
    mFColor.tag = 0;
    unsigned int fcolor = [m_annot getFillColor];
    if(m_has_fill) [mFColor setColor:fcolor :YES :m_vc];
    // Opacity controls LINE alpha; initialize from stroke alpha
    if (mAlpha) mAlpha.value = ((lcolor >> 24) & 0xFF) / 255.0f;
    if (mLEnableFill) mLEnableFill.text = NSLocalizedString(@"Enable fill", nil);
    if (mEnableFill) mEnableFill.on = (((fcolor >> 24) & 0xFF) != 0);
    mLocked.on = [m_annot isLocked];
    mLLWidth.text = NSLocalizedString(@"Line width", nil);
    mLLStyle.text = NSLocalizedString(@"Line style", nil);
    mLLColor.text = NSLocalizedString(@"Line color", nil);
    mLFColor.text = NSLocalizedString(@"Fill color", nil);
    mLLock.text = NSLocalizedString(@"Lock", nil);
    UIFont *labelFont = RD_FONT(NORMAL_FONT_SIZE);
    mLLWidth.font = labelFont;
    mLLStyle.font = labelFont;
    mLLColor.font = labelFont;
    mLFColor.font = labelFont;
    mLLock.font = labelFont;
    // Tint controls
    if (mEnableFill) mEnableFill.onTintColor = RD_COLOR;
    if (mAlpha) {
        mAlpha.minimumTrackTintColor = RD_COLOR;
        if ([mAlpha respondsToSelector:@selector(setThumbTintColor:)]) mAlpha.thumbTintColor = RD_COLOR;
    }
    UIFont *buttonFont = RD_FONT(NORMAL_FONT_SIZE);
    mLocked.onTintColor = RD_COLOR;
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
    // UISwitch doesn't have title
}

-(void)hasFill:(BOOL)has
{
    m_has_fill = has;
    mFColor.hidden = !has;
    mLFColor.hidden = !has;
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
    if (mLocked.on) { [m_annot setLocked:YES]; return; }
    CGFloat lw = [mLWidth.text floatValue];
    const CGFloat *dash = mLStyle.dash;
    float dashf[4];
    if(dash)
    {
        dashf[0] = dash[0];
        dashf[1] = dash[1];
        dashf[2] = dash[2];
        dashf[3] = dash[3];
    }
    int dash_cnt = mLStyle.dashCnt;
    [m_annot setStrokeWidth:lw];
    [m_annot setStrokeDash:dashf :dash_cnt];
    // Set stroke alpha from slider
    unsigned int stroke_rgb = mLColor.color & 0x00FFFFFF;
    unsigned int stroke_alpha = (unsigned int)(255 * (mAlpha ? mAlpha.value : 1.0f)) << 24;
    [m_annot setStrokeColor:(stroke_rgb | stroke_alpha)];
    if (m_has_fill)
    {
        unsigned int fcolor0 = mFColor.color;
        float a_fill = (mEnableFill && !mEnableFill.on) ? 0.0f : (mAlpha ? mAlpha.value : 1.0f);
        unsigned int ia = (unsigned int)(255 * a_fill);
        unsigned int fnew = (fcolor0 & 0x00FFFFFF) | (ia << 24);
        [m_annot setFillColor:fnew];
    }
    [m_annot setLocked:NO];
}

- (void)dismissKeyboard
{
    [mLWidth resignFirstResponder];
}

-(IBAction)OnEnableFillChanged:(id)sender
{
    if (!mEnableFill) return;
    // Do not change slider value or enabled state; only update preview with effective alpha
    if (mFColor && mAlpha && m_has_fill) {
        unsigned int fcolor = mFColor.color;
        float a = mEnableFill.on ? mAlpha.value : 0.0f;
        unsigned int ia = 255 * a;
        unsigned int newColor = (fcolor & 0x00FFFFFF) | (ia << 24);
        [mFColor setColor:newColor :YES :m_vc];
    }
}

@end
