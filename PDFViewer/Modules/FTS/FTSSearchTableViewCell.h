//
//  FTSSearchTableViewCell.h
//  MobileReplica
//
//  Created by Emanuele Bortolami on 18/09/17.
//  Copyright © 2017 GEAR.it S.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FTSSearchManager.h"

@interface FTSSearchTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *snippetLabel;
@property (strong, nonatomic) IBOutlet UILabel *numberLabel;

- (void)configureCellWithOccurrence:(FTSOccurrence *)occurrence;

@end
