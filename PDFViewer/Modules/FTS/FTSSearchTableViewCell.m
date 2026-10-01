//
//  FTSSearchTableViewCell.m
//  MobileReplica
//
//  Created by Emanuele Bortolami on 18/09/17.
//  Copyright © 2017 GEAR.it S.r.l. All rights reserved.
//

#import "FTSSearchTableViewCell.h"
#import "RDVGlobal.h"
#import "RDUtils.h"

@implementation FTSSearchTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.snippetLabel.font = RD_FONT(NORMAL_FONT_SIZE);
    self.snippetLabel.textColor = RD_TEXT_BLACK;
    self.numberLabel.font = RD_FONT_BOLD(NORMAL_FONT_SIZE);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureCellWithOccurrence:(FTSOccurrence *)occurrence
{
    self.snippetLabel.attributedText = [self boldSearchedString:occurrence.text];
    self.numberLabel.text = [NSString stringWithFormat:@"%i", (occurrence.page + 1)];
}

- (NSAttributedString *)boldSearchedString:(NSString *)string
{
    // FTS Search
    NSString *term = [[FTSSearchManager sharedInstance] getFTSTerm];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName: RD_FONT(NORMAL_FONT_SIZE), NSForegroundColorAttributeName: RD_TEXT_BLACK}];
    if (term.length > 0) {
        NSRange range = [string rangeOfString:term options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound && range.length > 0) {
            [attrString addAttribute:NSFontAttributeName value:RD_FONT_BOLD(NORMAL_FONT_SIZE) range:range];
        }
    }
    return attrString;
}

@end
