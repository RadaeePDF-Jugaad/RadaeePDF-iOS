//
//  RDAnnotSettingsViewController.m
//  PDFViewer
//

#import "RDAnnotSettingsViewController.h"

@interface RDLineIconView : UIView
@end

@implementation RDLineIconView
- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;
    CGFloat inset = 3.0;
    CGFloat midY = CGRectGetMidY(rect);
    CGContextSetStrokeColorWithColor(ctx, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(ctx, 2.0);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextMoveToPoint(ctx, inset, midY);
    CGContextAddLineToPoint(ctx, CGRectGetWidth(rect) - inset, midY);
    CGContextStrokePath(ctx);
}
@end

@interface RDAnnotSettingsViewController ()
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *previewView;

@property (nonatomic, strong) UISlider *redSlider;
@property (nonatomic, strong) UILabel *redValueLabel;

@property (nonatomic, strong) UISlider *greenSlider;
@property (nonatomic, strong) UILabel *greenValueLabel;

@property (nonatomic, strong) UISlider *blueSlider;
@property (nonatomic, strong) UILabel *blueValueLabel;

@property (nonatomic, strong) UISlider *opacitySlider;
@property (nonatomic, strong) UILabel *opacityValueLabel;

@property (nonatomic, strong) UISlider *widthSlider;
@property (nonatomic, strong) UILabel *widthValueLabel;

// Fill controls (used for Rectangle/Ellipse)
@property (nonatomic, strong) UISlider *fillRedSlider;
@property (nonatomic, strong) UILabel *fillRedValueLabel;
@property (nonatomic, strong) UISlider *fillGreenSlider;
@property (nonatomic, strong) UILabel *fillGreenValueLabel;
@property (nonatomic, strong) UISlider *fillBlueSlider;
@property (nonatomic, strong) UILabel *fillBlueValueLabel;
@property (nonatomic, strong) UISlider *fillOpacitySlider;
@property (nonatomic, strong) UILabel *fillOpacityValueLabel;

@property (nonatomic) unsigned int textColor;
@property (nonatomic, strong) UIButton *textColorButton;

@end

@implementation RDAnnotSettingsViewController

- (instancetype)initWithType:(RDAnnotSettingsType)type {
    self = [super init];
    if (self) {
        _settingsType = type;
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (instancetype)initWithAnnot:(RDPDFAnnot *)annot type:(RDAnnotSettingsType)type {
    self = [self initWithType:type];
    if (self) {
        _annot = annot;
    }
    return self;
}

- (instancetype)initWithAnnot:(RDPDFAnnot *)annot page:(RDPDFPage *)page type:(RDAnnotSettingsType)type {
    self = [self initWithType:type];
    if (self) {
        _annot = annot;
        _page = page;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    
    [self setupUI];
    [self loadCurrentSettings];
}

- (void)setupUI {
    // Container view
    _containerView = [[UIView alloc] init];
    _containerView.backgroundColor = [UIColor whiteColor];
    _containerView.layer.cornerRadius = 12;
    _containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    _containerView.layer.shadowOffset = CGSizeMake(0, 2);
    _containerView.layer.shadowOpacity = 0.3;
    _containerView.layer.shadowRadius = 8;
    _containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_containerView];
    
    // Title label
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = [self getTitleForType];
    titleLabel.font = RD_TITLE_FONT(BIG_FONT_SIZE);
    titleLabel.textColor = RD_TEXT_GRAY;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_containerView addSubview:titleLabel];
    
    // Preview view (only for non-text types)
    _previewView = [[UIView alloc] init];
    _previewView.layer.cornerRadius = 8;
    _previewView.layer.borderWidth = 1;
    _previewView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _previewView.translatesAutoresizingMaskIntoConstraints = NO;
    [_containerView addSubview:_previewView];
    if (_settingsType == RDAnnotSettingsTypeText) {
        _previewView.hidden = YES;
    }
    
    CGFloat yOffset = 90;
    if (_settingsType == RDAnnotSettingsTypeText) {
        // Text color button
        UILabel *colorLabel = [[UILabel alloc] init];
        colorLabel.text = @"Text Color";
        colorLabel.font = [UIFont systemFontOfSize:14];
        colorLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_containerView addSubview:colorLabel];
        
        _textColorButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _textColorButton.layer.cornerRadius = 4;
        _textColorButton.layer.borderWidth = 1;
        _textColorButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
        [_textColorButton addTarget:self action:@selector(textColorButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        _textColorButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_containerView addSubview:_textColorButton];
        
        [NSLayoutConstraint activateConstraints:@[
            [_textColorButton.widthAnchor constraintEqualToConstant:85]
        ]];

        [NSLayoutConstraint activateConstraints:@[
            [colorLabel.leadingAnchor constraintEqualToAnchor:_containerView.leadingAnchor constant:20],
            [colorLabel.topAnchor constraintEqualToAnchor:_containerView.topAnchor constant:yOffset],
            [colorLabel.widthAnchor constraintEqualToConstant:80],
            
            [_textColorButton.trailingAnchor constraintEqualToAnchor:_containerView.trailingAnchor constant:-20],
            [_textColorButton.centerYAnchor constraintEqualToAnchor:colorLabel.centerYAnchor],
            [_textColorButton.heightAnchor constraintEqualToConstant:30]
        ]];
        
        yOffset += 40;
    } else {
        // Red slider row
        yOffset += [self createSliderRowWithTitle:@"Red" icon:[UIColor redColor] slider:&_redSlider valueLabel:&_redValueLabel minValue:0 maxValue:255 atY:yOffset];
        
        // Green slider row
        yOffset += [self createSliderRowWithTitle:@"Green" icon:[UIColor greenColor] slider:&_greenSlider valueLabel:&_greenValueLabel minValue:0 maxValue:255 atY:yOffset];
        
        // Blue slider row
        yOffset += [self createSliderRowWithTitle:@"Blue" icon:[UIColor blueColor] slider:&_blueSlider valueLabel:&_blueValueLabel minValue:0 maxValue:255 atY:yOffset];
        
        // Opacity slider row (display 0-1, store 0-255)
        yOffset += [self createSliderRowWithTitle:@"Opacity" icon:[UIColor blackColor] slider:&_opacitySlider valueLabel:&_opacityValueLabel minValue:0 maxValue:1 atY:yOffset];
        
        // Width slider row
        yOffset += [self createSliderRowWithTitle:@"Width" icon:[UIColor grayColor] slider:&_widthSlider valueLabel:&_widthValueLabel minValue:0 maxValue:100 atY:yOffset];

        // For Rectangle and Ellipse, add Fill color controls
        if (_settingsType == RDAnnotSettingsTypeRectangle || _settingsType == RDAnnotSettingsTypeEllipse) {
            // Fill Red
            yOffset += [self createSliderRowWithTitle:@"Fill Red" icon:[UIColor redColor] slider:&_fillRedSlider valueLabel:&_fillRedValueLabel minValue:0 maxValue:255 atY:yOffset];
            // Fill Green
            yOffset += [self createSliderRowWithTitle:@"Fill Green" icon:[UIColor greenColor] slider:&_fillGreenSlider valueLabel:&_fillGreenValueLabel minValue:0 maxValue:255 atY:yOffset];
            // Fill Blue
            yOffset += [self createSliderRowWithTitle:@"Fill Blue" icon:[UIColor blueColor] slider:&_fillBlueSlider valueLabel:&_fillBlueValueLabel minValue:0 maxValue:255 atY:yOffset];
            // Fill Opacity
            yOffset += [self createSliderRowWithTitle:@"Fill Opacity" icon:[UIColor blackColor] slider:&_fillOpacitySlider valueLabel:&_fillOpacityValueLabel minValue:0 maxValue:1 atY:yOffset];
        }
    }
    
    // Buttons
    CGFloat buttonY = yOffset + 10;
    UIButton *okButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [okButton setTitle:@"OK" forState:UIControlStateNormal];
    okButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [okButton addTarget:self action:@selector(okButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    okButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_containerView addSubview:okButton];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelButton setTitle:@"Annulla" forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_containerView addSubview:cancelButton];
    [okButton setTitleColor:RD_COLOR forState:UIControlStateNormal];
    [okButton setTitleColor:RD_COLOR forState:UIControlStateHighlighted];
    [okButton setTitleColor:RD_COLOR forState:UIControlStateSelected];
    okButton.tintColor = RD_COLOR;
    [cancelButton setTitleColor:RD_COLOR forState:UIControlStateNormal];
    [cancelButton setTitleColor:RD_COLOR forState:UIControlStateHighlighted];
    [cancelButton setTitleColor:RD_COLOR forState:UIControlStateSelected];
    cancelButton.tintColor = RD_COLOR;
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        [_containerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_containerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_containerView.widthAnchor constraintEqualToConstant:320],
        [_containerView.heightAnchor constraintEqualToConstant:buttonY + 50],
        
        [titleLabel.topAnchor constraintEqualToAnchor:_containerView.topAnchor constant:15],
        [titleLabel.leadingAnchor constraintEqualToAnchor:_containerView.leadingAnchor constant:20],
        [titleLabel.trailingAnchor constraintEqualToAnchor:_containerView.trailingAnchor constant:-20],
        
        [_previewView.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:10],
        [_previewView.leadingAnchor constraintEqualToAnchor:_containerView.leadingAnchor constant:20],
        [_previewView.trailingAnchor constraintEqualToAnchor:_containerView.trailingAnchor constant:-20],
        [_previewView.heightAnchor constraintEqualToConstant:40],
        
        [okButton.leadingAnchor constraintEqualToAnchor:_containerView.leadingAnchor constant:20],
        [okButton.bottomAnchor constraintEqualToAnchor:_containerView.bottomAnchor constant:-15],
        [okButton.widthAnchor constraintEqualToConstant:100],
        
        [cancelButton.trailingAnchor constraintEqualToAnchor:_containerView.trailingAnchor constant:-20],
        [cancelButton.bottomAnchor constraintEqualToAnchor:_containerView.bottomAnchor constant:-15],
        [cancelButton.widthAnchor constraintEqualToConstant:100]
    ]];
}

- (CGFloat)createSliderRowWithTitle:(NSString *)title icon:(UIColor *)iconColor slider:(UISlider * __strong *)slider valueLabel:(UILabel * __strong *)valueLabel minValue:(CGFloat)minValue maxValue:(CGFloat)maxValue atY:(CGFloat)yOffset {
    // Icon view: use a straight line for Width, colored boxes for others
    UIView *iconView;
    if ([title isEqualToString:@"Width"]) {
        RDLineIconView *lineIcon = [[RDLineIconView alloc] init];
        lineIcon.backgroundColor = [UIColor whiteColor];
        lineIcon.layer.cornerRadius = 4;
        lineIcon.layer.borderWidth = 1;
        lineIcon.layer.borderColor = [UIColor lightGrayColor].CGColor;
        iconView = lineIcon;
    } else {
        UIView *box = [[UIView alloc] init];
        box.backgroundColor = iconColor;
        box.layer.cornerRadius = 4;
        box.layer.borderWidth = 1;
        box.layer.borderColor = [UIColor lightGrayColor].CGColor;
        iconView = box;
    }
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [_containerView addSubview:iconView];
    
    // Slider
    *slider = [[UISlider alloc] init];
    (*slider).minimumValue = minValue;
    (*slider).maximumValue = maxValue;
    [(*slider) addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    (*slider).translatesAutoresizingMaskIntoConstraints = NO;
    [_containerView addSubview:*slider];
    
    // Value label
    *valueLabel = [[UILabel alloc] init];
    (*valueLabel).font = [UIFont systemFontOfSize:14];
    (*valueLabel).textAlignment = NSTextAlignmentRight;
    (*valueLabel).translatesAutoresizingMaskIntoConstraints = NO;
    [_containerView addSubview:*valueLabel];
    
    // Layout
    [NSLayoutConstraint activateConstraints:@[
        [iconView.leadingAnchor constraintEqualToAnchor:_containerView.leadingAnchor constant:20],
        [iconView.centerYAnchor constraintEqualToAnchor:(*slider).centerYAnchor],
        [iconView.widthAnchor constraintEqualToConstant:24],
        [iconView.heightAnchor constraintEqualToConstant:24],
        
        [(*slider).leadingAnchor constraintEqualToAnchor:iconView.trailingAnchor constant:12],
        [(*slider).trailingAnchor constraintEqualToAnchor:(*valueLabel).leadingAnchor constant:-12],
        [(*slider).topAnchor constraintEqualToAnchor:_containerView.topAnchor constant:yOffset],
        
        [(*valueLabel).trailingAnchor constraintEqualToAnchor:_containerView.trailingAnchor constant:-20],
        [(*valueLabel).centerYAnchor constraintEqualToAnchor:(*slider).centerYAnchor],
        [(*valueLabel).widthAnchor constraintEqualToConstant:40]
    ]];
    
    return 40;
}

- (void)loadCurrentSettings {
    if (_settingsType == RDAnnotSettingsTypeText) {
        _textColor = _annot ? [_annot getEditTextColor] : 0xFF000000;
        [self updateTextColorButton];
        
        _redSlider = nil; _greenSlider = nil; _blueSlider = nil; _opacitySlider = nil;
        _widthSlider = nil;
        return;
    }
    unsigned int color;
    float width;
    unsigned int fillColor = 0x00000000;
    switch (_settingsType) {
        case RDAnnotSettingsTypeLine:
        case RDAnnotSettingsTypeArrow:
            color = GLOBAL.g_line_color;
            width = GLOBAL.g_line_width;
            break;
        case RDAnnotSettingsTypeRectangle:
            color = GLOBAL.g_rect_color;
            width = GLOBAL.g_rect_width;
            fillColor = GLOBAL.g_rect_fill_color;
            break;
        case RDAnnotSettingsTypeEllipse:
            color = GLOBAL.g_oval_color;
            width = GLOBAL.g_oval_width;
            fillColor = GLOBAL.g_oval_fill_color;
            break;
        default:
            color = 0xFF000000; width = 1;
            break;
    }
    unsigned int red = (color >> 16) & 0xFF;
    unsigned int green = ((color >> 8) & 0xFF);
    unsigned int blue = (color & 0xFF);
    unsigned int alpha = ((color >> 24) & 0xFF);
    _redSlider.value = red;
    _greenSlider.value = green;
    _blueSlider.value = blue;
    _opacitySlider.value = alpha / 255.0; // Display as 0-1
    _widthSlider.value = width;

    if (_settingsType == RDAnnotSettingsTypeRectangle || _settingsType == RDAnnotSettingsTypeEllipse) {
        unsigned int fr = (fillColor >> 16) & 0xFF;
        unsigned int fg = (fillColor >> 8) & 0xFF;
        unsigned int fb = (fillColor & 0xFF);
        unsigned int fa = (fillColor >> 24) & 0xFF;
        if (_fillRedSlider) _fillRedSlider.value = fr;
        if (_fillGreenSlider) _fillGreenSlider.value = fg;
        if (_fillBlueSlider) _fillBlueSlider.value = fb;
        if (_fillOpacitySlider) _fillOpacitySlider.value = fa / 255.0;
    }
    [self updateLabels];
    [self updatePreview];
}

- (void)sliderValueChanged:(UISlider *)slider {
    [self updateLabels];
    [self updatePreview];
}

- (void)updateLabels {
    if (_settingsType == RDAnnotSettingsTypeText) {
        return;
    }
    _redValueLabel.text = [NSString stringWithFormat:@"%.0f", _redSlider.value];
    _greenValueLabel.text = [NSString stringWithFormat:@"%.0f", _greenSlider.value];
    _blueValueLabel.text = [NSString stringWithFormat:@"%.0f", _blueSlider.value];
    _opacityValueLabel.text = [NSString stringWithFormat:@"%.1f", _opacitySlider.value];
    _widthValueLabel.text = [NSString stringWithFormat:@"%.1f", _widthSlider.value];

    if (_settingsType == RDAnnotSettingsTypeRectangle || _settingsType == RDAnnotSettingsTypeEllipse) {
        if (_fillRedValueLabel) _fillRedValueLabel.text = [NSString stringWithFormat:@"%.0f", _fillRedSlider.value];
        if (_fillGreenValueLabel) _fillGreenValueLabel.text = [NSString stringWithFormat:@"%.0f", _fillGreenSlider.value];
        if (_fillBlueValueLabel) _fillBlueValueLabel.text = [NSString stringWithFormat:@"%.0f", _fillBlueSlider.value];
        if (_fillOpacityValueLabel) _fillOpacityValueLabel.text = [NSString stringWithFormat:@"%.1f", _fillOpacitySlider.value];
    }
}

- (void)updatePreview {
    if (_settingsType == RDAnnotSettingsTypeText) {
        _previewView.backgroundColor = [UIColor whiteColor];
        return;
    }
    // Fill background
    UIColor *fillColor = [UIColor clearColor];
    if (_settingsType == RDAnnotSettingsTypeRectangle || _settingsType == RDAnnotSettingsTypeEllipse) {
        CGFloat fa = (_fillOpacitySlider ? _fillOpacitySlider.value : 0.0);
        fillColor = [UIColor colorWithRed:(_fillRedSlider.value/255.0)
                                     green:(_fillGreenSlider.value/255.0)
                                      blue:(_fillBlueSlider.value/255.0)
                                     alpha:fa];
    }
    _previewView.backgroundColor = fillColor;
    // Stroke border
    UIColor *strokeColor = [UIColor colorWithRed:_redSlider.value/255.0
                                           green:_greenSlider.value/255.0
                                            blue:_blueSlider.value/255.0
                                           alpha:_opacitySlider.value];
    _previewView.layer.borderColor = strokeColor.CGColor;
    _previewView.layer.borderWidth = MAX(1.0, _widthSlider.value / 4.0);
}

- (NSString *)getTitleForType {
    /*switch (_settingsType) {
        case RDAnnotSettingsTypeLine:
            return @"Line settings";
        case RDAnnotSettingsTypeArrow:
            return @"Arrow settings";
        case RDAnnotSettingsTypeRectangle:
            return @"Rectangle settings";
        case RDAnnotSettingsTypeEllipse:
            return @"Ellipse settings";
        case RDAnnotSettingsTypeText:
            return @"Floating Text settings";
    }*/
    return @"Annotation Settings";
}

- (void)okButtonTapped {
    if (_settingsType == RDAnnotSettingsTypeText) {
        if (_annot && _page) {
            [_page objsStart:NO];
            int colorRGB = (int)(_textColor & 0x00FFFFFF);
            [_annot setEditTextColor:colorRGB];
        }
    } else {
        // Build color in ARGB format
        unsigned int r = (unsigned int)_redSlider.value;
        unsigned int g = (unsigned int)_greenSlider.value;
        unsigned int b = (unsigned int)_blueSlider.value;
        unsigned int a = (unsigned int)(_opacitySlider.value * 255); // Convert back to 0-255
        
        unsigned int color = (a << 24) | (r << 16) | (g << 8) | b;
        float width = _widthSlider.value;
        // Build fill color (defaults to transparent)
        unsigned int fr = (unsigned int)(_fillRedSlider ? _fillRedSlider.value : 0);
        unsigned int fg = (unsigned int)(_fillGreenSlider ? _fillGreenSlider.value : 0);
        unsigned int fb = (unsigned int)(_fillBlueSlider ? _fillBlueSlider.value : 0);
        unsigned int fa = (unsigned int)((_fillOpacitySlider ? _fillOpacitySlider.value : 0) * 255);
        unsigned int fcolor = (fa << 24) | (fr << 16) | (fg << 8) | fb;
        
        // Save to global settings
        switch (_settingsType) {
            case RDAnnotSettingsTypeLine:
            case RDAnnotSettingsTypeArrow:
                GLOBAL.g_line_color = color;
                GLOBAL.g_line_width = width;
                [[NSUserDefaults standardUserDefaults] setInteger:color forKey:@"LineColor"];
                [[NSUserDefaults standardUserDefaults] setFloat:width forKey:@"LineWidth"];
                break;
            case RDAnnotSettingsTypeRectangle:
                GLOBAL.g_rect_color = color;
                GLOBAL.g_rect_width = width;
                GLOBAL.g_rect_fill_color = fcolor;
                [[NSUserDefaults standardUserDefaults] setInteger:color forKey:@"RectColor"];
                [[NSUserDefaults standardUserDefaults] setFloat:width forKey:@"RectWidth"];
                [[NSUserDefaults standardUserDefaults] setInteger:fcolor forKey:@"RectFillColor"];
                break;
            case RDAnnotSettingsTypeEllipse:
                GLOBAL.g_oval_color = color;
                GLOBAL.g_oval_width = width;
                GLOBAL.g_oval_fill_color = fcolor;
                [[NSUserDefaults standardUserDefaults] setInteger:color forKey:@"OvalColor"];
                [[NSUserDefaults standardUserDefaults] setFloat:width forKey:@"OvalWidth"];
                [[NSUserDefaults standardUserDefaults] setInteger:fcolor forKey:@"OvalFillColor"];
                break;
            default:
                break;
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    if (_onApply) {
        _onApply();
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)textColorButtonTapped {
    RDAnnotPickerViewController *colorPicker = [[RDAnnotPickerViewController alloc] initWithNibName:@"RDAnnotPickerViewController" bundle:nil];
    colorPicker.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    colorPicker.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    colorPicker.annotColor = _textColor;
    colorPicker.containerView = _containerView;
    
    _containerView.hidden = YES;
    __weak typeof(self) weakSelf = self;
    [self presentViewController:colorPicker animated:YES completion:^{
        // After viewDidLoad, override sliders with the actual text color
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        unsigned int c = strongSelf->_textColor;
        unsigned int r = (c >> 16) & 0xFF;
        unsigned int g = (c >> 8) & 0xFF;
        unsigned int b = c & 0xFF;
        colorPicker.redSlider.value = r;
        colorPicker.greenSlider.value = g;
        colorPicker.blueSlider.value = b;
        colorPicker.redTextField.text = [NSString stringWithFormat:@"%u", r];
        colorPicker.greenTextField.text = [NSString stringWithFormat:@"%u", g];
        colorPicker.blueTextField.text = [NSString stringWithFormat:@"%u", b];
        colorPicker.paletteView.backgroundColor = [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
        colorPicker.existingAlpha = 1.0;
        
        // Rewire OK button to capture color back
        [colorPicker.dismissButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [colorPicker.dismissButton addTarget:strongSelf action:@selector(colorPickerDidSelectColor:) forControlEvents:UIControlEventTouchUpInside];
    }];
}

- (void)colorPickerDidSelectColor:(UIButton *)sender {
    RDAnnotPickerViewController *colorPicker = (RDAnnotPickerViewController *)self.presentedViewController;
    if (colorPicker) {
        unsigned int red = (unsigned int)colorPicker.redSlider.value;
        unsigned int green = (unsigned int)colorPicker.greenSlider.value;
        unsigned int blue = (unsigned int)colorPicker.blueSlider.value;
        
        _textColor = 0xFF000000 | (red << 16) | (green << 8) | blue;
        [self updateTextColorButton];
        
        _containerView.hidden = NO;
        [colorPicker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)updateTextColorButton {
    unsigned int red = (_textColor >> 16) & 0xFF;
    unsigned int green = (_textColor >> 8) & 0xFF;
    unsigned int blue = _textColor & 0xFF;
    
    UIColor *color = [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
    _textColorButton.backgroundColor = color;
}

@end
