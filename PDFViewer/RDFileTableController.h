//
//  RDFileTableController.h
//  PDFViewer
//
//  Created by Radaee on 12-10-29.
//  Copyright (c) 2012年 __Radaee__. All rights reserved.


#import <UIKit/UIKit.h>
#import "RDUPassWord.h"
#import "sys/utsname.h"
#import "PDFHttpStream.h"
#import "RDLoPDFViewController.h"
#import "RDPDFReflowViewController.h"
#import "RDVGlobal.h"
#import "PDFHttpStream.h"

@interface RDFileTableController : UITableViewController <UIApplicationDelegate>
{
    RDLoPDFViewController *m_pdf;
    RDPDFReflowViewController *m_pdfR;
    NSMutableArray *m_files;
    NSMutableSet *m_thumbnailsRequested;
    NSMutableDictionary *m_thumbnailCache;
}
@end




