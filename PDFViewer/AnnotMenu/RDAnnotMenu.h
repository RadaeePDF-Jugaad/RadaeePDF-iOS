//
//  RDAnnotMenu.h
//  PDFViewer
//
//  Lightweight two-button annotation menu (Delete, Settings)
//

#import <UIKit/UIKit.h>
@class RDPDFAnnot;

typedef NS_ENUM(NSInteger, RDAnnotMenuAction) {
    RDAnnotMenuActionDelete = 0,
    RDAnnotMenuActionSettings = 1,
    RDAnnotMenuActionIncreaseFont = 2,
    RDAnnotMenuActionDecreaseFont = 3
};

@interface RDAnnotMenu : UIView

- (instancetype)initWithAnnot:(RDPDFAnnot *)annot
                      atPoint:(CGPoint)pointInView
                     callback:(void (^)(RDAnnotMenuAction action))callback;

@end
