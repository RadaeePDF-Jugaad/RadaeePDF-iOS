//
//  RDAnnotResizeView.h
//  PDFViewer
//

#import <UIKit/UIKit.h>

/// Callback when the user finishes a move or resize drag.
/// newFrame is the final frame of the text area (in the parent's coordinate space).
typedef void(^RDAnnotResizeCompletion)(CGRect newFrame);

/// A transparent overlay that draws a black selection border and 8 resize handles
/// around a target rect. Handles pan gestures for move and resize.
@interface RDAnnotResizeView : UIView

/// Initialize with the target content rect (text area frame within the container).
/// The completion block fires with the new rect when the user finishes dragging.
- (instancetype)initWithTextFrame:(CGRect)textFrame completion:(RDAnnotResizeCompletion)completion;

/// Update the text frame (e.g. after external layout changes).
- (void)updateTextFrame:(CGRect)textFrame;

@end
