//
//  RDFileTableController.m
//  PDFViewer
//
//  Created by Radaee on 12-10-29.
//  Copyright (c) 2012年 Radaee. All rights reserved.
//

#import "RDFileTableController.h"
#import <MobileCoreServices/MobileCoreServices.h>

NSMutableString *pdfName;
NSMutableString *pdfPath;
static NSString *pdfFullPath;

@interface RDFileTableController () <UIDocumentPickerDelegate>

@end

@implementation RDFileTableController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        
    }
    return self;
}
#pragma mark -addFiles
- (void)addPDFs:(NSString *)dpath :(NSString *)subdir :(NSFileManager *)fm :(int)level
{
    NSString *path = [dpath stringByAppendingFormat:@"/%@", subdir];
    NSDirectoryEnumerator *fenum = [fm enumeratorAtPath:path];
    NSString *fName;
    while(fName = [fenum nextObject])
    {
        BOOL dir;
        NSString *dst = [path stringByAppendingFormat:@"%@",fName];
        pdfPath = (NSMutableString *)path;
        if( [fm fileExistsAtPath:dst isDirectory:&dir] )
        {
            if( dir )
            {
                [self addPDFs:dpath :dst :fm :level+1];
            }
            else if( [dst hasSuffix:@".pdf"] )
            {
                NSString *dis = [subdir stringByAppendingFormat:@"%@",fName];//display name
                
                //add to list
                NSArray *arr = [[NSArray alloc] initWithObjects:dis,dst,level, nil];
                [m_files addObject:arr];
            }
        }
    }
}

- (void)delPDFs:(NSString *)dpath :(NSString *)subdir :(NSFileManager *)fm :(int)level
{
    NSString *path = [dpath stringByAppendingFormat:@"/%@", subdir];
    NSDirectoryEnumerator *fenum = [fm enumeratorAtPath:path];
    NSString *fName;
    while(fName = [fenum nextObject])
    {
        BOOL dir;
        NSString *dst = [path stringByAppendingFormat:@"/%@",fName];
        if( [fm fileExistsAtPath:dst isDirectory:&dir] )
        {
            if( dir )
            {
                [self addPDFs:dpath :dst :fm :level+1];
            }
            else if( [dst hasSuffix:@".pdf"] )
            {
                NSString *dis = [subdir stringByAppendingFormat:@"%@",fName];//display name
                
                NSArray *arr = [[NSArray alloc] initWithObjects:dis,dst,level, nil];
                
                [m_files addObject:arr];
            }
        }
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if([[[UIDevice currentDevice]systemVersion] floatValue]>=7.0)
    {
        UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
        temporaryBarButtonItem.title = @"";
        self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    }
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dpath=[paths objectAtIndex:0];
    NSFileManager *fm = [NSFileManager defaultManager];
    m_files = [[NSMutableArray alloc] init];
    m_thumbnailsRequested = [[NSMutableSet alloc] init];
    m_thumbnailCache = [[NSMutableDictionary alloc] init];
    [self addPDFs:dpath :@"" :fm :0];

    NSString *title = [[NSString alloc] initWithFormat:NSLocalizedString(@"All Files", @"Localizable")];
    self.title = title;
    UITabBarItem *item = [[UITabBarItem alloc]initWithTitle:title image:[UIImage systemImageNamed:@"doc.text"] tag:0];
    
    self.tabBarItem =item;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    [self initSettingWithUserDefault:dpath];
    //test demo for PDFMemOpen or PDFStreamOpen or HTTPPDFStream，click right button
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd  target:self action:@selector(selectRightAction)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
    
}
-(void)selectRightAction
{
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[(NSString *)kUTTypePDF] inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    if (@available(iOS 13.0, *)) {
        picker.allowsMultipleSelection = YES;
    }
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dpath = [paths objectAtIndex:0];

    for (NSURL *url in urls) {
        NSString *destPath = [dpath stringByAppendingPathComponent:url.lastPathComponent];
        if ([fm fileExistsAtPath:destPath]) {
            [fm removeItemAtPath:destPath error:nil];
        }
        NSError *error = nil;
        [fm copyItemAtURL:url toURL:[NSURL fileURLWithPath:destPath] error:&error];
        if (error) {
            NSLog(@"Failed to import PDF %@: %@", url.lastPathComponent, error);
        }
    }

    [self reloadFileList];
}

- (void)reloadFileList
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dpath = [paths objectAtIndex:0];
    NSFileManager *fm = [NSFileManager defaultManager];
    [m_files removeAllObjects];
    [self addPDFs:dpath :@"" :fm :0];
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (BOOL)shouldAutorotate
{
    return YES;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 84;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return m_files.count;
}

- (NSString *)formattedFileSizeAtPath:(NSString *)path
{
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    unsigned long long bytes = [attrs fileSize];
    return [NSByteCountFormatter stringFromByteCount:bytes countStyle:NSByteCountFormatterCountStyleFile];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FileCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        cell.imageView.clipsToBounds = YES;
        cell.imageView.layer.cornerRadius = 6.0;
        cell.imageView.layer.borderWidth = 1.0;
        cell.imageView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
    }

    NSArray *arr = [m_files objectAtIndex:indexPath.row];
    NSString *displayName = [arr objectAtIndex:0];
    NSString *path = [arr objectAtIndex:1];

    cell.textLabel.text = [displayName stringByDeletingPathExtension];
    cell.textLabel.font = RD_FONT_BOLD(NORMAL_FONT_SIZE);
    cell.textLabel.numberOfLines = 1;
    cell.detailTextLabel.text = [self formattedFileSizeAtPath:path];
    cell.detailTextLabel.font = RD_FONT(SMALL_FONT_SIZE);
    cell.detailTextLabel.textColor = RD_TEXT_GRAY;

    UIImage *cached = [m_thumbnailCache objectForKey:path];
    if (cached) {
        cell.imageView.image = cached;
        cell.imageView.tintColor = nil;
    } else {
        UIImage *placeholder = [[UIImage systemImageNamed:@"doc.richtext"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.imageView.image = placeholder;
        cell.imageView.tintColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    }

    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSUInteger row = [indexPath row];
    
    if( m_pdf == nil )
    {
        m_pdf = [[RDLoPDFViewController alloc] initWithNibName:@"RDLoPDFViewController" bundle:nil];
    }
    
    NSArray *row_item = [m_files objectAtIndex:indexPath.row];
    NSString *path = [row_item objectAtIndex:1];
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:path error:nil];
    [m_files removeObjectAtIndex:row];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    //GEAR
    [self loadSettingsWithDefaults];
    //END
    NSArray *row_item = [m_files objectAtIndex:indexPath.row];
    NSString *path = [row_item objectAtIndex:1];
    
    pdfName = (NSMutableString *)[path substringFromIndex:pdfPath.length];
    pdfFullPath = path;
    
    if( m_pdf == nil )
    {
        m_pdf = [[RDLoPDFViewController alloc] initWithNibName:@"RDLoPDFViewController" bundle:nil];
    }
    NSString *Enterpassword =[[NSString alloc]initWithFormat:NSLocalizedString(@"Please Enter PassWord", @"Localizable")];
    NSString *ok = [[NSString alloc]initWithFormat:NSLocalizedString(@"OK", @"Localizable")];
    NSString *cancel = [[NSString alloc]initWithFormat:NSLocalizedString(@"Cancel", @"Localizable")];
    RDUPassWord* pwdDlg = [[RDUPassWord alloc]
                           initWithTitle:Enterpassword
                           message:nil
                           delegate:self
                           cancelButtonTitle:ok
                           otherButtonTitles:cancel, nil];
    
    NSLock *theLock = [[NSLock alloc] init];
    
    if(GLOBAL.g_render_mode == 5) {
        m_pdfR = [[RDPDFReflowViewController alloc] initWithNibName:@"RDPDFReflowViewController" bundle:nil];
        // Serialize against the background thumbnail-render thread (see
        // updateImageForCellAtIndexPath), which touches the same PDF library
        // state and is not safe to run concurrently with opening a document.
        @synchronized (self) {
            [m_pdfR PDFOpen:pdfFullPath];
        }

        m_pdfR.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:m_pdfR animated:YES];
        return;
    }

    if ([theLock tryLock])
    {
        NSString *pwd = NULL;

        int result;
        @synchronized (self) {
            result = [m_pdf PDFOpen:pdfFullPath :pwd :-1 :GLOBAL.g_render_mode :GLOBAL.g_show_outline_sidebar :@"" :NO :@""];
        }
        //int result = [m_pdf PDFOpen:pdfFullPath :pwd];

        if(result == 1)
        {
            m_pdf.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:m_pdf animated:YES];
        }
        //return value is encryption document
        else if(result == 2)
        {
            [pwdDlg show];
        }
        else if (result == 0)
        {
            NSString *str1=NSLocalizedString(@"Alert", @"Localizable");
            NSString *str2=NSLocalizedString(@"Error Document,Can't open", @"Localizable");
            NSString *str3=NSLocalizedString(@"OK", @"Localizable");
            UIAlertController *alter = [UIAlertController alertControllerWithTitle:str1 message:str2 preferredStyle:UIAlertControllerStyleAlert];
            [alter addAction:[UIAlertAction actionWithTitle:str3 style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alter animated:YES completion:nil];
        }
        [theLock unlock];
    }
}
- (void)alertView:(UIAlertView *)pwdDlg clickedButtonAtIndex:(NSInteger)buttonIndex
{
    int result;
    NSString *pwd;
    if ([[[UIDevice currentDevice] systemVersion] floatValue]>=7.0)
    {
        UITextField *tf = [pwdDlg textFieldAtIndex:0];
        pwd = tf.text;
    }
    if(buttonIndex == 0)
    {
        @synchronized (self) {
            result = [m_pdf PDFOpen:pdfFullPath :pwd];
        }

        if(result == 1)
        {
            UINavigationController *nav = self.navigationController;
            m_pdf.hidesBottomBarWhenPushed = YES;
            nav.hidesBottomBarWhenPushed =NO;
            [nav pushViewController:m_pdf animated:YES];
        }
        else if(result == 2)
        {
            NSString *str1=NSLocalizedString(@"Alert", @"Localizable");
            NSString *str2=NSLocalizedString(@"Error PassWord", @"Localizable");
            NSString *str3=NSLocalizedString(@"OK", @"Localizable");
            UIAlertController *alter = [UIAlertController alertControllerWithTitle:str1 message:str2 preferredStyle:UIAlertControllerStyleAlert];
            [alter addAction:[UIAlertAction actionWithTitle:str3 style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alter animated:YES completion:nil];
        }
    }
    
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
}

- (void)loadSettingsWithDefaults
{
    GLOBAL.g_case_sensitive = [[NSUserDefaults standardUserDefaults] boolForKey:@"CaseSensitive"];
    GLOBAL.g_match_whole_word = [[NSUserDefaults standardUserDefaults] boolForKey:@"MatchWholeWord"];
    
    GLOBAL.g_screen_awake = [[NSUserDefaults standardUserDefaults] boolForKey:@"KeepScreenAwake"];
    [[UIApplication sharedApplication] setIdleTimerDisabled:GLOBAL.g_screen_awake];

    GLOBAL.g_show_outline_sidebar = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowOutlineSidebar"];
    GLOBAL.g_dark_mode = [[NSUserDefaults standardUserDefaults] boolForKey:@"DarkMode"];

    GLOBAL.g_render_mode =  (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"ViewMode"];

    //for curl mode
    GLOBAL.g_curl_enabled = (GLOBAL.g_render_mode == 6);

    GLOBAL.g_ink_color = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"InkColor"];
    if(GLOBAL.g_ink_color ==0)
    {
        GLOBAL.g_ink_color =0xFF000000;
    }

    GLOBAL.g_ink_width = [[NSUserDefaults standardUserDefaults] floatForKey:@"InkWidth"];
    if (GLOBAL.g_ink_width == 0) {
        GLOBAL.g_ink_width = 2.0f;
    }

    GLOBAL.g_rect_color = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"RectColor"];
    if (GLOBAL.g_rect_color == 0)
    {
        GLOBAL.g_rect_color = 0xFFFFFF00;
    }

    GLOBAL.g_annot_underline_clr = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"UnderlineColor"];
    if (GLOBAL.g_annot_underline_clr == 0) {
        GLOBAL.g_annot_underline_clr = 0xFFFF9500;
    }
    GLOBAL.g_annot_strikeout_clr = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"StrikeoutColor"];
    if (GLOBAL.g_annot_strikeout_clr == 0) {
        GLOBAL.g_annot_strikeout_clr = 0xFFFF9500;
    }
    GLOBAL.g_annot_highlight_clr = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"HighlightColor"];
    if(GLOBAL.g_annot_highlight_clr ==0)
    {
        GLOBAL.g_annot_highlight_clr =0xFFFFFF00;
    }
    GLOBAL.g_oval_color = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"OvalColor"];
    if(GLOBAL.g_oval_color ==0)
    {
        GLOBAL.g_oval_color = 0xFFFFFF00;
    }
    GLOBAL.g_line_color = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"LineColor"];
    if(GLOBAL.g_line_color ==0)
    {
        GLOBAL.g_line_color = 0xFFFFFF00;
    }
}

- (void)initSettingWithUserDefault :(NSString *)dpath
{
    NSString *hf = [[NSBundle mainBundle]pathForResource:@"EULA" ofType:@"pdf" inDirectory:@"fdat"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    bool b_helpfile = [userDefaults boolForKey:@"sampleFileLoaded"];
    if (!b_helpfile)
    {
        NSString *helpfile = [hf lastPathComponent];

        NSString *documentPath = [dpath stringByAppendingString: [NSString stringWithFormat:@"/%@",helpfile]];

        // A file with this name may already be in Documents (and already picked up by
        // the addPDFs: scan above) - don't overwrite it or add a duplicate row for it.
        if (![[NSFileManager defaultManager] fileExistsAtPath:documentPath]) {
            [[NSFileManager defaultManager] copyItemAtPath:hf toPath:documentPath error:nil];
            [m_files addObject:[NSArray arrayWithObjects:helpfile,documentPath,0,nil]];
        }
        [[NSUserDefaults standardUserDefaults]  setBool:true forKey:@"sampleFileLoaded"];
        [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"CaseSensitive"];
        GLOBAL.g_case_sensitive = FALSE;
        
        [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"MatchWholeWord"];
        GLOBAL.g_match_whole_word = FALSE;
        
        [[NSUserDefaults standardUserDefaults] setFloat:0.1f forKey:@"SwipeSpeed"];
        GLOBAL.g_swipe_speed = 0.15f;

        GLOBAL.g_swipe_distance = 1.0f;
        [[NSUserDefaults standardUserDefaults] setFloat:GLOBAL.g_swipe_distance forKey:@"SwipeDistance"];

        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"ViewMode"];
        GLOBAL.g_render_mode =0;

        [[NSUserDefaults standardUserDefaults]  setBool:FALSE forKey:@"KeepScreenAwake"];
        GLOBAL.g_screen_awake = FALSE;
        [[UIApplication sharedApplication] setIdleTimerDisabled:GLOBAL.g_screen_awake];

        [[NSUserDefaults standardUserDefaults]  setInteger:0xFF000000 forKey:@"InkColor"];
        GLOBAL.g_ink_color = 0xFF000000;
        [[NSUserDefaults standardUserDefaults]  setInteger:0xFFFFFF00 forKey:@"RectColor"];
        GLOBAL.g_rect_color = 0xFFFFFF00;
        [[NSUserDefaults standardUserDefaults]  setInteger:0xFFFFFF00 forKey:@"OvalColor"];
        GLOBAL.g_oval_color = 0xFFFFFF00;
        GLOBAL.g_ink_width = 2.0f;
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
}

- (BOOL)isPortrait
{
    return ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait ||
            [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown);
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= m_files.count) {
        return;
    }
    NSArray *row_item = [m_files objectAtIndex:indexPath.row];
    NSString *path = [row_item objectAtIndex:1];
    if ([m_thumbnailsRequested containsObject:path]) {
        return;
    }
    [m_thumbnailsRequested addObject:path];
    [NSThread detachNewThreadSelector:@selector(updateImageForCellAtIndexPath:) toTarget:self withObject:indexPath];
}

- (void)updateImageForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *row_item = [m_files objectAtIndex:indexPath.row];
    NSString *path = [row_item objectAtIndex:1];
    CGImageRef img_ref = nil;
    @synchronized (self) {
        const char *cpath = [path UTF8String];
        PDF_ERR err;
        PDF_DOC m_docThumb = PDF_Document_open(cpath,nil, &err);
        int result = 1;
        if( m_docThumb == NULL )
        {
            switch( err )
            {
                case err_password:
                    result = 2;
                    break;
                default: result = 0;
            }
        }
        
        PDF_PAGE page = PDF_Document_getPage(m_docThumb, 0);
        float w = PDF_Document_getPageWidth(m_docThumb,0);
        float h = PDF_Document_getPageHeight(m_docThumb,0);
        PDF_DIB m_dib = NULL;
        CGFloat screenScale = [UIScreen mainScreen].scale;
        int iw = (int)(52 * screenScale);
        int ih = (int)(68 * screenScale);
        PDF_DIB bmp = Global_dibGet(m_dib, iw, ih);
        float ratiox = iw/w;
        float ratioy = ih/h;
        if( ratiox > ratioy ) ratiox = ratioy;
        PDF_MATRIX mat = Matrix_createScale(ratiox, -ratiox, 0, h * ratioy);
        PDF_Page_renderPrepare( page, bmp );
        PDF_Page_render(page, bmp, mat,false,1);
        Matrix_destroy(mat);
        PDF_Page_close(page);
        
        if(m_docThumb) PDF_Document_close(m_docThumb);
        
        void *data = Global_dibGetData(bmp);
        CGDataProviderRef provider = CGDataProviderCreateWithData( NULL, data, iw * ih * 4, NULL );
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        img_ref = CGImageCreate( iw, ih, 8, 32, iw<<2, cs, kCGBitmapByteOrder32Little|kCGImageAlphaNoneSkipFirst, provider, NULL, FALSE, kCGRenderingIntentDefault );
        CGColorSpaceRelease(cs);
        CGDataProviderRelease( provider );
    }
    
    UIImage *img = [UIImage imageWithCGImage:img_ref scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    dispatch_async(dispatch_get_main_queue(), ^{
        [m_thumbnailCache setObject:img forKey:path];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.imageView.image = img;
        cell.imageView.tintColor = nil;
        // UITableViewCell's built-in imageView frame is only recomputed during
        // the cell's own layout pass, not merely on assigning a bigger image -
        // without this the thumbnail stays at the placeholder's small size
        // until something else (e.g. tapping the row) triggers a relayout.
        [cell setNeedsLayout];
    });
}

@end
