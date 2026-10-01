//
//  FTSSearchTableViewController.h
//  MobileReplica
//
//  Created by Emanuele Bortolami on 18/09/17.
//  Copyright © 2017 GEAR.it S.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FTSSearchTableViewCell.h"

@protocol FTSSearchResultDelegate <NSObject>

@optional
- (void)didSelectOccurrence:(FTSOccurrence *)occurrence;
@optional
- (void)didFinishSearching;

@end

@interface FTSSearchTableViewController : UITableViewController

@property (strong, nonatomic) NSString *docId;
@property (strong, nonatomic) NSMutableArray *items;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) id<FTSSearchResultDelegate> delegate;

@end
