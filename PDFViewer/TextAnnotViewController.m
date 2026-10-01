//
//  TextAnnotViewController.m
//  PDFViewer
//
//  Created by strong on 13-7-11.
//
//

#import "TextAnnotViewController.h"

@interface TextAnnotViewController ()

@end

@implementation TextAnnotViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *title = @"Annotation settings";
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.text = title;
    titleLabel.font = RD_TITLE_FONT(BIG_FONT_SIZE);
    titleLabel.textColor = RD_TEXT_GRAY;
    [titleLabel sizeToFit];
    self.navigationItem.titleView = titleLabel;
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithImage:[[UIImage systemImageNamed:@"chevron.backward"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(cancelTextAnnot)];
    cancelBtn.tintColor = RD_COLOR;
    
    UIBarButtonItem *settingsBtn = [[UIBarButtonItem alloc] initWithImage:[[UIImage systemImageNamed:@"gearshape"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(openAnnotSettings)];
    settingsBtn.tintColor = RD_COLOR;
    
    UIBarButtonItem *deleteBtn = [[UIBarButtonItem alloc] initWithImage:[[UIImage systemImageNamed:@"trash"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(deleteTextAnnot)];
    deleteBtn.tintColor = RD_COLOR;
    
    self.navigationItem.leftBarButtonItem = cancelBtn;
    self.navigationItem.rightBarButtonItems = @[settingsBtn, deleteBtn];
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// The subject field becomes first responder as soon as this screen appears, so
// the keyboard is effectively always up here. Track its real height (rather
// than a fixed guess) so the Content field and OK button sit snugly above it.
- (void)keyboardWillShow:(NSNotification *)notification
{
    if (!textView || !saveButton) return;
    CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat keyboardTop = [self.view convertRect:keyboardFrame fromView:nil].origin.y;

    CGFloat newButtonY = keyboardTop - saveButton.frame.size.height - 10;
    CGFloat newTextViewBottom = newButtonY - 10;
    CGFloat newTextViewHeight = newTextViewBottom - textView.frame.origin.y;
    if (newTextViewHeight < 40) return;

    [UIView animateWithDuration:duration animations:^{
        CGRect tvFrame = self->textView.frame;
        tvFrame.size.height = newTextViewHeight;
        self->textView.frame = tvFrame;

        CGRect btnFrame = self->saveButton.frame;
        btnFrame.origin.y = newButtonY;
        self->saveButton.frame = btnFrame;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if (!textView || !saveButton) return;
    NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat newTextViewBottom = self.view.bounds.size.height - 70.0f;

    [UIView animateWithDuration:duration animations:^{
        CGRect tvFrame = self->textView.frame;
        tvFrame.size.height = newTextViewBottom - tvFrame.origin.y;
        self->textView.frame = tvFrame;

        CGRect btnFrame = self->saveButton.frame;
        btnFrame.origin.y = CGRectGetMaxY(self->textView.frame) + 10;
        self->saveButton.frame = btnFrame;
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    CGFloat topOffset = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height + 15;
    UILabel *subjectLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, topOffset, 90, 50)];
    subjectLabel.text = @"Subject:";
    subjectLabel.textAlignment = NSTextAlignmentCenter;
    
    UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, subjectLabel.frame.origin.y + subjectLabel.frame.size.height + 5, 90, 50)];
    contentLabel.text = @"Content:";
    contentLabel.textAlignment = NSTextAlignmentCenter;
    
    textField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(subjectLabel.frame), subjectLabel.frame.origin.y, self.view.bounds.size.width  - (subjectLabel.frame.size.width + 10), 44)];
    textField.backgroundColor = [UIColor whiteColor];
    textField.font = RD_FONT(NORMAL_FONT_SIZE);
    UIView *leftPad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 44)];
    textField.leftView = leftPad;
    textField.leftViewMode = UITextFieldViewModeAlways;
    
    CGFloat bottomPadding = 70.0f;
    textView = [[UITextView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(contentLabel.frame), contentLabel.frame.origin.y, self.view.bounds.size.width - (contentLabel.frame.size.width + 10), self.view.bounds.size.height - contentLabel.frame.origin.y - bottomPadding)];
    textView.font = RD_FONT(NORMAL_FONT_SIZE);
    
    [self.view addSubview:subjectLabel];
    [self.view addSubview:contentLabel];
    [self.view addSubview:textField];
    [self.view addSubview:textView];
    
    if (!saveButton) {
        saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [saveButton setTitle:NSLocalizedString(@"Ok", nil) forState:UIControlStateNormal];
        saveButton.tintColor = RD_COLOR;
        saveButton.titleLabel.font = RD_FONT_BOLD(NORMAL_FONT_SIZE);
        saveButton.backgroundColor = [UIColor whiteColor];
        saveButton.layer.cornerRadius = 8.0f;
        saveButton.contentEdgeInsets = UIEdgeInsetsMake(10, 20, 10, 20);
        UIImage *saveIcon = [[UIImage systemImageNamed:@"checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        if (saveIcon) {
            [saveButton setImage:saveIcon forState:UIControlStateNormal];
            saveButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
            saveButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);
            saveButton.contentEdgeInsets = UIEdgeInsetsMake(10, 20, 10, 24);
        }
        [saveButton addTarget:self action:@selector(saveTextAnnot) forControlEvents:UIControlEventTouchUpInside];
    }
    CGFloat buttonWidth = 120.0f;
    CGFloat buttonHeight = 44.0f;
    saveButton.frame = CGRectMake(self.view.bounds.size.width - buttonWidth - 20,
                                  CGRectGetMaxY(textView.frame) + 10,
                                  buttonWidth,
                                  buttonHeight);
    saveButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self.view addSubview:saveButton];
    
    textField.text = _subject;
    textView.text = _text;
    
    if (self.readOnly)
    {
        textView.userInteractionEnabled = NO;
        textField.userInteractionEnabled = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.readOnly) {
        [textField becomeFirstResponder];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(BOOL)cancelTextAnnot
{
    if(m_delegate && !self.readOnly)
    {
        [m_delegate OnSaveTextAnnot:@"" subject:@""];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
    
    return NO;
}

-(void)saveTextAnnot
{
    if(m_delegate && !self.readOnly)
    {
        [m_delegate OnSaveTextAnnot:textView.text subject:textField.text];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}
-(void)deleteTextAnnot
{
    if(m_delegate && !self.readOnly)
    {
        [m_delegate OnDeleteTextAnnot];
    }
    [self dismissViewControllerAnimated:YES completion:^{}];
}

-(void)openAnnotSettings
{
    if(m_delegate)
    {
        [m_delegate OnSettingsForAnnot];
    }
}
-(void)setDelegate:(id<saveTextAnnotDelegate>)delegate
{
    m_delegate = delegate;
}

@end
