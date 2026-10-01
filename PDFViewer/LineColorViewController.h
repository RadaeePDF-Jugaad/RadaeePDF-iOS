//
//  LineColorViewController.h
//  PDFViewer
//

#import <UIKit/UIKit.h>

@interface LineColorViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property(strong,retain)UITableView *partitationTableView;
@property(strong,retain)UITableViewCell *partitationTableViewCell;
@property(strong,retain)NSDictionary *dicData;
@property(strong,retain)NSArray *arrayData;
@end
