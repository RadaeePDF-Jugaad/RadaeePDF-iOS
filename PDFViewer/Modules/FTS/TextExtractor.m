//
//  TextExtractor.m
//  PDFViewer
//
//  Created by Emanuele Bortolami on 14/08/17.
//
//

#import "TextExtractor.h"

@implementation TextExtractor

static float sHorzGap;
static float sVertGap;
static float sFontHeightDiff;
static PDF_RECT sBlockRect;
static PDF_RECT sCurCharRect;
static PDF_RECT sNextCharRect;
static NSString *PAGE = @"page";
static NSString *TEXT = @"text";
static NSString *BLOCKS = @"blocks";
static NSString *RECT_TOP = @"rect_t";
static NSString *RECT_LEFT = @"rect_l";
static NSString *RECT_RIGHT = @"rect_r";
static NSString *RECT_BOTTOM = @"rect_b";

- (int)extractDocumentText:(NSString *)filePath password:(NSString *)password
{
    NSString *ftsPath = FTS_JSON_PATH;
    NSString *logPath = FTS_LOG_PATH;
    NSLog(@"%@",FTS_JSON_PATH);
    [[NSFileManager defaultManager] createDirectoryAtPath:FTS_FOLDER withIntermediateDirectories:NO attributes:nil error:nil];
    [[NSFileManager defaultManager] createFileAtPath:ftsPath contents:nil attributes:nil];
    [[NSFileManager defaultManager] createFileAtPath:logPath contents:nil attributes:nil];
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:ftsPath];
    [fileHandler seekToEndOfFile];
    
    @try {
        [fileHandler writeData:[@"{\"pages\": [" dataUsingEncoding:NSUTF8StringEncoding]];
        BOOL pageAdded = NO;
        BOOL onlyImages = YES;
        RDPDFDoc *mDocument = [[RDPDFDoc alloc] init];
        if ([mDocument open:filePath :password] == 0) {
            int pageCount = [mDocument pageCount];
            for (int i = 0; i < pageCount; i++) {
                @autoreleasepool {
                    RDPDFPage *mPage = [mDocument page:i];
                    if (mPage != nil) {
                        NSString *pageText = [TextExtractor extractPageText:mPage :i];
                        if(i > 0 && pageAdded && (i < pageCount - 1 || (i == pageCount - 1 && !(pageText.length == 0))))
                            [fileHandler writeData:[@"," dataUsingEncoding:NSUTF8StringEncoding]];
                        
                        if (pageText.length == 0) {
                            pageAdded = NO;
                        } else {
                            [fileHandler writeData:[pageText dataUsingEncoding:NSUTF8StringEncoding]];
                            pageAdded = YES;
                            onlyImages = NO;
                        }
                        mPage = nil;
                    }
                    NSLog(@"====================================================================================================");
                }
            }
            
        }
        mDocument = nil;
        
        if (onlyImages)
        {
            [fileHandler closeFile];
            [[NSFileManager defaultManager] removeItemAtPath:ftsPath error:nil];
            [[NSFileManager defaultManager] createFileAtPath:ftsPath contents:nil attributes:nil];
            NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:ftsPath];
            [fileHandler seekToEndOfFile];
            [fileHandler writeData:[@"No text to extract\n" dataUsingEncoding:NSUTF8StringEncoding]];
            return 0;
        } else {
            [fileHandler writeData:[@"]}" dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandler closeFile];
        }
        
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.description);
        [fileHandler writeData:[[NSString stringWithFormat:@"Extract text error: %@ \n", exception.description] dataUsingEncoding:NSUTF8StringEncoding]];
        return -1;
    } @finally {
        
    }

    return 1;
}

+ (NSString *)extractPageText:(RDPDFPage *)page :(int)pageIndex
{
    @try {
        [page objsStart:false];
        
        int sBlockStartIndex = 0;
        
        [page objsCharRect:0 :&sBlockRect];
        
        NSMutableDictionary *pageJson = [NSMutableDictionary dictionary];
        [pageJson setObject:[NSNumber numberWithInt:pageIndex] forKey:@"page"];
        
        NSMutableArray *blocksArray = [NSMutableArray array];
        
        int objCount = [page objsCount];
        for(int charIndex = 0; charIndex < objCount; charIndex++) {
            [page objsCharRect:charIndex :&sCurCharRect]; // get char's box in PDF coordinate system
            
            if (charIndex < objCount - 1) {
                [page objsCharRect:(charIndex + 1) :&sNextCharRect]; // get next char's box in PDF coordinate system
            }
            
            sBlockRect = [TextExtractor adjustBlockRect:sCurCharRect :sBlockRect];
            
            BOOL nextBeforeBlock = [TextExtractor isNextOutOfBlock];
            
            if ([TextExtractor startNewTextBlock] || nextBeforeBlock || charIndex >= objCount - 1) {
                if (nextBeforeBlock || charIndex >= objCount - 1) {
                    charIndex++;
                }
                
                NSMutableDictionary *blockJson = [NSMutableDictionary dictionary];
                NSString *text = [page objsString:sBlockStartIndex :charIndex];
                if (text != nil && text.length > 0)
                {
                    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                }
                if (text != nil && text.length > 0)
                {
                    text = [TextExtractor handleUtf16Chars:[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                    text = [TextExtractor handleSpecialChars:text];
                    blockJson = [TextExtractor createBlockJson:text];
                    if(blockJson != nil) {
                        [blocksArray addObject:blockJson];
                        NSLog(@"%@", [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]);
                        NSLog(@"-----------------------------------------------");
                    }
                }
                
                if (charIndex + 1 >= objCount) {
                    continue;
                }
                
                [page objsCharRect:(nextBeforeBlock) ? charIndex : charIndex + 1 :&sBlockRect]; // reset block rect with next char's rect
                sBlockStartIndex = (nextBeforeBlock) ? charIndex : charIndex + 1;
            }
        }
        
        [pageJson setObject:blocksArray forKey:@"blocks"];
        
        return (blocksArray.count > 0) ? [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:pageJson options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding] : @"";
        
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.description);
    } @finally {
        
    }
    
    return @"";
}

+ (PDF_RECT)adjustBlockRect:(PDF_RECT) mCharRect :(PDF_RECT) mRect {
    @try {
        if (mRect.left < 0) {
            mRect = mCharRect;
        }
        if (mRect.left > mCharRect.left) {
            mRect.left = mCharRect.left;
        }
        if (mRect.top > mCharRect.top) {
            mRect.top = mCharRect.top;
        }
        if (mRect.right < mCharRect.right) {
            mRect.right = mCharRect.right;
        }
        if (mRect.top < mCharRect.top) {
            mRect.top = mCharRect.top;
        }

    } @catch (NSException *exception) {
        NSLog(@"%@", exception.description);
    } @finally {
        return mRect;
    }
}

+ (BOOL)isNextOutOfBlock {
    BOOL sameLine = (abs(sNextCharRect.top - sBlockRect.top) < 1.5 && abs(sNextCharRect.right - sBlockRect.right) < 1.5);
    float gap = (sNextCharRect.bottom - sNextCharRect.top) / 2.0f;
    if (!((sameLine && sNextCharRect.left < sBlockRect.left && sNextCharRect.right < sBlockRect.left) || (!sameLine && sNextCharRect.left - sBlockRect.right > gap && sNextCharRect.right - sBlockRect.right > gap))) {
        return NO;
    }
    return YES;
}

+ (BOOL)startNewTextBlock {
    sFontHeightDiff = abs(sNextCharRect.bottom - sNextCharRect.top - (sCurCharRect.bottom - sCurCharRect.top));
    sHorzGap = abs(sNextCharRect.left - sCurCharRect.right); // horizontal gap
    sVertGap = sNextCharRect.top - sCurCharRect.bottom; // vertical gap
    
    BOOL sameLine = abs(sCurCharRect.top - sNextCharRect.top) < 1.5 && abs(sCurCharRect.bottom - sNextCharRect.bottom) < 1.5;
    BOOL sameColumn = abs(sCurCharRect.left - sNextCharRect.left) < 1.5 && abs(sCurCharRect.right - sNextCharRect.right) < 1.5;
    BOOL sameBlock = abs(sBlockRect.left - sNextCharRect.left) < 3.0f && abs(sBlockRect.right - sNextCharRect.right) > 0.0f;
    
    if ((sFontHeightDiff >= 2.0f && !sameColumn) || (sameLine && sHorzGap >= 85.0f) || (sameBlock && (sVertGap <= -30.0f || sVertGap >= 20.0f)) || (!sameLine && !sameBlock && (sVertGap >= 15.0f || sVertGap <= -43.0f || sHorzGap >= 800.0f))) {
        return true;
    }
    return false;
}

+ (NSMutableDictionary *)createBlockJson:(NSString *)text {
    
    NSMutableDictionary *blockJson = [NSMutableDictionary dictionary];
    
    @try {
        [blockJson setObject:text forKey:@"text"];
        [blockJson setObject:[NSNumber numberWithFloat:sBlockRect.top] forKey:@"rect_t"];
        [blockJson setObject:[NSNumber numberWithFloat:sBlockRect.left] forKey:@"rect_l"];
        [blockJson setObject:[NSNumber numberWithFloat:sBlockRect.right] forKey:@"rect_r"];
        [blockJson setObject:[NSNumber numberWithFloat:sBlockRect.bottom] forKey:@"rect_b"];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.description);
    } @finally {
        return blockJson;
    }
}

+ (NSString *)handleUtf16Chars:(NSString *)input {
    input = [input stringByReplacingOccurrencesOfString:@"u0092" withString:@"'"];
    input = [input stringByReplacingOccurrencesOfString:@"u0095" withString:@"ï"];
    input = [input stringByReplacingOccurrencesOfString:@"u00B0" withString:@"∞"];

    return input;
}

+ (NSString *)handleSpecialChars:(NSString *)input {
    input = [input stringByReplacingOccurrencesOfString:@"í" withString:@"'"];
    input = [input stringByReplacingOccurrencesOfString:@"ë" withString:@"'"];
    input = [input stringByReplacingOccurrencesOfString:@"ì" withString:@"\""];
    input = [input stringByReplacingOccurrencesOfString:@"î" withString:@"\""];
    input = [input stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "];
    
    return input;
}

@end
