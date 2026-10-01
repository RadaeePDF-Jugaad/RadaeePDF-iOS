//
//  ViewModeTableViewController.m
//  Radaee-Cordova
//
//  Created by Emanuele Bortolami on 24/06/16.
//
//

#import "ViewModeTableViewController.h"
#import "RDVGlobal.h"

@interface ViewModeTableViewController ()

@end

@implementation ViewModeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    switch (indexPath.row) {
        case 0:
        {
            cell.textLabel.text = NSLocalizedString(@"Vertical", nil);
            cell.imageView.image = [[UIImage systemImageNamed:@"arrow.up.arrow.down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        }
        case 1:
        {
            cell.textLabel.text = NSLocalizedString(@"Horizontal", nil);
            cell.imageView.image = [[UIImage systemImageNamed:@"rectangle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        }
        case 2:
        {
            cell.textLabel.text = NSLocalizedString(@"Single Page", nil);
            cell.imageView.image = [[UIImage systemImageNamed:@"rectangle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        }
        case 3:
        {
            cell.textLabel.text = NSLocalizedString(@"Double Page", nil);
            cell.imageView.image = [[UIImage systemImageNamed:@"rectangle.split.2x1"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            break;
        }
        case 4:
        {
            cell.textLabel.text = NSLocalizedString(@"Dark Mode", nil);
            cell.imageView.image = [[UIImage systemImageNamed:@"moon.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UISwitch *switchView = [[UISwitch alloc] init];
            [switchView setOn:GLOBAL.g_dark_mode];
            [switchView addTarget:self action:@selector(updateDarkModeSwitch:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchView;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        default:
            break;
    }
    cell.imageView.tintColor = RD_COLOR;

    return cell;
}

- (void)updateDarkModeSwitch:(UISwitch *)sender
{
    GLOBAL.g_dark_mode = sender.isOn;
    [[NSUserDefaults standardUserDefaults] setBool:GLOBAL.g_dark_mode forKey:@"DarkMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [_delegate refreshReaderForDarkModeChange];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 4) {
        return;
    }
    [_delegate setReaderViewMode:(int)indexPath.row];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here, for example:
    // Create the next view controller.
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
