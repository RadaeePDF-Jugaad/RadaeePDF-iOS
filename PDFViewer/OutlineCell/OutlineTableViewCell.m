//
//  OutlineTableViewCell.m
//  PDFViewer
//
//  Created by Federico Vellani on 28/05/2019.
//

#import "OutlineTableViewCell.h"
#import "RDVGlobal.h"
#import "RDUtils.h"

@implementation OutlineTableViewCell

- (void)initCellWithSize:(CGSize)size {
    
    _cellView = [[UIView alloc] initWithFrame:CGRectMake(2, 2, size.width - 4, size.height - 4)];
    _indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _cellView.frame.size.width, _cellView.frame.size.height/2)];
    _detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _indexLabel.frame.size.height, _cellView.frame.size.width, _cellView.frame.size.height/2)];
    //_cellView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    _cellView.layer.cornerRadius = 5.0f;
    
    _indexLabel.textAlignment = _detailLabel.textAlignment = NSTextAlignmentCenter;
    _indexLabel.adjustsFontSizeToFitWidth = _detailLabel.adjustsFontSizeToFitWidth = YES;
    _indexLabel.lineBreakMode = _detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _indexLabel.numberOfLines = _detailLabel.lineBreakMode = 0;
    _indexLabel.textColor = RD_COLOR;
    [_indexLabel setFont:RD_FONT_BOLD(BIG_FONT_SIZE)];
    
    _detailLabel.numberOfLines = 0;
    [_detailLabel setFont:RD_FONT(SMALL_FONT_SIZE)];
    _detailLabel.textColor = RD_TEXT_GRAY;
    
    [_cellView addSubview:_indexLabel];
    [_cellView addSubview:_detailLabel];
    
    _cellView.backgroundColor = [UIColor whiteColor];
    
    self.backgroundColor = [RD_BACKGROUND_GRAY colorWithAlphaComponent:.8];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self addSubview:_cellView];
}

- (void)editCellWithScale:(float)scale
{
    _cellView.transform = CGAffineTransformMakeScale(scale, scale);
    [_indexLabel setFont:RD_FONT_BOLD(BIG_FONT_SIZE*scale)];
    [_detailLabel setFont:RD_FONT(SMALL_FONT_SIZE*scale)];
    [UIView animateWithDuration:0.05 delay:0.05 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _cellView.transform = CGAffineTransformIdentity;
        [_indexLabel setFont:RD_FONT_BOLD(BIG_FONT_SIZE)];
        [_detailLabel setFont:RD_FONT(SMALL_FONT_SIZE)];
    } completion:nil];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

-(void)prepareForReuse{
    [super prepareForReuse];
    // Then Reset here back to default values that you want.
    _indexLabel.text = @"";
    _detailLabel.text = @"";
}

@end
