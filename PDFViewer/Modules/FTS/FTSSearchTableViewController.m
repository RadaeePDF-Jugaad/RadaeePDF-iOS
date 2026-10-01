//
//  FTSSearchTableViewController.m
//  MobileReplica
//
//  Created by Emanuele Bortolami on 18/09/17.
//  Copyright © 2017 GEAR.it S.r.l. All rights reserved.
//

#import "FTSSearchTableViewController.h"

@interface FTSSearchTableViewController () <UISearchBarDelegate>

@end

@implementation FTSSearchTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"FTS Search", nil);
    
    _searchBar.delegate = self;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UISearchBar Delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // Minimum 4 characters
    if (searchBar.text.length <= 3) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"Enter at least 4 characters to start searching", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    [searchBar resignFirstResponder];
    
    //[SVProgressHUD showWithStatus:NSLocalizedString(@"search_wait_message", nil) maskType:SVProgressHUDMaskTypeGradient];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
        [[FTSSearchManager sharedInstance] searchInit:_docId]; // Filter using document id
        [[FTSSearchManager sharedInstance] searchText:searchBar.text success:^(NSMutableArray *occurrences) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //[SVProgressHUD dismiss];
                
                if (occurrences.count > 0) {
                    _items = occurrences;
                    [self.tableView reloadData];
                } else {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", nil) message:[NSString stringWithFormat:NSLocalizedString(@"No search results found for \'%@\'", nil), searchBar.text] preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                    [alert addAction:ok];
                    [self presentViewController:alert animated:YES completion:nil];
                }
                
                if ([_delegate respondsToSelector:@selector(didFinishSearching)]) {
                    [_delegate didFinishSearching];
                }
            });
        }];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _items.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *reusableIdentifier = @"FTSSearchTableViewCell";
    
    FTSSearchTableViewCell *cell = (FTSSearchTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FTSSearchTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    [cell configureCellWithOccurrence:(FTSOccurrence *)[_items objectAtIndex:indexPath.row]];
        
    return cell;
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


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if ([_delegate respondsToSelector:@selector(didSelectOccurrence:)]) {
        [[FTSSearchManager sharedInstance] setSelectedIndex:(int)indexPath.row];
        [_delegate didSelectOccurrence:[_items objectAtIndex:indexPath.row]];
    }
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
