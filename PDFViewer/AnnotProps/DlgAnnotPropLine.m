#import "DlgAnnotPropLine.h"
#import "RDVGlobal.h"
#import "RDUtils.h"

@implementation DlgAnnotPropLine

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
    // Update fill color preview with effective opacity (0 if Enable fill is OFF)
    if (mFColor && mAlpha) {
        unsigned int fcolor = mFColor.color;
        float a = (mEnableFill && !mEnableFill.on) ? 0.0f : mAlpha.value;
        unsigned int ia = 255 * a;
        unsigned int newColor = (fcolor & 0x00FFFFFF) | (ia << 24);
        [mFColor setColor:newColor :YES :m_vc];
    }
    // Update stroke preview with slider alpha
    if (mLColor && mAlpha) {
        unsigned int scolor = mLColor.color;
        unsigned int ia_s = (unsigned int)(255 * mAlpha.value);
        unsigned int snew = (scolor & 0x00FFFFFF) | (ia_s << 24);
        [mLColor setColor:snew :NO :m_vc];
    }
}
-(IBAction)OnLock:(id)sender
{
    // UISwitch handles state automatically
}

-(IBAction)OnEnableFillChanged:(id)sender
{
    if (!mEnableFill) return;
    // Do not change slider value or enabled state; only update preview with effective alpha
    if (mFColor && mAlpha) {
        unsigned int fcolor = mFColor.color;
        float a = mEnableFill.on ? mAlpha.value : 0.0f;
        unsigned int ia = 255 * a;
        unsigned int newColor = (fcolor & 0x00FFFFFF) | (ia << 24);
        [mFColor setColor:newColor :YES :m_vc];
    }
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
    // Preselect current line dash style from the annotation
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
    mFColor.tag = 0;
    unsigned int fcolor = [m_annot getFillColor];
    [mFColor setColor:fcolor :YES :m_vc];
    int lhead = [m_annot getLineStyle];
    [mLStart setStyle:lhead & 0xffff :m_vc];
    [mLStart setTitle:NSLocalizedString(@"Line start", nil)];
    [mLEnd setStyle:lhead >> 16 :m_vc];
    [mLEnd setTitle:NSLocalizedString(@"Line end", nil)];
    // Opacity controls STROKE alpha; initialize from stroke alpha
    mAlpha.value = ((lcolor >> 24) & 0xFF) / 255.0f;
    if (mLEnableFill) mLEnableFill.text = NSLocalizedString(@"Enable fill", nil);
    if (mEnableFill) mEnableFill.on = (((fcolor >> 24) & 0xFF) != 0);
    mLocked.on = [m_annot isLocked];
    mLLWidth.text = NSLocalizedString(@"Line width", nil);
    mLLStyle.text = NSLocalizedString(@"Line style", nil);
    mLLColor.text = NSLocalizedString(@"Line color", nil);
    mLFColor.text = NSLocalizedString(@"Fill color", nil);
    mLLStart.text = NSLocalizedString(@"Line start", nil);
    mLLEnd.text = NSLocalizedString(@"Line end", nil);
    mLLock.text = NSLocalizedString(@"Lock", nil);
    UIFont *labelFont = RD_FONT(NORMAL_FONT_SIZE);
    mLLWidth.font = labelFont;
    mLLStyle.font = labelFont;
    mLLColor.font = labelFont;
    mLFColor.font = labelFont;
    mLLStart.font = labelFont;
    mLLEnd.font = labelFont;
    mLLock.font = labelFont;
    UIFont *buttonFont = RD_FONT(NORMAL_FONT_SIZE);
    mLocked.onTintColor = RD_COLOR;
    if (mEnableFill) mEnableFill.onTintColor = RD_COLOR;
    if (mAlpha) {
        mAlpha.minimumTrackTintColor = RD_COLOR;
        if ([mAlpha respondsToSelector:@selector(setThumbTintColor:)]) mAlpha.thumbTintColor = RD_COLOR;
    }
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
    // Preserve line endpoints to prevent rect from growing when properties change
    PDF_POINT pt0 = [m_annot getLinePoint:0];
    PDF_POINT pt1 = [m_annot getLinePoint:1];
    
    // Keep stroke color alpha unchanged; apply opacity to fill alpha instead
    CGFloat lw = [mLWidth.text floatValue];
    const CGFloat *dash = mLStyle.dash;
    int dash_cnt = mLStyle.dashCnt;
    
    [m_annot setStrokeWidth:lw];
    // Only set dash if a valid pattern exists, otherwise clear it
    if(dash && dash_cnt > 0)
    {
        float dashf[16];
        for (int i = 0; i < dash_cnt && i < 16; i++) {
            dashf[i] = (float)dash[i];
        }
        [m_annot setStrokeDash:dashf :dash_cnt];
    }
    else
    {
        // Clear dash pattern (solid line)
        [m_annot setStrokeDash:NULL :0];
    }
    // Set stroke alpha from slider
    unsigned int stroke_rgb = mLColor.color & 0x00FFFFFF;
    unsigned int stroke_alpha = (unsigned int)(255 * (mAlpha ? mAlpha.value : 1.0f)) << 24;
    [m_annot setStrokeColor:(stroke_rgb | stroke_alpha)];
    {
        unsigned int fcolor0 = mFColor.color;
        unsigned int ia = 255 * (mEnableFill ? (mEnableFill.on ? (mAlpha ? mAlpha.value : 1.0f) : 0.0f) : (mAlpha ? mAlpha.value : 1.0f));
        unsigned int fnew = (fcolor0 & 0x00FFFFFF) | (ia << 24);
        [m_annot setFillColor:fnew];
    }
    int lhead = mLStart.style | (mLEnd.style << 16);
    [m_annot setLineStyle:lhead];
    
    // Restore line endpoints to prevent unwanted rect resize
    [m_annot setLinePoint:pt0.x :pt0.y :pt1.x :pt1.y];
    
    [m_annot setLocked:NO];
}

- (void)dismissKeyboard
{
    [mLWidth resignFirstResponder];
}

@end
