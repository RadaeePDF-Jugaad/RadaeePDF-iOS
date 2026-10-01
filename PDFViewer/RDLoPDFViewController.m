//
//  ViewController.m
//  RDPDFReader
//
//  Created by Radaee on 16/11/19.
//  Copyright © 2016年 radaee. All rights reserved.
//

#import "RDLoPDFViewController.h"
#import "RDAnnotSettingsViewController.h"
#import "OutLineViewController.h"
#import "RDToolBar.h"
#import "RDVGlobal.h"
#import "AnnotMenu/RDAnnotMenu.h"
#import "AnnotMenu/RDSelMenu.h"
#import "AnnotProps/DlgAnnotPropLine.h"
#import "AnnotProps/DlgAnnotPropComm.h"
#import "AnnotProps/DlgAnnotPropIcon.h"
#import "AnnotProps/PDFDialog.h"
#import "AnnotProps/PDFPopupCtrl.h"

#import "TextAnnotViewController.h"
#import <AVKit/AVKit.h>
#import "DrawModeTableViewController.h"
#import "RDMoreTableViewController.h"
#import "BookmarkTableViewController.h"
#import "RDAnnotListViewController.h"
#import "SignatureViewController.h"
#import "ViewModeTableViewController.h"
#import "RDFormManager.h"
#import "RDExtendedSearch.h"
#import "SearchResultTableViewController.h"
#import "OutlineTableViewCell.h"

#import "RDTreeTableViewController.h"
#import "FileList/RDFileListViewController.h"
#import "AnnotXFDFHelper/RDSeparateXFDFHelper.h"
#import "RDAnnotResizeView.h"

// Debug helper: find whichever view/control currently owns the keyboard,
// so keyboard-appearance logs can point at the actual first responder.
@interface UIResponder (RDFirstResponderDebug)
+ (nullable id)rd_currentFirstResponder;
@end

@implementation UIResponder (RDFirstResponderDebug)
static __weak id rd_currentFirstResponderRef;
+ (nullable id)rd_currentFirstResponder
{
    rd_currentFirstResponderRef = nil;
    [[UIApplication sharedApplication] sendAction:@selector(rd_captureFirstResponder:) to:nil from:nil forEvent:nil];
    return rd_currentFirstResponderRef;
}
- (void)rd_captureFirstResponder:(id)sender
{
    rd_currentFirstResponderRef = self;
}
@end

@interface RDSearchResultsOverlayViewController : UIViewController <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) SearchResultTableViewController *resultsController;
- (instancetype)initWithResultsController:(SearchResultTableViewController *)resultsController;
@end

@implementation RDSearchResultsOverlayViewController

- (instancetype)initWithResultsController:(SearchResultTableViewController *)resultsController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _resultsController = resultsController;
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundTap:)];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];

    self.containerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.layer.cornerRadius = 12.0;
    self.containerView.layer.masksToBounds = YES;
    [self.view addSubview:self.containerView];

    if (self.resultsController) {
        [self addChildViewController:self.resultsController];
        [self.containerView addSubview:self.resultsController.view];
        [self.resultsController didMoveToParentViewController:self];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        insets = self.view.safeAreaInsets;
    }

    CGFloat sideMargin = 16.0;
    CGFloat topBottomMargin = 90.0;
    CGFloat width = self.view.bounds.size.width - (sideMargin * 2.0);
    CGFloat height = self.view.bounds.size.height - insets.top - insets.bottom - (topBottomMargin * 2.0);
    CGFloat minHeight = 220.0;
    if (height < minHeight) {
        height = minHeight;
    }

    CGFloat originY = insets.top + topBottomMargin;
    CGFloat maxY = self.view.bounds.size.height - insets.bottom - topBottomMargin - height;
    if (originY < 0) originY = 0;
    if (originY > maxY) originY = MAX(insets.top, maxY);

    self.containerView.frame = CGRectMake(sideMargin, originY, width, height);
    self.resultsController.view.frame = self.containerView.bounds;
}

- (void)handleBackgroundTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) {
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint p = [touch locationInView:self.view];
    if (CGRectContainsPoint(self.containerView.frame, p)) {
        return NO;
    }
    return YES;
}

@end

#define SYS_VERSION [[[UIDevice currentDevice]systemVersion] floatValue]
#define THUMB_HEIGHT 99
#define OUTLINE_ROW_HEIGHT ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? 100 : 100
#define OUTLINE_WIDTH ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? 100 : 100
#define FAB_SIZE 50

@interface RDLoPDFViewController ()<UIPickerViewDataSource,UIPickerViewDelegate,UITextFieldDelegate,UIDocumentInteractionControllerDelegate,RDToolBarDelegate,DrawModeDelegate,RDMoreTableViewControllerDelegate, SignatureDelegate/*, ADVSignatureDelegate*/, ViewModeDelegate, BookmarkTableViewDelegate, RDAnnotListViewControllerDelegate, SearchResultViewControllerDelegate, saveTextAnnotDelegate, RDTreeTableDelegate, RDFileListDelegate>
{
    NSString *findString;
    RDToolBar *toolBar;
    UIToolbar *drawToolbar;
    UISearchBar* m_searchBar;
    UISlider *sliderBar;
    UILabel *pageNumLabel;
    BOOL b_findStart;
    BOOL m_bSel;
    BOOL statusBarHidden;
    BOOL isPrint;
    BOOL b_outline;
    BOOL b_noteAnnot;
    int pagecount;
    int pagenow;
    NSMutableArray *tempfiles;
    NSMutableArray *outlineItems;
    MPMoviePlayerViewController *mpvc;
    UIPickerView *pickerView;
    NSArray *pickViewArr;
    UIButton *confirmPickerBtn;
    UITextField *textFd;
    
    NSTimer *toolbarsTimer;
    
    RDSelMenu *selMenu;
    int selectItem;
    UIAlertController *moreItemsContainer;
    RDMoreTableViewController *moreTVContainer;
    BookmarkTableViewController *b;
    UIPopoverController *bookmarkPopover;
    CGPoint annotTapped;
    RDAnnotListViewController *annotListTV;
    BOOL alreadySelected;
    
    RDPDFAnnot *cachedAnnot;
    PDF_OBJ_REF cachedAnnotRef;
    int cachedAnnotPageIndex;
    int posx;
    int posy;
    // Sticky note placement (original tap) location in PDF space
    int noteTapPageIndex;
    float noteTapPdfX;
    float noteTapPdfY;
    RDAnnotMenu *annotMenu;
    
    int gridBackgroundColor;
    int gridElementHeight;
    int gridGap;
    int gridMode;
    int doubleTapZoomMode;
    
    int statusBarHeight;
    
    int fIndex;
    
    UIColor *toolbarColor;
    UIColor *toolbarTintColor;
    
    BOOL showSXToolbar;
    BOOL baseToolbarHiddenBeforeDraw;

    UILabel *sliderLabel;
    UIView *sliderLabelBackground;
    BOOL showThumb;
    
    UIButton *floatingButton;
    UIButton *toolIconButton;
    BOOL searchListPresentedModally;
    int currentDrawingMode; // -1=none, 0=line, 1=arrow, 2=rect, 3=ellipse
    BOOL noteDrawingMode; // YES when placing a single note
    BOOL textDrawingMode;
    
    NSString *currentPdfPath;
    NSString *currentDocumentId;
}
@end

@implementation RDLoPDFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    for (NSString *font in UIFont.familyNames) {
        NSArray *name = [UIFont fontNamesForFamilyName:font];
        NSLog(@"Familiy: %@ Font name: %@", font, name);
    }
    
    outlineItems = [NSMutableArray array];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBarsPosition) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }

 

    isPrint = NO;
    m_bSel = false;
    currentDrawingMode = -1;
    noteDrawingMode = NO;
    textDrawingMode = NO;
    cachedAnnotRef = 0;
    cachedAnnotPageIndex = -1;
    float width = [UIScreen mainScreen].bounds.size.width;
    pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 160, width, 60)];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    pickerView.backgroundColor = [UIColor lightGrayColor];
    pickerView.hidden = YES;
    [self.view addSubview:pickerView];
    [self.view bringSubviewToFront:pickerView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];

    // Debug: log every keyboard appearance while the reader is open, along with
    // whichever view actually requested it and the call stack that triggered it,
    // so an unexpected keyboard (e.g. from the "..." button) can be traced.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rd_logKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    confirmPickerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmPickerBtn.frame = CGRectMake(width - 60, pickerView.frame.origin.y - 40, 60, 40);
    [confirmPickerBtn setTitle:@"OK" forState:UIControlStateNormal];
    confirmPickerBtn.hidden = YES;
    [confirmPickerBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    confirmPickerBtn.backgroundColor = [UIColor clearColor];
    [confirmPickerBtn addTarget:self action:@selector(setComboselect) forControlEvents:UIControlEventTouchUpInside];
    confirmPickerBtn.hidden = YES;
    [self.view addSubview:confirmPickerBtn];
    
    textFd = [[UITextField alloc] init];
    textFd.delegate = self;
    [self.view addSubview:textFd];
    textFd.hidden = YES;
    
    [self createToolbarItems];
}
-(void)viewWillAppear:(BOOL)animated
{
    if (_delegate && [_delegate respondsToSelector:@selector(willShowReader)]) {
        [_delegate willShowReader];
    }
    
    [toolBar sizeToFit];
    b_findStart = NO;
    isPrint = NO;
    b_outline = NO;
    
    self.navigationController.navigationBarHidden = YES;
    
    [toolBar removeFromSuperview];
    
    [self refreshBarsPosition];
    
    [self.view addSubview:toolBar];
    
    [self toolBarStyle];
    
    if (!m_searchBar) {
        [self setImmersive:isImmersive];
    }

    toolBar.hidden = isImmersive;
    if (m_searchBar) {
        m_searchBar.hidden = isImmersive;
    }
    if (showThumb) {
        m_Thumbview.hidden = isImmersive;
    } else {
        m_slider.hidden = isImmersive;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_delegate && [_delegate respondsToSelector:@selector(didShowReader)]) {
        [_delegate didShowReader];
    }
    
    [toolBar.pageField setText:[NSString stringWithFormat:@"%i", pagenow+1]];
    [toolBar.pagesField setText:[NSString stringWithFormat:@" of %i", pagecount]];
    [toolBar.pagesField sizeToFit];
    [toolBar setNeedsLayout];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if(!b_outline)
    {
        if (_delegate && [_delegate respondsToSelector:@selector(didCloseReader)]) {
            [_delegate didCloseReader];
        }
        
        // Call the new delegate method with bookmarks
        if (_delegate && [_delegate respondsToSelector:@selector(didCloseReaderWithBookmarks:)]) {
            NSString *bookmarksJSON = @"";
            if (currentPdfPath && [[NSFileManager defaultManager] fileExistsAtPath:currentPdfPath]) {
                NSString *pdfDirectory = [currentPdfPath stringByDeletingLastPathComponent];
                NSMutableArray *bookmarks = [self loadBookmarkForPdf:pdfDirectory withPath:NO];
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bookmarks options:NSJSONWritingPrettyPrinted error:nil];
                if (jsonData) {
                    bookmarksJSON = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                }
            }
            [_delegate didCloseReaderWithBookmarks:bookmarksJSON];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeOrientation" object:nil];
    return YES;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

/*
- (void)pageNumLabelInit:(int)pageno
{
    if (pageNumLabel) {
        [pageNumLabel removeFromSuperview];
    }
    
    pageNumLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, [self barHeightDistance], 65, 30)];
    pagenow = pageno;
    pageNumLabel.backgroundColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.4];
    pageNumLabel.textColor = [UIColor whiteColor];
    pageNumLabel.adjustsFontSizeToFitWidth = YES;
    pageNumLabel.textAlignment= NSTextAlignmentCenter;
    pageNumLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    pageNumLabel.layer.cornerRadius = 10;
    pageNumLabel.font = RD_FONT_BOLD(16);
    [self updatePageNumLabel:pageno+1];
    [self.view addSubview:pageNumLabel];
    
    [pageNumLabel setHidden:toolBar.hidden];
}
*/

- (void)startToolbarTimer {
    return;
    [self stopToolbarTimer];
    //NSLog(@"start timer");
    toolbarsTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f repeats:NO block:^(NSTimer * _Nonnull timer) {
        [self hideBars];
    }];
}

- (void)stopToolbarTimer {
    //NSLog(@"stop timer");
    [toolbarsTimer invalidate];
}

- (void)updatePageNumLabel:(int)page
{
    NSString *pagestr = [[NSString alloc]initWithFormat:@"%d/",page];
    pagestr = [pagestr stringByAppendingFormat:@"%d",pagecount];
    [toolBar.pageField setText:[NSString stringWithFormat:@"%i", page]];
    pagenow = (page - 1);
    
    [self startToolbarTimer];
}

- (void)refreshPageNumLabelPosition {
    pageNumLabel.frame = CGRectMake(0, [self barHeightDistance], 65, 30);
}

-(void)PDFGoto:(int)pageno
{
    if (pageno < 0) {
        [self PDFGoto:0];
        return;
    }

    if (pageno > m_doc.pageCount - 1) {
        [self PDFGoto:m_doc.pageCount - 1];
        return;
    }

    [m_view resetZoomLevel];
    [m_view vGoto:pageno];
    [m_Thumbview vGoto:pageno];
    [self updatePageNumLabel:(pageno + 1)];
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (m_view) {
        CGRect rect = self.view.bounds;
        if (!CGRectIsEmpty(rect) && rect.size.width > 0 && rect.size.height > 0 && !CGRectEqualToRect(m_view.frame, rect)) {
            RDVPos pos;
            [m_view vGetPos:&pos];
            CGFloat zoom = m_view.zoomScale;

            [m_view setFrame:rect];
            [m_view sizeThatFits:rect.size];

            if (zoom > 1.0) {
                CGPoint centerPoint = CGPointMake(CGRectGetMidX(m_view.bounds), CGRectGetMidY(m_view.bounds));
                CGPoint centerPointInWindow = [m_view convertPoint:centerPoint toView:nil];
                [m_view zoomPageToScale:zoom atPoint:centerPointInWindow];
            }
            [m_view vGotoPos:&pos];
        }
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [m_view setFrame:CGRectMake(0, 0, size.width, size.height)];
    [m_view sizeThatFits:size];
    BOOL isPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    CGFloat bottomInset = 0;
    if (@available(iOS 11.0, *)) {
        bottomInset = self.view.safeAreaInsets.bottom;
    }
    CGFloat thumbBottomY = size.height - thumbViewHeight;
    if (isPhone) {
        thumbBottomY -= (toolBar ? toolBar.barHeight : 0) + bottomInset;
        if (thumbBottomY < 0) thumbBottomY = 0;
    }
    m_Thumbview.frame = CGRectMake(0, thumbBottomY, size.width, thumbViewHeight);
    m_slider.frame = CGRectMake(0, thumbBottomY, size.width, thumbViewHeight);
    [m_Thumbview sizeThatFits:m_Thumbview.frame.size];
    [m_slider sizeThatFits:m_slider.frame.size];
    [m_Thumbview vGoto:pagenow];
    m_slider.value = pagenow +1;
    [self setSliderText:(int)m_slider.value];
    
    if (GLOBAL.g_enable_fab) {
        [self didZoom:m_view.zoomScale];
    }

    // Recompute toolbar position during and after rotation to respect updated safe area insets
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self refreshBarsPosition];
        [self.view bringSubviewToFront:toolBar];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self refreshBarsPosition];
        [self.view bringSubviewToFront:toolBar];
        
        // Recalculate annotation rect and reposition menu after rotation
        // Only reshow menu if annotation is still visible in viewport
        if (annotMenu && annotMenu.superview) {
            BOOL annotVisible = [m_view recalculateAnnotRect];
            if (annotVisible) {
                [m_view reShowAnnotMenu];
            } else {
                // Annotation is off-screen after rotation, dismiss menu
                [annotMenu removeFromSuperview];
                [m_view vAnnotEnd];
            }
        }
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    /*
     CGRect rect =[[UIScreen mainScreen]bounds];
     if ([self isPortrait])
     {
     if (rect.size.height < rect.size.width) {
     
     float height = rect.size.height;
     rect.size.height = rect.size.width;
     rect.size.width = height;
     }
     }
     else
     {
     if (rect.size.height > rect.size.width) {
     
     float height = rect.size.height;
     rect.size.height = rect.size.width;
     rect.size.width = height;
     }
     }
     
     [m_view setFrame:rect];
     [m_view sizeThatFits:rect.size];
     [toolBar sizeToFit];
     
     CGRect boundsc = [[UIScreen mainScreen]bounds];
     int cwidth = boundsc.size.width;
     int cheight = boundsc.size.height;
     
     if ([self isPortrait]) {
     if (cwidth > cheight) {
     cwidth = cheight;
     cheight = boundsc.size.width;
     }
     }
     else
     {
     if (cwidth < cheight) {
     cwidth = cheight;
     cheight = boundsc.size.width;
     }
     }
     
     float hi = self.navigationController.navigationBar.bounds.size.height;
     
     [m_searchBar setFrame:CGRectMake(0,hi+20,cwidth,41)];
     */
}


- (void)createToolbarItems
{
    toolBar = [[RDToolBar alloc] init];
    toolBar.m_delegate = self;
    
    // Set images
    toolBar.closeImage = _closeImage;
    toolBar.searchImage = _searchImage;
    toolBar.selectImage = _selectImage;
    toolBar.drawImage = _drawImage;
    toolBar.undoImage = _undoImage;
    toolBar.redoImage = _redoImage;
    toolBar.gridImage = _gridImage;
    toolBar.deleteImage = _deleteImage;
    toolBar.doneImage = _doneImage;
    toolBar.tocImage = _tocImage;
    toolBar.performImage = _performImage;
    toolBar.moreImage = _moreImage;
    toolBar.nextImage = _nextImage;
    
    // Hide icons
    toolBar.hideSearchImage = _hideSearchImage;
    toolBar.hideDrawImage = _hideDrawImage;
    toolBar.hideSelImage = _hideSelImage;
    toolBar.hideUndoImage = _hideUndoImage;
    toolBar.hideRedoImage = _hideRedoImage;
    toolBar.hideMoreImage = _hideMoreImage;
    toolBar.hideGridImage = YES;
    
    toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    
    [toolBar setupToolBarArray];
}

- (void)refreshBarsPosition {
    [self refreshStatusBarHeight];
    BOOL isPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        insets = self.view.safeAreaInsets;
    }
    CGRect scr = [self screenRect];

    // Re-measure the toolbar's natural height for the current layout environment:
    // the system floating toolbar can render at a different height across
    // orientations/size classes, and the cached barHeight (captured once at
    // setup, in portrait) would otherwise leave a gap below it after rotating.
    [toolBar.bar sizeToFit];
    if (toolBar.bar.frame.size.height > 0) {
        toolBar.barHeight = toolBar.bar.frame.size.height;
    }

    if (isPhone) {
        // The system's floating toolbar style already draws its own clearance
        // above the true edge, on top of whatever margin we reserve here. That
        // extra system padding is more pronounced in landscape (shorter view
        // height), so reserve less of our own margin there to compensate.
        BOOL isLandscape = scr.size.width > scr.size.height;
        CGFloat bottomMargin = isLandscape ? MIN(insets.bottom, 12.0) : insets.bottom;
        CGFloat toolbarY = scr.size.height - toolBar.barHeight - bottomMargin;
        [toolBar setFrame:CGRectMake(0, toolbarY, scr.size.width, toolBar.barHeight)];
        [toolBar.bar setFrame:CGRectMake(0, 0, toolBar.frame.size.width, toolBar.frame.size.height)];
    } else {
        if (@available(iOS 13.0, *)) {
            [toolBar setFrame:CGRectMake(0, 0, scr.size.width, toolBar.barHeight + statusBarHeight)];
            [toolBar.bar setFrame:CGRectMake(0, toolBar.frame.size.height - toolBar.barHeight, scr.size.width, toolBar.barHeight)];
        } else {
            [toolBar setFrame:CGRectMake(0, statusBarHeight, scr.size.width, toolBar.barHeight)];
            [toolBar.bar setFrame:CGRectMake(0, 0, toolBar.frame.size.width, toolBar.frame.size.height)];
        }
    }
    // Ensure thumbnail/slider sit above the bottom toolbar on iPhone
    if (m_Thumbview || m_slider) {
        CGFloat bottomOccupied = 0;
        if (isPhone) {
            bottomOccupied = scr.size.height - toolBar.frame.origin.y;
        }
        CGFloat thumbY = scr.size.height - thumbViewHeight - bottomOccupied;
        if (thumbY < 0) thumbY = 0;
        if (m_Thumbview) {
            m_Thumbview.frame = CGRectMake(0, thumbY, scr.size.width, thumbViewHeight);
            // The thumbnail strip's own layout (RDVLayoutThumb) caches its width
            // internally and is otherwise only resynced during a live rotation
            // transition. If the reader opens directly into an orientation whose
            // real bounds weren't available yet when the strip was first created
            // (e.g. launching straight into landscape), that stale width sticks
            // around and only half the row ever gets populated with thumbnails.
            [m_Thumbview sizeThatFits:m_Thumbview.frame.size];
        }
        if (m_slider) {
            m_slider.frame = CGRectMake(0, thumbY, scr.size.width, thumbViewHeight);
        }
    }

    // Keep search bar positioned with an extra offset on newer iOS versions to avoid overlap
    if (m_searchBar) {
        CGRect sframe = toolBar.bar.frame;
        if (isPhone) {
            CGFloat padding = 12.0;
            sframe.origin.y = toolBar.frame.origin.y - sframe.size.height - padding;
            if (sframe.origin.y < 0) {
                sframe.origin.y = 0;
            }
        } else {
            sframe.origin.y = [self barHeightDistance];
            if (@available(iOS 26.0, *)) {
                sframe.origin.y += 10.0; // extra spacing below toolbar on iOS 26+
            }
        }
        CGFloat leftInset = 0;
        if (@available(iOS 11.0, *)) {
            leftInset += self.view.safeAreaInsets.left;
        }
        leftInset += toolBar.bar.layoutMargins.left;
        sframe.origin.x = leftInset;
        sframe.size.width = self.view.bounds.size.width * 0.5;
        sframe.size.height = toolBar.bar.frame.size.height;
        m_searchBar.frame = sframe;
    }

    [self refreshPageNumLabelPosition];
    [self initTableViews];
    if (m_Thumbview) {
        [self.view bringSubviewToFront:m_Thumbview];
    }
    if (m_slider) {
        [self.view bringSubviewToFront:m_slider];
    }
    [self.view bringSubviewToFront:toolBar];
    [self.view bringSubviewToFront:m_searchBar];
    [self updateFloatingButtonPosition];
    if (floatingButton) {
        [self.view bringSubviewToFront:floatingButton];
    }
    if (toolIconButton) {
        [self.view bringSubviewToFront:toolIconButton];
    }
}

- (int)PDFOpen:(NSString *)path :(NSString *)pwd :(int)page :(int)viewType :(BOOL)showOutlineTableView :(NSString *)json :(BOOL)immersive {
    // Reset documentId for legacy callers
    currentDocumentId = nil;
    // Force render mode: vertical or horizontal continuous (0/1)
    GLOBAL.g_render_mode = (viewType > 4 || viewType < 0) ? 0 :viewType;

    showSXToolbar = showOutlineTableView;

    isImmersive = immersive;

    return [self PDFOpen:path :pwd atPage:page readOnly:NO autoSave:NO author:@""];
}

// New overload with documentId support
- (int)PDFOpen:(NSString *)path :(NSString *)pwd :(int)page :(int)viewType :(BOOL)showOutlineTableView :(NSString *)json :(BOOL)immersive :(NSString *)documentId {
    currentDocumentId = (documentId && documentId.length > 0) ? [documentId copy] : nil;
    // Force render mode: vertical or horizontal continuous (0/1)
    GLOBAL.g_render_mode = (viewType > 4 || viewType < 0) ? 0 :viewType;

    showSXToolbar = showOutlineTableView;

    isImmersive = immersive;

    return [self PDFOpen:path :pwd atPage:page readOnly:NO autoSave:NO author:@""];
}

-(int)PDFOpen:(NSString *)path : (NSString *)pwd {
    return [self PDFOpen:path :pwd atPage:0 readOnly:NO autoSave:NO author:@""];
}

-(int)PDFOpen:(NSString *)path : (NSString *)pwd atPage:(int)page readOnly:(BOOL)readOnlyEnabled autoSave:(BOOL)autoSave author:(NSString *)author
{
    NSLog(@"[PDFOpen] Opening file: %@", path);
    GLOBAL.g_author = author;
    GLOBAL.pdfPath = [[path stringByDeletingLastPathComponent] mutableCopy];
    GLOBAL.pdfName = [[path lastPathComponent] mutableCopy];
    GLOBAL.g_save_doc = autoSave;
    
    currentPdfPath = path;
    
    showThumb = YES;
    
    CGRect rect = [self screenRect];
    m_doc = [[RDPDFDoc alloc] init];
    int err_code = [m_doc open:path :pwd];
    switch( err_code )
    {
        case err_ok:
            break;
        case err_password:
            return 2;
            break;
        default: return 0;
    }
    
    m_view = [[PDFLayoutView alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, rect.size.height)];
    [m_view setReadOnly:readOnlyEnabled];
    BOOL res = [m_view PDFOpen:m_doc :4 :self];
    [self.view addSubview:m_view];
    pagecount = [m_doc pageCount];
    
    // Load all per-annotation XFDF files for this PDF
    [self loadAllXFDFAnnotations];
    
    // If a valid page is provided, go to that page; otherwise restore last view state
    if (page >= 0 && page < pagecount) {
        [self thumbInit:page];
        [self PDFGoto:page];
    } else {
        [self loadPDFViewState];
    }
    
    [self updateBookmarkButtonAppearance];
    return res;
}

- (int)PDFOpenStream:(id<PDFStream>)stream :(NSString *)password
{
    CGRect rect = [self screenRect];
    m_doc = [[RDPDFDoc alloc] init];
    int err_code = [m_doc openStream:stream :password];
    switch( err_code )
    {
        case err_ok:
            break;
        case err_password:
            return 2;
            break;
        default: return 0;
    }
    
    m_view = [[PDFLayoutView alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, rect.size.height)];
    [self.view addSubview:m_view];
    pagecount = [m_doc pageCount];
    
    [self thumbInit:0];
    
    int res = [m_view PDFOpen:m_doc :4 :self];
    [self updateBookmarkButtonAppearance];
    return res;
}

- (int)PDFOpenMem:(void *)data :(int)data_size :(NSString *)pwd
{
    CGRect rect = [self screenRect];
    m_doc = [[RDPDFDoc alloc] init];
    int err_code = [m_doc openMem:data :data_size :pwd];
    switch( err_code )
    {
        case err_ok:
            break;
        case err_password:
            return 2;
            break;
        default: return 0;
    }
    
    m_view = [[PDFLayoutView alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, rect.size.height)];
    [self.view addSubview:m_view];
    pagecount = [m_doc pageCount];
    
    [self thumbInit:0];
    
    int res = [m_view PDFOpen:m_doc :4 :self];
    [self updateBookmarkButtonAppearance];
    return res;
}
/*
 #pragma mark - Grid View
 
 - (void)toggleGrid
 {
 [self toggleGridView];
 }
 
 - (void)toggleGridView
 {
 if (!m_Gridview) {
 [self showGridView];
 
 } else {
 [self hideGridView];
 }
 }
 
 - (void)showGridView
 {
 if (!m_Gridview) {
 m_Gridview = [[PDFGridView alloc] initWithFrame:CGRectMake(100, 100, 500, 500)];
 [m_Gridview PDFOpen:m_doc :4 :(id<PDFThumbViewDelegate>)self];
 
 if (gridBackgroundColor != 0) {
 [m_Gridview setThumbBackgroundColor:gridBackgroundColor];
 }
 
 [self.view addSubview:m_Gridview];
 }
 }
 
 - (void)hideGridView
 {
 if(m_Gridview) {
 [m_Gridview removeFromSuperview];
 [m_Gridview PDFClose];
 m_Gridview = nil;
 }
 }
 
 #pragma mark - Slider
 
 - (void)sliderInit:(int)pageno
 {
 CGRect boundsc = [self screenRect];
 
 int cwidth = boundsc.size.width;
 int cheight = boundsc.size.height;
 
 m_slider = [[UISlider alloc] initWithFrame:CGRectMake(0, cheight-50, cwidth, 50)];
 
 m_slider.minimumValue = 1;
 m_slider.maximumValue = pagecount;
 m_slider.continuous = NO;
 m_slider.value = pageno;
 
 [m_slider addTarget:self action:@selector(OnSliderValueChange:) forControlEvents:UIControlEventValueChanged];
 
 [m_slider setBackgroundColor:[UIColor blackColor]];
 
 [self.view addSubview:m_slider];
 
 [self pageNumLabelInit:pageno];
 }
 */
#pragma mark - Thumbnail

- (void)thumbInit:(int)pageno {
    CGRect rect = [self screenRect];
    
    if (thumbViewHeight == 0) {
        thumbViewHeight = THUMB_HEIGHT;
    }
    
    if (m_Thumbview) {
        [m_Thumbview PDFClose];
        [m_Thumbview removeFromSuperview];
        m_Thumbview = NULL;
    }
    
    if (m_slider) {
        [m_slider removeFromSuperview];
        m_slider = nil;
    }
    
    BOOL isPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    CGFloat bottomInset = 0;
    if (@available(iOS 11.0, *)) {
        bottomInset = self.view.safeAreaInsets.bottom;
    }
    CGFloat thumbY = rect.size.height - thumbViewHeight;
    if (isPhone) {
        thumbY -= (toolBar ? toolBar.barHeight : 0) + bottomInset;
        if (thumbY < 0) thumbY = 0;
    }
    m_Thumbview = [[PDFThumbView alloc] initWithFrame:CGRectMake(0, thumbY, rect.size.width, thumbViewHeight)];
    [m_Thumbview PDFOpen:m_doc :4 :self];
    [m_Thumbview vGoto:pageno];//page 0 for default selected page.
    [self.view addSubview:m_Thumbview];
    m_Thumbview.hidden = !showThumb;
    
    sliderLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, thumbViewHeight / 3)];
    sliderLabel.textColor = RD_TEXT_GRAY;
    sliderLabel.textAlignment = NSTextAlignmentCenter;
    
    {
        UIFont *labelFont = RD_FONT_BOLD(NORMAL_FONT_SIZE);
        sliderLabel.font = labelFont ? labelFont : [UIFont boldSystemFontOfSize:NORMAL_FONT_SIZE];
    }
    sliderLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    sliderLabelBackground = [[UIView alloc] initWithFrame:CGRectZero];
    sliderLabelBackground.backgroundColor = [UIColor whiteColor];
    
    [self setSliderText:pageno + 1];
    
    m_slider = [[UISlider alloc] initWithFrame:CGRectMake(0, thumbY, rect.size.width, thumbViewHeight)];
    m_slider.minimumValue = 1;
    m_slider.maximumValue = m_doc.pageCount;
    m_slider.tintColor = RD_COLOR;
    //m_slider.continuous = NO;
    m_slider.value = pageno + 1;
    [m_slider addTarget:self action:@selector(OnSliderValueChange:) forControlEvents:UIControlEventValueChanged];
    [m_slider addTarget:self action:@selector(OnSliderTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    m_slider.backgroundColor = RD_BACKGROUND_GRAY;
    //[m_slider addSubview:sliderLabelBackground];
    [m_slider addSubview:sliderLabel];
    m_slider.hidden = showThumb;
    [self.view addSubview:m_slider];
}

#pragma mark - Slider

- (void)setSliderText:(int)value {
    sliderLabel.text = [NSString stringWithFormat:@"%i/%i", value, m_doc.pageCount];
    // Build attributes with a safe font to avoid inserting nil into the attributes dictionary
    UIFont *font = RD_FONT_BOLD(NORMAL_FONT_SIZE);
    if (!font) {
        font = [UIFont boldSystemFontOfSize:16];
    }
    CGSize backgroundSize = [sliderLabel.text sizeWithAttributes:@{NSFontAttributeName : font}];
    sliderLabelBackground.frame = CGRectMake(0, 0, backgroundSize.width + 20, backgroundSize.height + 10);
    sliderLabelBackground.center = sliderLabel.center;
    sliderLabelBackground.layer.cornerRadius = sliderLabelBackground.frame.size.height / 2;
}

-(void)OnSliderValueChange:(UISlider *)slider
{
    [self updateSlider:roundf(slider.value) goto:NO];
}


-(void)OnSliderTouchUp:(UISlider *)slider
{
    [self updateSlider:roundf(slider.value) goto:YES];
}

- (void)updateSlider:(int)value goto:(BOOL)haveToGoTo {
    int page = value;
    if (page <= 0) {
        page = 1;
    }
    if (page >= m_doc.pageCount) {
        page = m_doc.pageCount;
    }
    
    if (haveToGoTo) {
        [self OnPageClicked:page - 1];
    } else {
        [self setSliderText:page];
    }
}

-(void)OnPageClicked:(int)pageno
{
    [self PDFGoto:pageno];
}

- (void)OnStartInteraction {
    [self stopToolbarTimer];
}

- (void)OnEndInteraction {
    [self startToolbarTimer];
}

- (void)didZoom:(CGFloat)zoomLevel {
    CGFloat maxalpha = GLOBAL.g_floatingbutton_alpha;
    if (GLOBAL.g_enable_fab) {
        if (floatingButton && floatingButton.layer.shadowOpacity == 1) {
            if(maxalpha > 1.0){
                maxalpha = 1.0;
            }
            CGFloat alpha = maxalpha - (zoomLevel / 10);
            if (zoomLevel <= 1) {
                alpha = maxalpha;
            }
            if (alpha < 0.2) {
                alpha = 0.2;
            }
            floatingButton.alpha = alpha;
        }
        
        if (!isImmersive) {
            floatingButton.alpha = maxalpha;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
#pragma mark perform annot method
-(void)performAnnot
{
    [m_view vAnnotPerform];
    [toolBar changeToNormalToolBar];
}
-(void)deleteAnnot
{
    [m_view vAnnotRemove];
}
-(void)annotCancel
{
    [self removeAnnotToolBar];
}
-(void)removeAnnotToolBar
{
    [toolBar changeToNormalToolBar];
    [m_view vAnnotEnd];
}

// RDToolBarDelegate
- (void)endCurrentAnnotationSelection
{
    if (m_view) {
        [m_view vAnnotEnd];
    }
    if (alreadySelected) {
        alreadySelected = false;
        [m_view vSelEnd];
        [toolBar.selectButton setTintColor:toolBar.bar.tintColor];
    }
    if (selMenu.superview) {
        [selMenu removeFromSuperview];
    }
}
#pragma mark - press annot method
- (void)OnPageChanged :(int)pageno
{
    static int prevPage = -1;
    if (_delegate && [_delegate respondsToSelector:@selector(didChangePage:)]) {
        if (pageno != prevPage) {
            prevPage = pageno;
            [_delegate didChangePage:pageno];
        }
    }
    
    [m_Thumbview vGoto:pageno];
    m_slider.value = pageno +1;
    [self setSliderText:(int)m_slider.value];
    [self updatePageNumLabel:(pageno + 1)];
    [self updateBookmarkButtonAppearance];
}

- (void)OnPageUpdated :(int)pageno
{
    [m_Thumbview PDFUpdatePage:pageno];
}

- (void)OnLongPressed:(float)x :(float)y
{
    if (_delegate && [_delegate respondsToSelector:@selector(didLongPressOnPage:atPoint:)]) {
        [_delegate didLongPressOnPage:(pagenow) atPoint:CGPointMake(x, y)];
    }
}

- (void)OnSingleTapped:(float)x :(float)y
{
    // A tap landing on the search bar itself must not be treated as a page tap:
    // this handler runs on a short delay (to disambiguate from a double tap), so
    // resigning the search bar here would cancel the focus the tap just requested.
    if (m_searchBar && !m_searchBar.hidden && CGRectContainsPoint(m_searchBar.frame, CGPointMake(x, y))) {
        return;
    }

    if (_delegate && [_delegate respondsToSelector:@selector(didTapOnPage:atPoint:)]) {
        RDVPos pos;
        [m_view vGetPos:&pos x:x y:y];
        [_delegate didTapOnPage:pos.pageno atPoint:CGPointMake(x, y)];
    }
    
    if (b_noteAnnot) {
        posx = x;
        posy = y;
        [self TextAnnot];
        return;
    }
    
    if (annotMenu && annotMenu.superview) {
        [annotMenu removeFromSuperview];
    }
    if (!pickerView.hidden) {
        pickerView.hidden = YES;
        confirmPickerBtn.hidden = YES;
    }
    
    [m_searchBar resignFirstResponder];
    
    // If the FAB is not enabled, toggle the toolbars instead
    if (!GLOBAL.g_enable_fab) {
        if(isImmersive)
        {
            [self showBars];
        }
        else
        {
            [self hideBars];
        }
    }
    
    b_outline = false;
    m_bSel = false;
    [m_view vSelEnd];
}

- (void)OnDoubleTapped:(float)x :(float)y
{
    if (_delegate && [_delegate respondsToSelector:@selector(didDoubleTapOnPage:atPoint:)]) {
        RDVPos pos;
        [m_view vGetPos:&pos x:x y:y];
        [_delegate didDoubleTapOnPage:pos.pageno atPoint:CGPointMake(x, y)];
    }
}
- (BOOL)isDrawingModeActive {
    return currentDrawingMode >= 0 && currentDrawingMode <= 3;
}

- (void)toggleBars {
    if ([self isDrawingModeActive]) {
        if (!isImmersive) {
            [self hideBars];
        }
        return;
    }

    if(isImmersive)
    {
        [self showBars];
    }
    else
    {
        [self hideBars];
    }
}

- (void)showToolIconButton:(NSString *)iconName {
    if (toolIconButton) {
        [toolIconButton removeFromSuperview];
        toolIconButton = nil;
    }
    
    // Normally positioned above the fullscreen button, but when the FAB itself
    // sits at the top-right (Dynamic Island on the right edge in landscape),
    // expanding upward would push this off-screen, so go below it instead.
    BOOL isPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    BOOL isLandscape = self.view.frame.size.width > self.view.frame.size.height;
    BOOL islandOnRight = NO;
    if (isPhone && isLandscape) {
        UIInterfaceOrientation orientation = UIInterfaceOrientationUnknown;
        if (@available(iOS 13.0, *)) {
            orientation = self.view.window.windowScene.interfaceOrientation;
        } else {
            orientation = [UIApplication sharedApplication].statusBarOrientation;
        }
        islandOnRight = (orientation == UIInterfaceOrientationLandscapeLeft);
    }
    CGFloat buttonY = islandOnRight ?
        (floatingButton.frame.origin.y + FAB_SIZE + 15) :
        (floatingButton.frame.origin.y - FAB_SIZE - 15);
    toolIconButton = [[UIButton alloc] initWithFrame:CGRectMake(floatingButton.frame.origin.x, buttonY, FAB_SIZE, FAB_SIZE)];
    toolIconButton.backgroundColor = RD_COLOR;
    toolIconButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    toolIconButton.layer.cornerRadius = FAB_SIZE / 2;
    toolIconButton.layer.shadowOffset = CGSizeMake(0, 1);
    toolIconButton.layer.shadowColor = [[UIColor blackColor] CGColor];
    toolIconButton.layer.shadowOpacity = 1;
    toolIconButton.transform = floatingButton.transform;
    [toolIconButton setImage:[[UIImage systemImageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    toolIconButton.tintColor = [UIColor whiteColor];
    [toolIconButton addTarget:self action:@selector(exitDrawingMode) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:toolIconButton];
    [self.view bringSubviewToFront:toolIconButton];
}

- (void)updateFloatingButtonAppearanceForDrawing:(BOOL)isDrawing {
    if (!floatingButton) {
        return;
    }
    floatingButton.backgroundColor = isDrawing ? RD_DISABLED_BUTTON_GRAY : RD_COLOR;
}

- (void)hideToolIconButton {
    if (toolIconButton) {
        [toolIconButton removeFromSuperview];
        toolIconButton = nil;
    }
}

- (void)exitDrawingMode {
    if (noteDrawingMode) {
        [self drawNoteCancel];
        noteDrawingMode = NO;
        if (floatingButton) {
            floatingButton.userInteractionEnabled = YES;
            floatingButton.backgroundColor = RD_COLOR;
        }
        [self hideToolIconButton];
        if (isImmersive) {
            [self showBars];
        }
        return;
    }
    if (textDrawingMode) {
        [self drawEditboxCancel];
        textDrawingMode = NO;
        if (floatingButton) {
            floatingButton.userInteractionEnabled = YES;
            floatingButton.backgroundColor = RD_COLOR;
        }
        [self hideToolIconButton];
        if (isImmersive) {
            [self showBars];
        }
        return;
    }

    // Call the appropriate cancel method based on currentDrawingMode
    switch (currentDrawingMode) {
        case 0: // line
            [self drawRowCancel];
            break;
        case 1: // arrow
            [self drawArrowCancel];
            break;
        case 2: // rect
            [self drawRectCancel:nil];
            break;
        case 3: // ellipse
            [self drawEllipseCancel:nil];
            break;
        default:
            break;
    }
    
    // Hide the tool icon button
    [self hideToolIconButton];
    
    // Reset drawing mode
    currentDrawingMode = -1;
    
    [self updateFloatingButtonAppearanceForDrawing:NO];

    // Exit fullscreen
    if (isImmersive) {
        [self showBars];
    }
}

- (void)OnFound:(bool)found
{
    if (_delegate && [_delegate respondsToSelector:@selector(didSearchTerm:found:)]) {
        [_delegate didSearchTerm:findString found:found];
    }
    
    if( !found )
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Waring" message:@"Find Over" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
- (void)OnSelStart:(float)x :(float)y
{
    if(m_bSel)
    {
        m_bSel = false;
    }
    m_bSel = YES;
}

- (void)OnSelEnd:(float)x1 :(float)y1 :(float)x2 :(float)y2
{
    if (m_bSel) {
        NSString *s = [m_view vSelGetText];
        NSLog(@"OnSelEnd select text = %@",s);
        if (s.length > 0)
        {
            if (selMenu.superview) {
                [selMenu removeFromSuperview];
            }
            __weak typeof(self) weakSelf = self;
            selMenu = [[RDSelMenu alloc] initAtPoint:CGPointMake(x2, y2) callback:^(RDSelMenuAction action) {
                __strong typeof(weakSelf) selfStrong = weakSelf;
                if (!selfStrong) return;
                switch (action) {
                    case RDSelMenuActionHighlight: [selfStrong HighLight:nil]; break;
                    case RDSelMenuActionUnderline: [selfStrong UnderLine:nil]; break;
                    case RDSelMenuActionStrikeout: [selfStrong StrikeOut:nil]; break;
                }
                [selfStrong->selMenu removeFromSuperview];
            }];
            [self.view addSubview:selMenu];
        }
    }
}
//enter annotation status.
- (void)OnAnnotClicked:(RDPDFAnnot *)annot :(CGRect)annotRect :(float)x :(float)y
{
    [m_searchBar setHidden:NO];
    b_outline = false;
    m_bSel = false;
    cachedAnnot = annot;
    int atype_guard = [annot type];
    if (atype_guard == 3 || atype_guard == 20) {
        return;
    }
    if (annotMenu.superview) {
        [annotMenu removeFromSuperview];
    }
    // Position menu at top-left of annotation rect using full rect conversion
    CGRect rectInSelf = [m_view convertRect:[m_view annotRectForAnnotMenu] toView:self.view];
    CGPoint pt = rectInSelf.origin;
    __weak typeof(self) weakSelf = self;
    annotMenu = [[RDAnnotMenu alloc] initWithAnnot:annot atPoint:pt callback:^(RDAnnotMenuAction action) {
        __strong typeof(weakSelf) selfStrong = weakSelf;
        if (!selfStrong) return;
        if (action == RDAnnotMenuActionDelete) {
            if (![annot isLocked]) {
                NSString *nm = [annot getName];
                [selfStrong->m_view removeAnnot:annot];
                [selfStrong deleteXFDFForAnnotName:nm];
                [selfStrong->m_view refreshCurrentPage];
                [selfStrong->m_view vAnnotEnd];
                [selfStrong->m_view setModified:YES force:NO];
            }
        } else if (action == RDAnnotMenuActionSettings) {
            int atype = [annot type];
            if (atype == 1 || atype == 17) { /* sticky note and file attachment */
                NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"DlgAnnotPropIcon" owner:selfStrong options:nil];
                DlgAnnotPropIcon *view = [views lastObject];
                __block NSString *prevName = [annot getName];
                __block PDF_OBJ_REF annotRef = [annot getRef];
                PDFDialog *dlg = [[PDFDialog alloc] init:view :CGRectMake(0, 0, 300, 250) :YES :^(BOOL is_ok){
                    if (is_ok) {
                        [view updateAnnot];
                        [selfStrong->m_view setModified:YES force:NO];
                        int pc = [selfStrong->m_doc pageCount];
                        int foundIndex = -1;
                        RDPDFPage *pgFound = nil;
                        RDPDFAnnot *target = nil;
                        for (int pi = 0; pi < pc; pi++) {
                            RDPDFPage *pgScan = [selfStrong->m_doc page:pi];
                            [pgScan objsStart:NO];
                            int ac = pgScan.annotCount;
                            for (int i = 0; i < ac; i++) {
                                RDPDFAnnot *a = [pgScan annotAtIndex:i];
                                if ([a getRef] == annotRef) { target = a; pgFound = pgScan; foundIndex = pi; break; }
                            }
                            if (target) break;
                        }
                        if (!target) {
                            int pageIndex = [selfStrong->m_view vGetCurrentPage];
                            pgFound = [selfStrong->m_doc page:pageIndex];
                            [pgFound objsStart:NO];
                            target = annot;
                            foundIndex = pageIndex;
                        }
                        // Ensure annot has a stable name (preserve or assign)
                        if (target) {
                            NSString *curName = [target getName];
                            if (curName.length == 0) {
                                if (prevName.length > 0) [target setName:prevName];
                                else [target setName:[[[NSUUID alloc] init] UUIDString]];
                            }
                            [selfStrong saveAnnotationToXFDF:target page:pgFound pageIndex:foundIndex];
                        }
                        [selfStrong->m_view refreshCurrentPage];
                    }
                }];
                [view setAnnot:annot :dlg];
                [view setTitle:@"Annotation settings"];
                [selfStrong presentViewController:dlg animated:YES completion:nil];
            } else if (atype == 4 /* line */) {
                NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"DlgAnnotPropLine" owner:selfStrong options:nil];
                DlgAnnotPropLine *view = [views lastObject];
                [view setAnnot:annot :selfStrong];
                int lineStyle = [annot getLineStyle];
                BOOL hasArrow = (lineStyle & 0xFFFF) != 0 || (lineStyle >> 16) != 0;
                [view setTitle:@"Annotation settings"];
                __block NSString *prevName = [annot getName];
                __block PDF_OBJ_REF annotRef = [annot getRef];
                PDFDialog *dlg = [[PDFDialog alloc] init:view :CGRectMake(0, 0, 300, 536) :YES :^(BOOL is_ok){
                    if (is_ok) {
                        [view updateAnnot];
                        [selfStrong->m_view setModified:YES force:NO];
                        int pcL = [selfStrong->m_doc pageCount];
                        int foundIndexL = -1;
                        RDPDFPage *pgFoundL = nil;
                        RDPDFAnnot *target = nil;
                        for (int pi = 0; pi < pcL; pi++) {
                            RDPDFPage *pgScan = [selfStrong->m_doc page:pi];
                            [pgScan objsStart:NO];
                            int ac = pgScan.annotCount;
                            for (int i = 0; i < ac; i++) {
                                RDPDFAnnot *a = [pgScan annotAtIndex:i];
                                if ([a getRef] == annotRef) { target = a; pgFoundL = pgScan; foundIndexL = pi; break; }
                            }
                            if (target) break;
                        }
                        if (!target) {
                            int pageIndex = [selfStrong->m_view vGetCurrentPage];
                            pgFoundL = [selfStrong->m_doc page:pageIndex];
                            [pgFoundL objsStart:NO];
                            target = annot;
                            foundIndexL = pageIndex;
                        }
                        if (target) {
                            NSString *curName = [target getName];
                            if (curName.length == 0) {
                                if (prevName.length > 0) [target setName:prevName];
                                else [target setName:[[[NSUUID alloc] init] UUIDString]];
                            }
                            [selfStrong saveAnnotationToXFDF:target page:pgFoundL pageIndex:foundIndexL];
                            if ([target isLocked]) {
                                [selfStrong->m_view vAnnotEnd];
                            }
                        }
                        [selfStrong->m_view refreshCurrentPage];
                        [selfStrong->m_view reShowAnnotMenu];
                    } else {
                        [selfStrong->m_view reShowAnnotMenu];
                    }
                }];
                [selfStrong presentViewController:dlg animated:YES completion:nil];
            } else if (atype == 5 || atype == 6) { /* square/circle */
                NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"DlgAnnotPropComm" owner:selfStrong options:nil];
                DlgAnnotPropComm *view = [views lastObject];
                [view setAnnot:annot :selfStrong];
                [view hasFill:YES];
                [view setTitle:@"Annotation settings"];
                __block NSString *prevName = [annot getName];
                __block PDF_OBJ_REF annotRef = [annot getRef];
                PDFDialog *dlg = [[PDFDialog alloc] init:view :CGRectMake(0, 0, 300, 449) :YES :^(BOOL is_ok){
                    if (is_ok) {
                        [view updateAnnot];
                        [selfStrong->m_view setModified:YES force:NO];
                        int pcC = [selfStrong->m_doc pageCount];
                        int foundIndexC = -1;
                        RDPDFPage *pgFoundC = nil;
                        RDPDFAnnot *target = nil;
                        for (int pi = 0; pi < pcC; pi++) {
                            RDPDFPage *pgScan = [selfStrong->m_doc page:pi];
                            [pgScan objsStart:NO];
                            int ac = pgScan.annotCount;
                            for (int i = 0; i < ac; i++) {
                                RDPDFAnnot *a = [pgScan annotAtIndex:i];
                                if ([a getRef] == annotRef) { target = a; pgFoundC = pgScan; foundIndexC = pi; break; }
                            }
                            if (target) break;
                        }
                        if (!target) {
                            int pageIndex = [selfStrong->m_view vGetCurrentPage];
                            pgFoundC = [selfStrong->m_doc page:pageIndex];
                            [pgFoundC objsStart:NO];
                            target = annot;
                            foundIndexC = pageIndex;
                        }
                        if (target) {
                            NSString *curName = [target getName];
                            if (curName.length == 0) {
                                if (prevName.length > 0) [target setName:prevName];
                                else [target setName:[[[NSUUID alloc] init] UUIDString]];
                            }
                            [selfStrong saveAnnotationToXFDF:target page:pgFoundC pageIndex:foundIndexC];
                            if ([target isLocked]) {
                                [selfStrong->m_view vAnnotEnd];
                            }
                        }
                        [selfStrong->m_view refreshCurrentPage];
                        [selfStrong->m_view reShowAnnotMenu];
                    } else {
                        [selfStrong->m_view reShowAnnotMenu];
                    }
                }];
                [selfStrong presentViewController:dlg animated:YES completion:nil];
            } else if (atype == 3) { /* edit text */
                int pageIndex = [selfStrong->m_view vGetCurrentPage];
                RDPDFPage *pgForSettings = [selfStrong->m_doc page:pageIndex];
                RDAnnotSettingsViewController *settingsVC = [[RDAnnotSettingsViewController alloc] initWithAnnot:annot page:pgForSettings type:RDAnnotSettingsTypeText];
                __block NSString *prevName = [annot getName];
                __block PDF_OBJ_REF annotRef = [annot getRef];
                settingsVC.onApply = ^{
                    [selfStrong->m_view setModified:YES force:NO];
                    [selfStrong->m_view refreshCurrentPage];
                    int pageIndex = [selfStrong->m_view vGetCurrentPage];
                    RDPDFPage *pg = [selfStrong->m_doc page:pageIndex];
                    [pg objsStart:NO];
                    RDPDFAnnot *target = nil;
                    int ac = pg.annotCount;
                    for (int i = 0; i < ac; i++) {
                        RDPDFAnnot *a = [pg annotAtIndex:i];
                        if ([a getRef] == annotRef) { target = a; break; }
                    }
                    if (!target) target = annot;
                    NSString *curName = [target getName];
                    if (curName.length == 0) {
                        if (prevName.length > 0) [target setName:prevName];
                        else [target setName:[[[NSUUID alloc] init] UUIDString]];
                    }
                    [selfStrong saveAnnotationToXFDF:target page:pg pageIndex:pageIndex];
                    [selfStrong->m_view reShowAnnotMenu];
                };
                [selfStrong presentViewController:settingsVC animated:YES completion:nil];
            }
        } else if (action == RDAnnotMenuActionIncreaseFont || action == RDAnnotMenuActionDecreaseFont) {
            if ([annot type] == 3 && ![annot isLocked]) {
                PDF_OBJ_REF annotRef = [annot getRef];
                float size = [annot getEditTextSize];
                float step = 1.0;
                size += (action == RDAnnotMenuActionIncreaseFont) ? step : -step;
                if (size < 6) size = 6;
                if (size > 100) size = 100;
                [annot setEditTextSize:size];
                [selfStrong->m_view setModified:YES force:NO];
                [selfStrong->m_view refreshCurrentPage];
                int pageIndex = [selfStrong->m_view vGetCurrentPage];
                RDPDFPage *pg = [selfStrong->m_doc page:pageIndex];
                [pg objsStart:NO];
                RDPDFAnnot *target = nil;
                int ac = pg.annotCount;
                for (int i = 0; i < ac; i++) {
                    RDPDFAnnot *a = [pg annotAtIndex:i];
                    if ([a getRef] == annotRef) { target = a; break; }
                }
                if (!target) target = annot;
                NSString *curName = [target getName];
                if (curName.length == 0) {
                    [target setName:[[[NSUUID alloc] init] UUIDString]];
                }
                [selfStrong saveAnnotationToXFDF:target page:pg pageIndex:pageIndex];
            }
        }
        [selfStrong->annotMenu removeFromSuperview];
    }];
    [self.view addSubview:annotMenu];
}
//notified when a new annotation is created or updated.
- (void)OnAnnotCreated:(RDPDFAnnot *)annot page:(RDPDFPage *)page pageIndex:(int)pageIndex
{
    [self saveAnnotationToXFDF:annot page:page pageIndex:pageIndex];
}

//notified when annotation status end.
- (void)OnAnnotEnd
{
    // If we're in continuous drawing mode (line, arrow, rect, ellipse), restart the drawing mode
    if (currentDrawingMode >= 0 && currentDrawingMode <= 3) {
        // Restart the appropriate drawing mode
        switch (currentDrawingMode) {
            case 0: // line
                [m_view vLineStart];
                break;
            case 1: // arrow
                [m_view vLineStart];
                break;
            case 2: // rect
                [m_view vRectStart];
                break;
            case 3: // ellipse
                [m_view vEllipseStart];
                break;
            default:
                break;
        }
        return;
    }

    // If we just placed a note, restore toolbars and re-enable fullscreen button
    if (noteDrawingMode) {
        noteDrawingMode = NO;
        if (floatingButton) {
            floatingButton.userInteractionEnabled = YES;
            floatingButton.backgroundColor = RD_COLOR;
        }
        if (isImmersive) {
            [self showBars];
        }
        [self hideToolIconButton];
        [self updateFloatingButtonAppearanceForDrawing:NO];
    }
    if (textDrawingMode) {
        textDrawingMode = NO;
        if (floatingButton) {
            floatingButton.userInteractionEnabled = YES;
            floatingButton.backgroundColor = RD_COLOR;
        }
        if (isImmersive) {
            [self showBars];
        }
        [self hideToolIconButton];
        [self updateFloatingButtonAppearanceForDrawing:NO];
    }
    
    [self teardownDrawToolbar];
    if (!pickerView.hidden) {
        pickerView.hidden = YES;
        confirmPickerBtn.hidden = YES;
    }
    if (!textFd.hidden){
        [textFd resignFirstResponder];
        textFd.hidden = YES;
    }
    [toolBar changeToNormalToolBar];
    if (annotMenu.superview) {
        [annotMenu removeFromSuperview];
    }
}
//this mehod fired only when vAnnotPerform method invoked.
- (void)OnAnnotGoto:(int)pageno
{
    [self PDFGoto:pageno];
}
//this mehod fired only when vAnnotPerform method invoked.
- (void)OnAnnotPopup:(RDPDFAnnot *)annot
{
        if(annot){
            b_outline = true;
            cachedAnnot = annot;
            cachedAnnotRef = [annot getRef];
            cachedAnnotPageIndex = [m_view vGetCurrentPage];
            textAnnotVC = [[TextAnnotViewController alloc]init];
            [textAnnotVC setDelegate:self];
            [textAnnotVC setText:[annot getPopupText]];
            [textAnnotVC setSubject:[annot getPopupSubject]];
            if ([annot isReadonly] || [annot isLocked])
                textAnnotVC.readOnly = YES;
            UINavigationController *navController = [[UINavigationController alloc]
                                                 initWithRootViewController:textAnnotVC];
            navController.preferredContentSize = CGSizeMake([self screenRect].size.width*0.8, [self screenRect].size.height*0.8);
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:navController animated:YES completion:nil];
        }
}

- (void)OnAnnotList:(RDPDFAnnot *)annot items:(NSArray *)dataArray selectedIndexes:(NSArray *)indexes
{
    NSLog(@"list sels");
    
    annotListTV = [[RDAnnotListViewController alloc] init];
    BOOL isMultiSel;
    isMultiSel = [annot isMultiSel];
    annotListTV.delegate = self;
    annotListTV.annotList = dataArray;
    annotListTV.multiSel = isMultiSel;
    annotListTV.annotSelected = [NSMutableArray arrayWithArray:indexes];
    annotListTV.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    annotListTV.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    b_outline = TRUE;
    [self presentViewController:annotListTV animated:YES completion:nil];
}

- (void)didTapAnnot:(RDPDFAnnot *)annot atPage:(int)page atPoint:(CGPoint)point
{
    if (_delegate && [_delegate respondsToSelector:@selector(didTapOnAnnotationOfType:atPage:atPoint:)]) {
        [_delegate didTapOnAnnotationOfType:annot.type atPage:page atPoint:point];
    }
}

//this mehod fired only when vAnnotPerform method invoked.
- (void)OnAnnotOpenURL:(NSString *)url
{
    b_outline = YES;
    //open URI
    if( url ){
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Alert", @"Localizable")
                                                                       message:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Do you want to open:", @"Localizable"), url]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"OK", nil)
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [[UIApplication sharedApplication]openURL:[NSURL URLWithString:url]];
                                 
                             }];
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                 style:UIAlertActionStyleDefault
                                 handler:nil];
        
        [alert addAction:ok];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
//this mehod fired only when vAnnotPerform method invoked.
- (void)OnAnnotMovie:(NSString *)fileName
{
    [tempfiles addObject:fileName];
    NSURL *urlPath = [NSURL fileURLWithPath:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        mpvc = [[MPMoviePlayerViewController alloc] initWithContentURL:urlPath];
        mpvc.view.frame = self.view.bounds;
        mpvc.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [self presentMoviePlayerViewControllerAnimated:mpvc];
    }else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Couldn't find media file" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
//this mehod fired only when vAnnotPerform method invoked.
- (void)OnAnnotSound:(NSString *)fileName
{
    [tempfiles addObject:fileName];
}
- (void)OnAnnotEditBox:(RDPDFAnnot *)annot :(CGRect)annotRect :(NSString *)editText :(float)textSize
{
    NSLog(@"[RDKeyboardLog] OnAnnotEditBox fired - annot=%@ rect=%@ editType=%d", annot, NSStringFromCGRect(annotRect), [annot getEditType]);
    PDFPopupCtrl *pop;
    // Remove any existing floating annot menu to avoid duplication under the popup
    if (annotMenu && annotMenu.superview) {
        [annotMenu removeFromSuperview];
    }
    __weak typeof(self) weakSelf = self;
    if ([annot getEditType] == 3) // multi-line
    {
        UIView *container = [[UIView alloc] initWithFrame:CGRectZero];
        container.backgroundColor = [UIColor clearColor];
        UITextView *text = [[UITextView alloc] init];
        // Ensure text is set - if empty, try re-fetching from annotation
        NSString *displayText = editText;
        if (displayText.length == 0) {
            displayText = [annot getEditText];
        }
        text.text = displayText;
        text.backgroundColor = [UIColor whiteColor];
        int annotTextColor = [annot getEditTextColor];
        if (annotTextColor != 0) {
            CGFloat tr = ((annotTextColor >> 16) & 0xFF) / 255.0;
            CGFloat tg = ((annotTextColor >> 8) & 0xFF) / 255.0;
            CGFloat tb = (annotTextColor & 0xFF) / 255.0;
            text.textColor = [UIColor colorWithRed:tr green:tg blue:tb alpha:1.0];
        } else {
            text.textColor = RD_TEXT_BLACK;
        }
        UIFont *baseFont = [UIFont fontWithName:@"PublicSans-Regular" size:textSize];
        text.font = baseFont ? baseFont : [UIFont systemFontOfSize:textSize];
        float baseAnnotSize = [annot getEditTextSize];
        __block float displayScale = (baseAnnotSize > 0) ? (text.font.pointSize / baseAnnotSize) : 1.0f;
        // Build popup first with container
        pop = [[PDFPopupCtrl alloc] init:container];
        // Calculate target rect in window coordinates
        // annotRect is now provided in annotRectForAnnotMenu format which works correctly with convertRect
        CGRect rect = [m_view convertRect:annotRect toView:nil];
        __block BOOL shouldSave = YES;
        // Create annot toolbar as a subview
        RDAnnotMenu *menu = [[RDAnnotMenu alloc] initWithAnnot:annot atPoint:rect.origin callback:^(RDAnnotMenuAction action) {
            __strong typeof(weakSelf) selfStrong = weakSelf;
            if (!selfStrong) return;
            if (action == RDAnnotMenuActionDelete) {
                if (![annot isLocked]) {
                    NSString *nm = [annot getName];
                    [selfStrong->m_view removeAnnot:annot];
                    [selfStrong deleteXFDFForAnnotName:nm];
                    [selfStrong->m_view refreshCurrentPage];
                }
                // prevent saving text on dismiss
                shouldSave = NO;
                [selfStrong->m_view vAnnotEnd];
                [selfStrong->m_view setModified:YES force:NO];
                [pop dismiss];
            } else if (action == RDAnnotMenuActionSettings) {
                int atype = [annot type];
                if (atype == 3) { /* edit text settings */
                    [annot setEditText:text.text];
                    shouldSave = NO;
                    [pop dismiss];
                    int pageIndex = [selfStrong->m_view vGetCurrentPage];
                    RDPDFPage *pg = [selfStrong->m_doc page:pageIndex];
                    RDAnnotSettingsViewController *settingsVC = [[RDAnnotSettingsViewController alloc] initWithAnnot:annot page:pg type:RDAnnotSettingsTypeText];
                    settingsVC.onApply = ^{
                        [selfStrong->m_view setModified:YES force:NO];
                        [selfStrong->m_view refreshCurrentPage];
                    };
                    [selfStrong presentViewController:settingsVC animated:YES completion:nil];
                }
            } else if (action == RDAnnotMenuActionIncreaseFont || action == RDAnnotMenuActionDecreaseFont) {
                if ([annot type] == 3 && ![annot isLocked]) {
                    float size = [annot getEditTextSize];
                    float step = 1.0;
                    size += (action == RDAnnotMenuActionIncreaseFont) ? step : -step;
                    if (size < 6) size = 6;
                    if (size > 100) size = 100;
                    [annot setEditTextSize:size];
                    float displaySize = size * displayScale;
                    NSString *family = text.font.fontName ?: @"PublicSans-Regular";
                    UIFont *scaledFont = [UIFont fontWithName:family size:displaySize];
                    text.font = scaledFont ? scaledFont : [UIFont systemFontOfSize:displaySize];
                    [selfStrong->m_view setModified:YES force:NO];
                }
            }
        }];
        CGFloat menuHeight = menu.frame.size.height; // 56 by design
        CGFloat toolbarPadding = 6.0f;
        CGFloat containerY = rect.origin.y - menuHeight - toolbarPadding;
        CGFloat delta = 0;
        if (containerY < 0) { delta = -containerY; containerY = 0; }
        // Ensure container is wide enough to include full toolbar; align toolbar to top-left of annot rect
        CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
        CGFloat toolbarW = menu.frame.size.width;
        CGFloat contentW = MAX(rect.size.width, toolbarW);
        CGFloat containerX = rect.origin.x;
        if (containerX + contentW > screenW) containerX = MAX(0, screenW - contentW);
        CGFloat handlePad = 8.0f; // extra padding for resize handles
        container.frame = CGRectMake(containerX - handlePad, containerY, contentW + handlePad * 2, rect.size.height + menuHeight + toolbarPadding - delta + handlePad);
        menu.frame = CGRectMake(handlePad, delta, menu.frame.size.width, menu.frame.size.height);
        text.frame = CGRectMake(handlePad, menuHeight + toolbarPadding + delta, rect.size.width, rect.size.height);
        container.clipsToBounds = NO;
        [container addSubview:menu];
        [container addSubview:text];

        // Add border + resize handles overlay around the text area
        // Use full-screen sized frame so handles/border are visible when dragged outside container
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        CGRect containerFrame0 = container.frame;
        CGRect resizeViewFrame = CGRectMake(-containerFrame0.origin.x, -containerFrame0.origin.y, screenBounds.size.width, screenBounds.size.height);
        // Text frame in resize view's coordinate space
        CGRect textFrameInResizeView = CGRectMake(text.frame.origin.x + containerFrame0.origin.x,
                                                   text.frame.origin.y + containerFrame0.origin.y,
                                                   text.frame.size.width,
                                                   text.frame.size.height);
        __block RDAnnotResizeView *resizeView = [[RDAnnotResizeView alloc] initWithTextFrame:textFrameInResizeView completion:^(CGRect newFrame) {
            __strong typeof(weakSelf) selfStrong = weakSelf;
            if (!selfStrong) return;
            // newFrame is in screen (window) coordinates since resize view covers full screen
            // Convert to m_view (PDFLayoutView) coordinate space
            CGRect newInView = [selfStrong->m_view convertRect:newFrame fromView:nil];
            // Convert screen rect to PDF rect
            PDF_RECT newPdfRect = [selfStrong->m_view pdfRectFromScreenRect:newInView];
            // Validate pdfRect before calling setRect
            if (isnan(newPdfRect.left) || isnan(newPdfRect.right) || isnan(newPdfRect.top) || isnan(newPdfRect.bottom) ||
                isinf(newPdfRect.left) || isinf(newPdfRect.right) || isinf(newPdfRect.top) || isinf(newPdfRect.bottom)) {
                NSLog(@"[RDAnnotResize] ERROR: invalid pdfRect (NaN/Inf) - left:%.2f right:%.2f top:%.2f bottom:%.2f, skipping setRect",
                      newPdfRect.left, newPdfRect.right, newPdfRect.top, newPdfRect.bottom);
                return;
            }
            if (newPdfRect.right <= newPdfRect.left || newPdfRect.bottom <= newPdfRect.top) {
                NSLog(@"[RDAnnotResize] ERROR: degenerate pdfRect - left:%.2f right:%.2f top:%.2f bottom:%.2f, skipping setRect",
                      newPdfRect.left, newPdfRect.right, newPdfRect.top, newPdfRect.bottom);
                return;
            }
            NSLog(@"[RDAnnotResize] setRect pdfRect: left:%.2f right:%.2f top:%.2f bottom:%.2f (screen: %.1f,%.1f %.1fx%.1f)",
                  newPdfRect.left, newPdfRect.right, newPdfRect.top, newPdfRect.bottom,
                  newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height);
            // Update annotation rect
            [annot setRect:&newPdfRect];
            [selfStrong->m_view setModified:YES force:NO];
            [selfStrong->m_view vAnnotEnd];
            [selfStrong->m_view refreshCurrentPage];
            // Update the text view frame in container-local coords
            CGRect containerFrameNow = container.frame;
            text.frame = CGRectMake(newFrame.origin.x - containerFrameNow.origin.x,
                                    newFrame.origin.y - containerFrameNow.origin.y,
                                    newFrame.size.width,
                                    newFrame.size.height);
            // Reposition menu above the new text area
            CGFloat menuW = menu.frame.size.width;
            CGFloat menuH = menu.frame.size.height;
            menu.frame = CGRectMake(text.frame.origin.x, text.frame.origin.y - menuH - 6.0f, menuW, menuH);
            [resizeView updateTextFrame:newFrame];
        }];
        resizeView.frame = resizeViewFrame;
        [container addSubview:resizeView];
        text.contentMode = UIViewContentModeRedraw;

        // Add dynamic resize as user types
        __block CGFloat initialTextHeight = rect.size.height;
        __block id textChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UITextViewTextDidChangeNotification 
                                                          object:text 
                                                           queue:[NSOperationQueue mainQueue] 
                                                      usingBlock:^(NSNotification *note) {
            // Calculate needed height based on content
            CGSize contentSize = [text sizeThatFits:CGSizeMake(rect.size.width, CGFLOAT_MAX)];
            CGFloat neededHeight = ceil(contentSize.height);
            
            if (neededHeight > initialTextHeight) {
                // Expand UITextView and container
                CGFloat heightDelta = neededHeight - text.frame.size.height;
                CGRect textFrame = text.frame;
                textFrame.size.height = neededHeight;
                text.frame = textFrame;
                
                CGRect containerFrame = container.frame;
                containerFrame.size.height += heightDelta;
                container.frame = containerFrame;
                
                initialTextHeight = neededHeight;
            }
        }];
        
        [pop setDismiss:^{
            [[NSNotificationCenter defaultCenter] removeObserver:textChangeObserver];
            if (shouldSave) {
                PDF_OBJ_REF annotRef = [annot getRef];
                int pidx = [m_view vGetCurrentPage];
                NSString *newText = [text.text copy];
                dispatch_async(dispatch_get_main_queue(), ^{
                    @try {
                        CGFloat curW = rect.size.width;
                        CGFloat curH = rect.size.height;
                        CGFloat dH = 0;
                        // Measure text using the annotation's actual font size, not the UITextView's scaled display font
                        float annotFontSize = [annot getEditTextSize];
                        if (annotFontSize > 0) {
                            // Account for UITextView's horizontal padding (insets + line fragment padding)
                            UIEdgeInsets inset = text.textContainerInset;
                            CGFloat lineFragmentPadding = text.textContainer.lineFragmentPadding;
                            CGFloat horizontalPadding = inset.left + inset.right + (lineFragmentPadding * 2);
                            // Convert annotation rect width to PDF points for measurement, accounting for padding
                            float pdfWidth = (curW - horizontalPadding) / displayScale;
                            UIFont *measureFont = [UIFont systemFontOfSize:annotFontSize];
                            CGSize constraint = CGSizeMake(pdfWidth, CGFLOAT_MAX);
                            CGRect bbox = [newText boundingRectWithSize:constraint
                                                                options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                             attributes:@{NSFontAttributeName: measureFont}
                                                                context:nil];
                            CGFloat neededH_pdf = ceil(bbox.size.height);
                            CGFloat neededH_screen = neededH_pdf * displayScale;
                            dH = (neededH_screen > curH) ? (neededH_screen - curH) : 0;
                        }
                        if (dH > 0) {
                            PDF_RECT pdfRect; [annot getRect:&pdfRect];
                            float w_pdf = fabsf(pdfRect.right - pdfRect.left);
                            float h_pdf_signed = pdfRect.top - pdfRect.bottom;
                            if (w_pdf > 0.0001f && fabsf(h_pdf_signed) > 0.0001f) {
                                PDF_RECT newRect = pdfRect;
                                float new_h_pdf = h_pdf_signed * (float)((curH + dH) / curH);
                                newRect.top = newRect.bottom + new_h_pdf;
                                [annot setRect:&newRect];
                            }
                        }
                    } @catch (__unused NSException *e)
                    {
                        
                    }
                    [annot setEditText:newText];
                    [m_view vUpdateAnnotPage];
                    [m_view vAnnotEnd];
                    [m_view setModified:YES force:NO];
                    // Force page refresh to ensure the text is rendered
                    [m_view refreshCurrentPage];
                    RDPDFPage *pg = [m_doc page:pidx];
                    [pg objsStart:NO];
                    RDPDFAnnot *toSave = nil;
                    int ac = pg.annotCount;
                    for (int i = 0; i < ac; i++) {
                        RDPDFAnnot *a = [pg annotAtIndex:i];
                        if ([a getRef] == annotRef) { toSave = a; break; }
                    }
                    if (toSave) {
                        [self saveAnnotationToXFDF:toSave page:pg pageIndex:pidx];
                    }
                });
            }
        }];
    }
    else
    {
        UIView *container = [[UIView alloc] initWithFrame:CGRectZero];
        container.backgroundColor = [UIColor clearColor];
        UITextField *text = [[UITextField alloc] init];
        // Ensure text is set - if empty, try re-fetching from annotation
        NSString *displayText = editText;
        if (displayText.length == 0) {
            displayText = [annot getEditText];
        }
        text.text = displayText;
        text.backgroundColor = [UIColor whiteColor];
        int annotTextColorField = [annot getEditTextColor];
        if (annotTextColorField != 0) {
            CGFloat tr = ((annotTextColorField >> 16) & 0xFF) / 255.0;
            CGFloat tg = ((annotTextColorField >> 8) & 0xFF) / 255.0;
            CGFloat tb = (annotTextColorField & 0xFF) / 255.0;
            text.textColor = [UIColor colorWithRed:tr green:tg blue:tb alpha:1.0];
        } else {
            text.textColor = RD_TEXT_BLACK;
        }
        UIFont *baseFontField = [UIFont fontWithName:@"PublicSans-Regular" size:textSize];
        text.font = baseFontField ? baseFontField : [UIFont systemFontOfSize:textSize];
        float baseAnnotSizeField = [annot getEditTextSize];
        __block float displayScaleField = (baseAnnotSizeField > 0) ? (text.font.pointSize / baseAnnotSizeField) : 1.0f;
        pop = [[PDFPopupCtrl alloc] init:container];
        // Calculate target rect in window coordinates
        // annotRect is now provided in annotRectForAnnotMenu format which works correctly with convertRect
        CGRect rect = [m_view convertRect:annotRect toView:nil];
        __block BOOL shouldSave = YES;
        RDAnnotMenu *menu = [[RDAnnotMenu alloc] initWithAnnot:annot atPoint:rect.origin callback:^(RDAnnotMenuAction action) {
            __strong typeof(weakSelf) selfStrong = weakSelf;
            if (!selfStrong) return;
            if (action == RDAnnotMenuActionDelete) {
                if (![annot isLocked]) {
                    NSString *nm = [annot getName];
                    [selfStrong->m_view removeAnnot:annot];
                    [selfStrong deleteXFDFForAnnotName:nm];
                    [selfStrong->m_view refreshCurrentPage];
                }
                shouldSave = NO;
                [selfStrong->m_view vAnnotEnd];
                [selfStrong->m_view setModified:YES force:NO];
                [pop dismiss];
            } else if (action == RDAnnotMenuActionSettings) {
                int atype = [annot type];
                if (atype == 3) {
                    [annot setEditText:text.text];
                    shouldSave = NO;
                    [pop dismiss];
                    int pageIndex = [selfStrong->m_view vGetCurrentPage];
                    RDPDFPage *pg = [selfStrong->m_doc page:pageIndex];
                    RDAnnotSettingsViewController *settingsVC = [[RDAnnotSettingsViewController alloc] initWithAnnot:annot page:pg type:RDAnnotSettingsTypeText];
                    settingsVC.onApply = ^{
                        [selfStrong->m_view setModified:YES force:NO];
                        [selfStrong->m_view refreshCurrentPage];
                    };
                    [selfStrong presentViewController:settingsVC animated:YES completion:nil];
                }
            } else if (action == RDAnnotMenuActionIncreaseFont || action == RDAnnotMenuActionDecreaseFont) {
                if ([annot type] == 3 && ![annot isLocked]) {
                    float size = [annot getEditTextSize];
                    float step = 1.0;
                    size += (action == RDAnnotMenuActionIncreaseFont) ? step : -step;
                    if (size < 6) size = 6;
                    if (size > 100) size = 100;
                    [annot setEditTextSize:size];
                    float displaySize = size * displayScaleField;
                    UIFont *scaledFontField = [UIFont fontWithName:@"PublicSans-Regular" size:displaySize];
                    text.font = scaledFontField ? scaledFontField : [UIFont systemFontOfSize:displaySize];
                    [selfStrong->m_view setModified:YES force:NO];
                }
            }
        }];
        CGFloat menuHeight = menu.frame.size.height;
        CGFloat toolbarPadding = 6.0f;
        CGFloat containerY = rect.origin.y - menuHeight - toolbarPadding;
        CGFloat delta = 0;
        if (containerY < 0) { delta = -containerY; containerY = 0; }
        CGFloat screenW2 = [UIScreen mainScreen].bounds.size.width;
        CGFloat toolbarW2 = menu.frame.size.width;
        CGFloat contentW2 = MAX(rect.size.width, toolbarW2);
        CGFloat containerX2 = rect.origin.x;
        if (containerX2 + contentW2 > screenW2) containerX2 = MAX(0, screenW2 - contentW2);
        CGFloat handlePad2 = 8.0f; // extra padding for resize handles
        container.frame = CGRectMake(containerX2 - handlePad2, containerY, contentW2 + handlePad2 * 2, rect.size.height + menuHeight + toolbarPadding - delta + handlePad2);
        menu.frame = CGRectMake(handlePad2, delta, menu.frame.size.width, menu.frame.size.height);
        text.frame = CGRectMake(handlePad2, menuHeight + toolbarPadding + delta, rect.size.width, rect.size.height);
        container.clipsToBounds = NO;
        [container addSubview:menu];
        [container addSubview:text];

        // Add border + resize handles overlay around the text area
        // Use full-screen sized frame so handles/border are visible when dragged outside container
        CGRect screenBounds2 = [UIScreen mainScreen].bounds;
        CGRect containerFrame02 = container.frame;
        CGRect resizeViewFrame2 = CGRectMake(-containerFrame02.origin.x, -containerFrame02.origin.y, screenBounds2.size.width, screenBounds2.size.height);
        // Text frame in resize view's coordinate space (screen coords)
        CGRect textFrameInResizeView2 = CGRectMake(text.frame.origin.x + containerFrame02.origin.x,
                                                    text.frame.origin.y + containerFrame02.origin.y,
                                                    text.frame.size.width,
                                                    text.frame.size.height);
        __block RDAnnotResizeView *resizeView2 = [[RDAnnotResizeView alloc] initWithTextFrame:textFrameInResizeView2 completion:^(CGRect newFrame) {
            __strong typeof(weakSelf) selfStrong = weakSelf;
            if (!selfStrong) return;
            // newFrame is in screen (window) coordinates
            CGRect newInView = [selfStrong->m_view convertRect:newFrame fromView:nil];
            PDF_RECT newPdfRect = [selfStrong->m_view pdfRectFromScreenRect:newInView];
            // Validate pdfRect before calling setRect
            if (isnan(newPdfRect.left) || isnan(newPdfRect.right) || isnan(newPdfRect.top) || isnan(newPdfRect.bottom) ||
                isinf(newPdfRect.left) || isinf(newPdfRect.right) || isinf(newPdfRect.top) || isinf(newPdfRect.bottom)) {
                NSLog(@"[RDAnnotResize] ERROR: invalid pdfRect (NaN/Inf) - left:%.2f right:%.2f top:%.2f bottom:%.2f, skipping setRect",
                      newPdfRect.left, newPdfRect.right, newPdfRect.top, newPdfRect.bottom);
                return;
            }
            if (newPdfRect.right <= newPdfRect.left || newPdfRect.bottom <= newPdfRect.top) {
                NSLog(@"[RDAnnotResize] ERROR: degenerate pdfRect - left:%.2f right:%.2f top:%.2f bottom:%.2f, skipping setRect",
                      newPdfRect.left, newPdfRect.right, newPdfRect.top, newPdfRect.bottom);
                return;
            }
            NSLog(@"[RDAnnotResize] setRect pdfRect: left:%.2f right:%.2f top:%.2f bottom:%.2f (screen: %.1f,%.1f %.1fx%.1f)",
                  newPdfRect.left, newPdfRect.right, newPdfRect.top, newPdfRect.bottom,
                  newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height);
            [annot setRect:&newPdfRect];
            [selfStrong->m_view setModified:YES force:NO];
            [selfStrong->m_view refreshCurrentPage];
            [selfStrong->m_view vAnnotEnd];
            // Update the text view frame in container-local coords
            CGRect containerFrameNow = container.frame;
            text.frame = CGRectMake(newFrame.origin.x - containerFrameNow.origin.x,
                                    newFrame.origin.y - containerFrameNow.origin.y,
                                    newFrame.size.width,
                                    newFrame.size.height);
            // Reposition menu above the new text area
            CGFloat menuW = menu.frame.size.width;
            CGFloat menuH = menu.frame.size.height;
            menu.frame = CGRectMake(text.frame.origin.x, text.frame.origin.y - menuH - 6.0f, menuW, menuH);
            [resizeView2 updateTextFrame:newFrame];
        }];
        resizeView2.frame = resizeViewFrame2;
        [container addSubview:resizeView2];
        text.contentMode = UIViewContentModeRedraw;

        [pop setDismiss:^{
            if (shouldSave) {
                [annot setEditText:text.text];
                // Enlarge rect if content doesn't fit, keep top-left anchored
                @try {
                    // Current on-screen rect used for editing
                    CGFloat curW = rect.size.width;
                    CGFloat curH = rect.size.height;
                    // Measure needed width for single-line text field
                    CGSize txtSize = [text.text sizeWithAttributes:@{NSFontAttributeName: (text.font ?: [UIFont systemFontOfSize:text.font.pointSize])}];
                    CGFloat neededW = ceil(txtSize.width) + 2.0; // small padding
                    CGFloat dW = (neededW > curW) ? (neededW - curW) : 0;
                    if (dW > 0) {
                        PDF_RECT pdfRect; [annot getRect:&pdfRect];
                        float w_pdf = fabsf(pdfRect.right - pdfRect.left);
                        float h_pdf = fabsf(pdfRect.top - pdfRect.bottom);
                        if (w_pdf > 0.0001f && h_pdf > 0.0001f) {
                            float ratioW = curW / w_pdf; // screen pts per 1 PDF unit horizontally
                            float dPdfW = (float)(dW / ratioW);
                            PDF_RECT newRect = pdfRect;
                            // Keep TOP-LEFT fixed; extend right only
                            if (pdfRect.right >= pdfRect.left) newRect.right += dPdfW; else newRect.right -= dPdfW;
                            [annot setRect:&newRect];
                        }
                    }
                } @catch (__unused NSException *e) {}
                [m_view vUpdateAnnotPage];
                [m_view vAnnotEnd];
                [m_view setModified:YES force:NO];
                // Force page refresh to ensure the text is rendered
                [m_view refreshCurrentPage];
                PDF_OBJ_REF annotRef = [annot getRef];
                int pidx = [m_view vGetCurrentPage];
                RDPDFPage *pg = [m_doc page:pidx];
                [pg objsStart:NO];
                RDPDFAnnot *toSave = nil;
                int ac = pg.annotCount;
                for (int i = 0; i < ac; i++) {
                    RDPDFAnnot *a = [pg annotAtIndex:i];
                    if ([a getRef] == annotRef) { toSave = a; break; }
                }
                if (!toSave) toSave = annot;
                NSString *nm = [toSave getName];
                if (nm.length == 0) [toSave setName:[[[NSUUID alloc] init] UUIDString]];
                [self saveAnnotationToXFDF:toSave page:pg pageIndex:pidx];
            }
        }];
    }
    [self presentViewController:pop animated:NO completion:nil];
}
- (void)OnAnnotCommboBox:(NSArray *)dataArray selected:(int)index
{
    pickViewArr = dataArray;
    pickerView.hidden = NO;
    confirmPickerBtn.hidden = NO;
    [self.view bringSubviewToFront:confirmPickerBtn];
    [self.view bringSubviewToFront:pickerView];
    [pickerView reloadAllComponents];
}

#pragma mark - PickerView DataSource and Delegate
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}
-(NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [pickViewArr count];
}
-(NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return [pickViewArr objectAtIndex:(int)row];
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    selectItem = (int)row;
}
- (void)setComboselect
{
    [m_view setCommboItem:selectItem];
    pickerView.hidden = YES;
    confirmPickerBtn.hidden = YES;
}

#pragma mark - annotList Delegate
- (void)listCheckedAt:(NSArray *)indexes
{
    [annotListTV dismissViewControllerAnimated:YES completion:nil];
    [m_view selectListBoxItems:indexes];
    [m_view vSelEnd];
}

#pragma mark - textField Delegate
- (void)textFieldDidEndEditing:(UITextField *)textField;
{
    NSLog(@"textView.text = %@",textField.text);
    [m_view setEditBoxWithText:textField.text];
    textField.hidden = YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

//add begin and end editing delegate to add keyboard notifications
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    [self.view endEditing:YES];
    return YES;
}

//add keyboard notification
#pragma mark - Keyboard Notifications

- (void)keyboardDidShow:(NSNotification *)notification
{
    //move the view to avoid the keyboard overlay
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    float gap = (keyboardFrameBeginRect.size.height - 30) - (textFd.frame.origin.y + textFd.frame.size.height);
    
    if (gap < 0) {
        [self.view setFrame:CGRectMake(0, gap, self.view.frame.size.width, self.view.frame.size.height)];
    }
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    //restore the correct view position
    [self.view setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
}

- (void)rd_logKeyboardWillShow:(NSNotification *)notification
{
    id firstResponder = [UIResponder rd_currentFirstResponder];
    NSLog(@"[RDKeyboardLog] UIKeyboardWillShow - firstResponder=%@ (class=%@) userInfo=%@",
          firstResponder, [firstResponder class], notification.userInfo);
    NSLog(@"[RDKeyboardLog] triggered from call stack:\n%@", [NSThread callStackSymbols]);
}

- (BOOL)isPortrait
{
    return ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait ||
            [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Toolbar Method

- (void)closeView
{
    [self stopToolbarTimer];
    
    b_outline = NO;
    
    if (@available(iOS 13.0, *)) {
    }
    else {
        UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
        
        if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
            statusBar.backgroundColor = [UIColor clearColor];
        }
    }
    
    if ([m_view isModified] && !GLOBAL.g_save_doc) {
        
        [m_view setModified:NO force:YES];
        [self PDFClose];
        [self.navigationController setNavigationBarHidden:NO];
        [self.navigationController popViewControllerAnimated:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [self PDFClose];
        self.navigationController.navigationBarHidden = NO;
        [self.navigationController popViewControllerAnimated:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)importXFDFFromPath:(NSString *)pdfPath
{
#if !RD_HAS_XFDF
    // The Classic SDK does not expose XFDF import. Annotations already stored
    // inside the PDF still load normally; only the sidecar .xfdf is ignored.
    (void)pdfPath;
    return;
#else
    if (m_doc == nil || pdfPath == nil) {
        return;
    }
    
    // Generate XFDF file path in the same directory as the PDF, using documentId if provided
    NSString *dir = [pdfPath stringByDeletingLastPathComponent];
    NSString *base = [self effectiveBaseName];
    NSString *xfdfPath = [[dir stringByAppendingPathComponent:base] stringByAppendingPathExtension:@"xfdf"];
    
    // Check if XFDF file exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:xfdfPath]) {
        NSError *error = nil;
        NSString *xfdfContent = [NSString stringWithContentsOfFile:xfdfPath encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            //NSLog(@"Error reading XFDF file: %@", error.localizedDescription);
            return;
        }
        
        if (xfdfContent != nil && xfdfContent.length > 0) {
            // Import XFDF into the document
            bool success = [m_doc importXFDF:xfdfContent];
            
            if (success) {
                //NSLog(@"XFDF file successfully imported from: %@", xfdfPath);
                // Refresh the view to show imported annotations
                if (m_view) {
                    [m_view setModified:NO force:YES];
                }
            } else {
                //NSLog(@"Failed to import XFDF file: %@", xfdfPath);
            }
        }
    } else {
        //NSLog(@"No XFDF file found at: %@", xfdfPath);
    }
#endif  // RD_HAS_XFDF
}

- (void)exportXFDFBeforeClosing
{
#if !RD_HAS_XFDF
    // No XFDF export on the Classic SDK; annotations are saved into the PDF itself.
    return;
#else
    if (m_doc != nil && currentPdfPath != nil) {
        // Generate XFDF file path with documentId if provided
        NSString *xfdfPath = [self statePathForExtension:@"xfdf"];
        
        // Export XFDF (href parameter is the reference to the source PDF file)
        NSString *pdfFileName = [currentPdfPath lastPathComponent];
        NSString *xfdfContent = [m_doc exportXFDF:pdfFileName];
        
        if (xfdfContent != nil && xfdfContent.length > 0) {
            NSError *error = nil;
            [xfdfContent writeToFile:xfdfPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
            
            if (error) {
                //NSLog(@"Error writing XFDF file: %@", error.localizedDescription);
            } else {
                //NSLog(@"XFDF file successfully exported to: %@", xfdfPath);
            }
        } else {
            //NSLog(@"No annotations to export or XFDF export returned empty content");
        }
    }
#endif  // RD_HAS_XFDF
}

//TODO: remove after thorough testing
- (void)clearAllXFDFFiles
{
    if (!currentPdfPath) {
        //NSLog(@"clearAllXFDFFiles called without a current PDF path");
        return;
    }
    NSString *directoryPath = [currentPdfPath stringByDeletingLastPathComponent];
    if (!directoryPath || directoryPath.length == 0) {
        //NSLog(@"Unable to resolve directory for current PDF path: %@", currentPdfPath);
        return;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *contentsError = nil;
    NSArray<NSString *> *directoryContents = [fileManager contentsOfDirectoryAtPath:directoryPath error:&contentsError];
    if (contentsError) {
        //NSLog(@"Failed to enumerate directory %@: %@", directoryPath, contentsError.localizedDescription);
        return;
    }
    for (NSString *fileName in directoryContents) {
        if ([[fileName pathExtension] caseInsensitiveCompare:@"xfdf"] == NSOrderedSame) {
            NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
            NSError *removeError = nil;
            if ([fileManager removeItemAtPath:filePath error:&removeError]) {
                //NSLog(@"Deleted XFDF file: %@", filePath);
            } else if (removeError) {
                //NSLog(@"Failed to delete XFDF file %@: %@", filePath, removeError.localizedDescription);
            }
        }
    }
}

#pragma mark - PDF View State Persistence

- (void)savePDFViewState
{
    if (!currentPdfPath || !m_view || !m_doc) {
        //NSLog(@"Cannot save PDF state: missing required components");
        return;
    }
    
    // Get current view state in PDF coordinates (stable across zoom levels)
    RDVPos pos;
    [m_view vGetPos:&pos];  // Gets center point of current view
    CGFloat zoom = m_view.zoomScale;
    
    // Create state dictionary with PDF coordinates
    NSDictionary *state = @{
        @"page": @(pos.pageno),
        @"zoom": @(zoom),
        @"pdfX": @(pos.pdfx),
        @"pdfY": @(pos.pdfy)
    };
    
    // Merge with existing .amr JSON to preserve any other keys already stored there
    NSString *stateFilePath = [self statePathForExtension:@"amr"];
    NSError *error = nil;
    NSMutableDictionary *merged = [NSMutableDictionary dictionary];
    if ([[NSFileManager defaultManager] fileExistsAtPath:stateFilePath]) {
        NSData *existingData = [NSData dataWithContentsOfFile:stateFilePath options:0 error:&error];
        if (!error && existingData) {
            NSDictionary *existing = [NSJSONSerialization JSONObjectWithData:existingData options:0 error:&error];
            if (!error && [existing isKindOfClass:[NSDictionary class]]) {
                [merged addEntriesFromDictionary:existing];
            }
        }
    }
    // Overwrite only the state-related keys
    merged[@"page"] = state[@"page"];
    merged[@"zoom"] = state[@"zoom"];
    merged[@"pdfX"] = state[@"pdfX"];
    merged[@"pdfY"] = state[@"pdfY"];
    
    NSData *outData = [NSJSONSerialization dataWithJSONObject:merged options:NSJSONWritingPrettyPrinted error:&error];
    if (outData) {
        if ([outData writeToFile:stateFilePath atomically:YES]) {
            //NSLog(@"PDF state saved to: %@", stateFilePath);
        } else {
            //NSLog(@"Failed to write PDF state file: %@", stateFilePath);
        }
    } else if (error) {
        //NSLog(@"Error serializing merged PDF state: %@", error.localizedDescription);
    }
}

- (void)loadPDFViewState
{
    if (!currentPdfPath || !m_view) {
        //NSLog(@"Cannot load PDF state: missing required components");
        return;
    }
    
    // Generate .amr file path
    NSString *stateFilePath = [self statePathForExtension:@"amr"];
    
    // Check if state file exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:stateFilePath]) {
        //NSLog(@"No saved state found at: %@", stateFilePath);
        [m_view vGoto:0];
        [self thumbInit:0];
        if (m_slider) {
            m_slider.value = 1;
            [self setSliderText:(int)m_slider.value];
        }
        [self updatePageNumLabel:1];
        return;
    }
    
    // Read state file
    NSError *error = nil;
    NSData *jsonData = [NSData dataWithContentsOfFile:stateFilePath options:0 error:&error];
    
    if (error) {
        //NSLog(@"Error reading PDF state file: %@", error.localizedDescription);
        return;
    }
    
    // Parse JSON
    NSDictionary *state = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error) {
        //NSLog(@"Error parsing PDF state JSON: %@", error.localizedDescription);
        return;
    }
    
    // Extract state values (PDF coordinates)
    NSNumber *pageNum = state[@"page"];
    NSNumber *zoomNum = state[@"zoom"];
    NSNumber *pdfXNum = state[@"pdfX"];
    NSNumber *pdfYNum = state[@"pdfY"];
    
    if (!pageNum || !zoomNum || !pdfXNum || !pdfYNum) {
        //NSLog(@"Invalid PDF state data: missing required fields");
        [m_view vGoto:0];
        [self thumbInit:0];
        if (m_slider) {
            m_slider.value = 1;
            [self setSliderText:(int)m_slider.value];
        }
        [self updatePageNumLabel:1];
        return;
    }
    
    int page = [pageNum intValue];
    CGFloat zoom = [zoomNum floatValue];
    RDVPos pos;
    pos.pageno = page;
    pos.pdfx = [pdfXNum floatValue];
    pos.pdfy = [pdfYNum floatValue];
    
    // Validate page number
    if (page < 0 || page >= [m_doc pageCount]) {
        //NSLog(@"Invalid page number in state: %d (document has %d pages)", page, [m_doc pageCount]);
        page = 0;
    }
    
    // Validate zoom level
    if (zoom < 1.0 || zoom > GLOBAL.g_zoom_level) {
        //NSLog(@"Invalid zoom level in state: %f (clamping to valid range)", zoom);
        zoom = MAX(1.0, MIN(zoom, GLOBAL.g_zoom_level));
    }
    
    //NSLog(@"Restoring PDF state: page=%d, zoom=%.2f, pdfPos=(%.1f, %.1f)", page, zoom, pos.pdfx, pos.pdfy);
    
    // Navigate to the page first
    [m_view vGoto:page];
    [self thumbInit:page];
    
    // Apply zoom if needed using the proper zoom sequence
    if (zoom > 1.0) {
        CGPoint centerPoint = CGPointMake(CGRectGetMidX(m_view.bounds), CGRectGetMidY(m_view.bounds));
        CGPoint centerPointInWindow = [m_view convertPoint:centerPoint toView:nil];
        [m_view zoomPageToScale:zoom atPoint:centerPointInWindow];
    }
    // Now navigate to the exact saved position
    [m_view vGotoPos:&pos];
    
    // Update UI elements
    if (m_slider) {
        m_slider.value = page + 1;
        [self setSliderText:(int)m_slider.value];
    }
    [self updatePageNumLabel:(page + 1)];
    
    //NSLog(@"PDF state restored successfully");
}

- (void)handleAppDidEnterBackground:(NSNotification *)note
{
    [self savePDFViewState];
}

- (void)handleAppWillTerminate:(NSNotification *)note
{
    [self savePDFViewState];
}

-(void)PDFClose
{
    [self savePDFViewState];
    
    if (_delegate && [_delegate respondsToSelector:@selector(willCloseReader)] && m_doc != nil) {
        [_delegate willCloseReader];
    }
    
    if (m_Thumbview != nil) {
        [m_Thumbview PDFClose];
        [m_Thumbview removeFromSuperview];
        m_Thumbview = NULL;
    }
    
    if( m_view != nil )
    {
        [m_view PDFClose];
        [m_view removeFromSuperview];
        m_view = NULL;
    }
    
    m_doc = NULL;
    [toolBar removeFromSuperview];
    [_outlineTableView removeFromSuperview];
    [floatingButton removeFromSuperview];
    floatingButton = nil;
    [toolIconButton removeFromSuperview];
    toolIconButton = nil;
    currentDrawingMode = -1;
    outlineItems = nil;
    toolBar.pagesField.text = @"";
    
    //delete temp files
    [self clearTempFiles];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

- (void)didSelectTextField {
    [self stopToolbarTimer];
}

- (void)shareClick
{
    [_delegate shareCallback];
}

- (void)switchClick
{
    showThumb = !showThumb;
    m_Thumbview.hidden = !showThumb;
    m_slider.hidden = showThumb;
}

#pragma mark - More

-(void)showMoreButtons{
    if (m_bSel == true)
    {
        [m_view vSelEnd];
        m_bSel = false;
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
        
        moreItemsContainer = [UIAlertController
                              alertControllerWithTitle:NSLocalizedString(@"Select Action", nil)
                              message:@""
                              preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *viewMode = [UIAlertAction actionWithTitle:NSLocalizedString(@"View Mode", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                   {
                                       [self showViewModeTableView];
                                   }];
        UIAlertAction *addBookMark = [UIAlertAction actionWithTitle:NSLocalizedString(@"Add Bookmark", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                      {
                                          [self composeFile];
                                      }];
        
        UIAlertAction *bookMarkList = [UIAlertAction actionWithTitle:NSLocalizedString(@"Bookmark List", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                       {
                                           [self bookmarkList];
                                       }];
        
        UIAlertAction *viewMenu =  [UIAlertAction actionWithTitle:NSLocalizedString(@"View Menu", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                    {
                                        [self viewMenu];
                                    }];
        
        UIAlertAction *savePDF = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                  {
                                      [self savePdf];
                                  }];
        
        UIAlertAction *printPDF =  [UIAlertAction actionWithTitle:NSLocalizedString(@"Print", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                    {
                                        [self printPdf];
                                    }];
        UIAlertAction *sharePDF =  [UIAlertAction actionWithTitle:NSLocalizedString(@"Share", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                    {
                                        [self sharePDF];
                                    }];
        
        UIAlertAction *cancel =  [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action)
                                  {
                                      [moreItemsContainer dismissViewControllerAnimated:YES completion:nil];
                                  }];
        
        [viewMode setValue:[(_viewModeImage) ? _viewModeImage : [UIImage systemImageNamed:@"rectangle.stack"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
        [addBookMark setValue:[(_addBookmarkImage) ? _addBookmarkImage : [UIImage systemImageNamed:@"bookmark.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
        [bookMarkList setValue:[(_bookmarkImage) ? _bookmarkImage : [UIImage systemImageNamed:@"bookmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
        [viewMenu setValue:[(_outlineImage) ? _outlineImage : [UIImage systemImageNamed:@"list.bullet"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
        [savePDF setValue:[(_saveImage) ? _saveImage : [UIImage systemImageNamed:@"square.and.arrow.down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
        [printPDF setValue:[(_printImage) ? _printImage : [UIImage systemImageNamed:@"printer"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
        [sharePDF setValue:[(_shareImage) ? _shareImage : [UIImage systemImageNamed:@"square.and.arrow.up"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
        
        [moreItemsContainer addAction:viewMode];
        [moreItemsContainer addAction:addBookMark];
        [moreItemsContainer addAction:bookMarkList];
        [moreItemsContainer addAction:viewMenu];
        [moreItemsContainer addAction:savePDF];
        [moreItemsContainer addAction:printPDF];
        [moreItemsContainer addAction:sharePDF];
        [moreItemsContainer addAction:cancel];
        moreItemsContainer.view.tintColor = [self getTintColor];
        
        [self presentViewController:moreItemsContainer animated:YES completion:nil];
    }
    else
    {
        moreTVContainer = [[RDMoreTableViewController alloc] init];
        moreTVContainer.modalPresentationStyle = UIModalPresentationPopover;
        [moreTVContainer setPreferredContentSize:CGSizeMake(300, 320)];
        moreTVContainer.delegate = self;
        moreTVContainer.viewModeImage = _viewModeImage;
        moreTVContainer.addBookmarkImage = _addBookmarkImage;
        moreTVContainer.bookmarkImage = _bookmarkImage;
        moreTVContainer.outlineImage = _outlineImage;
        moreTVContainer.saveImage = _saveImage;
        moreTVContainer.printImage = _printImage;
        moreTVContainer.shareImage = _shareImage;
        moreTVContainer.tintColor = [self getTintColor];
        UIPopoverPresentationController *popPresenter = [moreTVContainer
                                                         popoverPresentationController];
        popPresenter.barButtonItem = toolBar.moreButton;
        popPresenter.permittedArrowDirections = UIPopoverArrowDirectionAny;
        [self presentViewController:moreTVContainer animated:YES completion:nil];
    }
    
}

-(void)selectAction:(int)type{
    [moreTVContainer dismissViewControllerAnimated:YES completion:nil];
    
    switch (type) {
        case 0:
            [self showViewModeTableView];
            break;
        case 1:
            [self composeFile];
            break;
        case 2:
            [self bookmarkList];
            break;
        case 3:
            [self viewMenu];
            break;
        case 4:
            [self savePdf];
            break;
        case 5:
            [self printPdf];
            break;
        case 6:
            [self sharePDF];
            
        default:
            break;
    }
}

- (void)showViewModeTableView
{
    ViewModeTableViewController *vm = [[ViewModeTableViewController alloc] init];
    vm.delegate = self;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        
        vm.modalPresentationStyle = UIModalPresentationPopover;
        vm.delegate = self;
        vm.preferredContentSize = CGSizeMake(320, (44 * 5) + 10);
        
        UIPopoverPresentationController *pop = vm.popoverPresentationController;
        pop.permittedArrowDirections = UIPopoverArrowDirectionUp;
        pop.barButtonItem = toolBar.moreButton;
        
        [self presentViewController:vm animated:YES completion:nil];
    }
    else
    {
        UIAlertController *action = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select View Mode", nil) message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }];
        
        UIAlertAction *vert = [UIAlertAction actionWithTitle:NSLocalizedString(@"Vertical", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self setReaderViewMode:0];
        }];
        [vert setValue:[[UIImage systemImageNamed:@"arrow.up.arrow.down"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
        
        UIAlertAction *horz = [UIAlertAction actionWithTitle:NSLocalizedString(@"Horizontal", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self setReaderViewMode:1];
        }];
        [horz setValue:[[UIImage systemImageNamed:@"arrow.left.arrow.right"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
        
        UIAlertAction *singleP = [UIAlertAction actionWithTitle:NSLocalizedString(@"Single Page", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self setReaderViewMode:2];
        }];
        [singleP setValue:[[UIImage systemImageNamed:@"rectangle"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
        
        UIAlertAction *doubleP = [UIAlertAction actionWithTitle:NSLocalizedString(@"Double Page", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self setReaderViewMode:3];
        }];
        [doubleP setValue:[[UIImage systemImageNamed:@"rectangle.split.2x1"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];

        NSString *darkModeTitle = GLOBAL.g_dark_mode ?
            [NSString stringWithFormat:@"%@ ✓", NSLocalizedString(@"Dark Mode", nil)] :
            NSLocalizedString(@"Dark Mode", nil);
        UIAlertAction *darkMode = [UIAlertAction actionWithTitle:darkModeTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            GLOBAL.g_dark_mode = !GLOBAL.g_dark_mode;
            [[NSUserDefaults standardUserDefaults] setBool:GLOBAL.g_dark_mode forKey:@"DarkMode"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self refreshReaderForDarkModeChange];
        }];
        [darkMode setValue:[[UIImage systemImageNamed:@"moon.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];

        [action addAction:vert];
        [action addAction:horz];
        [action addAction:singleP];
        [action addAction:doubleP];
        [action addAction:darkMode];

        [action addAction:cancel];
        
        [self presentViewController:action animated:YES completion:nil];
    }
}

- (void)setReaderViewMode:(int)mode {
    [self setReaderViewMode:mode isDarkMode:NO];
}

- (void)refreshReaderForDarkModeChange {
    // Rebuild m_view without touching GLOBAL.g_render_mode: this re-renders
    // every page so it picks up the new dark-mode state in RDVCache's ProLayer.
    [self rebuildReaderView];
}

- (void)setReaderViewMode:(int)mode isDarkMode:(BOOL)darkMode
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad /*&& !darkMode*/)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    switch (mode) {
        case 2:
        {
            GLOBAL.g_render_mode = 3;
            break;
        }
        case 3:
        {
            GLOBAL.g_render_mode = 4;
            break;
        }
        default:
            GLOBAL.g_render_mode = mode;
            break;
    }

    [[NSUserDefaults standardUserDefaults] setInteger:GLOBAL.g_render_mode forKey:@"ViewMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self rebuildReaderView];
}

- (void)rebuildReaderView
{
    int currentPage = [m_view vGetCurrentPage];
    if( m_view != nil )
    {
        [m_view PDFClose];
        [m_view removeFromSuperview];
        m_view = NULL;
    }

    CGRect rect = [self screenRect];

    m_view = [[PDFLayoutView alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, rect.size.height)];
    [m_view PDFOpen:m_doc :4 :self];
    pagecount = [m_doc pageCount];

    [self.view addSubview:m_view];

    m_bSel = false;

    [self thumbInit:currentPage];
    [self PDFGoto:currentPage];

    [self.view bringSubviewToFront:m_Thumbview];
    [self.view bringSubviewToFront:m_slider];
    [self.view bringSubviewToFront:toolBar];
    if (m_searchBar) {
        [self.view bringSubviewToFront:m_searchBar];
    }
    [self.view bringSubviewToFront:pageNumLabel];
    [self.view bringSubviewToFront:_outlineTableView];
    [self.view bringSubviewToFront:floatingButton];
}

- (NSMutableArray *)loadBookmarkForPdf:(NSString *)pdfPath withPath:(BOOL)withPath
{
    return [self addBookMarks:pdfPath :@"" :[NSFileManager defaultManager] pdfName:[self effectiveBaseName] withPath:withPath];
}

- (NSMutableArray *)addBookMarks:(NSString *)dpath :(NSString *)subdir :(NSFileManager* )fm pdfName:(NSString *)pdfName withPath:(BOOL)withPath
{
    NSMutableArray *bookmarks = [NSMutableArray array];

    // Only search in the immediate directory, not recursively
    NSError *error = nil;
    NSArray *contents = [fm contentsOfDirectoryAtPath:dpath error:&error];
    if (error || !contents) {
        return bookmarks;
    }

    for (NSString *fName in contents) {
        NSString *dst = [dpath stringByAppendingPathComponent:fName];
        NSString *tempString = [fName pathExtension];

        if ([tempString isEqualToString:@"bookmark"]) {
            if (pdfName.length > 0 && ![fName containsString:pdfName]) {
                continue;
            }

            //add to list.
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:dst];
            NSString *content = [[NSString alloc] initWithData:[fileHandle availableData] encoding:NSUTF8StringEncoding];
            NSArray *myarray = [content componentsSeparatedByString:@","];
            [myarray objectAtIndex:0];
            NSArray *arr = [[NSArray alloc] initWithObjects:[myarray objectAtIndex:0], dst, nil];

            if (withPath) {
                // Return array format for UI (backward compatibility)
                [bookmarks addObject:arr];
            } else {
                // Return dictionary format for JSON with path included
                [bookmarks addObject:@{
                    @"Page": [NSNumber numberWithInteger:[[myarray objectAtIndex:0] intValue]],
                    @"Path": dst
                }];
            }
        }
    }

    return bookmarks;
}

- (void)bookmarkList
{
    BookmarkTableViewController *b = [[BookmarkTableViewController alloc] init];
    b.items = [self loadBookmarkForPdf:GLOBAL.pdfPath withPath:YES];
    b.delegate = self;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        
        b_outline = true;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:b];
        nav.preferredContentSize = CGSizeMake([self screenRect].size.width * 0.5, [self screenRect].size.height * 0.8);
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:nav animated:YES completion:nil];
    }
    else
    {
        b_outline = true;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:b];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

-(void)didSelectItem:(int)pageno {
    [self PDFGoto:pageno];
}

#pragma mark - View Mode

- (void)viewMenu
{
    b_outline =true;
    RDPDFOutline *root = [m_doc rootOutline];
    if( root )
    {
        OutLineViewController *outlineView = [[OutLineViewController alloc] init];
        //First parameter is root node
        [outlineView setList:m_doc :NULL :root];
        UINavigationController *nav = self.navigationController;
        outlineView.hidesBottomBarWhenPushed = YES;
        [outlineView setJump:self];
        [nav pushViewController:outlineView animated:YES];
    }
}

#pragma mark - RDTreeTableview

- (void)showTreeView {

    [self stopToolbarTimer];

    b_outline = YES;

    RDTreeTableViewController *t = [[RDTreeTableViewController alloc] init];
    t.doc = m_doc;
    t.delegate = self;

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:t];
    nav.preferredContentSize = CGSizeMake([self screenRect].size.width*0.8, [self screenRect].size.height*0.8);
    nav.modalPresentationStyle = UIModalPresentationFormSheet;

    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showBookmarkList {
    [self bookmarkList];
}

- (void)addBookmark {
    if ([self currentPageHasBookmark]) {
        // Delete the bookmark
        NSString *resultKey = [self deleteCurrentBookmark];
        NSString *message = NSLocalizedString(resultKey, nil);
        [self showToastWithMessage:message];
    } else {
        // Add the bookmark
        NSString *resultKey = [self composeFile];
        NSString *message = NSLocalizedString(resultKey, nil);
        [self showToastWithMessage:message];
    }
    [self updateBookmarkButtonAppearance];
}

- (void)showToastWithMessage:(NSString *)message {
    if (message.length == 0) {
        return;
    }

    UIView *existingToast = [self.view viewWithTag:98765];
    if (existingToast) {
        [existingToast removeFromSuperview];
    }

    UIView *toastContainer = [[UIView alloc] init];
    toastContainer.tag = 98765;
    toastContainer.translatesAutoresizingMaskIntoConstraints = NO;
    toastContainer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    toastContainer.layer.cornerRadius = 8.0f;
    toastContainer.layer.masksToBounds = YES;
    toastContainer.alpha = 0.0f;

    UILabel *toastLabel = [[UILabel alloc] init];
    toastLabel.translatesAutoresizingMaskIntoConstraints = NO;
    toastLabel.text = message;
    toastLabel.textColor = [UIColor whiteColor];
    toastLabel.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightMedium];
    toastLabel.textAlignment = NSTextAlignmentCenter;
    toastLabel.numberOfLines = 0;

    [toastContainer addSubview:toastLabel];
    [self.view addSubview:toastContainer];

    CGFloat horizontalPadding = 16.0f;
    CGFloat verticalPadding = 12.0f;

    [NSLayoutConstraint activateConstraints:@[
        [toastLabel.leadingAnchor constraintEqualToAnchor:toastContainer.leadingAnchor constant:horizontalPadding],
        [toastLabel.trailingAnchor constraintEqualToAnchor:toastContainer.trailingAnchor constant:-horizontalPadding],
        [toastLabel.topAnchor constraintEqualToAnchor:toastContainer.topAnchor constant:verticalPadding],
        [toastLabel.bottomAnchor constraintEqualToAnchor:toastContainer.bottomAnchor constant:-verticalPadding]
    ]];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [toastContainer.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [toastContainer.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-60.0f],
        [toastContainer.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor constant:-40.0f]
    ]];

    [UIView animateWithDuration:0.25f animations:^{
        toastContainer.alpha = 1.0f;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.25f animations:^{
                toastContainer.alpha = 0.0f;
            } completion:^(BOOL finishedInner) {
                if (finishedInner) {
                    [toastContainer removeFromSuperview];
                }
            }];
        });
    }];
}

#pragma mark - TreeTableviewDelegate

- (void)didSelectDest:(OUTLINE_ITEM *)item {
    [self dismissViewControllerAnimated:YES completion:^{
        [self startToolbarTimer];
        if ([item dest]) {
            [self PDFGoto:[item dest]];
        }
    }];
}

#pragma mark - Save

- (void)savePdf
{
    if([m_view forceSave])
    {
        // Export XFDF when document is saved
        //[self exportXFDFBeforeClosing];
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Notice", nil)
                                                                       message:NSLocalizedString(@"Document saved", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"OK", nil)
                             style:UIAlertActionStyleDefault
                             handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - Draw

- (void)showDrawModeTableView
{
    if (m_bSel == true)
    {
        [m_view vSelEnd];
        m_bSel = false;
    }
    
    DrawModeTableViewController *vm = [[DrawModeTableViewController alloc] init];
    vm.delegate = self;
    vm.lineImage = _lineImage;
    vm.rowImage = _rowImage;
    vm.rectImage = _rectImage;
    vm.ellipseImage = _ellipseImage;
    vm.bitmapImage = _bitmapImage;
    vm.noteImage = _noteImage;
    vm.arrowImage = _arrowImage;
    vm.tintColor = [self getTintColor];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        
        vm.modalPresentationStyle = UIModalPresentationPopover;
        vm.delegate = self;
        vm.preferredContentSize = CGSizeMake(200, (60 * 7) + 10);
        
        UIPopoverPresentationController *pop = vm.popoverPresentationController;
        pop.permittedArrowDirections = UIPopoverArrowDirectionUp;
        if (_hideSearchImage) {
            pop.barButtonItem = [toolBar.bar.items objectAtIndex:1];
        } else {
            pop.barButtonItem = [toolBar.bar.items objectAtIndex:2];
        }
        
        [self presentViewController:vm animated:YES completion:nil];
    }
    else
    {
        UIAlertController *action = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select Draw Mode", nil) message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *line = [UIAlertAction actionWithTitle:NSLocalizedString(@"Line", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self didSelectDrawMode:0];
        }];
        [line setValue:[(_rowImage) ? _rowImage : [UIImage systemImageNamed:@"line.diagonal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
        
        UIAlertAction *arrow = [UIAlertAction actionWithTitle:NSLocalizedString(@"Arrow", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self didSelectDrawMode:1];
        }];
        [arrow setValue:[(_arrowImage) ? _arrowImage : [UIImage systemImageNamed:@"arrow.up.right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
        
        UIAlertAction *rect = [UIAlertAction actionWithTitle:NSLocalizedString(@"Rect", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self didSelectDrawMode:2];
        }];
        [rect setValue:[(_rectImage) ? _rectImage : [UIImage systemImageNamed:@"rectangle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
        
        UIAlertAction *ellipse = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ellipse", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self didSelectDrawMode:3];
        }];
        [ellipse setValue:[(_ellipseImage) ? _ellipseImage : [UIImage systemImageNamed:@"circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
        
        UIAlertAction *note = [UIAlertAction actionWithTitle:NSLocalizedString(@"Note", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self didSelectDrawMode:4];
        }];
        [note setValue:[(_noteImage) ? _noteImage : [UIImage systemImageNamed:@"note.text"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];
        
        UIAlertAction *floatingText = [UIAlertAction actionWithTitle:NSLocalizedString(@"Text", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self didSelectDrawMode:5];
        }];
        [floatingText setValue:[[UIImage systemImageNamed:@"textformat"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];

        UIAlertAction *ink = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ink", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self didSelectDrawMode:6];
        }];
        [ink setValue:[[UIImage systemImageNamed:@"scribble"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];

        [action addAction:line];
        [action addAction:arrow];
        [action addAction:rect];
        [action addAction:ellipse];
        [action addAction:note];
        [action addAction:floatingText];
        [action addAction:ink];

        action.view.tintColor = [self getTintColor];
        
        // Add a cancel action to allow dismissing by tapping outside on iPhone
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
        [action addAction:cancel];

        [self presentViewController:action animated:YES completion:nil];
    }
}

- (void)didSelectDrawMode:(int)mode
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    switch (mode) {
        case 0:
            [self drawRow];
            break;
        case 1:
            [self drawArrow];
            break;
        case 2:
            [self drawRectangle];
            break;
        case 3:
            [self drawEllipse];
            break;
        case 4:
            [self drawNote];
            break;
        case 5:
            [self drawFloatingText];
            break;
        case 6:
            [self drawLine];
            break;

        default:
            break;
    }
}

- (void)showViewMoreMenu
{
    UIAlertController *action = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"View tools", nil) message:@"" preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *viewMode = [UIAlertAction actionWithTitle:NSLocalizedString(@"View Mode", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showViewModeTableView];
    }];
    [viewMode setValue:[[UIImage systemImageNamed:@"rectangle.stack"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];

    UIAlertAction *toc = [UIAlertAction actionWithTitle:NSLocalizedString(@"Table of Contents", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showTreeView];
    }];
    [toc setValue:[[UIImage systemImageNamed:@"list.bullet"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];

    UIAlertAction *bookmarkList = [UIAlertAction actionWithTitle:NSLocalizedString(@"Bookmark List", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showBookmarkList];
    }];
    [bookmarkList setValue:[[UIImage systemImageNamed:@"bookmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];

    UIAlertAction *switchView = [UIAlertAction actionWithTitle:NSLocalizedString(@"Thumb/slider", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self switchClick];
    }];
    [switchView setValue:[[UIImage systemImageNamed:@"square.grid.2x2"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forKey:@"image"];

    [action addAction:viewMode];
    [action addAction:toc];
    [action addAction:bookmarkList];
    [action addAction:switchView];
    action.view.tintColor = [self getTintColor];
    
    // Add a cancel action to allow dismissing by tapping outside on iPhone
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    [action addAction:cancel];

    [self presentViewController:action animated:YES completion:nil];
}

#pragma mark - File List Dialog

- (void)showFileList {
    [self stopToolbarTimer];
    
    b_outline = YES;
    
    RDFileListViewController *fileListVC = [[RDFileListViewController alloc] init];
    fileListVC.delegate = self;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:fileListVC];
    nav.preferredContentSize = CGSizeMake([self screenRect].size.width*0.8, [self screenRect].size.height*0.8);
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)didSelectFile:(NSString *)filePath fileName:(NSString *)fileName {
    // Dismiss the file list dialog
    [self dismissViewControllerAnimated:YES completion:^{
        b_outline = NO;
        
        if (filePath && fileName) {
            // File was selected - show toast message with the selected file name
            NSString *message = [NSString stringWithFormat:@"Selected: %@", fileName];
            [self showToastWithMessage:message];
            
            // Optionally, you can open the PDF file here
            // For now, just showing the selection confirmation
        }
        
        [self startToolbarTimer];
    }];
}

#ifdef SIGNATURE_ENABLED
- (void)drawSignature
{
    b_outline = YES;
    AdvSignatureViewController *sign = [[AdvSignatureViewController alloc] init];
    sign.delegate = self;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        sign.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self presentViewController:sign animated:YES completion:nil];
}
#endif

- (NSString *)composeFile
{
    NSString *pdfpath = [GLOBAL.pdfPath stringByAppendingPathComponent:GLOBAL.pdfName];
    RDVPos pos;
    [m_view vGetPos:&pos];
    int pageno = pos.pageno;
    NSString *tempName = [self effectiveBaseName];
    NSString *tempFile = [tempName stringByAppendingFormat:@"_%d%@",pageno,@".bookmark"];
    
    NSString *fileContent = [NSString stringWithFormat:@"%i",pageno];
    NSString *BookMarkDir = [pdfpath stringByDeletingLastPathComponent];
    
    NSString *bookMarkFile = [BookMarkDir stringByAppendingPathComponent:tempFile];
    
    if (![[NSFileManager defaultManager] isWritableFileAtPath:BookMarkDir]) {
        return @"Cannot add bookmark";
    }
    
    NSLog(@"%@", bookMarkFile);
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:bookMarkFile])
    {
        [[NSFileManager defaultManager]createFileAtPath:bookMarkFile contents:nil attributes:nil];
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:bookMarkFile];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[fileContent dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
        
        return @"Add BookMark Success!";
    }
    else {
        return @"BookMark Already Exist";
    }
}

- (BOOL)currentPageHasBookmark {
    NSString *pdfpath = [GLOBAL.pdfPath stringByAppendingPathComponent:GLOBAL.pdfName];
    RDVPos pos;
    [m_view vGetPos:&pos];
    int pageno = pos.pageno;
    NSString *tempName = [self effectiveBaseName];
    NSString *tempFile = [tempName stringByAppendingFormat:@"_%d%@",pageno,@".bookmark"];
    NSString *BookMarkDir = [pdfpath stringByDeletingLastPathComponent];
    NSString *bookMarkFile = [BookMarkDir stringByAppendingPathComponent:tempFile];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:bookMarkFile];
}

- (NSString *)deleteCurrentBookmark {
    NSString *pdfpath = [GLOBAL.pdfPath stringByAppendingPathComponent:GLOBAL.pdfName];
    RDVPos pos;
    [m_view vGetPos:&pos];
    int pageno = pos.pageno;
    NSString *tempName = [self effectiveBaseName];
    NSString *tempFile = [tempName stringByAppendingFormat:@"_%d%@",pageno,@".bookmark"];
    NSString *BookMarkDir = [pdfpath stringByDeletingLastPathComponent];
    NSString *bookMarkFile = [BookMarkDir stringByAppendingPathComponent:tempFile];
    
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:bookMarkFile]) {
        [[NSFileManager defaultManager] removeItemAtPath:bookMarkFile error:&error];
        if (error) {
            return @"Failed to delete bookmark";
        }
        return @"Bookmark Deleted";
    }
    return @"No bookmark to delete";
}

- (void)updateBookmarkButtonAppearance {
    BOOL hasBookmark = [self currentPageHasBookmark];
    if (hasBookmark) {
        if (toolBar.addBookmarkButtonView) {
            toolBar.addBookmarkButtonView.backgroundColor = RD_DISABLED_BUTTON_GRAY;
        }
    } else {
        if (toolBar.addBookmarkButtonView) {
            toolBar.addBookmarkButtonView.backgroundColor = [UIColor clearColor];
        }
    }
}

-(void)searchView
{
    [self stopToolbarTimer];
    [toolBar changeToSearchToolBar];
    
    CGRect frame = toolBar.bar.frame;
    BOOL isPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (isPhone) {
        CGFloat padding = 12.0;
        frame.origin.y = toolBar.frame.origin.y - frame.size.height - padding;
        if (frame.origin.y < 0) {
            frame.origin.y = 0;
        }
    } else {
        frame.origin.y = [self barHeightDistance];
        if (@available(iOS 26.0, *)) {
            frame.origin.y += 10.0; // extra spacing below toolbar on iOS 26+
        }
    }
    CGFloat leftInset = 0;
    if (@available(iOS 11.0, *)) {
        leftInset += self.view.safeAreaInsets.left;
    }
    leftInset += toolBar.bar.layoutMargins.left;
    frame.origin.x = leftInset;
    frame.size.width = self.view.bounds.size.width * 0.5;
    
    if (m_searchBar) {
        if (SEARCH_LIST == 1) {
            [self showSearchList];
        }
        
        return;
    }
    UIColor *txtColor = RD_TEXT_BLACK;
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setDefaultTextAttributes:@{NSForegroundColorAttributeName:txtColor, NSFontAttributeName: RD_FONT(NORMAL_FONT_SIZE)}];
    
    m_searchBar = [[UISearchBar alloc] initWithFrame:frame];
    m_searchBar.delegate = self;
    m_searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    m_searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    m_searchBar.placeholder = NSLocalizedString(@"Search", nil);
    m_searchBar.keyboardType = UIKeyboardTypeDefault;
    m_searchBar.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    m_searchBar.backgroundImage = [[UIImage alloc] init];
    m_searchBar.barTintColor = [UIColor whiteColor];
    m_searchBar.backgroundColor = [UIColor clearColor];
    m_searchBar.layer.borderWidth = 0;
    
    [self toolBarStyle];
    
    [toolBar setButtonEnabled:(m_searchBar.text.length > 0) forButton:toolBar.searchButton];
    
    //2023-05-08 TODO: disable/enable buttons
    //toolBar.searchNextbutton.enabled = false;
    //toolBar.searchPrevbutton.enabled = false;
    
    [self.view addSubview:m_searchBar];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rd_searchKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rd_searchKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [self refreshBarsPosition];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [toolBar setButtonEnabled:(searchText.length > 0) forButton:toolBar.searchButton];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return YES;
}

// While the search bar is being edited, keep it and the toolbar above the keyboard
// instead of letting the keyboard cover them (there is no automatic keyboard
// avoidance for these floating bars elsewhere in this controller).
- (void)rd_searchKeyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat keyboardTop = [self.view convertRect:keyboardFrame fromView:nil].origin.y;

    CGFloat searchBarBottom = m_searchBar.frame.origin.y + m_searchBar.frame.size.height;
    CGFloat toolBarBottom = toolBar.frame.origin.y + toolBar.frame.size.height;
    CGFloat overlap = MAX(searchBarBottom, toolBarBottom) - keyboardTop;

    if (overlap > 0) {
        [UIView animateWithDuration:duration animations:^{
            m_searchBar.transform = CGAffineTransformMakeTranslation(0, -overlap);
            toolBar.transform = CGAffineTransformMakeTranslation(0, -overlap);
        }];
    }
}

- (void)rd_searchKeyboardWillHide:(NSNotification *)notification
{
    NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration animations:^{
        m_searchBar.transform = CGAffineTransformIdentity;
        toolBar.transform = CGAffineTransformIdentity;
    }];
}

- (void)showDocReadonlyAlert
{
    NSString *str1=NSLocalizedString(@"Alert", @"Localizable");
    NSString *str2=NSLocalizedString(@"This Document is readonly", @"Localizable");
    NSString *str3=NSLocalizedString(@"OK", @"Localizable");
    UIAlertController *alter = [UIAlertController alertControllerWithTitle:str1 message:str2 preferredStyle:UIAlertControllerStyleAlert];
    [alter addAction:[UIAlertAction actionWithTitle:str3 style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alter animated:YES completion:nil];
}

- (void)initDrawToolbar {
    if (drawToolbar) {
        [drawToolbar removeFromSuperview];
        drawToolbar = nil;
    }
    drawToolbar = [UIToolbar new];
    CGRect frame = toolBar.bar.frame;
    drawToolbar.frame = frame;
    drawToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    [self toolBarStyle];
    baseToolbarHiddenBeforeDraw = toolBar.bar.hidden;
    toolBar.bar.hidden = YES;
}

- (void)teardownDrawToolbar {
    if (drawToolbar) {
        [drawToolbar removeFromSuperview];
        drawToolbar = nil;
    }
    if (toolBar && toolBar.bar) {
        toolBar.bar.hidden = baseToolbarHiddenBeforeDraw;
    }
    baseToolbarHiddenBeforeDraw = NO;
}

-(void)drawLine
{
    if(![m_view vInkStart])
    {
        [self showDocReadonlyAlert];
        return;
    }
    
    [self initDrawToolbar];
    UIBarButtonItem *drawLineCancelBtn=[[UIBarButtonItem alloc]initWithImage:[[UIImage systemImageNamed:@"xmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarStyleBlackOpaque target:self action:@selector(drawLineCancel:)];
    drawLineCancelBtn.width =30;
    drawLineCancelBtn.tintColor = [self getTintColor];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                               target:nil
                               action:nil];
    
    NSArray *toolbarItem = [[NSArray alloc]initWithObjects:drawLineCancelBtn,nil];
    [drawToolbar setItems:toolbarItem animated:NO];
    [toolBar addSubview:drawToolbar];
}
-(void)drawLineDone:(id)sender
{
    [self teardownDrawToolbar];
    [m_view vInkEnd];
}
-(void)drawLineCancel:(id)sender
{
    [self teardownDrawToolbar];
    [m_view vInkCancel];
}

- (void)drawRow
{
    if(![m_view vLineStart])
    {
        [self showDocReadonlyAlert];
        return;
    }
    
    // Set drawing mode and enter fullscreen
    currentDrawingMode = 0;
    if (!isImmersive) {
        [self hideBars];
    }
    
    [self updateFloatingButtonAppearanceForDrawing:YES];
    
    // Show tool icon button
    [self showToolIconButton:@"line.diagonal"];
}

- (void)drawRowDone
{
    [m_view vLineEnd];
    [self teardownDrawToolbar];
}

- (void)drawRowCancel
{
    [m_view vLineCancel];
    currentDrawingMode = -1;
    [self hideToolIconButton];
    [self updateFloatingButtonAppearanceForDrawing:NO];
    [self teardownDrawToolbar];
}

- (void)drawLineSettings
{
    RDAnnotSettingsViewController *settingsVC = [[RDAnnotSettingsViewController alloc] initWithType:RDAnnotSettingsTypeLine];
    [self presentViewController:settingsVC animated:YES completion:nil];
}

-(void)drawRectangle
{
    if(![m_view vRectStart])
    {
        [self showDocReadonlyAlert];
        return;
    }
    
    // Set drawing mode and enter fullscreen
    currentDrawingMode = 2;
    if (!isImmersive) {
        [self hideBars];
    }
    
    [self updateFloatingButtonAppearanceForDrawing:YES];
    
    // Show tool icon button
    [self showToolIconButton:@"rectangle"];
}
-(void)drawRectDone:(id)sender
{
    [self teardownDrawToolbar];
    [m_view vRectEnd];
}
-(void)drawRectCancel:(id)sender
{
    [m_view vRectCancel];
    currentDrawingMode = -1;
    [self hideToolIconButton];
    [self updateFloatingButtonAppearanceForDrawing:NO];
    [self teardownDrawToolbar];
}

- (void)drawRectSettings
{
    RDAnnotSettingsViewController *settingsVC = [[RDAnnotSettingsViewController alloc] initWithType:RDAnnotSettingsTypeRectangle];
    [self presentViewController:settingsVC animated:YES completion:nil];
}

-(void)drawEllipse
{
    if(![m_view vEllipseStart])
    {
        [self showDocReadonlyAlert];
        return;
    }
    
    // Set drawing mode and enter fullscreen
    currentDrawingMode = 3;
    if (!isImmersive) {
        [self hideBars];
    }
    
    [self updateFloatingButtonAppearanceForDrawing:YES];
    
    // Show tool icon button
    [self showToolIconButton:@"circle"];
}
-(void)drawEllipseDone:(id)sender
{
    [self teardownDrawToolbar];
    [m_view vEllipseEnd];
}
-(void)drawEllipseCancel:(id)sender
{
    [m_view vEllipseCancel];
    currentDrawingMode = -1;
    [self hideToolIconButton];
    [self updateFloatingButtonAppearanceForDrawing:NO];
    [self teardownDrawToolbar];
}

- (void)drawEllipseSettings
{
    RDAnnotSettingsViewController *settingsVC = [[RDAnnotSettingsViewController alloc] initWithType:RDAnnotSettingsTypeEllipse];
    [self presentViewController:settingsVC animated:YES completion:nil];
}

- (void)drawImageStart
{
    if(![m_view vImageStart]){
        [self showDocReadonlyAlert];
        return;
    }
    
    [self initDrawToolbar];
    UIBarButtonItem *drawLineCancelBtn=[[UIBarButtonItem alloc]initWithImage:[[UIImage systemImageNamed:@"xmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarStyleBlackOpaque target:self action:@selector(drawImageCancel)];
    drawLineCancelBtn.width =30;
    drawLineCancelBtn.tintColor = [self getTintColor];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                               target:nil
                               action:nil];
    
    NSArray *toolbarItem = [[NSArray alloc]initWithObjects:drawLineCancelBtn,nil];
    [drawToolbar setItems:toolbarItem animated:NO];
    [toolBar addSubview:drawToolbar];
}

- (void)drawImageDone
{
    [self teardownDrawToolbar];
    [m_view vImageEnd];
}

- (void)drawImageCancel
{
    [self teardownDrawToolbar];
    [m_view vImageCancel];
}

- (void)drawFloatingText
{
    if(![m_view vEditboxStart])
    {
        [self showDocReadonlyAlert];
        return;
    }
    textDrawingMode = YES;
    if (!isImmersive) {
        [self hideBars];
    }
    [self updateFloatingButtonAppearanceForDrawing:YES];
    [self showToolIconButton:@"textformat"];
    if (floatingButton) {
        floatingButton.userInteractionEnabled = NO;
        floatingButton.backgroundColor = RD_DISABLED_BUTTON_GRAY;
    }
}

- (void)drawEditboxDone
{
    [self teardownDrawToolbar];
    [m_view vEditboxEnd];
}

- (void)drawEditboxCancel
{
    [self teardownDrawToolbar];
    [m_view vEditboxCancel];
}

- (void)drawArrow
{
    if(![m_view vLineStart])
    {
        [self showDocReadonlyAlert];
        return;
    }
    
    // Set arrow style: start = None (0), end = Arrow (1)
    GLOBAL.g_line_style_start = 0;
    GLOBAL.g_line_style_end = 1;
    
    // Set drawing mode and enter fullscreen
    currentDrawingMode = 1;
    if (!isImmersive) {
        [self hideBars];
    }
    
    [self updateFloatingButtonAppearanceForDrawing:YES];
    
    // Show tool icon button
    [self showToolIconButton:@"arrow.up.right"];
}

- (void)drawArrowDone
{
    [m_view vLineEnd];
    [self teardownDrawToolbar];
    
    // Reset line styles to default (no arrows)
    GLOBAL.g_line_style_start = 0;
    GLOBAL.g_line_style_end = 0;
}

- (void)drawArrowCancel
{
    [m_view vLineCancel];
    currentDrawingMode = -1;
    [self hideToolIconButton];
    [self updateFloatingButtonAppearanceForDrawing:NO];
    [self teardownDrawToolbar];
    
    // Reset line styles to default (no arrows)
    GLOBAL.g_line_style_start = 0;
    GLOBAL.g_line_style_end = 0;
}

- (void)drawArrowSettings
{
    RDAnnotSettingsViewController *settingsVC = [[RDAnnotSettingsViewController alloc] initWithType:RDAnnotSettingsTypeArrow];
    [self presentViewController:settingsVC animated:YES completion:nil];
}

- (void)drawNote
{
    if(![m_view vNoteStart])
    {
        [self showDocReadonlyAlert];
        return;
    }
    noteDrawingMode = YES;
    if (!isImmersive) {
        [self hideBars];
    }
    [self updateFloatingButtonAppearanceForDrawing:YES];
    [self showToolIconButton:@"pencil"];
    if (floatingButton) {
        floatingButton.userInteractionEnabled = NO;
        floatingButton.backgroundColor = RD_DISABLED_BUTTON_GRAY;
    }
}

- (void)drawNoteDone
{
    [m_view vNoteEnd];
    [self teardownDrawToolbar];
}

- (void)drawNoteCancel
{
    [self teardownDrawToolbar];
    [m_view vNoteCancel];
}

-(void)addBookMark
{
    int pageno = 0;
    RDVPos pos;
    [m_view vGetPos :&pos];
    pageno = pos.pageno;
    float x = pos.pdfx;
    float y = pos.pdfy;
    NSString *tempFile;
    NSString *tempName;
    tempName = [GLOBAL.pdfName substringToIndex:GLOBAL.pdfName.length-4];
    tempFile = [tempName stringByAppendingFormat:@"%d%@",pageno,@".bookmark"];
    NSString *tempPath;
    tempPath = [GLOBAL.pdfPath stringByAppendingFormat:@"%@",GLOBAL.pdfName];
    NSString *fileContent = [NSString stringWithFormat:@"%@,%@,%d,%f,%f",tempPath,tempName,pageno,x,y];
    NSString *BookMarkDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    
    NSString *bookMarkFile = [BookMarkDir stringByAppendingPathComponent:tempFile];
    if(![[NSFileManager defaultManager]fileExistsAtPath:bookMarkFile])
    {
        [[NSFileManager defaultManager]createFileAtPath:bookMarkFile contents:nil attributes:nil];
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:bookMarkFile];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[fileContent dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
        NSString *str1=NSLocalizedString(@"Alert", @"Localizable");
        NSString *str2=NSLocalizedString(@"Add BookMark Success!", @"Localizable");
        NSString *str3=NSLocalizedString(@"OK", @"Localizable");
        UIAlertController *alter = [UIAlertController alertControllerWithTitle:str1 message:str2 preferredStyle:UIAlertControllerStyleAlert];
        [alter addAction:[UIAlertAction actionWithTitle:str3 style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alter animated:YES completion:nil];
    }
    else {
        NSString *str1=NSLocalizedString(@"Alert", @"Localizable");
        NSString *str2=NSLocalizedString(@"BookMark Already Exist", @"Localizable");
        NSString *str3=NSLocalizedString(@"OK", @"Localizable");
        UIAlertController *alter = [UIAlertController alertControllerWithTitle:str1 message:str2 preferredStyle:UIAlertControllerStyleAlert];
        [alter addAction:[UIAlertAction actionWithTitle:str3 style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alter animated:YES completion:nil];
    }
}

-(void)printPdf
{
    NSString *path = [GLOBAL.pdfPath stringByAppendingString:GLOBAL.pdfName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        UIAlertController *alter = [UIAlertController alertControllerWithTitle:@"Warning" message:@"PDF file not available" preferredStyle:UIAlertControllerStyleAlert];
        [alter addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alter animated:YES completion:nil];
        return;
    }
    
    NSData *myData = [NSData dataWithContentsOfFile:path];
    
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    
    if ( pic && [UIPrintInteractionController canPrintData: myData] ) {
        pic.delegate = self;
        
        UIPrintInfo *printInfo = [UIPrintInfo printInfo];
        printInfo.outputType = UIPrintInfoOutputGeneral;
        printInfo.jobName = [GLOBAL.pdfPath lastPathComponent];
        printInfo.duplex = UIPrintInfoDuplexLongEdge;
        pic.printInfo = printInfo;
        pic.showsPageRange = YES;
        pic.printingItem = myData;
        
        void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) = ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
            if (!completed && error) {
                NSLog(@"FAILED! due to error in domain %@ with error code %ld", error.domain, (long)error.code);
            }
        };
        
        [pic presentAnimated:YES completionHandler:completionHandler];
    }
    else
    {
        UIAlertController *alter = [UIAlertController alertControllerWithTitle:@"Warning" message:@"Cannot print the file" preferredStyle:UIAlertControllerStyleAlert];
        [alter addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alter animated:YES completion:nil];
    }
    isPrint = YES;
}

- (void)sharePDF
{
    NSURL *url = [NSURL fileURLWithPath:[GLOBAL.pdfPath stringByAppendingPathComponent:GLOBAL.pdfName]];
    if(url)
    {
        UIActivityViewController *a = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
        NSArray *excludedActivities = @[UIActivityTypePostToTwitter, UIActivityTypePostToFacebook,
                                        UIActivityTypePostToWeibo, UIActivityTypeMessage,
                                        UIActivityTypePrint, UIActivityTypeCopyToPasteboard,
                                        UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,
                                        UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,
                                        UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo];
        a.excludedActivityTypes = excludedActivities;
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            a.modalPresentationStyle = UIModalPresentationPopover;
            UIPopoverPresentationController *popover = a.popoverPresentationController;
            popover.barButtonItem = toolBar.moreButton; // search bar button item
        } else {
            b_outline = true;
        }
        
        [self presentViewController:a animated:YES completion:nil];
        
    }
    else
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Waring", nil)
                                                                       message:NSLocalizedString(@"Error", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"OK", nil)
                             style:UIAlertActionStyleDefault
                             handler:nil];
        
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - Search Bar Method
-(void)prevword
{
    NSString *text = m_searchBar.text;
    [m_searchBar resignFirstResponder];
    if (m_searchBar.text.length > 40 || m_searchBar.text.length <= 0)
        return;
    
    if (SEARCH_LIST == 1) {
        if ([[[RDExtendedSearch sharedInstance] searchResults] count] <= 0) {
            return;
        }
        int i = [[RDExtendedSearch sharedInstance] getPrevPageFromCurrentPage:pagenow];
        
        if (i >= 0) {
            [self PDFGoto:i];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self startSearch:text dir:-1 reset:YES];
            });
        } else {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Alert", @"Localizable")
                                                                           message:NSLocalizedString(@"Reached first occurrence", @"Localizable")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* ok = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"OK", nil)
                                 style:UIAlertActionStyleDefault
                                 handler:nil];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else {
        [self startSearch:text dir:-1 reset:NO];
    }
}

-(void)nextword
{
    NSString *text = m_searchBar.text;
    [m_searchBar resignFirstResponder];
    if (m_searchBar.text.length > 40 || m_searchBar.text.length <= 0){
        return ;
    }
    
    if (SEARCH_LIST == 1) {
        if ([[[RDExtendedSearch sharedInstance] searchResults] count] <= 0) {
            return;
        }
        int i = [[RDExtendedSearch sharedInstance] getNextPageFromCurrentPage:pagenow];
        
        if (i >= 0) {
            [self PDFGoto:i];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self startSearch:text dir:1 reset:YES];
            });
        } else {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Alert", @"Localizable")
                                                                           message:NSLocalizedString(@"Reached last occurrence", @"Localizable")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* ok = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"OK", nil)
                                 style:UIAlertActionStyleDefault
                                 handler:nil];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else {
        NSString *text = m_searchBar.text;
        [m_searchBar resignFirstResponder];
        if (m_searchBar.text.length > 40)
            return;
        
        [self startSearch:text dir:1 reset:NO];
    }
}

- (void)startSearch:(NSString *)text dir:(int)dir reset:(BOOL)reset
{
    if (reset) {
        findString = nil;
        [m_view vFindEnd];
        b_findStart = NO;
    }
    
    if (!b_findStart) {
        findString = text;
        [m_view vFindStart:text :GLOBAL.g_case_sensitive :GLOBAL.g_match_whole_word];
        b_findStart = YES;
        [m_view vFind:dir];
    } else if (text != nil && text.length > 0) {
        bool stringCmp = false;
        if (findString != NULL) {
            if(GLOBAL.g_case_sensitive)
                stringCmp = [text compare:findString] == NSOrderedSame;
            else
                stringCmp = [text caseInsensitiveCompare:findString] == NSOrderedSame;
        }
        if (!stringCmp) {
            [m_view vFindStart:text :GLOBAL.g_case_sensitive :GLOBAL.g_match_whole_word];
            findString = text;
        }
        
        [m_view vFind:dir];
    }
}

-(void)searchCancel
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && [self presentedViewController]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self startToolbarTimer];
    if (SEARCH_LIST == 1) {
        [[RDExtendedSearch sharedInstance] clearSearch];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    [m_searchBar resignFirstResponder];
    [m_searchBar removeFromSuperview];
    [toolBar changeToNormalToolBar];
    toolBar.transform = CGAffineTransformIdentity;

    findString = nil;
    [m_view vFindEnd];
    b_findStart = NO;
    m_searchBar = NULL;
    
    [self refreshCurrentPage];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)m_SearchBar
{
    NSString *text = m_SearchBar.text;
    [m_SearchBar resignFirstResponder];
    if (m_SearchBar.text.length > 40)
        return;
    
    if (SEARCH_LIST == 1) {
        [self showSearchList];
    } else {
        [self startSearch:text dir:1 reset:NO];
    }
}

#pragma mark - Search List
- (void)showSearchList
{
    if (SEARCH_LIST == 1) {
        // Hide both toolbar and search bar when showing search list
        toolBar.hidden = YES;
        m_searchBar.hidden = YES;
        
        SearchResultTableViewController *viewController = [[SearchResultTableViewController alloc] init];
        viewController.delegate = self;
        viewController.searchedString = m_searchBar.text;
        viewController.doc = m_doc;
    
        [self stopToolbarTimer];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            
            viewController.modalPresentationStyle = UIModalPresentationPopover;
            [viewController setPreferredContentSize:CGSizeMake(400, 600)];
            UIPopoverPresentationController *popover = viewController.popoverPresentationController;
            popover.barButtonItem = (UIBarButtonItem *)[toolBar.bar.items objectAtIndex:0]; // search bar button item
            
            [self presentViewController:viewController animated:YES completion:nil];
        }
        else
        {
            b_outline = YES;
            self.definesPresentationContext = YES;
            if (self.navigationController) {
                self.navigationController.definesPresentationContext = YES;
            }
            RDSearchResultsOverlayViewController *overlay = [[RDSearchResultsOverlayViewController alloc] initWithResultsController:viewController];
            searchListPresentedModally = YES;
            [self presentViewController:overlay animated:YES completion:nil];
        }
    }
}

- (void)didSelectSelectSearchResult:(int)index
{
    b_outline = NO;
    
    // Restore toolbar and search bar visibility
    toolBar.hidden = isImmersive;
    if (m_searchBar) {
        m_searchBar.hidden = isImmersive;
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self goToSearchResult:index];
        }];
    } else {
        if (searchListPresentedModally) {
            searchListPresentedModally = NO;
            [self dismissViewControllerAnimated:YES completion:^{
                [self goToSearchResult:index];
            }];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
            self.navigationController.navigationBarHidden = YES;
            [self goToSearchResult:index];
        }
    }
}

- (void)didCancelSearchResult
{
    // Restore toolbar and search bar visibility when search is cancelled
    toolBar.hidden = isImmersive;
    if (m_searchBar) {
        m_searchBar.hidden = isImmersive;
    }

    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) && searchListPresentedModally) {
        UIViewController *presented = self.presentedViewController;
        searchListPresentedModally = NO;
        if (presented && !presented.isBeingDismissed && !presented.isBeingPresented) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)goToSearchResult:(int)index
{
    [self PDFGoto:index];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startSearch:[[RDExtendedSearch sharedInstance] searchTxt] dir:1 reset:YES];
    });
}

#pragma mark - Popup Menu Method
-(void)selectIsStarting
{
    UIBarButtonItem *item = toolBar.selectButton;

    if (alreadySelected)
    {
        [item setTintColor:toolBar.bar.tintColor];

        [m_view vSelEnd];
        alreadySelected = false;
        if (selMenu.superview) {
            [selMenu removeFromSuperview];
        }
    }
    else
    {
        [item setTintColor:[UIColor lightGrayColor]];
        
        [m_view vSelEnd];
        [m_view vSelStart];
        alreadySelected = true;
    }
}

-(void)HighLight :(id)sender
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //0HighLight
        [m_view vSelMarkup :GLOBAL.g_annot_highlight_clr :0];
        [self endSelect];
    });
    
}
-(void)UnderLine :(id)sender
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //1UnderLine
        [m_view vSelMarkup:GLOBAL.g_annot_underline_clr :1];
        [self endSelect];
    });
}
-(void)StrikeOut :(id)sender
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //2strikethrough
        [m_view vSelMarkup :GLOBAL.g_annot_strikeout_clr :2];
        [self endSelect];
    });
}

- (void)endSelect
{
    if(m_bSel){
        m_bSel = false;
        [m_view vSelEnd];
    }
    
    // Toggle selection mode
    alreadySelected = YES;
    [self selectIsStarting];
}

-(void)TextAnnot
{
    b_noteAnnot = NO;
    m_bSel = false;
    b_outline = true;
    [m_view vSelEnd];
    // Capture the PDF coordinates and page at tap time to ensure correct placement on save
    RDVPos tapPos;
    [m_view vGetPos:&tapPos x:posx y:posy];
    noteTapPageIndex = tapPos.pageno;
    noteTapPdfX = tapPos.pdfx;
    noteTapPdfY = tapPos.pdfy;
    
    cachedAnnot = [m_view vGetTextAnnot:posx :posy];
    cachedAnnotRef = cachedAnnot ? [cachedAnnot getRef] : 0;
    cachedAnnotPageIndex = [m_view vGetCurrentPage];
    textAnnotVC = [[TextAnnotViewController alloc]init];
    [textAnnotVC setDelegate:self];
    
    UINavigationController *navController = [[UINavigationController alloc]
                                             initWithRootViewController:textAnnotVC];
    // A compact card sheet instead of covering the whole screen for a simple
    // two-field note editor.
    navController.modalPresentationStyle = UIModalPresentationPageSheet;
    if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet = navController.sheetPresentationController;
        sheet.detents = @[UISheetPresentationControllerDetent.mediumDetent, UISheetPresentationControllerDetent.largeDetent];
        sheet.prefersGrabberVisible = YES;
    }
    [m_view vNoteStart];
    [self presentViewController:navController animated:YES completion:^{
        
    }];
}

-(void)OnSaveTextAnnot:(NSString *)textAnnot subject:(NSString *)subject
{
    if([textAnnot isEqualToString:@""] && [subject isEqualToString:@""])
    {
        [m_view vNoteEnd];
    }
    else{
        [m_view vNoteEnd];
        // Resolve the target annotation by stored reference on the stored page
        RDPDFAnnot *target = nil;
        if(cachedAnnot)
            target = cachedAnnot;
        else if (cachedAnnotPageIndex >= 0) {
            RDPDFPage *pg = [m_doc page:cachedAnnotPageIndex];
            if (pg) {
                [pg objsStart:NO];
                int ac = pg.annotCount;
                for (int i = 0; i < ac; i++) {
                    RDPDFAnnot *a = [pg annotAtIndex:i];
                    if ([a getRef] == cachedAnnotRef) { target = a; break; }
                }
            }
        }
        //if (!target) target = cachedAnnot;
        if(target){
            [target setPopupSubject:subject];
            [target setPopupText:textAnnot];
            [m_view refreshCurrentPage];
            [m_view setModified:YES force:NO];
            int pidx = (cachedAnnotPageIndex >= 0 ? cachedAnnotPageIndex : [m_view vGetCurrentPage]);
            RDPDFPage *pg = [m_doc page:pidx];
            if (pg) {
                [pg objsStart:NO];
                // Reacquire annotation by ref to avoid stale pointer after SDK updates
                RDPDFAnnot *toSave = nil;
                int ac = pg.annotCount;
                for (int i = 0; i < ac; i++) {
                    RDPDFAnnot *a = [pg annotAtIndex:i];
                    if ([a getRef] == cachedAnnotRef) { toSave = a; break; }
                }
                if (!toSave) toSave = target;
                [self saveAnnotationToXFDF:toSave page:pg pageIndex:pidx];
            }
        } else {
            // Add note exactly where user tapped (original page and PDF coordinates)
            if (noteTapPageIndex >= 0) {
                [m_view vAddTextAnnotAtPage:noteTapPageIndex pdfx:noteTapPdfX pdfy:noteTapPdfY text:textAnnot subject:subject];
            } else {
                [m_view vAddTextAnnot:posx :posy:textAnnot :subject];
            }
        }
    }
    // Deselect annotation after exiting sticky note editor
    [m_view vAnnotEnd];
    cachedAnnot = nil;
    cachedAnnotRef = 0;
    cachedAnnotPageIndex = -1;
}

-(void)OnDeleteTextAnnot
{
    // Resolve the target annotation by stored reference on the stored page
    RDPDFAnnot *target = nil;
    if(cachedAnnot)
        target = cachedAnnot;
    else if (cachedAnnotPageIndex >= 0) {
        RDPDFPage *pg = [m_doc page:cachedAnnotPageIndex];
        if (pg) {
            [pg objsStart:NO];
            int ac = pg.annotCount;
            for (int i = 0; i < ac; i++) {
                RDPDFAnnot *a = [pg annotAtIndex:i];
                if ([a getRef] == cachedAnnotRef) { target = a; break; }
            }
        }
    }
    if (target && ![target isLocked]) {
        NSString *nm = [target getName];
        [m_view removeAnnot:target];
        [self deleteXFDFForAnnotName:nm];
        [m_view refreshCurrentPage];
        [m_view setModified:YES force:NO];
    }
    // Deselect annotation after exiting sticky note editor
    [m_view vAnnotEnd];
    cachedAnnot = nil;
    cachedAnnotRef = 0;
    cachedAnnotPageIndex = -1;
}

-(void)OnSettingsForAnnot
{
    if (!cachedAnnot) return;
    int atype = [cachedAnnot type];
    if (atype == 1 || atype == 17) {
        NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"DlgAnnotPropIcon" owner:self options:nil];
        DlgAnnotPropIcon *view = [views lastObject];
        PDFDialog *dlg = [[PDFDialog alloc] init:view :CGRectMake(0, 0, 300, 260) :YES :^(BOOL is_ok){
            if (is_ok) {
                [view updateAnnot];
                [m_view setModified:YES force:NO];
                // Resolve the target annotation by stored reference on the stored page and export to XFDF
                PDF_OBJ_REF aref = cachedAnnot ? [cachedAnnot getRef] : 0;
                int pidx = (cachedAnnotPageIndex >= 0 ? cachedAnnotPageIndex : [m_view vGetCurrentPage]);
                RDPDFPage *pg = [m_doc page:pidx];
                if (pg) {
                    [pg objsStart:NO];
                    RDPDFAnnot *toSave = nil;
                    int ac = pg.annotCount;
                    for (int i = 0; i < ac; i++) {
                        RDPDFAnnot *a = [pg annotAtIndex:i];
                        if ([a getRef] == aref) { toSave = a; break; }
                    }
                    if (!toSave) toSave = cachedAnnot;
                    if (toSave) {
                        NSString *nm = [toSave getName];
                        if (nm.length == 0) [toSave setName:[[[NSUUID alloc] init] UUIDString]];
                        [self saveAnnotationToXFDF:toSave page:pg pageIndex:pidx];
                    }
                }
                [m_view refreshCurrentPage];
            }
        }];
        [view setAnnot:cachedAnnot :dlg];
        [view setTitle:@"Note settings"];
        UIViewController *presenter = textAnnotVC.navigationController ?: textAnnotVC ?: self;
        if (presenter.presentedViewController) {
            presenter = presenter.presentedViewController;
        }
        [presenter presentViewController:dlg animated:YES completion:nil];
    }
}

- (void)refreshStatusBarHeight {
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        statusBarHeight = window.safeAreaInsets.top;
    } else {
        statusBarHeight = 20;
    }
}

-(void)refreshStatusBar{
    [self setNeedsStatusBarAppearanceUpdate];
}

-(BOOL)prefersStatusBarHidden
{
    return statusBarHidden;
}

#pragma mark - lib methods

- (RDPDFDoc *)getDoc
{
    return m_doc;
}

- (int)getCurrentPage
{
    return [m_view vGetCurrentPage];
}

- (CGImageRef)imageForPage:(int)pg
{
    CGRect bounds = [self screenRect];
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        if (bounds.size.height > bounds.size.width) {
            bounds.size.width = bounds.size.height;
            bounds.size.height = [[[[UIApplication sharedApplication] delegate] window] bounds].size.width;
        }
    }
    
    RDPDFPage *page = [m_doc page:pg];;
    float w = [m_doc pageWidth:pg];
    float h = [m_doc pageHeight:pg];
    int iw = w;
    int ih = h;
    PDF_DIB m_dib = NULL;
    PDF_DIB bmp = Global_dibGet(m_dib, iw, ih);
    float ratiox = 1;
    float ratioy = 1;
    
    if (ratiox>ratioy) {
        ratiox = ratioy;
    }
    
    ratiox = ratiox * 1.0;
    PDF_MATRIX mat = Matrix_createScale(ratiox, -ratiox, 0, h * ratioy);
    PDF_Page_renderPrepare(page.handle, bmp);
    PDF_Page_render(page.handle, bmp, mat, false, 1);
    Matrix_destroy(mat);
    page = nil;
    
    void *data = Global_dibGetData(bmp);
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, iw * ih * 4, NULL);
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGImageRef imgRef = CGImageCreate(iw, ih, 8, 32, iw<<2, cs, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst, provider, NULL, FALSE, kCGRenderingIntentDefault);
    
    
    CGContextRef context = CGBitmapContextCreate(NULL, (bounds.size.width - ((bounds.size.width - iw) / 2)) * 1, ih * 1, 8, 0, cs, kCGImageAlphaPremultipliedLast);
    
    
    // Draw ...
    //
    CGContextSetAlpha(context, 1);
    CGContextSetRGBFillColor(context, (CGFloat)0.0, (CGFloat)0.0, (CGFloat)0.0, (CGFloat)1.0 );
    CGContextDrawImage(context, CGRectMake(((bounds.size.width- iw) / 2), 1, iw, ih), imgRef);
    
    
    // Get your image
    //
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    
    CGColorSpaceRelease(cs);
    CGDataProviderRelease(provider);
    
    return cgImage;
}

- (void)setThumbnailBGColor:(int)color
{
    [m_Thumbview setThumbBackgroundColor:color];
}

- (void)setThumbGridBGColor:(int)color
{
    gridBackgroundColor = color;
}

- (void)setThumbGridElementHeight:(float)height
{
    gridElementHeight = height;
}

- (void)setThumbGridGap:(float)gap
{
    gridGap = gap;
}

- (void)setThumbGridViewMode:(int)mode
{
    gridMode = mode;
}

- (void)setReaderBGColor:(int)color
{
    [m_view setReaderBackgroundColor:color];
}

- (void)setToolbarColor:(int)color {
    toolbarColor = UIColorFromRGB(color);
}

- (void)setToolbarTintColor:(int)color {
    toolbarTintColor = UIColorFromRGB(color);
}


- (void)setThumbHeight:(float)height
{
    thumbViewHeight = height;
    CGRect rect = [self screenRect];
    m_Thumbview.frame = CGRectMake(0, rect.size.height - thumbViewHeight, rect.size.width, thumbViewHeight);
    [m_Thumbview sizeThatFits:m_Thumbview.frame.size];
}

- (void)setFirstPageCover:(BOOL)cover
{
    firstPageCover = cover;
}

- (void)setDoubleTapZoomMode:(int)mode
{
    doubleTapZoomMode = mode;
}

- (void)setImmersive:(BOOL)immersive
{
    isImmersive = immersive;
    
    if (isImmersive) {
        [self hideBars];
    } else {
        [self showBars];
    }
}

#pragma mark - Attachments

- (BOOL)saveImageFromAnnotAtIndex:(int)index atPage:(int)pageno savePath:(NSString *)path size:(CGSize )size
{
    return [m_view saveImageFromAnnotAtIndex:index atPage:pageno savePath:path size:size];
}

#pragma mark - Annot render

- (BOOL)addAttachmentFromPath:(NSString *)path
{
    return [m_view addAttachmentFromPath:path];
}

#pragma mark - Flat annot

- (bool)flatAnnotAtPage:(int)page doc:(RDPDFDoc *)doc
{
    if (doc == nil) {
        doc = [[RDPDFDoc alloc] init];
        [doc open:[GLOBAL.pdfPath stringByAppendingPathComponent:GLOBAL.pdfName] :@""];
    }
    
    if(page >= 0 && page < doc.pageCount)
    {
        RDPDFPage *ppage = [doc page:page];
        [ppage objsStart:NO];
        if ([ppage flatAnnots]) {
            return [doc save];
        }
    }
    
    return NO;
}

- (bool)flatAnnots
{
    RDPDFDoc *doc = [[RDPDFDoc alloc] init];
    if (m_doc == nil) {
        [doc open:[GLOBAL.pdfPath stringByAppendingPathComponent:GLOBAL.pdfName] :@""];
    } else {
        doc = m_doc;
    }
    for (int page = 0; page != [doc pageCount]; page++) {
        [self flatAnnotAtPage:page doc:doc];
        if (page == [m_view vGetCurrentPage]) [m_view refreshCurrentPage];
    }
    return nil;
}

#pragma mark - Save document

- (bool)saveDocumentToPath:(NSString *)path
{
    NSString *prefix = @"file://";
    if([path rangeOfString:prefix].location != NSNotFound)
    {
        path = [path substringFromIndex:prefix.length];
    }
    return [m_doc saveAs:path: NO];
}

#pragma mark - Form Manager

- (NSString *)getJSONFormFields
{
    RDFormManager *fe = [[RDFormManager alloc] initWithDoc:m_doc];
    return [fe jsonInfoForAllPages];
}

- (NSString *)getJSONFormFieldsAtPage:(int)page
{
    RDFormManager *fe = [[RDFormManager alloc] initWithDoc:m_doc];
    return [fe jsonInfoForPage:page];
}

- (NSString *)setFormFieldWithJSON:(NSString *)json
{
    RDFormManager *fe = [[RDFormManager alloc] initWithDoc:m_doc];
    
    NSError *error;
    if (json && json.length > 0) {
        [fe setInfoWithJson:json error:&error];
        
        if (error) {
            return error.description;
        } else
        {
            [self refreshCurrentPage];
        }
    } else
    {
        return @"JSON not valid";
    }
    
    return @"";
}

#pragma mark - Utils Method

- (void)clearTempFiles
{
    //delete temp files
    for(int i=0; i<[tempfiles count];i++)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:[tempfiles objectAtIndex:i] error:nil];
        [tempfiles removeObjectAtIndex:i];
    }
}

- (float)barHeightDistance
{
    return toolBar.bar.frame.size.height + statusBarHeight;
}

- (CGRect)screenRect
 {
     CGRect viewRect = self.view.bounds;
     if (!CGRectIsEmpty(viewRect) && viewRect.size.width > 0 && viewRect.size.height > 0) {
         return viewRect;
     }

    return [[UIScreen mainScreen] bounds];
}

- (UIColor *)getBarColor {
    /*UIColor *barColor = (self.navigationController.navigationBar.barTintColor) ? self.navigationController.navigationBar.barTintColor : [UIColor grayColor];
    
    if (toolbarColor) {
        barColor = toolbarColor;
    }*/
    
    UIColor *barColor = RD_BACKGROUND_GRAY;
    return [barColor colorWithAlphaComponent:1];
}

- (UIColor *)getTintColor {
    /*UIColor *tintColor = (self.navigationController.navigationBar.tintColor) ? self.navigationController.navigationBar.tintColor : [UIColor redColor];
    
    if (toolbarTintColor) {
        tintColor = toolbarTintColor;
    }
    */
    return RD_COLOR;
}

- (void)toolBarStyle
{
    BOOL isLiquidGlass = NO;
    if (@available(iOS 26.0, *)) {
        isLiquidGlass = YES;
    }

    toolBar.bar.translucent = isLiquidGlass ? YES : NO;

    //set tint
    toolBar.bar.tintColor = [self getTintColor];
    if (isLiquidGlass) {
        // iOS 26's floating toolbar already draws its own inset "pill"
        // background via Liquid Glass. Forcing an opaque full-width fill
        // behind it left a flat gray strip visible on either side of the
        // pill, so let the system glass material be the only fill here.
        toolBar.backgroundColor = [UIColor clearColor];
        toolBar.bar.barTintColor = nil;
    } else {
        toolBar.backgroundColor = toolBar.bar.barTintColor = [self getBarColor];
    }

    toolBar.pageField.textColor = RD_TEXT_BLACK;
    
    if (@available(iOS 13.0, *)) {
        
    } else {
        UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
        
        if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
            statusBar.backgroundColor = [self getBarColor];
        }
    }
}

- (void)showBars
{
    if ([self isDrawingModeActive]) {
        return;
    }

    //CGFloat buttonWidth = OUTLINE_WIDTH;
    BOOL isPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    CGFloat toolbarTranslationY = isPhone ? toolBar.frame.size.height : -toolBar.frame.size.height;
    
    m_Thumbview.hidden = !showThumb;
    m_slider.hidden = showThumb;
    
    [self refreshBarsPosition];
    
    m_Thumbview.transform = CGAffineTransformMakeTranslation(0, m_Thumbview.frame.size.height);
    m_slider.transform = CGAffineTransformMakeTranslation(0, m_slider.frame.size.height);
    _outlineTableView.transform = CGAffineTransformMakeTranslation(-_outlineTableView.frame.size.width , 0);
    toolBar.transform = CGAffineTransformMakeTranslation(0, toolbarTranslationY);

    [pageNumLabel setHidden:false];
    toolBar.hidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [m_searchBar setHidden:NO];
    _outlineTableView.hidden = (outlineItems.count == 0);
    statusBarHidden = NO;
    isImmersive = NO;
    [self didZoom:m_view.zoomScale];
    [self.view bringSubviewToFront:m_Thumbview];
    if (m_slider) {
        [self.view bringSubviewToFront:m_slider];
    }
    [self.view bringSubviewToFront:toolBar];
    if (m_searchBar) {
        [self.view bringSubviewToFront:m_searchBar];
    }
    [self refreshStatusBar];
    
    [UIView animateWithDuration:0.3 animations:^{
        m_Thumbview.transform = CGAffineTransformIdentity;
        m_slider.transform = CGAffineTransformIdentity;
        _outlineTableView.transform = CGAffineTransformIdentity;
        toolBar.transform = CGAffineTransformIdentity;
        if(GLOBAL.g_enable_fab) {
            [self setRoundedFloatingButton:NO];
            [floatingButton setImage:[[UIImage systemImageNamed:@"arrow.up.left.and.arrow.down.right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
    } completion:^(BOOL finished) {
        [self refreshBarsPosition];
        [self.view bringSubviewToFront:m_Thumbview];
        if (m_slider) {
            [self.view bringSubviewToFront:m_slider];
        }
        [self.view bringSubviewToFront:toolBar];
        if (m_searchBar) {
            [self.view bringSubviewToFront:m_searchBar];
        }
        [self updateFloatingButtonPosition];
        [self startToolbarTimer];
    }];
}

- (void)hideBars
{
    BOOL isPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    CGFloat toolbarTranslationY = isPhone ? toolBar.frame.size.height : -toolBar.frame.size.height;
    
    [UIView animateWithDuration:0.3 animations:^{
        m_Thumbview.transform = CGAffineTransformMakeTranslation(0, m_Thumbview.frame.size.height);
        m_slider.transform = CGAffineTransformMakeTranslation(0, m_slider.frame.size.height);
        _outlineTableView.transform = CGAffineTransformMakeTranslation(-_outlineTableView.frame.size.width , 0);
        toolBar.transform = CGAffineTransformMakeTranslation(0, toolbarTranslationY);
        if(GLOBAL.g_enable_fab) {
            [self setRoundedFloatingButton:YES];
            [floatingButton setImage:[[UIImage systemImageNamed:@"arrow.down.right.and.arrow.up.left"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
    } completion:^(BOOL finished) {
        m_Thumbview.hidden =YES;
        m_slider.hidden = YES;
        [pageNumLabel setHidden:true];
        toolBar.hidden = YES;
        [m_searchBar resignFirstResponder];
        [m_searchBar setHidden:YES];
        _outlineTableView.hidden = YES;
        statusBarHidden = YES;
        isImmersive = YES;
        [self didZoom:m_view.zoomScale];

        m_Thumbview.transform = CGAffineTransformIdentity;
        m_slider.transform = CGAffineTransformIdentity;
        _outlineTableView.transform = CGAffineTransformIdentity;
        toolBar.transform = CGAffineTransformIdentity;
        
        [self refreshStatusBar];
        [self updateFloatingButtonPosition];
    }];
}

- (void)refreshCurrentPage
{
    [m_view refreshCurrentPage];
}

- (UIColor *)transparentBackground {
    return [RD_BACKGROUND_GRAY colorWithAlphaComponent:.8];
}

- (void)initFloatingButton {
    if (!GLOBAL.g_enable_fab) {
        return;
    }
    
    if (!floatingButton) {
        // 2023-05-08 halved the size OUTLINE_WIDTH / 2
        floatingButton = [[UIButton alloc] initWithFrame:CGRectMake(toolBar.frame.size.width - FAB_SIZE - 25, self.view.frame.size.height - m_Thumbview.frame.size.height - FAB_SIZE - 25, FAB_SIZE, FAB_SIZE)];
        floatingButton.backgroundColor = RD_COLOR;
        floatingButton.titleLabel.text = @"";
        floatingButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        floatingButton.layer.shadowOffset = CGSizeMake(0, 1);
        floatingButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        floatingButton.layer.shadowOpacity = 0;
        [floatingButton setImage:[[UIImage systemImageNamed:(isImmersive) ? @"arrow.down.right.and.arrow.up.left" : @"arrow.up.left.and.arrow.down.right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        floatingButton.tintColor = [UIColor whiteColor];
        [floatingButton addTarget:self action:@selector(toggleBars) forControlEvents:UIControlEventTouchUpInside];
        [self setRoundedFloatingButton:NO];
    }
}

- (void)setRoundedFloatingButton:(BOOL)usingThumb {
    if (!GLOBAL.g_enable_fab) {
        return;
    }
    // 2023-05-08 halved the size OUTLINE_WIDTH / 2
    //CGFloat buttonWidth = OUTLINE_WIDTH / 2;
    //floatingButton.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(.9, .9), CGAffineTransformMakeTranslation(-10, thumbSize - 10));
    floatingButton.transform = CGAffineTransformMakeScale(.9, .9);
    floatingButton.layer.cornerRadius = FAB_SIZE / 2;
    floatingButton.layer.shadowOpacity = 1;
}

- (void)updateFloatingButtonPosition {
    if (!GLOBAL.g_enable_fab || !floatingButton) {
        return;
    }
    BOOL isPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    CGFloat bottomOffset = 25; // padding from bottom elements
    CGFloat buttonX = self.view.frame.size.width - FAB_SIZE - 25;
    CGFloat buttonY;

    // The Dynamic Island sits at a fixed physical spot near the top-center of
    // the device. In landscape that rotates to the vertical center of one of
    // the side edges - safe area insets don't reflect this (they're symmetric
    // left/right in landscape), but the interface orientation reliably tells
    // us which edge: LandscapeRight always puts it on the right edge.
    BOOL isLandscape = self.view.frame.size.width > self.view.frame.size.height;
    BOOL islandOnRight = NO;
    if (isPhone && isLandscape) {
        UIInterfaceOrientation orientation = UIInterfaceOrientationUnknown;
        if (@available(iOS 13.0, *)) {
            orientation = self.view.window.windowScene.interfaceOrientation;
        } else {
            orientation = [UIApplication sharedApplication].statusBarOrientation;
        }
        islandOnRight = (orientation == UIInterfaceOrientationLandscapeLeft);
    }

    if (islandOnRight) {
        buttonX = self.view.frame.size.width - FAB_SIZE - 25;
        buttonY = 25;
    } else if (isPhone) {
        if (isImmersive) {
            UIEdgeInsets insets = UIEdgeInsetsZero;
            if (@available(iOS 11.0, *)) {
                insets = self.view.safeAreaInsets;
            }
            buttonY = self.view.frame.size.height - FAB_SIZE - bottomOffset - insets.bottom;
        } else {
            buttonY = self.view.frame.size.height - thumbViewHeight - toolBar.barHeight - FAB_SIZE - bottomOffset;
            UIEdgeInsets insets = UIEdgeInsetsZero;
            if (@available(iOS 11.0, *)) {
                insets = self.view.safeAreaInsets;
            }
            buttonY -= insets.bottom;
        }
    } else {
        buttonY = self.view.frame.size.height - m_Thumbview.frame.size.height - FAB_SIZE - bottomOffset;
    }

    floatingButton.frame = CGRectMake(buttonX, buttonY, FAB_SIZE, FAB_SIZE);

    if (toolIconButton) {
        CGFloat toolButtonY = islandOnRight ?
            (floatingButton.frame.origin.y + FAB_SIZE + 15) :
            (floatingButton.frame.origin.y - FAB_SIZE - 15);
        toolIconButton.frame = CGRectMake(floatingButton.frame.origin.x, toolButtonY, FAB_SIZE, FAB_SIZE);
        toolIconButton.transform = floatingButton.transform;
    }
}

- (void)initTableViews
{
    int safeArea = [self barHeightDistance];

    [_outlineTableView removeFromSuperview];

    [self initFloatingButton];

    //start fill outlineItems
    [self initOutlineDocItems];

    [self setRoundedFloatingButton:NO];

    if (showSXToolbar) {
        fIndex = -1;
        //outline table view

        _outlineTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, safeArea, OUTLINE_WIDTH, self.view.frame.size.height-safeArea-m_Thumbview.frame.size.height)];
        _outlineTableView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        _outlineTableView.delegate = self;
        _outlineTableView.dataSource = self;
        _outlineTableView.tag = 0;
        _outlineTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _outlineTableView.backgroundColor = [self transparentBackground];

        _outlineTableView.hidden = isImmersive || (outlineItems.count == 0);

        [self.view addSubview:_outlineTableView];
    }

    if (floatingButton) {
        [self.view addSubview:floatingButton];
    }
}

- (void)initOutlineDocItems
{
    outlineItems = [NSMutableArray array];
    RDPDFOutline *root = [m_doc rootOutline];
    while(root)
    {
        OUTLINE_ITEM *outline_item = [[OUTLINE_ITEM alloc]init];
        outline_item.label = [root label];
        outline_item.dest = [root dest];

        root = [root next];

        [outlineItems addObject:outline_item];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return outlineItems.count;
}

- (OutlineTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    OutlineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[OutlineTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [cell initCellWithSize:CGSizeMake(self.outlineTableView.frame.size.width, OUTLINE_ROW_HEIGHT)];

    [cell.indexLabel setText:@""];
    [cell.detailLabel setText:@""];
    OUTLINE_ITEM *outline = (OUTLINE_ITEM *)[outlineItems objectAtIndex:indexPath.row];
    NSString *outlineNum = [NSString string];
    NSString *outlineDetail = [NSString string];
    if ([outline.label rangeOfString:@"SECTION "].location != NSNotFound) {
        NSString *clean = [RDUtils cleanString:outline.label];
        clean = [clean stringByReplacingOccurrencesOfString:@"SECTION " withString:@""];
        outlineNum = [clean substringToIndex:[clean rangeOfString:@" "].location];
        outlineDetail = [NSString stringWithFormat:@"%@", [clean substringFromIndex:[clean rangeOfString:@" "].location + 1]];
        [cell.indexLabel setText:outlineNum];
        [cell.detailLabel setText:outlineDetail];
    } else {
        if ([[outline.label uppercaseString] rangeOfString:@"TABLE OF CONTENTS"].location != NSNotFound) {
            [cell.indexLabel setText:@"TOC"];
        } else {
            if (fIndex == -1 || fIndex == indexPath.row) {
                fIndex = (int)indexPath.row;
                [cell.indexLabel setText:@"F"];
            }
        }
        [cell.detailLabel setText:outline.label];
    }

    [self startToolbarTimer];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return OUTLINE_ROW_HEIGHT;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self PDFGoto:[(OUTLINE_ITEM *)[outlineItems objectAtIndex:indexPath.row] dest]];
    OutlineTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell editCellWithScale:0.95];
}

- (BOOL)deleteAllBookmarks
{
    if (!currentPdfPath || ![[NSFileManager defaultManager] fileExistsAtPath:currentPdfPath]) {
        //NSLog(@"Invalid PDF path");
        return NO;
    }
    
    NSString *pdfDirectory = [currentPdfPath stringByDeletingLastPathComponent];
    NSMutableArray *bookmarks = [self loadBookmarkForPdf:pdfDirectory withPath:YES];
    
    if (bookmarks.count == 0) {
        //NSLog(@"No bookmarks to delete");
        return YES; // No bookmarks to delete
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL allDeleted = YES;
    int deletedCount = 0;
    
    for (NSArray *bookmark in bookmarks) {
        if (bookmark.count > 1) {
            NSString *bookmarkPath = [bookmark objectAtIndex:1];
            NSError *error = nil;
            
            if ([fm removeItemAtPath:bookmarkPath error:&error]) {
                deletedCount++;
            } else {
                //NSLog(@"Error deleting bookmark at %@: %@", bookmarkPath, error.localizedDescription);
                allDeleted = NO;
            }
        }
    }
    
    //NSLog(@"Deleted %d of %lu bookmarks", deletedCount, (unsigned long)bookmarks.count);
    return allDeleted;
}

#pragma mark - XFDF Per-Annotation Management

- (NSString *)xfdfDirectoryForCurrentPDF {
    if (!currentPdfPath || currentPdfPath.length == 0) return nil;

    // Create XFDF directory in the same folder as the PDF file
    NSString *pdfDirectory = [currentPdfPath stringByDeletingLastPathComponent];
    NSString *pdfBaseName = [self effectiveBaseName];
    NSString *xfdfDir = [pdfDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"XFDF/%@", pdfBaseName]];

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:xfdfDir]) {
        NSError *err = nil;
        [fm createDirectoryAtPath:xfdfDir withIntermediateDirectories:YES attributes:nil error:&err];
        if (err) {
            //NSLog(@"[XFDF] Failed to create directory: %@", err);
            return nil;
        }
    }
    return xfdfDir;
}

- (void)saveAnnotationToXFDF:(RDPDFAnnot *)annot page:(RDPDFPage *)page pageIndex:(int)pageIndex {
    if (!annot || !page) return;
    
    NSString *xfdfDir = [self xfdfDirectoryForCurrentPDF];
    if (!xfdfDir) return;
    
    [page objsStart:NO];
    NSString *annotName = [annot getName];
    //TODO remove after done
    //NSLog(@"[XFDF] Saving annotation: %@", annotName);
    
    // Sanitize annot id for filename matching
    NSCharacterSet *illegal = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.@"] invertedSet];
    NSString *sanitizedAnnotId = annotName.length ? [[annotName componentsSeparatedByCharactersInSet:illegal] componentsJoinedByString:@"_"] : @"";
    
    // Remove any previous XFDF files for this annot id (regardless of page)
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *lsErr = nil;
    NSArray *files = [fm contentsOfDirectoryAtPath:xfdfDir error:&lsErr];
    if (!lsErr && sanitizedAnnotId.length) {
        NSString *suffix = [NSString stringWithFormat:@"_%@.xfdf", sanitizedAnnotId];
        for (NSString *fn in files) {
            if ([fn hasSuffix:suffix]) {
                NSString *oldPath = [xfdfDir stringByAppendingPathComponent:fn];
                [fm removeItemAtPath:oldPath error:nil];
            }
        }
    }
    
    // Get PDF filename without extension
    NSString *pdfFileName = [self effectiveBaseName];
    
    NSString *resultPath = [RDSeparateXFDFHelper exportAnnotation:annot 
                                                      toDirectory:xfdfDir 
                                                             page:page 
                                                        pageIndex:pageIndex 
                                                      pdfFileName:pdfFileName];
    if (resultPath) {
        //NSLog(@"[XFDF] Saved annotation to: %@", resultPath);
    } else {
        //NSLog(@"[XFDF] Failed to save annotation: %@", annotName);
    }
}

// Delete any XFDF files associated with the given annot name for this PDF
- (void)deleteXFDFForAnnotName:(NSString *)annotName {
    if (!annotName) return;
    NSString *xfdfDir = [self xfdfDirectoryForCurrentPDF];
    if (!xfdfDir) return;
    // Sanitize annot id same as writer
    NSCharacterSet *illegal = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.@"] invertedSet];
    NSString *sanitizedAnnotId = [[annotName componentsSeparatedByCharactersInSet:illegal] componentsJoinedByString:@"_"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *lsErr = nil;
    NSArray *files = [fm contentsOfDirectoryAtPath:xfdfDir error:&lsErr];
    if (lsErr) return;
    NSString *suffix = [NSString stringWithFormat:@"_%@.xfdf", sanitizedAnnotId];
    for (NSString *fn in files) {
        if ([fn hasSuffix:suffix]) {
            [fm removeItemAtPath:[xfdfDir stringByAppendingPathComponent:fn] error:nil];
        }
    }
}

- (void)loadAllXFDFAnnotations {
    NSString *xfdfDir = [self xfdfDirectoryForCurrentPDF];
    if (!xfdfDir) return;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err = nil;
    NSArray *files = [fm contentsOfDirectoryAtPath:xfdfDir error:&err];
    if (err) {
        //NSLog(@"[XFDF] Error reading XFDF directory: %@", err);
        return;
    }
    
    int totalImported = 0;
    for (NSString *fileName in files) {
        if ([fileName.pathExtension isEqualToString:@"xfdf"]) {
            NSString *filePath = [xfdfDir stringByAppendingPathComponent:fileName];
            int count = [RDSeparateXFDFHelper importAnnotationFromPath:filePath toDocument:m_doc];
            if (count > 0) {
                totalImported += count;
            }
        }
    }
    
    if (totalImported > 0) {
        //NSLog(@"[XFDF] Loaded %d annotations from XFDF files", totalImported);
        [m_view refreshCurrentPage];
    }
}

#pragma mark - File Naming Helpers

- (NSString *)effectiveBaseName {
    if (currentDocumentId && currentDocumentId.length > 0) {
        return currentDocumentId;
    }
    if (currentPdfPath && currentPdfPath.length > 0) {
        return [[[currentPdfPath lastPathComponent] stringByDeletingPathExtension] copy];
    }
    if (GLOBAL.pdfName) {
        return [[GLOBAL.pdfName stringByDeletingPathExtension] copy];
    }
    return @"";
}

- (NSString *)statePathForExtension:(NSString *)ext {
    if (!currentPdfPath || ext.length == 0) return nil;
    NSString *dir = [currentPdfPath stringByDeletingLastPathComponent];
    NSString *base = [self effectiveBaseName];
    return [[dir stringByAppendingPathComponent:base] stringByAppendingPathExtension:ext];
}

@end

