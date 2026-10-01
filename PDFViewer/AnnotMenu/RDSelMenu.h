//
//  RDSelMenu.h
//  PDFViewer
//
//  Floating icon menu shown after a text selection (Highlight, Underline, Strikeout)
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, RDSelMenuAction) {
    RDSelMenuActionHighlight = 0,
    RDSelMenuActionUnderline = 1,
    RDSelMenuActionStrikeout = 2
};

@interface RDSelMenu : UIView

- (instancetype)initAtPoint:(CGPoint)pointInView
                    callback:(void (^)(RDSelMenuAction action))callback;

@end
