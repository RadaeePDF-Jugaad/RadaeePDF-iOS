//
//  RDSceneDelegate.m
//  PDFViewer
//

#import "RDSceneDelegate.h"
#import "PDFObjc.h"
#import "RDVGlobal.h"

@implementation RDSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions
{
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    UIWindowScene *windowScene = (UIWindowScene *)scene;

    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    if ([self isPortrait]) {
        NSLog(@"portrait");
    }
    else
    {
        NSLog(@"landscape");
    }
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    NSMutableArray *localControllesArray = [[NSMutableArray alloc]initWithCapacity:4];
    RDFileTableController *ctl = [[RDFileTableController alloc] initWithNibName:@"RDFileTableController" bundle:nil];
    self.navController = [[UINavigationController alloc] initWithRootViewController:ctl];
    self.navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    [localControllesArray addObject:self.navController];

    BookMarkViewController *bmctl=[[BookMarkViewController alloc]initWithNibName:@"BookMarkViewController" bundle:nil];
    self.navController = [[UINavigationController alloc]initWithRootViewController:bmctl];
    self.navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    NSString *title1 =[[NSString alloc]initWithFormat:NSLocalizedString(@"Marks", @"Localizable")];

    UITabBarItem *item1 = [[UITabBarItem alloc]initWithTitle:title1 image:[UIImage systemImageNamed:@"bookmark"] tag:1 ];
    bmctl.tabBarItem = item1;
    [localControllesArray addObject:self.navController];

    SettingViewController *settingCtl = [[SettingViewController alloc]initWithNibName:@"SettingViewController" bundle:nil];
    self.navController = [[UINavigationController alloc]initWithRootViewController:settingCtl];
    self.navController.navigationBar.barStyle = UIBarStyleBlackOpaque;

    NSString *title2 =[[NSString alloc]initWithFormat:NSLocalizedString(@"Setting", @"Localizable")];

    UITabBarItem *item2 = [[UITabBarItem alloc]initWithTitle:title2 image:[UIImage systemImageNamed:@"gearshape"] tag:2 ];
    settingCtl.tabBarItem = item2;
    [localControllesArray addObject:self.navController];

    NSString *title4 =[[NSString alloc]initWithFormat:NSLocalizedString(@"More", @"Localizable")];
    // Do any additional setup after loading the view from its nib.
    MoreViewController *moreCtl = [[MoreViewController alloc]initWithNibName:@"MoreViewController" bundle:nil];
    self.navController = [[UINavigationController alloc]initWithRootViewController:moreCtl];
    self.navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    UITabBarItem *item3 = [[UITabBarItem alloc]initWithTitle:title4 image:[UIImage systemImageNamed:@"info.circle"] tag:3 ];
    moreCtl.tabBarItem = item3;
    [localControllesArray addObject:self.navController];

    self.tabBarController = [[UITabBarController alloc]init];
    self.tabBarController.viewControllers = localControllesArray;

    // Preloads keyboard so there's no lag on initial keyboard appearance.
    UITextField *lagFreeField = [[UITextField alloc] init];
    [self.window addSubview:lagFreeField];
    [lagFreeField becomeFirstResponder];
    [lagFreeField resignFirstResponder];
    [lagFreeField removeFromSuperview];

    [self customizeAppearance];

    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
}

- (void)customizeAppearance
{
    [[UINavigationBar appearance] setTintColor:RD_COLOR];
    [[UITabBar appearance] setTintColor:RD_COLOR];
    [[UIToolbar appearance] setTintColor:RD_COLOR];
}

- (void)sceneDidDisconnect:(UIScene *)scene
{
}

- (void)sceneDidBecomeActive:(UIScene *)scene
{
}

- (void)sceneWillResignActive:(UIScene *)scene
{
}

- (void)sceneWillEnterForeground:(UIScene *)scene
{
}

- (void)sceneDidEnterBackground:(UIScene *)scene
{
}

#pragma mark - Device orientation
- (BOOL)isPortrait
{
    return ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait ||
            [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown);
}
@end
