//
//  FTSManager.m
//  PDFViewer
//
//  Created by Emanuele Bortolami on 21/09/17.
//

#import "FTSManager.h"

@implementation FTSManager

+ (FTSManager *)sharedInstance
{
    static FTSManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FTSManager alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

- (void)FTS_SetIndexDB:(NSString *)dbPath
{
    databasebPath = dbPath;
    [[FTSSearchManager sharedInstance] createDatabaseAtPath:dbPath];
}

- (BOOL)FTS_AddIndex:(NSString *)pdfPath password:(NSString *)password
{
    // Get the PDF's ID
    NSString *pdfId = [RDUtils getPDFID:pdfPath password:password];
    
    if ([[FTSSearchManager sharedInstance] documentExist:pdfId]) {
        return NO;
    }
    
    // Extract text and build the JSON structure
    TextExtractor *t = [[TextExtractor alloc] init];
    [t extractDocumentText:pdfPath password:password];
    
    // Create the db structure
    return [[FTSSearchManager sharedInstance] createFTSStruct:FTS_JSON_PATH withHash:pdfId];
}

- (void)FTS_RemoveFromIndex:(NSString *)pdfPath password:(NSString *)password
{
    // Get the PDF's ID;
    NSString *pdfId = [RDUtils getPDFID:pdfPath password:password];
    
    [[FTSSearchManager sharedInstance] cleanFTSForHash:pdfId];
}

- (void)FTS_Search:(NSString *)term filter:(NSString *)pdfPath password:(NSString *)password writeJSON:(NSString *)filePath success:(void (^)(NSMutableArray *, BOOL))success
{
    // Get the PDF's ID;
    NSString *pdfId = [RDUtils getPDFID:pdfPath password:password];
    
    [[FTSSearchManager sharedInstance] searchInit:pdfId];
    [[FTSSearchManager sharedInstance] searchText:term success:^(NSMutableArray *occurrences) {
        
        // Write the result as JSON
        if (filePath.length > 0 && occurrences.count > 0) {
            // Remove the file if already exist
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
            
            [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
            NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
            [fileHandler seekToEndOfFile];
            [fileHandler writeData:[@"[" dataUsingEncoding:NSUTF8StringEncoding]];
            
            for (int i = 0; i < occurrences.count; i++) {
                [fileHandler writeData:[[[occurrences objectAtIndex:i] getJSONFormat] dataUsingEncoding:NSUTF8StringEncoding]];
                
                if (i < (occurrences.count - 1)) {
                    [fileHandler writeData:[@"," dataUsingEncoding:NSUTF8StringEncoding]];
                }
            }
            
            [fileHandler writeData:[@"]" dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandler closeFile];
        }
        
        success(occurrences, (filePath.length > 0));
    }];
}

- (void)SetSearchType:(int)type
{
    searchType = type;
}

- (int)GetSearchType
{
    return searchType;
}

@end
