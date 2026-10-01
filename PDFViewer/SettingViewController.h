//
//  SettingViewController.h
//  PDFViewer
//
//  Created by Radaee on 12-12-9.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UnderLineViewController.h"
#import "StrikeoutViewController.h"
#import "LineMarkViewController.h"
#import "ViewModeViewController.h"
#import "InkColorViewController.h"
#import "RectColorViewController.h"
#import "HighlightColorViewController.h"
#import "OvalColorViewController.h"
#import "LineColorViewController.h"
#import "RDLoPDFViewController.h"

@interface SettingViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    UnderLineViewController *underlineColor;
    StrikeoutViewController  *strikeColorSet;
    LineMarkViewController *lineWidthSet;
    ViewModeViewController *viewModeSet;
    InkColorViewController *inkColorSet;
    RectColorViewController *rectColorSet;
    HighlightColorViewController *highlightColor;
    OvalColorViewController *ovalColor;
    LineColorViewController *lineColorSet;

    UIButton *button;
    NSUserDefaults *userDefaults;
   
}
- (IBAction) updateSwitchScreenAwake:(id) sender;
- (IBAction) updateSwitchShowOutlineSidebar:(id) sender;
- (IBAction) updateCaseSensitive:(id) sender;
- (IBAction) updateMatchWholeWord:(id) sender;

@property(strong,retain)UITableView *partitationTableView;
@property(strong,retain)UITableViewCell *partitationTableViewCell;
@property(strong,retain)NSDictionary *dicData;
@property(strong,retain)NSArray *arrayData;
- (BOOL)isPortrait;
//GEAR
- (void)saveSettings;
//END
@end
