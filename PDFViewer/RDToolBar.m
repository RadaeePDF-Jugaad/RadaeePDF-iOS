//
//  RDAnnotToolBar.m
//  PDFViewer
//
//  Created by strong on 2018/3/26.
//

#import "RDToolBar.h"
#import "RDVGlobal.h"
#import "RDUtils.h"

@interface RDToolBar()
{
    NSMutableArray *normalToolBarArray;
    NSArray *performToolBarArray;
    NSArray *searchToolBarArray;
}
@end

@implementation RDToolBar

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.bar = [[UIToolbar alloc] init];
        self.bar.barStyle = UIBarStyleDefault;
        self.bar.tintColor = RD_COLOR;
        [self.bar sizeToFit];
    }
    return self;
}

- (void)setupToolBarArray
{
    self.bar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _barHeight = self.bar.frame.size.height;
    
    self.bar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    
    UIImage *closeImg = (_closeImage) ? _closeImage : [[UIImage systemImageNamed:@"chevron.backward"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithImage:closeImg style:UIBarButtonItemStylePlain target:self action:@selector(closeClick)];
    closeButton.width = ICON_WIDTH;
    closeButton.tintColor = RD_COLOR;

    UIImage *TOCImg = (_tocImage) ? _tocImage : [[UIImage systemImageNamed:@"list.bullet"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *TOCButton = [[UIBarButtonItem alloc] initWithImage:TOCImg style:UIBarButtonItemStylePlain target:self action:@selector(showToc)];
    TOCButton.width = ICON_WIDTH;
    TOCButton.tintColor = RD_COLOR;

    UIImage *leftImg = [[UIImage systemImageNamed:@"chevron.left"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    /*
    UIBarButtonItem *prevButton=[[UIBarButtonItem alloc]initWithImage:leftImg style:UIBarStyleBlackOpaque target:self action:@selector(prevPage)];
    prevButton.width = ICON_WIDTH;
    
    [self initPageField];
    UIBarButtonItem *pageButton = [[UIBarButtonItem alloc] initWithCustomView:_pageField];
    pageButton.width = ICON_WIDTH;
    
    [self initPagesField];
    UIBarButtonItem *pagesButton = [[UIBarButtonItem alloc] initWithCustomView:_pagesField];
    pagesButton.width = ICON_WIDTH;
    */
    UIImage *rightImg = (_nextImage) ? _nextImage : [[UIImage systemImageNamed:@"chevron.right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    //UIBarButtonItem *nextButton=[[UIBarButtonItem alloc]initWithImage:rightImg style:UIBarStyleBlackOpaque target:self action:@selector(nextPage)];
    //nextButton.width = ICON_WIDTH;
    
    UIImage *annotationImg = (_drawImage) ? _drawImage : [[UIImage systemImageNamed:@"pencil"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _annotationButton = [[UIBarButtonItem alloc] initWithImage:annotationImg style:UIBarButtonItemStylePlain target:self action:@selector(annotationClick)];
    _annotationButton.width = ICON_WIDTH;
    _annotationButton.tintColor = RD_COLOR;

    UIImage *searchImg = (_searchImage) ? _searchImage : [[UIImage systemImageNamed:@"magnifyingglass"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _searchButton = [[UIBarButtonItem alloc]initWithImage:searchImg style:UIBarStyleBlackOpaque target:self action:@selector(searchClick)];
    _searchButton.width = ICON_WIDTH;
    _searchButton.tintColor = RD_COLOR;

    UIImage *selectImg = (_selectImage) ? _selectImage : [[UIImage systemImageNamed:@"character.cursor.ibeam"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _selectButton = [[UIBarButtonItem alloc]initWithImage:selectImg style:UIBarButtonItemStylePlain target:self action:@selector(selectClick)];
    _selectButton.width = ICON_WIDTH;
    _selectButton.tintColor = RD_COLOR;
    
    /*UIImage *mailImg = [UIImage imageNamed:GLOBAL.g_custom_button_name];
    UIBarButtonItem *mailButton = [[UIBarButtonItem alloc]initWithImage:mailImg style:UIBarStyleBlackOpaque target:self action:@selector(shareClick)];
    mailButton.width = ICON_WIDTH;*/
    
    
    UIImage *switchImg = [[UIImage systemImageNamed:@"square.grid.2x2"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *switchButton = [[UIBarButtonItem alloc]initWithImage:switchImg style:UIBarStyleBlackOpaque target:self action:@selector(switchClick)];
    switchButton.width = ICON_WIDTH;
    switchButton.tintColor = RD_COLOR;

    // File List button (using same icon as switchButton for testing)
    UIImage *fileListImg = [[UIImage systemImageNamed:@"square.grid.2x2"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *fileListButton = [[UIBarButtonItem alloc]initWithImage:fileListImg style:UIBarStyleBlackOpaque target:self action:@selector(fileListClick)];
    fileListButton.width = ICON_WIDTH;
    fileListButton.tintColor = RD_COLOR;
    
    UIImage *viewMoreImg;
    if (@available(iOS 13.0, *)) {
        viewMoreImg = [[UIImage systemImageNamed:@"ellipsis"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    if (!viewMoreImg) {
        viewMoreImg = [[UIImage systemImageNamed:@"ellipsis"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    UIBarButtonItem *viewMoreButton = [[UIBarButtonItem alloc]initWithImage:viewMoreImg style:UIBarStyleBlackOpaque target:self action:@selector(viewMoreClick)];
    viewMoreButton.width = ICON_WIDTH;
    viewMoreButton.tintColor = RD_COLOR;
    
    UIImage *bookmarkImg = (_bookmarkImage) ? _bookmarkImage : [[UIImage systemImageNamed:@"bookmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _bookmarkButton = [[UIBarButtonItem alloc]initWithImage:bookmarkImg style:UIBarStyleBlackOpaque target:self action:@selector(bookmarkClick)];
    _bookmarkButton.width = ICON_WIDTH;
    _bookmarkButton.tintColor = RD_COLOR;
    
    UIImage *addBookmarkImg = (_addBookmarkImage) ? _addBookmarkImage : [[UIImage systemImageNamed:@"bookmark.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.addBookmarkButtonView = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.addBookmarkButtonView setImage:addBookmarkImg forState:UIControlStateNormal];
    self.addBookmarkButtonView.tintColor = RD_COLOR;
    self.addBookmarkButtonView.backgroundColor = [UIColor clearColor];
    self.addBookmarkButtonView.frame = CGRectMake(0, 0, ICON_WIDTH + 8, 32);
    self.addBookmarkButtonView.layer.cornerRadius = 6.0;
    self.addBookmarkButtonView.layer.masksToBounds = YES;
    self.addBookmarkButtonView.contentEdgeInsets = UIEdgeInsetsMake(4, 6, 4, 6);
    [self.addBookmarkButtonView addTarget:self action:@selector(addBookmarkClick) forControlEvents:UIControlEventTouchUpInside];
    _addBookmarkButton = [[UIBarButtonItem alloc] initWithCustomView:self.addBookmarkButtonView];
    
    BOOL shouldIncludeSeparators = YES;
    if (@available(iOS 26.0, *)) {
        shouldIncludeSeparators = NO;
    }
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        if (shouldIncludeSeparators) {
            normalToolBarArray = [[NSMutableArray alloc] initWithObjects: closeButton, [self getSeparator], TOCButton, [self getSeparator], _addBookmarkButton, [self getSeparator], _bookmarkButton, [self getSeparator], _annotationButton, [self getSeparator], _selectButton, [self getSeparator], _searchButton, [self getSeparator], fileListButton, [self getSeparator]/*, mailButton*/, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],nil];
        } else {
            normalToolBarArray = [[NSMutableArray alloc] initWithObjects: closeButton, TOCButton, _addBookmarkButton, _bookmarkButton, _annotationButton, _selectButton, _searchButton, /*fileListButton*/ switchButton /*, mailButton*/, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],nil];
        }
    }

    else
    {
        // iPhone: group TOC, bookmark list, and switch into viewMoreButton
        normalToolBarArray = [[NSMutableArray alloc] initWithObjects: closeButton, _addBookmarkButton, _annotationButton, _selectButton, _searchButton, viewMoreButton,nil];
    }
    
    /*
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [normalToolBarArray removeObject:pagesButton];
    }
    */
    
    
    _searchNextbutton=[[UIBarButtonItem alloc]initWithImage:rightImg style:UIBarStyleBlackOpaque target:self action:@selector(nextword)];
    _searchNextbutton.width = ICON_WIDTH;
    _searchNextbutton.tintColor = RD_COLOR;
    
    
    _searchPrevbutton=[[UIBarButtonItem alloc]initWithImage:leftImg style:UIBarStyleBlackOpaque target:self action:@selector(prevword)];
    _searchPrevbutton.width = ICON_WIDTH;
    _searchPrevbutton.tintColor = RD_COLOR;
    
    UIImage *removeImg = [[UIImage systemImageNamed:@"xmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *searchCancelbtn=[[UIBarButtonItem alloc]initWithImage:removeImg style:UIBarStyleBlackOpaque target:self action:@selector(searchCancel)];
    searchCancelbtn.width = ICON_WIDTH;
    searchCancelbtn.tintColor = RD_COLOR;
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    searchToolBarArray = [[NSArray alloc]initWithObjects:_searchButton,_searchPrevbutton,_searchNextbutton,searchCancelbtn, flexSpace, nil];
    
    [self addSubview:self.bar];
    
    [self changeToNormalToolBar];
}

- (UIBarButtonItem *) getSeparator
{
    UILabel *separatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 1, 22)];
    separatorLabel.backgroundColor = RD_TEXT_GRAY;
    UIBarButtonItem *separator = [[UIBarButtonItem alloc] initWithCustomView:separatorLabel];
    separator.width = 1;
    
    return separator;
}

- (void)initPageField
{
    _pageField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 50, 20)];
    _pageField.backgroundColor = [UIColor clearColor];
    [_pageField setBorderStyle:UITextBorderStyleNone];
    CALayer *topBorder = [CALayer layer];
    topBorder.borderColor = [UIColor darkGrayColor].CGColor;
    topBorder.borderWidth = 1;
    topBorder.frame = CGRectMake(0, _pageField.frame.size.height - topBorder.borderWidth, _pageField.frame.size.width, 1);
    _pageField.layer.masksToBounds = YES;
    [_pageField.layer addSublayer:topBorder];
    _pageField.textAlignment = NSTextAlignmentCenter;
    [_pageField setKeyboardType:UIKeyboardTypeNumberPad];
    [_pageField addTarget:self action:@selector(textFieldDidChange)forControlEvents:UIControlEventEditingDidEndOnExit];
    [_pageField addTarget:self action:@selector(didSelectTextField)forControlEvents:UIControlEventEditingDidBegin];
    _pageField.font = RD_FONT(NORMAL_FONT_SIZE);
    _pageField.returnKeyType = UIReturnKeyGo;
    _pageField.textColor = RD_TEXT_BLACK;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, 50)];
        numberToolbar.barStyle = UIBarStyleBlackTranslucent;
        numberToolbar.items = @[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(didTypePage)]];
        [numberToolbar sizeToFit];
        numberToolbar.barTintColor = RD_BACKGROUND_GRAY;
        numberToolbar.tintColor = RD_COLOR;
        _pageField.inputAccessoryView = numberToolbar;
    }
}

- (void)initPagesField
{
    _pagesField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 60, 20)];
    _pagesField.textColor = RD_TEXT_GRAY;
    _pagesField.backgroundColor = [UIColor clearColor];
    [_pagesField setBorderStyle:UITextBorderStyleNone];
    _pagesField.userInteractionEnabled = NO;
    _pagesField.font = RD_FONT(NORMAL_FONT_SIZE);
}

- (void)changeToPerformToolBar
{
    [self.bar setItems:performToolBarArray];
}

- (void)changeToSearchToolBar
{
    [self.bar setItems:searchToolBarArray];
}

- (void)changeToNormalToolBar
{
    [self setButtonEnabled:YES forButton:_searchButton];
    [self.bar setItems:normalToolBarArray];
}

- (void)setButtonEnabled:(BOOL)enabled forButton:(UIBarButtonItem *)button
{
    // For bar buttons with custom views (our custom buttons)
    if ([button.customView isKindOfClass:[UIButton class]]) {
        UIButton *customButton = (UIButton *)button.customView;
        customButton.enabled = enabled;
        customButton.tintColor = enabled ? RD_COLOR : RD_DISABLED_BUTTON_GRAY;
        return;
    }
    
    button.tintColor = enabled ? RD_COLOR : RD_DISABLED_BUTTON_GRAY;
}

#pragma mark - Delegate
// normalbar delegate
- (void)closeClick
{
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    if (self.m_delegate) {
        [_m_delegate closeView];
    }
}
- (void)searchClick
{
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    if (self.m_delegate) {
        [_m_delegate searchView];
    }
}

- (void)annotationClick
{
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    if (self.m_delegate) {
        [_m_delegate showDrawModeTableView];
    }
}

- (void)switchClick
{
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    if (self.m_delegate) {
        [_m_delegate switchClick];
    }
}

- (void)selectClick
{
    if (self.m_delegate) {
        [_m_delegate selectIsStarting];
    }
}

/*
- (void)drawModeClick;
{
    if (self.m_delegate) {
        [_m_delegate showDrawModeTableView];
    }
}
- (void)undoClick;
{
    if (self.m_delegate) {
        [_m_delegate undoAnnot];
    }
}
- (void)redoClick;
{
    if (self.m_delegate) {
        [_m_delegate redoAnnot];
    }
}
- (void)gridlick;
{
    if (self.m_delegate) {
        [_m_delegate toggleGrid];
    }
}
- (void)moreClick;
{
    if (self.m_delegate) {
        [_m_delegate showMoreButtons];
    }
}
 */
//performbar delegate
- (void)nextword;
{
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    if (self.m_delegate) {
        [_m_delegate nextword];
    }
}
- (void)prevword;
{
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    if (self.m_delegate) {
        [_m_delegate prevword];
    }
}
- (void)searchCancel;
{
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    if (self.m_delegate) {
        [_m_delegate searchCancel];
    }
}
//searchbar delegate
- (void)performAnnot;
{
    if (self.m_delegate) {
        [_m_delegate performAnnot];
    }
}
/*
- (void)deleteAnnot;
{
    if (self.m_delegate) {
        [_m_delegate deleteAnnot];
    }
}
 */

- (void)annotCancel;
{
    if (self.m_delegate) {
        [_m_delegate annotCancel];
    }
}

- (void)textFieldDidChange
{
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    [_m_delegate goToPage:[_pageField.text intValue]-1];
}

- (void)didSelectTextField {
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    [_m_delegate didSelectTextField];
}

- (void)didTypePage {
    [self textFieldDidChange];
    [_pageField resignFirstResponder];
}

- (void)prevPage
{
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    [_m_delegate goToPrevPage];
}

- (void)nextPage
{
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    [_m_delegate goToNextPage];
}

- (void)showToc {
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    [_m_delegate showTreeView];
}

- (void)shareClick
{
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    [_m_delegate shareClick];
}

- (void)bookmarkClick
{
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    if (self.m_delegate) {
        [_m_delegate showBookmarkList];
    }
}

- (void)addBookmarkClick
{
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    if (self.m_delegate) {
        [_m_delegate addBookmark];
    }
}

- (void)viewMoreClick
{
    NSLog(@"[RDKeyboardLog] \"...\" (viewMoreButton) tapped");
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    if (self.m_delegate) {
        [_m_delegate showViewMoreMenu];
    }
}

- (void)fileListClick
{
    if (self.m_delegate) {
        [_m_delegate endCurrentAnnotationSelection];
    }
    if (self.m_delegate) {
        [_m_delegate showFileList];
    }
}

@end
