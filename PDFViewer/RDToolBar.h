//
//  RDAnnotToolBar.h
//  PDFViewer
//
//  Created by strong on 2018/3/26.
//

#import <UIKit/UIKit.h>

#define ICON_WIDTH 40

@protocol RDToolBarDelegate

// normalbar delegate
- (void)closeView;
- (void)searchView;
- (void)showDrawModeTableView;
- (void)selectIsStarting;
- (void)toggleGrid;
- (void)showMoreButtons;
//performbar delegate
- (void)nextword;
- (void)prevword;
- (void)searchCancel;
//searchbar delegate
- (void)performAnnot;
- (void)deleteAnnot;
- (void)annotCancel;
//goto delegate
- (void)goToPage:(int)page;
- (void)goToPrevPage;
- (void)goToNextPage;
- (void)showTreeView;
- (void)showBookmarkList;
- (void)addBookmark;
//xamarin callback
- (void)shareClick;
- (void)didSelectTextField;
//swicth slider/thumb
- (void)switchClick;
// request VC to end/deselect current annotation selection
- (void)endCurrentAnnotationSelection;
//view more menu (iPhone only)
- (void)showViewMoreMenu;
//file list dialog
- (void)showFileList;

@end

@interface RDToolBar : UIView

@property (nonatomic, strong) UIToolbar *bar;
@property (nonatomic, strong) UIBarButtonItem *moreButton;
@property (nonatomic, strong) UIBarButtonItem *searchButton;
@property (nonatomic, strong) UIBarButtonItem *searchPrevbutton;
@property (nonatomic, strong) UIBarButtonItem *searchNextbutton;
@property (nonatomic, strong) UIBarButtonItem *annotationButton;
@property (nonatomic, strong) UIBarButtonItem *selectButton;
@property (nonatomic, strong) UIBarButtonItem *bookmarkButton;
@property (nonatomic, strong) UIBarButtonItem *addBookmarkButton;
@property (nonatomic, strong) UIButton *addBookmarkButtonView;
@property (nonatomic, strong) UITextField *pageField;
@property (nonatomic, strong) UITextField *pagesField;
@property (nonatomic,weak) id<RDToolBarDelegate> m_delegate;

@property (strong, nonatomic) UIImage *closeImage;
@property (strong, nonatomic) UIImage *searchImage;
@property (strong, nonatomic) UIImage *gridImage;
@property (strong, nonatomic) UIImage *deleteImage;
@property (strong, nonatomic) UIImage *doneImage;
@property (strong, nonatomic) UIImage *tocImage;
@property (strong, nonatomic) UIImage *undoImage;
@property (strong, nonatomic) UIImage *redoImage;
@property (strong, nonatomic) UIImage *performImage;
@property (strong, nonatomic) UIImage *moreImage;
@property (strong, nonatomic) UIImage *drawImage;
@property (strong, nonatomic) UIImage *selectImage;
@property (strong, nonatomic) UIImage *nextImage;
@property (strong, nonatomic) UIImage *bookmarkImage;
@property (strong, nonatomic) UIImage *addBookmarkImage;

@property (nonatomic) BOOL hideSearchImage;
@property (nonatomic) BOOL hideDrawImage;
@property (nonatomic) BOOL hideSelImage;
@property (nonatomic) BOOL hideUndoImage;
@property (nonatomic) BOOL hideRedoImage;
@property (nonatomic) BOOL hideMoreImage;
@property (nonatomic) BOOL hideGridImage;

@property (nonatomic) int barHeight;

- (void)setupToolBarArray;
- (void)changeToPerformToolBar;
- (void)changeToSearchToolBar;
- (void)changeToNormalToolBar;
- (void)setButtonEnabled:(BOOL)enabled forButton:(UIBarButtonItem *)button;
- (void)moreClick;

@end
