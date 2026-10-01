//
//  MoreViewController.m
//  PDFViewer
//
//  Created by Radaee on 12-12-9.
//  Copyright (c) 2012年 Radaee. All rights reserved.
//

#import "MoreViewController.h"
#import "RDVGlobal.h"

#define SUPPORT_EMAIL @"support@radaeepdf.com"
#define WEBSITE_URL @"https://www.radaeepdf.com"

@implementation MoreViewController
@synthesize partitationTableView;
@synthesize partitationTableViewCell;

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
    NSString *title = [[NSString alloc] initWithFormat:NSLocalizedString(@"More", @"Localizable")];
    self.title = title;
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect boundsc = [[UIScreen mainScreen] bounds];
    int cwidth = boundsc.size.width;
    int cheight = boundsc.size.height;

    self.partitationTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, cwidth, cheight - 100) style:UITableViewStyleGrouped];
    self.partitationTableView.delegate = self;
    self.partitationTableView.dataSource = self;
    self.partitationTableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.partitationTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.partitationTableView.frame = self.view.bounds;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.parentViewController.view sizeToFit];
    [self.partitationTableViewCell sizeToFit];
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"About", @"Localizable");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1)
    {
        NSString *urlString = [NSString stringWithFormat:@"mailto:%@", SUPPORT_EMAIL];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString] options:@{} completionHandler:nil];
    }
    else if (indexPath.row == 2)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:WEBSITE_URL] options:@{} completionHandler:nil];
    }
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"MoreCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.imageView.tintColor = RD_COLOR;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    switch (indexPath.row)
    {
        case 0:
        {
            NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
            // The SDK itself exposes no safe runtime version accessor (Global_getVersion()
            // crashes - see docs/release_history_ios.txt for why it's avoided here); keep
            // this in sync with the top entry of that changelog when the library is updated.
            NSString *sdkVersion = @"3.57";
            cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Version %@ (SDK %@)", @"Localizable"), version, sdkVersion];
            cell.imageView.image = [[UIImage systemImageNamed:@"info.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case 1:
        {
            cell.textLabel.text = NSLocalizedString(@"Contact Support", @"Localizable");
            cell.imageView.image = [[UIImage systemImageNamed:@"envelope"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case 2:
        {
            cell.textLabel.text = NSLocalizedString(@"Visit www.radaeepdf.com", @"Localizable");
            cell.imageView.image = [[UIImage systemImageNamed:@"globe"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        default:
            break;
    }
    return cell;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)isPortrait
{
    return ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait ||
            [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown);
}
-(void)performWillRotateOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    CGRect rect =[[UIScreen mainScreen]bounds];
    if ([self isPortrait])
    {
        if (rect.size.height < rect.size.width) {

            float height = rect.size.height;
            rect.size.height = rect.size.width;
            rect.size.width = height;
        }
    }
    else
    {
        if (rect.size.height > rect.size.width) {
            float height = rect.size.height;
            rect.size.height = rect.size.width;
            rect.size.width = height;
        }
    }
    [self.view setFrame:rect];
    [self.view sizeThatFits:rect.size];

}
@end
