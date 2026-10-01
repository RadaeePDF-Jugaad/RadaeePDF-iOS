//
//  BookmarkTableViewController.m
//  RDPDFViewLib
//
//  Created by Emanuele Bortolami on 17/07/15.
//  Copyright (c) 2015 gear.it. All rights reserved.
//

#import "BookmarkTableViewController.h"

@interface BookmarkTableViewController ()

@end

@implementation BookmarkTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UIImage *backImage = [[UIImage systemImageNamed:@"chevron.backward"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:backImage style:UIBarButtonItemStylePlain target:self action:@selector(closeView)];
    backButton.tintColor = RD_COLOR;
    self.navigationItem.leftBarButtonItem = backButton;
    
    // Set table view appearance
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = RD_BACKGROUND_GRAY;
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    // Set navigation bar title appearance
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.text = NSLocalizedString(@"Bookmarks", nil);
    UIFont *titleFont = RD_TITLE_FONT(BIG_FONT_SIZE);
    titleLabel.font = titleFont ? titleFont : [UIFont systemFontOfSize:BIG_FONT_SIZE weight:UIFontWeightRegular];
    titleLabel.textColor = RD_TEXT_GRAY;
    [titleLabel sizeToFit];
    self.navigationItem.titleView = titleLabel;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)closeView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // Create and add delete button
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        deleteButton.frame = CGRectMake(0, 0, 40, 40);
        UIImage *deleteIcon = [[UIImage systemImageNamed:@"bookmark.slash"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [deleteButton setImage:deleteIcon forState:UIControlStateNormal];
        deleteButton.tintColor = RD_COLOR;
        [deleteButton addTarget:self action:@selector(deleteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        deleteButton.tag = indexPath.row;
        cell.accessoryView = deleteButton;
        
        // Set left alignment but add padding to center the text
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
    }
    
    // Update delete button tag
    if (cell.accessoryView && [cell.accessoryView isKindOfClass:[UIButton class]]) {
        UIButton *deleteButton = (UIButton *)cell.accessoryView;
        deleteButton.tag = indexPath.row;
    }
    
    NSArray *arr = [_items objectAtIndex:indexPath.row];
    
    int pageno = [[arr objectAtIndex:0] intValue];
    pageno++;
    
    cell.textLabel.text = [NSString stringWithFormat:@"Page: %i", pageno];
    UIFont *pageFont = RD_FONT(NORMAL_FONT_SIZE);
    cell.textLabel.font = pageFont ? pageFont : [UIFont systemFontOfSize:NORMAL_FONT_SIZE weight:UIFontWeightRegular];
    cell.textLabel.textColor = RD_TEXT_BLACK;
    cell.backgroundColor = [UIColor whiteColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *arr = [_items objectAtIndex:indexPath.row];
    int pageno = [[arr objectAtIndex:0] intValue];
    
    [_delegate didSelectItem:pageno];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Make each row a reasonable height so multiple bookmarks are visible
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0; // More reasonable height allowing 3-4 bookmarks visible at once
}

- (void)deleteButtonTapped:(UIButton *)sender {
    NSInteger row = sender.tag;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete Bookmark", nil)
                                                                   message:NSLocalizedString(@"Are you sure you want to delete this bookmark?", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil)
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * _Nonnull action) {
        [self performDeleteAtRow:row];
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:deleteAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performDeleteAtRow:(NSInteger)row {
    if (row < 0 || row >= _items.count) {
        return;
    }
    
    NSArray *row_item = [_items objectAtIndex:row];
    NSString *path = [row_item objectAtIndex:1];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:path error:nil];
    
    [_items removeObjectAtIndex:row];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.indentationLevel = 0;
    cell.indentationWidth = 0;
    cell.separatorInset = UIEdgeInsetsMake(0, 16.0, 0, 0);
    if (@available(iOS 11.0, *)) {
        cell.contentView.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(0, 0, 0, 0);
    }
}

// Swipe-to-delete is disabled in favor of explicit delete button

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
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
