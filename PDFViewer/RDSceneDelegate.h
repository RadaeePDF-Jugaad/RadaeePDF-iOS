//
//  RDSceneDelegate.h
//  PDFViewer
//

#import <UIKit/UIKit.h>
#import "RDFileTableController.h"
#import "BookMarkViewController.h"
#import "SettingViewController.h"
#import "MoreViewController.h"

@interface RDSceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navController;
@property (strong, nonatomic) RDFileTableController *viewController;
@property (strong, nonatomic) UITabBarController *tabBarController;

- (BOOL)isPortrait;
@end
