//
//  RDFileListViewController.m
//  PDFViewer
//
//  File list dialog similar to TOC
//

#import "RDFileListViewController.h"
#import "RDVGlobal.h"
#import "PDFObjc.h"
#import "RDUtils.h"

@interface RDFileListViewController () {
    NSMutableArray *files;
    NSMutableDictionary *thumbnailCache;
}

@end

@implementation RDFileListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.navigationController.navigationBar.bounds.size.height)];
    titleLabel.text = NSLocalizedString(@"File List", nil);
    titleLabel.font = RD_TITLE_FONT(BIG_FONT_SIZE) ?: [UIFont systemFontOfSize:BIG_FONT_SIZE weight:UIFontWeightRegular];
    titleLabel.textColor = RD_TEXT_GRAY;
    self.navigationItem.titleView = titleLabel;
    
    UIImage *empty = [[UIImage alloc] init];
    self.navigationController.navigationBar.shadowImage = empty;
    self.navigationController.navigationBar.tintColor = RD_COLOR;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    // Set table view appearance
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = RD_BACKGROUND_GRAY;
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.backgroundColor = [UIColor whiteColor];
   
    UIImage *closeImage = [[UIImage systemImageNamed:@"xmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithImage:closeImage style:UIBarButtonItemStylePlain target:self action:@selector(closeView)];
    closeButton.tintColor = RD_COLOR;
    self.navigationItem.rightBarButtonItem = closeButton;
    
    files = [NSMutableArray array];
    thumbnailCache = [NSMutableDictionary dictionary];
    
    // Get the documents directory
    if (!_currentDirectory) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        _currentDirectory = [paths objectAtIndex:0];
    }
    
    // Load PDF files
    [self loadPDFFiles];
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.view.superview.layer.cornerRadius = 0;
}

- (void)loadPDFFiles {
    [files removeAllObjects];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *fenum = [fm enumeratorAtPath:_currentDirectory];
    NSString *fName;
    
    while(fName = [fenum nextObject]) {
        BOOL dir;
        NSString *fullPath = [_currentDirectory stringByAppendingPathComponent:fName];
        
        if([fm fileExistsAtPath:fullPath isDirectory:&dir]) {
            if(!dir && [fName hasSuffix:@".pdf"]) {
                NSArray *arr = [[NSArray alloc] initWithObjects:fName, fullPath, nil];
                [files addObject:arr];
            }
        }
    }
    
    // Sort files alphabetically
    [files sortUsingComparator:^NSComparisonResult(NSArray *obj1, NSArray *obj2) {
        NSString *name1 = [obj1 objectAtIndex:0];
        NSString *name2 = [obj2 objectAtIndex:0];
        return [name1 localizedCaseInsensitiveCompare:name2];
    }];
}

- (void)closeView {
    if (_delegate) {
        [_delegate didSelectFile:nil fileName:nil];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FileCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor whiteColor];
        
        // Set text label properties
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        UIFont *fileFont = [UIFont fontWithName:@"PublicSans-Regular" size:NORMAL_FONT_SIZE];
        cell.textLabel.font = fileFont ? fileFont : [UIFont systemFontOfSize:NORMAL_FONT_SIZE weight:UIFontWeightRegular];
        cell.textLabel.textColor = RD_TEXT_BLACK;
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    
    NSArray *fileInfo = [files objectAtIndex:indexPath.row];
    NSString *fileName = [fileInfo objectAtIndex:0];
    cell.textLabel.text = fileName;
    
    // Check if we have a cached thumbnail
    NSString *filePath = [fileInfo objectAtIndex:1];
    UIImage *cachedImage = [thumbnailCache objectForKey:filePath];
    if (cachedImage) {
        cell.imageView.image = cachedImage;
    } else {
        // Set placeholder image
        UIImage *placeholder = [[UIImage systemImageNamed:@"doc.text"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.imageView.image = placeholder;
        cell.imageView.tintColor = RD_COLOR;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80.0; // Taller to accommodate thumbnail
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *fileInfo = [files objectAtIndex:indexPath.row];
    NSString *fileName = [fileInfo objectAtIndex:0];
    NSString *filePath = [fileInfo objectAtIndex:1];
    
    if (_delegate) {
        [_delegate didSelectFile:filePath fileName:fileName];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.indentationLevel = 0;
    cell.indentationWidth = 0;
    cell.separatorInset = UIEdgeInsetsMake(0, 16.0, 0, 0);
    if (@available(iOS 11.0, *)) {
        cell.contentView.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(0, 0, 0, 0);
    }
    
    // Generate thumbnail asynchronously
    NSArray *fileInfo = [files objectAtIndex:indexPath.row];
    NSString *filePath = [fileInfo objectAtIndex:1];
    
    // Only generate if not already cached
    if (![thumbnailCache objectForKey:filePath]) {
        [NSThread detachNewThreadSelector:@selector(updateImageForCellAtIndexPath:) toTarget:self withObject:indexPath];
    }
}

- (void)updateImageForCellAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= files.count) {
        return;
    }
    
    NSArray *row_item = [files objectAtIndex:indexPath.row];
    NSString *path = [row_item objectAtIndex:1];
    CGImageRef img_ref = nil;
    
    @synchronized (self) {
        const char *cpath = [path UTF8String];
        PDF_ERR err;
        PDF_DOC m_docThumb = PDF_Document_open(cpath, nil, &err);
        
        if (m_docThumb == NULL) {
            return;
        }
        
        PDF_PAGE page = PDF_Document_getPage(m_docThumb, 0);
        if (!page) {
            PDF_Document_close(m_docThumb);
            return;
        }
        
        float w = PDF_Document_getPageWidth(m_docThumb, 0);
        float h = PDF_Document_getPageHeight(m_docThumb, 0);
        PDF_DIB m_dib = NULL;
        
        // Thumbnail size
        int iw = 60;
        int ih = 80;
        
        PDF_DIB bmp = Global_dibGet(m_dib, iw, ih);
        float ratiox = iw/w;
        float ratioy = ih/h;
        if (ratiox > ratioy) ratiox = ratioy;
        
        PDF_MATRIX mat = Matrix_createScale(ratiox, -ratiox, 0, h * ratioy);
        PDF_Page_renderPrepare(page, bmp);
        PDF_Page_render(page, bmp, mat, false, 1);
        Matrix_destroy(mat);
        PDF_Page_close(page);
        
        if (m_docThumb) PDF_Document_close(m_docThumb);
        
        void *data = Global_dibGetData(bmp);
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, iw * ih * 4, NULL);
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        img_ref = CGImageCreate(iw, ih, 8, 32, iw<<2, cs, kCGBitmapByteOrder32Little|kCGImageAlphaNoneSkipFirst, provider, NULL, FALSE, kCGRenderingIntentDefault);
        CGColorSpaceRelease(cs);
        CGDataProviderRelease(provider);
    }
    
    if (img_ref) {
        UIImage *img = [UIImage imageWithCGImage:img_ref];
        
        // Cache the thumbnail
        dispatch_async(dispatch_get_main_queue(), ^{
            [thumbnailCache setObject:img forKey:path];
            
            // Update the cell if it's still visible
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            if (cell) {
                cell.imageView.image = img;
                [cell setNeedsLayout];
            }
        });
        
        CGImageRelease(img_ref);
    }
}

@end
