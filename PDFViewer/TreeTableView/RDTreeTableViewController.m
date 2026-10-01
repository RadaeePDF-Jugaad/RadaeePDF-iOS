//
//  RDTreeTableViewController.m
//  PDFViewer
//
//  Created by Emanuele Bortolami on 31/05/2019.
//

#import "RDTreeTableViewController.h"

@interface RDTreeTableViewController () {

    NSMutableArray *items;
}

@end

@implementation RDTreeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    //self.title = NSLocalizedString(@"Table of contents", nil);
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.navigationController.navigationBar.bounds.size.height)];
    titleLabel.text = NSLocalizedString(@"Table of contents", nil);
    titleLabel.font = RD_TITLE_FONT(BIG_FONT_SIZE) ?: [UIFont systemFontOfSize:BIG_FONT_SIZE weight:UIFontWeightRegular];
    titleLabel.textColor = RD_TEXT_GRAY;
    self.navigationItem.titleView = titleLabel;
    
    UIImage *empty = [[UIImage alloc] init];
    //[self.navigationController.navigationBar setBackgroundImage:empty forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = empty;
    self.navigationController.navigationBar.tintColor = RD_COLOR;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.backgroundColor = [UIColor whiteColor];
   
    UIImage *backImage = [[UIImage systemImageNamed:@"chevron.backward"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:backImage style:UIBarButtonItemStylePlain target:self action:@selector(closeView)];
    backButton.tintColor = RD_COLOR;
    self.navigationItem.leftBarButtonItem = backButton;
    
    items = [NSMutableArray array];
    
    // Primo livello
    RDPDFOutline *root = [_doc rootOutline];
    while(root)
    {
        OUTLINE_ITEM *item = [self itemWithObject:root];
        item.level = 0;
        root = [root next];
        [items addObject:item];
    }
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.view.superview.layer.cornerRadius = 0;
}

- (OUTLINE_ITEM *)itemWithObject:(RDPDFOutline *)obj {
    OUTLINE_ITEM *outline_item = [[OUTLINE_ITEM alloc]init];
    outline_item.label = [obj label];
    outline_item.dest = [obj dest];
    outline_item.child = [obj child];
    return outline_item;
}

- (void)closeView {
    if (_delegate) {
        [_delegate didSelectDest:nil];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    RDTreeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[RDTreeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.outlineLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, tableView.frame.size.width - 60, 50)];
        cell.arrowImage = [[UIImageView alloc] initWithFrame:CGRectMake(20, 16, 18, 18)];
        [cell.arrowImage setImage:[[UIImage systemImageNamed:@"chevron.right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        cell.outlineLabel.font = RD_FONT(SMALL_FONT_SIZE);
        cell.arrowImage.tintColor = RD_COLOR;
        cell.outlineLabel.textColor = RD_TEXT_BLACK;
        cell.outlineLabel.numberOfLines = 0;
        cell.outlineLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.outlineLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [cell addSubview:cell.outlineLabel];
        [cell addSubview:cell.arrowImage];
        cell.backgroundColor = [UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    [cell setupWithItem:[items objectAtIndex:indexPath.row]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    OUTLINE_ITEM *selectedItem = (OUTLINE_ITEM *)[items objectAtIndex:indexPath.row];
    if ([selectedItem child]) {
        // Check if indexes are already saved (meaning the children are already shown)
        [self.tableView beginUpdates];
        if (selectedItem.childIndexes) {
            RDTreeTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            [cell resetArrow];
            [self closeChild:selectedItem atIndex:(int)indexPath.row];
        } else {
            RDTreeTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            [cell rotateArrow];
            [self openChild:selectedItem atIndex:(int)indexPath.row];
        }
        [self.tableView endUpdates];
    } else {
        if (_delegate) {
            [_delegate didSelectDest:selectedItem];
        }
    }
}

- (void)openChild:(OUTLINE_ITEM *)item atIndex:(int)index {
    RDPDFOutline *outline = [[items objectAtIndex:index] child];
    if (!outline) {
        return;
    }
    NSMutableArray *indexPaths = [NSMutableArray array];
    while(outline)
    {
        index++;
        OUTLINE_ITEM *child = [self itemWithObject:outline];
        child.level = item.level + 1;
        outline = [outline next];
        [items insertObject:child atIndex:index];
        [indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
    }
    
    if (indexPaths.count > 0) {
        item.childIndexes = indexPaths;
    }
    
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
}

- (void)closeChild:(OUTLINE_ITEM *)item atIndex:(int)index {
    int i = index + 1;
    NSMutableArray *indexPaths = [NSMutableArray array];
    while (i < items.count) {
        OUTLINE_ITEM *it = [items objectAtIndex:i];
        if (it.level > item.level) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        } else {
            break;
        }
        i++;
    }
    
    for (i = (int)indexPaths.count - 1; i >= 0; i--) {
        [items removeObjectAtIndex:[[indexPaths objectAtIndex:i] row]];
    }
    
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationBottom];
    item.childIndexes = nil;
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
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
