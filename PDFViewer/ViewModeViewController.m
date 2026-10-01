//
//  ViewModeViewController.m
//  PDFViewer
//
//  Created by Radaee on 13-1-8.
//  Copyright 2013年 Radaee. All rights reserved.
//

#import "ViewModeViewController.h"
#import "RDVGlobal.h"
@implementation ViewModeViewController

@synthesize partitationTableView;
@synthesize partitationTableViewCell;
@synthesize dicData;
@synthesize arrayData;

static int  currentIndex=0;

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
    // Do any additional setup after loading the view from its nib.
    self.title = NSLocalizedString(@"View Mode", @"Localizable");
    CGRect boundsc = [[UIScreen mainScreen]bounds];
    int cwidth = boundsc.size.width;
    int cheight = boundsc.size.height;
    
    //GEAR
    //setting moved in ViewWillAppear
    self.partitationTableView = [[UITableView alloc]initWithFrame:CGRectMake(0,0,cwidth, cheight) style:UITableViewStyleGrouped];
    self.partitationTableView.delegate =self;
    self.partitationTableView.dataSource = self;
    self.partitationTableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    [self.view addSubview:self.partitationTableView];
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *plistURL = [bundle URLForResource:@"ViewModeList" withExtension:@"plist"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfURL:plistURL];
    self.dicData = dictionary;
    NSArray *array = [self.dicData allKeys];
    self.arrayData = array;
    
}

//GEAR
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    GLOBAL.g_render_mode = [[NSUserDefaults standardUserDefaults] integerForKey:@"ViewMode"];
    currentIndex = GLOBAL.g_render_mode;
    GLOBAL.g_dark_mode = [[NSUserDefaults standardUserDefaults] boolForKey:@"DarkMode"];

    [self.partitationTableView reloadData];

    self.partitationTableView.frame = self.view.bounds;
}
//END

- (void)updateSwitchDarkMode:(id)sender
{
    UISwitch *switchView = (UISwitch *)sender;
    GLOBAL.g_dark_mode = [switchView isOn];
    [[NSUserDefaults standardUserDefaults] setBool:GLOBAL.g_dark_mode forKey:@"DarkMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.arrayData count] + 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }
    NSString *stringDataKey = [self.arrayData objectAtIndex:section - 1];
    NSArray *arraySection = [self.dicData objectForKey:stringDataKey];
    return [arraySection count];
}

-(UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return UITableViewCellAccessoryNone;
    }
    if(indexPath.row == currentIndex)
    {
        return UITableViewCellAccessoryCheckmark;
    }
    else{
        return UITableViewCellAccessoryNone;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow]animated:YES];
    if (indexPath.section == 0) {
        return;
    }
    if(indexPath.row == GLOBAL.g_render_mode)
    {
        return;
    }
    NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:currentIndex inSection:0];
    UITableViewCell *cell =[tableView cellForRowAtIndexPath:indexPath];
    
    GLOBAL.g_render_mode = indexPath.row;
    [[NSUserDefaults standardUserDefaults] setInteger:GLOBAL.g_render_mode forKey:@"ViewMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if(cell.accessoryType==UITableViewCellAccessoryCheckmark)
        
    {
        cell.accessoryType=UITableViewCellAccessoryNone;
    }
    else
    {
        cell.accessoryType=UITableViewCellAccessoryCheckmark;
    }
    UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:oldIndexPath];
    if(oldCell.accessoryType==UITableViewCellAccessoryCheckmark)
        
    {
        oldCell.accessoryType=UITableViewCellAccessoryNone;
    }
    else
    {
        oldCell.accessoryType=UITableViewCellAccessoryCheckmark;
    }
    currentIndex = indexPath.row;
    
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = [indexPath section];
    NSInteger row = [indexPath row];

    if (section == 0) {
        static NSString *darkModePartitation = @"darkModePartitation";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:darkModePartitation];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:darkModePartitation];
        }
        cell.textLabel.text = NSLocalizedString(@"Dark Mode", @"Localizable");
        UISwitch *switchView = [[UISwitch alloc] init];
        [switchView setOn:GLOBAL.g_dark_mode];
        [switchView addTarget:self action:@selector(updateSwitchDarkMode:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = switchView;
        return cell;
    }

    NSString *key =[self.arrayData objectAtIndex:section - 1];
    NSArray *arraySection = [self.dicData objectForKey:key];

    static NSString *partitation = @"partitation";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:partitation];

    if(cell == nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:partitation];

    }
    cell.textLabel.text = [arraySection objectAtIndex:row];
    cell.accessoryType = (indexPath.row == currentIndex) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"Appearance", @"Localizable");
    }
    NSString *key = [self.arrayData objectAtIndex:section - 1];
    return key;
}

@end
