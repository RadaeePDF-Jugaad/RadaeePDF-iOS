//
//  RDAnnotResizeView.m
//  PDFViewer
//

#import "RDAnnotResizeView.h"

#define HANDLE_SIZE 10.0f
#define HANDLE_HALF (HANDLE_SIZE / 2.0f)
#define HIT_SLOP 16.0f
#define MIN_DIMENSION 30.0f

typedef NS_ENUM(NSInteger, RDResizeNode) {
    RDResizeNodeNone = -1,
    RDResizeNodeMove = 0,
    RDResizeNodeTopLeft = 1,
    RDResizeNodeTopMid = 2,
    RDResizeNodeTopRight = 3,
    RDResizeNodeMidRight = 4,
    RDResizeNodeBottomRight = 5,
    RDResizeNodeBottomMid = 6,
    RDResizeNodeBottomLeft = 7,
    RDResizeNodeMidLeft = 8,
};

@interface RDAnnotResizeView () <UIGestureRecognizerDelegate>
{
    CGRect _textFrame;     // rect of the text area in parent coords
    RDResizeNode _activeNode;
    CGPoint _touchStart;
    CGRect _frameAtStart;
    RDAnnotResizeCompletion _completion;
    UIPanGestureRecognizer *_panGesture;
}
@end

@implementation RDAnnotResizeView

- (instancetype)initWithTextFrame:(CGRect)textFrame completion:(RDAnnotResizeCompletion)completion
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _textFrame = textFrame;
        _completion = [completion copy];
        _activeNode = RDResizeNodeNone;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        self.opaque = NO;
        
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        _panGesture.delegate = self;
        _panGesture.maximumNumberOfTouches = 1;
        [self addGestureRecognizer:_panGesture];
    }
    return self;
}

- (void)updateTextFrame:(CGRect)textFrame
{
    _textFrame = textFrame;
    [self setNeedsDisplay];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    // Draw selection border
    CGContextSetLineWidth(ctx, 1.5f);
    CGContextSetStrokeColorWithColor(ctx, [UIColor blackColor].CGColor);
    CGContextStrokeRect(ctx, _textFrame);

    // Draw 8 resize handles
    CGFloat l = CGRectGetMinX(_textFrame);
    CGFloat t = CGRectGetMinY(_textFrame);
    CGFloat r = CGRectGetMaxX(_textFrame);
    CGFloat b = CGRectGetMaxY(_textFrame);
    CGFloat mx = (l + r) * 0.5f;
    CGFloat my = (t + b) * 0.5f;

    [self drawHandle:ctx atX:l  y:t];
    [self drawHandle:ctx atX:mx y:t];
    [self drawHandle:ctx atX:r  y:t];
    [self drawHandle:ctx atX:r  y:my];
    [self drawHandle:ctx atX:r  y:b];
    [self drawHandle:ctx atX:mx y:b];
    [self drawHandle:ctx atX:l  y:b];
    [self drawHandle:ctx atX:l  y:my];
}

- (void)drawHandle:(CGContextRef)ctx atX:(CGFloat)x y:(CGFloat)y
{
    CGRect handleRect = CGRectMake(x - HANDLE_HALF, y - HANDLE_HALF, HANDLE_SIZE, HANDLE_SIZE);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, handleRect);
    CGContextSetStrokeColorWithColor(ctx, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(ctx, 1.0f);
    CGContextStrokeRect(ctx, handleRect);
}

#pragma mark - Hit Testing

- (RDResizeNode)handleNodeAtPoint:(CGPoint)pt
{
    CGFloat l = CGRectGetMinX(_textFrame);
    CGFloat t = CGRectGetMinY(_textFrame);
    CGFloat r = CGRectGetMaxX(_textFrame);
    CGFloat b = CGRectGetMaxY(_textFrame);
    CGFloat mx = (l + r) * 0.5f;
    CGFloat my = (t + b) * 0.5f;

    if ([self point:pt hitsHandleAt:CGPointMake(l, t)])   return RDResizeNodeTopLeft;
    if ([self point:pt hitsHandleAt:CGPointMake(mx, t)])  return RDResizeNodeTopMid;
    if ([self point:pt hitsHandleAt:CGPointMake(r, t)])   return RDResizeNodeTopRight;
    if ([self point:pt hitsHandleAt:CGPointMake(r, my)])  return RDResizeNodeMidRight;
    if ([self point:pt hitsHandleAt:CGPointMake(r, b)])   return RDResizeNodeBottomRight;
    if ([self point:pt hitsHandleAt:CGPointMake(mx, b)])  return RDResizeNodeBottomMid;
    if ([self point:pt hitsHandleAt:CGPointMake(l, b)])   return RDResizeNodeBottomLeft;
    if ([self point:pt hitsHandleAt:CGPointMake(l, my)])  return RDResizeNodeMidLeft;

    return RDResizeNodeNone;
}

- (BOOL)point:(CGPoint)pt hitsHandleAt:(CGPoint)handle
{
    CGRect hitArea = CGRectMake(handle.x - HIT_SLOP, handle.y - HIT_SLOP, HIT_SLOP * 2, HIT_SLOP * 2);
    return CGRectContainsPoint(hitArea, pt);
}

#pragma mark - Gesture Recognizer

- (void)handlePan:(UIPanGestureRecognizer *)gesture
{
    CGPoint pt = [gesture locationInView:self];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        _activeNode = [self handleNodeAtPoint:pt];
        if (_activeNode == RDResizeNodeNone && [self isOnBorderMargin:pt]) {
            _activeNode = RDResizeNodeMove;
        }
        if (_activeNode == RDResizeNodeNone) {
            gesture.enabled = NO;
            gesture.enabled = YES;
            return;
        }
        _touchStart = pt;
        _frameAtStart = _textFrame;
    }
    else if (gesture.state == UIGestureRecognizerStateChanged) {
        if (_activeNode == RDResizeNodeNone) return;
        CGFloat dx = pt.x - _touchStart.x;
        CGFloat dy = pt.y - _touchStart.y;
        
        CGRect newFrame = _frameAtStart;
        switch (_activeNode) {
            case RDResizeNodeMove:
                newFrame.origin.x += dx;
                newFrame.origin.y += dy;
                break;
            case RDResizeNodeTopLeft:
                newFrame.origin.x += dx;
                newFrame.origin.y += dy;
                newFrame.size.width -= dx;
                newFrame.size.height -= dy;
                break;
            case RDResizeNodeTopMid:
                newFrame.origin.y += dy;
                newFrame.size.height -= dy;
                break;
            case RDResizeNodeTopRight:
                newFrame.size.width += dx;
                newFrame.origin.y += dy;
                newFrame.size.height -= dy;
                break;
            case RDResizeNodeMidRight:
                newFrame.size.width += dx;
                break;
            case RDResizeNodeBottomRight:
                newFrame.size.width += dx;
                newFrame.size.height += dy;
                break;
            case RDResizeNodeBottomMid:
                newFrame.size.height += dy;
                break;
            case RDResizeNodeBottomLeft:
                newFrame.origin.x += dx;
                newFrame.size.width -= dx;
                newFrame.size.height += dy;
                break;
            case RDResizeNodeMidLeft:
                newFrame.origin.x += dx;
                newFrame.size.width -= dx;
                break;
            default:
                break;
        }
        
        // Enforce minimum size
        if (newFrame.size.width < MIN_DIMENSION) {
            if (_activeNode == RDResizeNodeTopLeft || _activeNode == RDResizeNodeBottomLeft || _activeNode == RDResizeNodeMidLeft) {
                newFrame.origin.x = CGRectGetMaxX(_frameAtStart) - MIN_DIMENSION;
            }
            newFrame.size.width = MIN_DIMENSION;
        }
        if (newFrame.size.height < MIN_DIMENSION) {
            if (_activeNode == RDResizeNodeTopLeft || _activeNode == RDResizeNodeTopMid || _activeNode == RDResizeNodeTopRight) {
                newFrame.origin.y = CGRectGetMaxY(_frameAtStart) - MIN_DIMENSION;
            }
            newFrame.size.height = MIN_DIMENSION;
        }
        
        _textFrame = newFrame;
        [self setNeedsDisplay];
    }
    else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        if (gesture.state == UIGestureRecognizerStateCancelled) {
            _textFrame = _frameAtStart;
            [self setNeedsDisplay];
        } else {
            if (_activeNode != RDResizeNodeNone && !CGRectEqualToRect(_frameAtStart, _textFrame)) {
                if (_completion) {
                    _completion(_textFrame);
                }
            }
        }
        _activeNode = RDResizeNodeNone;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer != _panGesture) return YES;
    CGPoint pt = [gestureRecognizer locationInView:self];
    // Allow if on a handle or in the border margin
    if ([self handleNodeAtPoint:pt] != RDResizeNodeNone) return YES;
    if ([self isOnBorderMargin:pt]) return YES;
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

#pragma mark - Border Margin Detection

- (BOOL)isOnBorderMargin:(CGPoint)pt
{
    // A margin strip around the text frame border (outside the inner content area)
    CGFloat margin = HIT_SLOP;
    CGRect outerRect = CGRectInset(_textFrame, -margin, -margin);
    CGRect innerRect = CGRectInset(_textFrame, margin, margin);
    // Point is on the border margin if it's inside outer but outside inner
    return CGRectContainsPoint(outerRect, pt) && !CGRectContainsPoint(innerRect, pt);
}

#pragma mark - Point Inside

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    // Intercept touches on resize handles
    if ([self handleNodeAtPoint:point] != RDResizeNodeNone) return YES;
    // Intercept touches on the border margin (for move)
    if ([self isOnBorderMargin:point]) return YES;
    // Let touches inside the text area pass through for text editing
    return NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    // If touch is on a handle or border margin, this view handles it
    if ([self handleNodeAtPoint:point] != RDResizeNodeNone) return self;
    if ([self isOnBorderMargin:point]) return self;
    // Otherwise pass through
    return nil;
}

@end
