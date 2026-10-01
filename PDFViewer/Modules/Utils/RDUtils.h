//
//  RDUtils.h
//  RadaeePDF-Cordova
//
//  Created by Emanuele Bortolami on 26/09/17.
//

#import <Foundation/Foundation.h>
#import "PDFObjc.h"

#define UUID @"UUID"

#define BIG_FONT_SIZE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? 21 : 21
#define NORMAL_FONT_SIZE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? 16 : 16
#define SMALL_FONT_SIZE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? 12 : 12

@interface NSData (Radaee)

- (NSString *)MD5;

@end

@interface NSString (Radaee)

- (NSString *)MD5;

@end

@interface RDUtils : NSObject

+ (NSString *)getPDFID:(NSString *)pdfPath password:(NSString *)password;
+ (NSString *)getPDFIDForDoc:(RDPDFDoc *)m_doc;
+ (NSDate *)dateFromPdfDate:(NSString *)dateString;
+ (NSString *)pdfDateFromDate:(NSDate *)date;
+ (UIColor *)invertColor:(UIColor *)color;

+ (NSString *)cleanString:(NSString *)string;
+ (UIColor *)radaeeWhiteColor;
+ (UIColor *)radaeeBlackColor;

@end
