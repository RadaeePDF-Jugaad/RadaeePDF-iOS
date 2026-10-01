//
//  RDFileListViewController.h
//  PDFViewer
//
//  File list dialog similar to TOC
//

#import <UIKit/UIKit.h>
#import "RDVGlobal.h"

NS_ASSUME_NONNULL_BEGIN

// define the protocol for the delegate
@protocol RDFileListDelegate
// define protocol functions that can be used in any class using this delegate
- (void)didSelectFile:(NSString * _Nullable)filePath fileName:(NSString * _Nullable)fileName;
@end;

@interface RDFileListViewController : UITableViewController

@property (nonatomic, weak) id<RDFileListDelegate> delegate;
@property (nonatomic, strong) NSString *currentDirectory;

@end

NS_ASSUME_NONNULL_END
