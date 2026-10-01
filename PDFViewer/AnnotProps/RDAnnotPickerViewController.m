//
//  RDAnnotPickerViewController.m
//  PDFViewer
//
//  Port of reference color picker used by UIColorBtn
//

#import "RDAnnotPickerViewController.h"
#import "RDVGlobal.h"
#import "RDUtils.h"

@interface RDAnnotPickerViewController ()

@end

@implementation RDAnnotPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Respect existing alpha for both stroke and fill colors
    _paletteView.backgroundColor = UIColorFromRGB([self getAnnotColor]);

    CGFloat red = 0;
    CGFloat green = 0;
    CGFloat blue = 0;
    CGFloat alpha = 0;
    [_paletteView.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
    self.existingAlpha = alpha;
    
    _redSlider.value = red * 255;
    _greenSlider.value = green * 255;
    _blueSlider.value = blue * 255;
    _redTextField.text = [NSString stringWithFormat:@"%i", (int)_redSlider.value];
    _greenTextField.text = [NSString stringWithFormat:@"%i", (int)_greenSlider.value];
    _blueTextField.text = [NSString stringWithFormat:@"%i", (int)_blueSlider.value];
    [_cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    UIFont *labelFont = RD_FONT(NORMAL_FONT_SIZE);
    UIFont *textFieldFont = RD_FONT(NORMAL_FONT_SIZE);
    _redTextField.font = textFieldFont;
    _greenTextField.font = textFieldFont;
    _blueTextField.font = textFieldFont;
    UIFont *buttonFont = RD_FONT(NORMAL_FONT_SIZE);
    _cancelButton.titleLabel.font = buttonFont;
    [_cancelButton setTitleColor:RD_COLOR forState:UIControlStateNormal];
    [_cancelButton setTitleColor:RD_COLOR forState:UIControlStateHighlighted];
    [_cancelButton setTitleColor:RD_COLOR forState:UIControlStateSelected];
    _cancelButton.tintColor = RD_COLOR;
    [_dismissButton setTitle:NSLocalizedString(@"OK", nil) forState:UIControlStateNormal];
    _dismissButton.titleLabel.font = buttonFont;
    [_dismissButton setTitleColor:RD_COLOR forState:UIControlStateNormal];
    [_dismissButton setTitleColor:RD_COLOR forState:UIControlStateHighlighted];
    [_dismissButton setTitleColor:RD_COLOR forState:UIControlStateSelected];
    _dismissButton.tintColor = RD_COLOR;
    UIColor *sliderTint = RD_COLOR;
    _redSlider.minimumTrackTintColor = sliderTint;
    _greenSlider.minimumTrackTintColor = sliderTint;
    _blueSlider.minimumTrackTintColor = sliderTint;
    
    [_redSlider addTarget:self action:@selector(onSliderValueChange:) forControlEvents:UIControlEventValueChanged];
    [_greenSlider addTarget:self action:@selector(onSliderValueChange:) forControlEvents:UIControlEventValueChanged];
    [_blueSlider addTarget:self action:@selector(onSliderValueChange:) forControlEvents:UIControlEventValueChanged];
    
    [_redTextField addTarget:self action:@selector(onTextFieldTextChanged:) forControlEvents:UIControlEventEditingDidEnd];
    [_greenTextField addTarget:self action:@selector(onTextFieldTextChanged:) forControlEvents:UIControlEventEditingDidEnd];
    [_blueTextField addTarget:self action:@selector(onTextFieldTextChanged:) forControlEvents:UIControlEventEditingDidEnd];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    [[_pickerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor] setActive:YES];
    [[_pickerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor] setActive:YES];
    
    _paletteView.layer.shadowColor = [RDUtils radaeeBlackColor].CGColor;
    
    // Add rounded corners to picker view (iOS default styling)
    _pickerView.layer.cornerRadius = 10.0;
    _pickerView.layer.masksToBounds = YES;

    // Hide and collapse legacy alpha controls in the picker
    if (_alphaSlider) {
        UIView *alphaContainer = _alphaSlider.superview ? _alphaSlider.superview.superview : nil;
        if (alphaContainer) {
            alphaContainer.hidden = YES;
            for (NSLayoutConstraint *c in alphaContainer.constraints) {
                if (c.firstAttribute == NSLayoutAttributeHeight) {
                    c.constant = 0.0;
                }
            }
        }
        if (_alphaTextField) _alphaTextField.hidden = YES;
    }
}

-(void)dismissKeyboard
{
    [_redTextField resignFirstResponder];
    [_greenTextField resignFirstResponder];
    [_blueTextField resignFirstResponder];
}

-(void)onSliderValueChange:(UISlider*)slider
{
    [self updatePaletteViewColor];
    _redTextField.text = [NSString stringWithFormat:@"%i", (int)_redSlider.value];
    _greenTextField.text = [NSString stringWithFormat:@"%i", (int)_greenSlider.value];
    _blueTextField.text = [NSString stringWithFormat:@"%i", (int)_blueSlider.value];
}

-(void)onTextFieldTextChanged:(UITextField *)textField
{
    NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *inStringSet = [NSCharacterSet characterSetWithCharactersInString:textField.text];
    if ([alphaNums isSupersetOfSet:inStringSet])
    {
        if ([textField.text floatValue] <= 255.0) {
            _redSlider.value = [_redTextField.text floatValue];
            _greenSlider.value = [_greenTextField.text floatValue];
            _blueSlider.value = [_blueTextField.text floatValue];
        } else {
            _redSlider.value = (textField == _redTextField) ? 255 : [_redTextField.text floatValue];
            _greenSlider.value = (textField == _greenTextField) ? 255 : [_greenTextField.text floatValue];
            _blueSlider.value = (textField == _blueTextField) ? 255 : [_blueTextField.text floatValue];
            textField.text = @"255";
        }
        [self updatePaletteViewColor];
    }
}

- (void)updatePaletteViewColor
{
    _paletteView.backgroundColor = [UIColor colorWithRed:_redSlider.value/255 green:_greenSlider.value/255 blue:_blueSlider.value/255 alpha:self.existingAlpha];
}

- (IBAction)dismissPicker:(id)sender
{
    unsigned int color;
    color = [self hexFromColor:_paletteView.backgroundColor];
    
    if (!_colorBtn) {
        switch (_annotType) {
            case 1:
                GLOBAL.g_line_color = color;
                break;
            case 3:
                GLOBAL.g_rect_color = color;
                break;
            case 4:
                GLOBAL.g_oval_color = color;
                break;
            case 7:
                GLOBAL.g_line_color = color;
                break;
            case 8:
                GLOBAL.g_line_color = color;
                break;
            default:
                GLOBAL.g_ink_color = color;
                break;
        }
    } else {
        [_colorBtn setColor:color :YES];
    }
    
    // Unhide container view
    if (_containerView) {
        _containerView.hidden = NO;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelPicker:(id)sender
{
    // Unhide container view
    if (_containerView) {
        _containerView.hidden = NO;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (uint)getAnnotColor
{
    uint rgbValue;
    if (!_colorBtn) {
        switch (_annotType) {
            case 1:
                rgbValue = GLOBAL.g_line_color;
                break;
            case 3:
                rgbValue = GLOBAL.g_rect_color;
                break;
            case 4:
                rgbValue = GLOBAL.g_oval_color;
                break;
            case 7:
                rgbValue = GLOBAL.g_line_color;
                break;
            case 8:
                rgbValue = GLOBAL.g_line_color;
                break;
            default:
                rgbValue = GLOBAL.g_ink_color;
                break;
        }
    } else {
        rgbValue = _colorBtn.color;
    }
    return rgbValue;
}
    
- (uint)hexFromColor:(UIColor *)color {
    uint m_color = 0xFF000000|((int)_redSlider.value << 16)|((int)_greenSlider.value << 8)|(int)_blueSlider.value;
    uint ia = 255 * self.existingAlpha;
    m_color = (m_color&0xFFFFFF)|(ia << 24);
    return m_color;
}

@end
