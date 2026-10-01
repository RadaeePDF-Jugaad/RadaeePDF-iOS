#import <Foundation/Foundation.h>
#import "PDFObjc.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDSeparateXFDFHelper : NSObject

+ (nullable NSString *)exportAnnotation:(RDPDFAnnot *)annot
                            toDirectory:(NSString *)directory
                                   page:(RDPDFPage *)page
                              pageIndex:(int)pageIndex
                            pdfFileName:(NSString *)pdfFileName;

+ (int)importAnnotationFromPath:(NSString *)path
                      toDocument:(RDPDFDoc *)doc;

@end

NS_ASSUME_NONNULL_END
