//
//  FTSManager.h
//  PDFViewer
//
//  Created by Emanuele Bortolami on 21/09/17.
//

#import <Foundation/Foundation.h>
#import "FTSSearchManager.h"
#import "TextExtractor.h"
#import "FTSSearchTableViewController.h"

#define FTS_ENABLED

typedef enum {
    kPDFSearch = 0,
    kFTSSearch = 1
} PDFSearchType;

@interface FTSManager : NSObject {
    
    NSString *databasebPath;
    int searchType;
}

+ (FTSManager *)sharedInstance;

- (void)FTS_SetIndexDB:(NSString *)dbPath;
- (BOOL)FTS_AddIndex:(NSString *)pdfPath password:(NSString *)password;
- (void)FTS_RemoveFromIndex:(NSString *)pdfPath password:(NSString *)password;
- (void)FTS_Search:(NSString *)term filter:(NSString *)pdfPath password:(NSString *)password writeJSON:(NSString *)filePath success:(void (^)(NSMutableArray *occurrences, BOOL didWriteFile))success;
- (void)SetSearchType:(int)type;
- (int)GetSearchType;

@end
