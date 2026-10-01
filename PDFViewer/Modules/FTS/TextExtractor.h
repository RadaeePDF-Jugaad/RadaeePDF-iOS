//
//  TextExtractor.h
//  PDFViewer
//
//  Created by Emanuele Bortolami on 14/08/17.
//
//

#import <Foundation/Foundation.h>
#import "RDUtils.h"

#define FTS_JSON @"fts.text"
#define FTS_LOG @"log.txt"
#define FTS_FOLDER [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"FTS"]
#define FTS_JSON_PATH [FTS_FOLDER stringByAppendingPathComponent:FTS_JSON]
#define FTS_LOG_PATH [FTS_FOLDER stringByAppendingPathComponent:FTS_LOG]

@class PDFPage;
@class PDFDoc;
@interface TextExtractor : NSObject

+ (NSString *)extractPageText:(PDFPage *)page :(int)pageIndex;

- (int)extractDocumentText:(NSString *)filePath password:(NSString *)password;

@end
