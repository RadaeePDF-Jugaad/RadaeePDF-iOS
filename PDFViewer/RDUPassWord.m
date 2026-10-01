//
//  RDUPassWord.m
//  PDFViewer
//
//  Created by radaee on 13-2-1.
//  Copyright (c) 2013年 Radaee. All rights reserved.
//

#import "RDUPassWord.h"

@interface RDUPassWord ()
@property (nonatomic, copy) NSString *alertTitle;
@property (nonatomic, copy) NSString *alertMessage;
@property (nonatomic, copy) NSString *cancelButtonTitle;
@property (nonatomic, copy) NSString *otherButtonTitle;
@end

@implementation RDUPassWord

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.alertTitle = title;
        self.alertMessage = message;
        self.cancelButtonTitle = cancelButtonTitle;
        self.otherButtonTitle = otherButtonTitles;

        self.uPwd = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 240, 30)];
        NSString *password = [[NSString alloc] initWithFormat:NSLocalizedString(@"PassWord", @"Localizable")];
        self.uPwd.placeholder = password;
        self.uPwd.secureTextEntry = YES;
    }
    return self;
}

- (UITextField *)textFieldAtIndex:(NSInteger)textFieldIndex {
    return self.uPwd;
}

- (void)show {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.alertTitle
                                                                     message:self.alertMessage
                                                              preferredStyle:UIAlertControllerStyleAlert];

    NSString *placeholder = self.uPwd.placeholder;
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = placeholder;
        textField.secureTextEntry = YES;
        self.uPwd = textField;
    }];

    [alert addAction:[UIAlertAction actionWithTitle:self.cancelButtonTitle
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
        [self notifyDelegateWithButtonIndex:0];
    }]];
    if (self.otherButtonTitle.length > 0) {
        [alert addAction:[UIAlertAction actionWithTitle:self.otherButtonTitle
                                                   style:UIAlertActionStyleCancel
                                                 handler:^(UIAlertAction *action) {
            [self notifyDelegateWithButtonIndex:1];
        }]];
    }

    UIViewController *presenter = [RDUPassWord topViewController];
    [presenter presentViewController:alert animated:YES completion:nil];
}

- (void)notifyDelegateWithButtonIndex:(NSInteger)buttonIndex {
    if ([self.delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
        [self.delegate alertView:(UIAlertView *)self clickedButtonAtIndex:buttonIndex];
    }
}

+ (UIViewController *)topViewController {
    UIWindow *keyWindow = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
    }
    UIViewController *top = keyWindow.rootViewController;
    while (top.presentedViewController) {
        top = top.presentedViewController;
    }
    return top;
}

@end
