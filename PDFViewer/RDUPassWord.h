//
//  RDUPassWord.h
//  PDFViewer
//
//  Created by radaee on 13-2-1.
//  Copyright (c) 2013年 _Radaee. All rights reserved.
//

#import <UIKit/UIKit.h>

// UIAlertView is unavailable for UIScene based applications (iOS 13+), so this
// wraps a password-prompt UIAlertController while keeping the old UIAlertView-style
// API (initWithTitle:..., show, textFieldAtIndex:) so existing callers/delegates
// (-alertView:clickedButtonAtIndex:) don't need to change.
@interface RDUPassWord : NSObject
@property(nonatomic, weak) id delegate;
@property(nonatomic, strong) UITextField* uPwd;    // 密码输入框

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;
- (void)show;
- (UITextField *)textFieldAtIndex:(NSInteger)textFieldIndex;
@end
