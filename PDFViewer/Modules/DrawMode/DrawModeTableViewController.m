//
//  DrawModeTableViewController.m
//  PDFViewer
//
//  Created by Emanuele Bortolami on 29/12/17.
//

#import "DrawModeTableViewController.h"

@interface DrawModeTableViewController ()

@end

@implementation DrawModeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set row height to 60 to make the menu taller and avoid scrolling
    self.tableView.rowHeight = 60;
    
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
#ifdef SIGNATURE_ENABLED
    return 8;
#else
    return 7;
#endif
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
            cell.textLabel.text = NSLocalizedString(@"Line", nil);
            cell.imageView.image = (_rowImage) ? _rowImage : [UIImage systemImageNamed:@"line.diagonal"];
            break;
        }
        case 1:
        {
            cell.textLabel.text = NSLocalizedString(@"Arrow", nil);
            cell.imageView.image = (_arrowImage) ? _arrowImage : [UIImage systemImageNamed:@"arrow.up.right"];
            break;
        }
        case 2:
        {
            cell.textLabel.text = NSLocalizedString(@"Rect", nil);
            cell.imageView.image = (_rectImage) ? _rectImage : [UIImage systemImageNamed:@"rectangle"];
            break;
        }
        case 3:
        {
            cell.textLabel.text = NSLocalizedString(@"Ellipse", nil);
            cell.imageView.image = (_ellipseImage) ? _ellipseImage : [UIImage systemImageNamed:@"circle"];
            break;
        }
        case 4:
        {
            cell.textLabel.text = NSLocalizedString(@"Note", nil);
            cell.imageView.image = (_noteImage) ? _noteImage : [UIImage systemImageNamed:@"note.text"];
            break;
        }
        case 5:
        {
            cell.textLabel.text = NSLocalizedString(@"Text", nil);
            cell.imageView.image = (_floatingTextImage) ? _floatingTextImage : [UIImage systemImageNamed:@"textformat"];
            break;
        }
        case 6:
        {
            cell.textLabel.text = NSLocalizedString(@"Ink", nil);
            cell.imageView.image = (_inkImage) ? _inkImage : [UIImage systemImageNamed:@"scribble"];
            break;
        }
#ifdef SIGNATURE_ENABLED
        case 7:
        {
            cell.textLabel.text = NSLocalizedString(@"Signature", nil);
            cell.imageView.image = (_signatureImage) ? _signatureImage : [UIImage systemImageNamed:@"signature"];
            break;
        }
#endif
        default:
            break;
    }
    
    cell.imageView.image = [cell.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.tintColor = self.tintColor;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_delegate didSelectDrawMode:(int)indexPath.row];
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
