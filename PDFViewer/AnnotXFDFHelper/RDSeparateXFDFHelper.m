#import "RDSeparateXFDFHelper.h"

static NSString *const kXFDFNamespace = @"http://ns.adobe.com/xfdf/";
static NSString *const kXMLSpace = @"preserve";

@implementation RDSeparateXFDFHelper

+ (nullable NSString *)exportAnnotation:(RDPDFAnnot *)annot
                            toDirectory:(NSString *)directory
                                   page:(RDPDFPage *)page
                              pageIndex:(int)pageIndex
                            pdfFileName:(NSString *)pdfFileName {
    if (!annot || directory.length == 0) return nil;

    @try {
        if (page) {
            [page objsStart:NO];
        }
        NSString *name = [annot getName];
        if (name.length == 0) {
            name = [self generateUniqueAnnotationId:annot page:page pageIndex:pageIndex];
        }

        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:directory]) {
            NSError *derr = nil;
            [fm createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&derr];
            if (derr) return nil;
        }

        // Build filename: [pdfname]_[page]_[annotid].xfdf
        NSString *sanitizedAnnotId = [self sanitizedFileName:name];
        NSString *fileName = [NSString stringWithFormat:@"%@_%d_%@.xfdf", pdfFileName, pageIndex, sanitizedAnnotId];
        NSString *path = [directory stringByAppendingPathComponent:fileName];
 
        // Thread a nameOverride into XML so <... name="..."> is always present
        NSString *annotXML = [self createAnnotationElement:annot page:page pageIndex:pageIndex nameOverride:name];
        if (annotXML.length == 0) return nil;
        NSMutableString *xml = [NSMutableString string];
        [xml appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"]; 
        [xml appendFormat:@"<xfdf xmlns=\"%@\" xml:space=\"%@\">\n", kXFDFNamespace, kXMLSpace];
        [xml appendString:@"  <annots>\n"]; 
        [xml appendString:annotXML];
        [xml appendString:@"  </annots>\n"]; 
        [xml appendString:@"  <f href=\"\"/>\n"]; 
        [xml appendString:@"</xfdf>\n"]; 
        NSError *werr = nil;
        BOOL ok = [xml writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&werr];
        if (!ok || werr) return nil;
        return path;
    } @catch (NSException *ex) {
        return nil;
    }
}

+ (int)importAnnotationFromPath:(NSString *)path toDocument:(RDPDFDoc *)doc {
    if (path.length == 0 || !doc) return -1;
    NSError *err = nil;
    NSString *xml = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if (err || xml.length == 0) return -1;

    // Try to detect a single annotation element inside <annots>
    NSArray<NSString *> *tags = @[@"line", @"square", @"circle", @"text", @"freetext"]; 
    NSString *foundTag = nil;
    NSRange tagRange = NSMakeRange(NSNotFound, 0);
    for (NSString *tag in tags) {
        NSRange r1 = [xml rangeOfString:[NSString stringWithFormat:@"<%@ ", tag] options:NSCaseInsensitiveSearch];
        NSRange r2 = [xml rangeOfString:[NSString stringWithFormat:@"<%@>", tag] options:NSCaseInsensitiveSearch];
        if (r1.location != NSNotFound) { foundTag = tag; tagRange = r1; break; }
        if (r2.location != NSNotFound) { foundTag = tag; tagRange = r2; break; }
    }
    if (!foundTag) return 0; // nothing to import

    // Extract opening tag segment to parse attributes
    NSUInteger openStart = tagRange.location;
    NSRange searchRange = NSMakeRange(openStart, xml.length - openStart);
    NSRange closeOfOpen = [xml rangeOfString:@">" options:0 range:searchRange];
    if (closeOfOpen.location == NSNotFound) return -1;
    NSString *openTag = [xml substringWithRange:NSMakeRange(openStart, closeOfOpen.location - openStart + 1)];
    NSDictionary<NSString *, NSString *> *attrs = [self p_parseAttributesFromOpenTag:openTag];

    // Page index: prefer filename-encoded index, then XML attribute, then 0
    // Filename format: [pdfname]_[page]_[annotId].xfdf (pdfname may contain underscores)
    NSString *fname = [[path lastPathComponent] stringByDeletingPathExtension];
    NSArray<NSString *> *parts = [fname componentsSeparatedByString:@"_"];
    int pageFromName = -1;
    if (parts.count >= 2) {
        NSString *tok = parts[parts.count - 2];
        pageFromName = (int)tok.intValue;
    }
    int pageFromAttr = attrs[@"page"] ? (int)attrs[@"page"].intValue : -1;
    int pageIndex = (pageFromName >= 0) ? pageFromName : ((pageFromAttr >= 0) ? pageFromAttr : 0);
    int pc = [doc pageCount];
    if (pageIndex < 0) pageIndex = 0;
    if (pc > 0 && pageIndex >= pc) pageIndex = pc - 1;
    RDPDFPage *page = [doc page:pageIndex];
    if (!page) return -1;
    
    [page objsStart:NO];

    int imported = 0;
    BOOL ok = NO;

    if ([foundTag caseInsensitiveCompare:@"line"] == NSOrderedSame) {
        // line: start, end, width, color, opacity, fillcolor, fillopacity
        NSString *sval = attrs[@"start"]; NSString *eval = attrs[@"end"]; 
        PDF_POINT p1 = [self parsePoint:(sval ?: @"0,0")];
        PDF_POINT p2 = [self parsePoint:(eval ?: @"0,0")];
        float width = attrs[@"width"] ? attrs[@"width"].floatValue : 1.0f;
        int color = attrs[@"color"] ? [self parseColor:attrs[@"color"]] : 0xFF000000;
        if (attrs[@"opacity"]) {
            int sa = (int)roundf(attrs[@"opacity"].floatValue * 255.0f);
            if (sa < 0) sa = 0; if (sa > 255) sa = 255;
            color = (color & 0x00FFFFFF) | (sa << 24);
        }
        int style1 = attrs[@"startstyle"] ? attrs[@"startstyle"].intValue : 0; // start
        int style2 = attrs[@"endstyle"] ? attrs[@"endstyle"].intValue : 0;   // end
        int icolor = attrs[@"fillcolor"] ? [self parseColor:attrs[@"fillcolor"]] : color;
        if (attrs[@"fillopacity"]) {
            int fa = (int)roundf(attrs[@"fillopacity"].floatValue * 255.0f);
            if (fa < 0) fa = 0; if (fa > 255) fa = 255;
            icolor = (icolor & 0x00FFFFFF) | (fa << 24);
        }
        ok = [page addAnnotLine:&p1 :&p2 :style1 :style2 :width :color :icolor];
        if (ok) {
            RDPDFAnnot *a = [page annotAtIndex:(page.annotCount - 1)];
            if (a) {
                // Ensure precise endpoints, some providers adjust on creation
                [a setLinePoint:p1.x :p1.y :p2.x :p2.y];
                // Also set a normalized bounding rect derived from endpoints
                PDF_RECT lrc;
                lrc.left = (p1.x < p2.x) ? p1.x : p2.x;
                lrc.right = (p1.x > p2.x) ? p1.x : p2.x;
                lrc.bottom = (p1.y < p2.y) ? p1.y : p2.y;
                lrc.top = (p1.y > p2.y) ? p1.y : p2.y;
                [a setRect:&lrc];
                [a setStrokeWidth:width];
                [a setStrokeColor:color];
                // Ensure style persisted even if provider ignores constructor flags
                int style = (style2 << 16) | (style1 & 0xFFFF);
                [a setLineStyle:style];
                NSString *nm = attrs[@"name"]; if (nm.length) [a setName:nm]; else [a setName:[[[NSUUID alloc] init] UUIDString]];
                // Dash pattern (if provided). Only apply if it is a real dash (>=2 positive values)
                NSString *dashStr = attrs[@"dash"];
                if (dashStr.length > 0) {
                    NSArray<NSString *> *parts = [dashStr componentsSeparatedByString:@","];
                    float dashVals[16]; int dcnt = 0; int posCnt = 0;
                    for (NSString *p in parts) {
                        if (dcnt >= 16) break;
                        NSString *t = [p stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        if (t.length == 0) continue;
                        float v = t.floatValue;
                        if (v > 0.0001f) { dashVals[dcnt++] = v; posCnt++; }
                    }
                    if (posCnt >= 2) {
                        [a setStrokeDash:dashVals :dcnt];
                    }
                }
                if ([self p_hasLockedFlagInAttributes:attrs]) {
                    [a setLocked:YES];
                }
            }
        }
    } else if ([foundTag caseInsensitiveCompare:@"square"] == NSOrderedSame) {
        // square: rect, width, color, fillcolor, opacities
        PDF_RECT rc = [self parseRect:(attrs[@"rect"] ?: @"0,0,0,0")];
        // normalize
        if (rc.left > rc.right) { float t = rc.left; rc.left = rc.right; rc.right = t; }
        if (rc.bottom > rc.top) { float t = rc.bottom; rc.bottom = rc.top; rc.top = t; }
        float width = attrs[@"width"] ? attrs[@"width"].floatValue : 1.0f;
        int color = attrs[@"color"] ? [self parseColor:attrs[@"color"]] : 0xFF000000;
        if (attrs[@"opacity"]) {
            int sa = (int)roundf(attrs[@"opacity"].floatValue * 255.0f);
            if (sa < 0) sa = 0; if (sa > 255) sa = 255;
            color = (color & 0x00FFFFFF) | (sa << 24);
        }
        int fillColor = attrs[@"fillcolor"] ? [self parseColor:attrs[@"fillcolor"]] : 0;
        if (attrs[@"fillopacity"]) {
            int fa = (int)roundf(attrs[@"fillopacity"].floatValue * 255.0f);
            if (fa < 0) fa = 0; if (fa > 255) fa = 255;
            fillColor = (fillColor & 0x00FFFFFF) | (fa << 24);
        }
        ok = [page addAnnotRect:&rc :width :color :fillColor];
        if (ok) {
            RDPDFAnnot *a = [page annotAtIndex:(page.annotCount - 1)];
            if (a) {
                [a setRect:&rc];
                [a setStrokeWidth:width];
                [a setStrokeColor:color];
                if (fillColor) [a setFillColor:fillColor];
                NSString *nm = attrs[@"name"]; if (nm.length) [a setName:nm]; else [a setName:[[[NSUUID alloc] init] UUIDString]];
                NSString *dashStr = attrs[@"dash"];
                if (dashStr.length > 0) {
                    NSArray<NSString *> *parts = [dashStr componentsSeparatedByString:@","];
                    float dashVals[16]; int dcnt = 0; int posCnt = 0;
                    for (NSString *p in parts) {
                        if (dcnt >= 16) break;
                        NSString *t = [p stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        if (t.length == 0) continue;
                        float v = t.floatValue;
                        if (v > 0.0001f) { dashVals[dcnt++] = v; posCnt++; }
                    }
                    if (posCnt >= 2) {
                        [a setStrokeDash:dashVals :dcnt];
                    }
                }
                // Apply locked status if present in flags
                if ([self p_hasLockedFlagInAttributes:attrs]) {
                    [a setLocked:YES];
                }
            }
        }
    } else if ([foundTag caseInsensitiveCompare:@"circle"] == NSOrderedSame) {
        // circle: rect, width, color, fillcolor
        PDF_RECT rc = [self parseRect:(attrs[@"rect"] ?: @"0,0,0,0")];
        // normalize
        if (rc.left > rc.right) { float t = rc.left; rc.left = rc.right; rc.right = t; }
        if (rc.bottom > rc.top) { float t = rc.bottom; rc.bottom = rc.top; rc.top = t; }
        float width = attrs[@"width"] ? attrs[@"width"].floatValue : 1.0f;
        int color = attrs[@"color"] ? [self parseColor:attrs[@"color"]] : 0xFF000000;
        if (attrs[@"opacity"]) {
            int sa = (int)roundf(attrs[@"opacity"].floatValue * 255.0f);
            if (sa < 0) sa = 0; if (sa > 255) sa = 255;
            color = (color & 0x00FFFFFF) | (sa << 24);
        }
        int fillColor = attrs[@"fillcolor"] ? [self parseColor:attrs[@"fillcolor"]] : 0;
        if (attrs[@"fillopacity"]) {
            int fa = (int)roundf(attrs[@"fillopacity"].floatValue * 255.0f);
            if (fa < 0) fa = 0; if (fa > 255) fa = 255;
            fillColor = (fillColor & 0x00FFFFFF) | (fa << 24);
        }
        ok = [page addAnnotEllipse:&rc :width :color :fillColor];
        if (ok) {
            RDPDFAnnot *a = [page annotAtIndex:(page.annotCount - 1)];
            if (a) {
                [a setRect:&rc];
                [a setStrokeWidth:width];
                [a setStrokeColor:color];
                if (fillColor) [a setFillColor:fillColor];
                NSString *nm = attrs[@"name"]; if (nm.length) [a setName:nm];
                NSString *dashStr = attrs[@"dash"];
                if (dashStr.length > 0) {
                    NSArray<NSString *> *parts = [dashStr componentsSeparatedByString:@","];
                    float dashVals[16]; int dcnt = 0; int posCnt = 0;
                    for (NSString *p in parts) {
                        if (dcnt >= 16) break;
                        NSString *t = [p stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        if (t.length == 0) continue;
                        float v = t.floatValue;
                        if (v > 0.0001f) { dashVals[dcnt++] = v; posCnt++; }
                    }
                    if (posCnt >= 2) {
                        [a setStrokeDash:dashVals :dcnt];
                    }
                }
                // Apply locked status if present in flags
                if ([self p_hasLockedFlagInAttributes:attrs]) {
                    [a setLocked:YES];
                }
            }
        }
    } else if ([foundTag caseInsensitiveCompare:@"text"] == NSOrderedSame) {
        // sticky note: rect -> use top-left as point; optional subject, contents-richtext/span text
        PDF_RECT rc = [self parseRect:(attrs[@"rect"] ?: @"0,0,0,0")];
        PDF_POINT pt = { rc.left, rc.top };
        ok = [page addAnnotNote:&pt];
        if (ok) {
            RDPDFAnnot *a = [page annotAtIndex:(page.annotCount - 1)];
            if (a) {
                NSString *nm = attrs[@"name"]; if (nm.length) [a setName:nm]; else [a setName:[[[NSUUID alloc] init] UUIDString]];
                NSString *subj = attrs[@"subject"]; if (subj.length) [a setPopupSubject:subj];
                // Extract contents from <span>..</span>
                NSString *span = [self p_extractFirstSpanText:xml];
                if (span.length) [a setPopupText:span];
                // Apply color and opacity if present (XFDF typically stores color on text annot)
                // Prefer 'color' + 'opacity'; fallback to 'fillcolor' + 'fillopacity'
                int hasColor = 0;
                int fill = 0;
                if (attrs[@"color"]) {
                    fill = [self parseColor:attrs[@"color"]];
                    hasColor = 1;
                    if (attrs[@"opacity"]) {
                        int fa = (int)roundf(attrs[@"opacity"].floatValue * 255.0f);
                        if (fa < 0) fa = 0; if (fa > 255) fa = 255;
                        fill = (fill & 0x00FFFFFF) | (fa << 24);
                    }
                } else if (attrs[@"fillcolor"]) {
                    fill = [self parseColor:attrs[@"fillcolor"]];
                    hasColor = 1;
                    if (attrs[@"fillopacity"]) {
                        int fa = (int)roundf(attrs[@"fillopacity"].floatValue * 255.0f);
                        if (fa < 0) fa = 0; if (fa > 255) fa = 255;
                        fill = (fill & 0x00FFFFFF) | (fa << 24);
                    }
                }
                if (hasColor) {
                    [a setFillColor:fill];
                    // Also set stroke color for broader compatibility with viewers
                    [a setStrokeColor:fill];
                }
                // Apply icon if present
                NSString *iconStr = attrs[@"icon"];
                if (iconStr.length) { int iconIdx = (int)iconStr.intValue; [a setIcon:iconIdx]; }
                // Apply locked status if present in flags
                if ([self p_hasLockedFlagInAttributes:attrs]) {
                    [a setLocked:YES];
                }
            }
        }
    } else if ([foundTag caseInsensitiveCompare:@"freetext"] == NSOrderedSame) {
        // freetext: rect; defaultappearance -> text color and size; contents-richtext/span -> text
        PDF_RECT rc = [self parseRect:(attrs[@"rect"] ?: @"0,0,0,0")];
        ok = [page addAnnotEditText:&rc];
        if (ok) {
            RDPDFAnnot *a = [page annotAtIndex:(page.annotCount - 1)];
            if (a) {
                NSString *nm = attrs[@"name"]; if (nm.length) [a setName:nm]; else [a setName:[[[NSUUID alloc] init] UUIDString]];
                // parse defaultappearance
                NSString *defap = [self p_extractFirstTagText:@"defaultappearance" inXML:xml];
                if (defap.length) {
                    // format like: "R G B rg /RDF001 size Tf"
                    float r=0,g=0,b=0, size=12.0f;
                    [self p_parseDefaultAppearance:defap r:&r g:&g b:&b size:&size];
                    int textColor = 0xFF000000 | (((int)(r*255)&0xFF)<<16) | (((int)(g*255)&0xFF)<<8) | ((int)(b*255)&0xFF);
                    [a setEditTextColor:textColor];
                    [a setEditTextSize:size];
                }
                // text content
                NSString *span = [self p_extractFirstSpanText:xml];
                if (span.length) [a setEditText:span];
                // border color/width if present at element level
                if (attrs[@"color"]) [a setStrokeColor:[self parseColor:attrs[@"color"]]];
                if (attrs[@"width"]) [a setStrokeWidth:attrs[@"width"].floatValue];
                // Apply locked status if present in flags
                if ([self p_hasLockedFlagInAttributes:attrs]) {
                    [a setLocked:YES];
                }
            }
        }
    }

    if (ok) imported = 1;
    return imported;
}

#pragma mark - Element creation

+ (NSString *)createAnnotationElement:(RDPDFAnnot *)annot
                                 page:(RDPDFPage *)page
                            pageIndex:(int)pageIndex
                         nameOverride:(NSString *)nameOverride {
    int type = [annot type];
    switch (type) {
        case 1: return [self createText:annot page:page pageIndex:pageIndex nameOverride:nameOverride];
        case 3: return [self createFreeText:annot page:page pageIndex:pageIndex nameOverride:nameOverride];
        case 4: return [self createLine:annot page:page pageIndex:pageIndex nameOverride:nameOverride];
        case 5: return [self createSquare:annot page:page pageIndex:pageIndex nameOverride:nameOverride];
        case 6: return [self createCircle:annot page:page pageIndex:pageIndex nameOverride:nameOverride];
        default: return @"";
    }
}

+ (NSString *)commonAttributesForAnnot:(RDPDFAnnot *)annot pageIndex:(int)pageIndex skipColor:(BOOL)skipColor nameOverride:(NSString *)nameOverride {
    NSMutableArray<NSString *> *attrs = [NSMutableArray array];
    [attrs addObject:[NSString stringWithFormat:@"page=\"%d\"", pageIndex]];
    PDF_RECT rc; [annot getRect:&rc];
    NSString *rectStr = [NSString stringWithFormat:@"%.4f,%.4f,%.4f,%.4f", rc.left, rc.bottom, rc.right, rc.top];
    [attrs addObject:[NSString stringWithFormat:@"rect=\"%@\"", rectStr]];
    if ([annot isLocked]) {
        [attrs addObject:@"flags=\"print,locked\""];
    } else {
        [attrs addObject:@"flags=\"print\""];
    }
    if (!skipColor) {
        int stroke = [annot getStrokeColor];
        if (stroke) {
            [attrs addObject:[NSString stringWithFormat:@"color=\"%@\"", [self colorHex:stroke]]];
            float sa = ((stroke >> 24) & 0xFF) / 255.0f;
            [attrs addObject:[NSString stringWithFormat:@"opacity=\"%.4f\"", sa]];
        }
    }
    float w = [annot getStrokeWidth];
    if (w > 0) [attrs addObject:[NSString stringWithFormat:@"width=\"%.4f\"", w]];
    NSString *nm = (nameOverride.length > 0) ? nameOverride : [annot getName];
    if (nm.length > 0) [attrs addObject:[NSString stringWithFormat:@"name=\"%@\"", [self escapeAttribute:nm]]];
    return [attrs componentsJoinedByString:@" "];
}

+ (NSString *)createText:(RDPDFAnnot *)annot page:(RDPDFPage *)page pageIndex:(int)pageIndex nameOverride:(NSString *)nameOverride {
    NSMutableString *s = [NSMutableString string];
    NSMutableString *attrs = [[self commonAttributesForAnnot:annot pageIndex:pageIndex skipColor:YES nameOverride:nameOverride] mutableCopy];
    // Prefer fill color; if not set, fall back to stroke color for text annotations
    int fill = [annot getFillColor];
    int colorForText = fill ? fill : [annot getStrokeColor];
    if (colorForText) {
        [attrs appendFormat:@" color=\"%@\"", [self colorHex:colorForText]];
        float a = ((colorForText >> 24) & 0xFF) / 255.0f;
        [attrs appendFormat:@" opacity=\"%.4f\"", a];
    }
    NSString *subject = [annot getPopupSubject];
    if (subject.length > 0) [attrs appendFormat:@" subject=\"%@\"", [self escapeAttribute:subject]];
    // Export icon index
    int iconIdx = [annot getIcon];
    [attrs appendFormat:@" icon=\"%d\"", iconIdx];
    [s appendFormat:@"    <text %@>\n", attrs];
    NSString *content = [annot getPopupText];
    if (content.length > 0) {
        [s appendString:@"      <contents-richtext>\n"]; 
        [s appendString:@"        <body xmlns=\"http://www.w3.org/1999/xhtml\" xmlns:xfa=\"http://www.xfa.org/schema/xfa-data/1.0/\" xfa:APIVersion=\"Radaee:1.0\" xfa:spec=\"2.0.2\">\n"]; 
        [s appendString:@"          <p><span>"]; 
        [s appendString:[self escape:content]]; 
        [s appendString:@"</span></p>\n"]; 
        [s appendString:@"        </body>\n"]; 
        [s appendString:@"      </contents-richtext>\n"]; 
    }
    [s appendString:@"      <popup/>\n"]; 
    [s appendString:@"    </text>\n"]; 
    return s;
}

+ (NSString *)createFreeText:(RDPDFAnnot *)annot page:(RDPDFPage *)page pageIndex:(int)pageIndex nameOverride:(NSString *)nameOverride {
    NSMutableString *s = [NSMutableString string];
    NSString *attrs = [self commonAttributesForAnnot:annot pageIndex:pageIndex skipColor:YES nameOverride:nameOverride];
    [s appendFormat:@"    <freetext %@>\n", attrs];
    NSString *text = [annot getEditText];
    if (text.length > 0) {
        int tcolor = [annot getEditTextColor];
        float tsize = [annot getEditTextSize];
        [s appendFormat:@"      <defaultappearance>%@ rg /RDF001 %.6f Tf</defaultappearance>\n", [self colorRGB:tcolor], tsize];
        [s appendFormat:@"      <defaultstyle>color:%@</defaultstyle>\n", [self colorHex:tcolor]];
        [s appendString:@"      <contents-richtext>\n"]; 
        [s appendString:@"        <body xmlns=\"http://www.w3.org/1999/xhtml\" xmlns:xfa=\"http://www.xfa.org/schema/xfa-data/1.0/\" xfa:APIVersion=\"Radaee:1.0\" xfa:spec=\"2.0.2\">\n"]; 
        [s appendString:@"          <p><span>"]; 
        [s appendString:[self escape:text]]; 
        [s appendString:@"</span></p>\n"]; 
        [s appendString:@"        </body>\n"]; 
        [s appendString:@"      </contents-richtext>\n"]; 
    }
    [s appendString:@"      <popup/>\n"]; 
    [s appendString:@"    </freetext>\n"]; 
    return s;
}

+ (NSString *)createLine:(RDPDFAnnot *)annot page:(RDPDFPage *)page pageIndex:(int)pageIndex nameOverride:(NSString *)nameOverride {
    NSMutableString *s = [NSMutableString string];
    NSString *attrs = [self commonAttributesForAnnot:annot pageIndex:pageIndex skipColor:NO nameOverride:nameOverride];
    PDF_POINT p1 = [annot getLinePoint:0];
    PDF_POINT p2 = [annot getLinePoint:1];
    NSString *startEnd = @"";
    if (!(p1.x == 0 && p1.y == 0 && p2.x == 0 && p2.y == 0)) {
        startEnd = [NSString stringWithFormat:@" start=\"%.4f,%.4f\" end=\"%.4f,%.4f\"", p1.x, p1.y, p2.x, p2.y];
    } else {
        PDF_RECT rc; [annot getRect:&rc];
        startEnd = [NSString stringWithFormat:@" start=\"%.4f,%.4f\" end=\"%.4f,%.4f\"", rc.left, rc.top, rc.right, rc.bottom];
    }
    // Arrowhead styles and fill color
    int style = [annot getLineStyle];
    int startStyle = (style & 0xFFFF);
    int endStyle = ((style >> 16) & 0xFFFF);
    int fill = [annot getFillColor];
    NSMutableString *extra = [NSMutableString stringWithFormat:@" startstyle=\"%d\" endstyle=\"%d\"", startStyle, endStyle];
    if (fill) {
        [extra appendFormat:@" fillcolor=\"%@\"", [self colorHex:fill]];
        float fa = ((fill >> 24) & 0xFF) / 255.0f;
        [extra appendFormat:@" fillopacity=\"%.4f\"", fa];
    }
    // Dash pattern
    float dashs[16];
    int dcnt = [annot getStrokeDash:dashs :16];
    // Export dash only if it is a real dashed pattern: >=2 positive segments and at least one segment > 0.5 * stroke width
    if (dcnt > 0) {
        NSMutableArray<NSString *> *vals = [NSMutableArray arrayWithCapacity:dcnt];
        int posCnt = 0; float maxSeg = 0.0f; float w = [annot getStrokeWidth];
        for (int i = 0; i < dcnt; i++) {
            if (dashs[i] > 0.0001f) {
                [vals addObject:[NSString stringWithFormat:@"%.4f", dashs[i]]];
                posCnt++;
                if (dashs[i] > maxSeg) maxSeg = dashs[i];
            }
        }
        if (posCnt >= 2 && maxSeg > (w * 0.5f)) {
            [extra appendFormat:@" dash=\"%@\"", [vals componentsJoinedByString:@","]];
        }
    }
    [s appendFormat:@"    <line %@%@%@/>\n", attrs, startEnd, extra];
    return s;
}

+ (NSString *)createSquare:(RDPDFAnnot *)annot page:(RDPDFPage *)page pageIndex:(int)pageIndex nameOverride:(NSString *)nameOverride {
    NSString *attrs = [self commonAttributesForAnnot:annot pageIndex:pageIndex skipColor:NO nameOverride:nameOverride];
    NSMutableString *extra = [NSMutableString string];
    int fill = [annot getFillColor];
    if (fill) {
        [extra appendFormat:@" fillcolor=\"%@\"", [self colorHex:fill]];
        float fa = ((fill >> 24) & 0xFF) / 255.0f;
        [extra appendFormat:@" fillopacity=\"%.4f\"", fa];
    }
    float dashs[16];
    int dcnt = [annot getStrokeDash:dashs :16];
    if (dcnt > 0) {
        NSMutableArray<NSString *> *vals = [NSMutableArray arrayWithCapacity:dcnt];
        int posCnt = 0; float maxSeg = 0.0f; float w = [annot getStrokeWidth];
        for (int i = 0; i < dcnt; i++) {
            if (dashs[i] > 0.0001f) {
                [vals addObject:[NSString stringWithFormat:@"%.4f", dashs[i]]];
                posCnt++;
                if (dashs[i] > maxSeg) maxSeg = dashs[i];
            }
        }
        if (posCnt >= 2 && maxSeg > (w * 0.5f)) {
            [extra appendFormat:@" dash=\"%@\"", [vals componentsJoinedByString:@","]];
        }
    }
    return [NSString stringWithFormat:@"    <square %@%@/>\n", attrs, extra];
}

+ (NSString *)createCircle:(RDPDFAnnot *)annot page:(RDPDFPage *)page pageIndex:(int)pageIndex nameOverride:(NSString *)nameOverride {
    NSString *attrs = [self commonAttributesForAnnot:annot pageIndex:pageIndex skipColor:NO nameOverride:nameOverride];
    NSMutableString *extra = [NSMutableString string];
    int fill = [annot getFillColor];
    if (fill) {
        [extra appendFormat:@" fillcolor=\"%@\"", [self colorHex:fill]];
        float fa = ((fill >> 24) & 0xFF) / 255.0f;
        [extra appendFormat:@" fillopacity=\"%.4f\"", fa];
    }
    float dashs[16];
    int dcnt = [annot getStrokeDash:dashs :16];
    if (dcnt > 0) {
        NSMutableArray<NSString *> *vals = [NSMutableArray arrayWithCapacity:dcnt];
        int posCnt = 0; float maxSeg = 0.0f; float w = [annot getStrokeWidth];
        for (int i = 0; i < dcnt; i++) {
            if (dashs[i] > 0.0001f) {
                [vals addObject:[NSString stringWithFormat:@"%.4f", dashs[i]]];
                posCnt++;
                if (dashs[i] > maxSeg) maxSeg = dashs[i];
            }
        }
        if (posCnt >= 2 && maxSeg > (w * 0.5f)) {
            [extra appendFormat:@" dash=\"%@\"", [vals componentsJoinedByString:@","]];
        }
    }
    return [NSString stringWithFormat:@"    <circle %@%@/>\n", attrs, extra];
}

#pragma mark - Import helpers

// Placeholder import helpers (not used)
// Intentionally left without implementation for now

// Import helpers removed for now

#pragma mark - Utils

+ (NSString *)generateUniqueAnnotationId:(RDPDFAnnot *)annot page:(RDPDFPage *)page pageIndex:(int)pageIndex {
    return [[[NSUUID alloc] init] UUIDString];
}

+ (NSString *)sanitizedFileName:(NSString *)name {
    NSCharacterSet *illegal = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_@."] invertedSet];
    return [[name componentsSeparatedByCharactersInSet:illegal] componentsJoinedByString:@"_"];
}

+ (NSString *)colorHex:(int)color {
    int r = (color >> 16) & 0xFF; int g = (color >> 8) & 0xFF; int b = color & 0xFF;
    return [NSString stringWithFormat:@"#%02X%02X%02X", r, g, b];
}

+ (NSString *)colorRGB:(int)color {
    int r = (color >> 16) & 0xFF; int g = (color >> 8) & 0xFF; int b = color & 0xFF;
    return [NSString stringWithFormat:@"%.6f %.6f %.6f", r/255.0, g/255.0, b/255.0];
}

+ (NSString *)escape:(NSString *)text {
    if (!text) return @"";
    NSMutableString *m = [text mutableCopy];
    [m replaceOccurrencesOfString:@"&" withString:@"&amp;" options:0 range:NSMakeRange(0, m.length)];
    [m replaceOccurrencesOfString:@"<" withString:@"&lt;" options:0 range:NSMakeRange(0, m.length)];
    [m replaceOccurrencesOfString:@">" withString:@"&gt;" options:0 range:NSMakeRange(0, m.length)];
    [m replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:0 range:NSMakeRange(0, m.length)];
    [m replaceOccurrencesOfString:@"'" withString:@"&apos;" options:0 range:NSMakeRange(0, m.length)];
    return m;
}

+ (NSString *)escapeAttribute:(NSString *)text {
    // For attribute values, also escape
    return [self escape:text];
}

// Parse attributes from an opening tag like: <line page="0" rect="..." />
+ (NSDictionary<NSString*, NSString*> *)p_parseAttributesFromOpenTag:(NSString *)openTag {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    // find name="value" pairs
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"([A-Za-z_:][A-Za-z0-9_:\\-]*)\\s*=\\s*\"([^\"]*)\"" options:0 error:nil];
    NSArray<NSTextCheckingResult *> *matches = [re matchesInString:openTag options:0 range:NSMakeRange(0, openTag.length)];
    for (NSTextCheckingResult *m in matches) {
        if (m.numberOfRanges >= 3) {
            NSString *key = [openTag substringWithRange:[m rangeAtIndex:1]];
            NSString *val = [openTag substringWithRange:[m rangeAtIndex:2]];
            if (key && val) dict[key.lowercaseString] = val;
        }
    }
    return dict;
}

+ (BOOL)p_hasLockedFlagInAttributes:(NSDictionary<NSString*, NSString*> *)attrs {
    NSString *flags = attrs[@"flags"];
    if (flags.length == 0) return NO;
    NSCharacterSet *seps = [NSCharacterSet characterSetWithCharactersInString:@", \t\r\n"];
    NSArray<NSString *> *parts = [flags componentsSeparatedByCharactersInSet:seps];
    for (NSString *p in parts) {
        NSString *t = [[p stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
        if (t.length == 0) continue;
        if ([t isEqualToString:@"locked"]) return YES;
    }
    return NO;
}

// Extract first <tag>...</tag> inner text (without nested tags parsing)
+ (NSString *)p_extractFirstTagText:(NSString *)tag inXML:(NSString *)xml {
    NSString *open = [NSString stringWithFormat:@"<%@", tag];
    NSRange r = [xml rangeOfString:open options:NSCaseInsensitiveSearch];
    if (r.location == NSNotFound) return @"";
    NSRange fromOpenEnd = [xml rangeOfString:@">" options:0 range:NSMakeRange(r.location, xml.length - r.location)];
    if (fromOpenEnd.location == NSNotFound) return @"";
    NSString *close = [NSString stringWithFormat:@"</%@>", tag];
    NSRange closeR = [xml rangeOfString:close options:NSCaseInsensitiveSearch range:NSMakeRange(fromOpenEnd.location+1, xml.length - (fromOpenEnd.location+1))];
    if (closeR.location == NSNotFound) return @"";
    return [xml substringWithRange:NSMakeRange(fromOpenEnd.location+1, closeR.location - (fromOpenEnd.location+1))];
}

// Extract first contents-richtext span text
+ (NSString *)p_extractFirstSpanText:(NSString *)xml {
    NSString *body = [self p_extractFirstTagText:@"contents-richtext" inXML:xml];
    if (body.length == 0) return @"";
    // Now get <span>..</span>
    NSString *open = @"<span>";
    NSRange r = [body rangeOfString:open options:NSCaseInsensitiveSearch];
    if (r.location == NSNotFound) return @"";
    NSRange closeR = [body rangeOfString:@"</span>" options:NSCaseInsensitiveSearch range:NSMakeRange(r.location+open.length, body.length - (r.location+open.length))];
    if (closeR.location == NSNotFound) return @"";
    NSString *inner = [body substringWithRange:NSMakeRange(r.location+open.length, closeR.location - (r.location+open.length))];
    // Unescape XML entities minimal
    NSMutableString *m = [inner mutableCopy];
    [m replaceOccurrencesOfString:@"&lt;" withString:@"<" options:0 range:NSMakeRange(0, m.length)];
    [m replaceOccurrencesOfString:@"&gt;" withString:@">" options:0 range:NSMakeRange(0, m.length)];
    [m replaceOccurrencesOfString:@"&amp;" withString:@"&" options:0 range:NSMakeRange(0, m.length)];
    [m replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:0 range:NSMakeRange(0, m.length)];
    [m replaceOccurrencesOfString:@"&apos;" withString:@"'" options:0 range:NSMakeRange(0, m.length)];
    return m;
}

// Parse defaultappearance like: "R G B rg /RDF001 size Tf"
+ (void)p_parseDefaultAppearance:(NSString *)ap r:(float *)r g:(float *)g b:(float *)b size:(float *)size {
    if (!ap) return;
    NSArray *parts = [[ap stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    for (NSInteger i = 0; i < parts.count; i++) {
        NSString *tok = parts[i];
        if ([tok isEqualToString:@"rg"]) {
            if (i >= 3) {
                if (r) *r = [parts[i-3] floatValue];
                if (g) *g = [parts[i-2] floatValue];
                if (b) *b = [parts[i-1] floatValue];
            }
        } else if ([tok isEqualToString:@"Tf"]) {
            if (i >= 1 && size) *size = [parts[i-1] floatValue];
        }
    }
}

+ (PDF_POINT)parsePoint:(NSString *)str {
    NSArray *p = [str componentsSeparatedByString:@","];
    PDF_POINT pt; pt.x = p.count>0 ? [p[0] floatValue] : 0; pt.y = p.count>1 ? [p[1] floatValue] : 0; return pt;
}

+ (PDF_RECT)parseRect:(NSString *)str {
    NSArray *p = [str componentsSeparatedByString:@","];
    PDF_RECT rc; rc.left = p.count>0 ? [p[0] floatValue] : 0; rc.bottom = p.count>1 ? [p[1] floatValue] : 0; rc.right = p.count>2 ? [p[2] floatValue] : 0; rc.top = p.count>3 ? [p[3] floatValue] : 0; return rc;
}

+ (int)parseColor:(NSString *)hex {
    NSString *h = [hex hasPrefix:@"#"] ? [hex substringFromIndex:1] : hex;
    unsigned int v = 0; [[NSScanner scannerWithString:h] scanHexInt:&v];
    if (h.length == 8) { // AARRGGBB
        return (int)v;
    } else { // RRGGBB
        return 0xFF000000 | (int)v;
    }
}

@end
