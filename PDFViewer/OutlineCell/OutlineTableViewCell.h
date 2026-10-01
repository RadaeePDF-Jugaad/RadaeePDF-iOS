//
//  OutlineTableViewCell.h
//  PDFViewer
//
//  Created by Federico Vellani on 28/05/2019.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OutlineTableViewCell : UITableViewCell
@property (strong, nonatomic) UILabel *indexLabel;
@property (strong, nonatomic) UILabel *detailLabel;
@property (strong, nonatomic) UIView *cellView;

- (void)initCellWithSize:(CGSize)size;
- (void)editCellWithScale:(float)scale;
- (void)prepareForReuse;
@end

NS_ASSUME_NONNULL_END
