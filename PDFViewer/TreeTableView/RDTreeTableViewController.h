//
//  RDTreeTableViewController.h
//  PDFViewer
//
//  Created by Emanuele Bortolami on 31/05/2019.
//

#import <UIKit/UIKit.h>
#import "RDTreeTableViewCell.h"
#import "PDFObjc.h"
#import "RDVGlobal.h"
#import "RDUtils.h"

NS_ASSUME_NONNULL_BEGIN

// define the protocol for the delegate
@protocol RDTreeTableDelegate
// define protocol functions that can be used in any class using this delegate
- (void)didSelectDest:(OUTLINE_ITEM *)item;
@end;

@interface RDTreeTableViewController : UITableViewController

@property (strong, nonatomic) RDPDFDoc *doc;
@property (nonatomic, weak) id<RDTreeTableDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
