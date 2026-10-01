# RadaeePDF SDK for iOS — Premium and Classic in a single project

<img src="https://www.radaeepdf.com/wp-content/uploads/2024/08/solo_butterly_midres.png" style="width:100px;">

RadaeePDF SDK is a powerful, native PDF rendering and manipulation library for iOS
applications. Built from true native C++ code, it provides exceptional performance
and a comprehensive set of features for working with PDF documents.

<p>
  <img src="https://upload.wikimedia.org/wikipedia/en/8/8c/IOS_27_icon.png" alt="iOS 27" width="72">
  <br>
  <strong>Ready for iOS 27</strong>
</p>

This repository builds **the very same app** against **two different Radaee SDKs** —
Premium (`RDDLib`) and Classic (`RDPDFLib`) — selected by the Xcode scheme. There is
no duplicated application code: both targets share all 88 sources, 45 resources and
16 frameworks. The Premium target additionally compiles the DOCX viewer
(`PDFViewer/DOCXLayout/`, `PDFLib/DOCXObjc.m`), which only `RDDLib` supports.

> It supersedes the two separate repositories
> [RadaeePDF-Master-iOS](https://github.com/RadaeePDF-Jugaad/RadaeePDF-Master-iOS)
> (Premium) and
> [RadaeePDF-Classic-iOS](https://github.com/RadaeePDF-Jugaad/RadaeePDF-Classic-iOS),
> whose READMEs this guide is based on.

---

## The two builds

| Scheme / Target | Library | Product | Define |
|---|---|---|---|
| `PDFViewer-Master` | `RDDLib.xcframework` | `RadaeePDF.app` | — |
| `PDFViewer-Classic` | `RDPDFLib.xcframework` | `RadaeePDF-Classic.app` | `RD_SDK_CLASSIC=1` |

Both use the bundle id `com.radaee.reader`, which is required by the license keys —
see [Licensing and keys](#licensing-and-keys).

### From Xcode

1. Open `PDFViewer.xcodeproj`
2. In the **scheme selector** at the top, next to the Run button, pick
   `PDFViewer-Master` or `PDFViewer-Classic`
3. Choose a destination (simulator or connected device)
4. Press **⌘R**

> If you just pulled with Xcode already open, close and reopen the project: Xcode
> keeps the previous project state in memory and will not show the new schemes.

### From the command line

```bash
# Premium
xcodebuild -project PDFViewer.xcodeproj -scheme PDFViewer-Master \
           -configuration Debug -sdk iphonesimulator build

# Classic
xcodebuild -project PDFViewer.xcodeproj -scheme PDFViewer-Classic \
           -configuration Debug -sdk iphonesimulator build
```

Both schemes are **shared** (`PDFViewer.xcodeproj/xcshareddata/xcschemes/`), so they
show up for anyone who clones the repository and work in CI without relying on the
per-user schemes Xcode creates automatically.

### Apple Silicon: no workaround needed

Earlier READMEs asked developers on M1/M2/M3 Macs to install the **Universal**
(x86_64/Rosetta) simulator runtime and to add `arm64` to *Excluded Architectures*.
**That is no longer necessary here.** Both libraries ship as `.xcframework` with an
`ios-arm64_x86_64-simulator` slice, so the native arm64 simulator works:

```bash
xcodebuild ... -sdk iphonesimulator -arch arm64 build   # fine on Apple Silicon
```

`EXCLUDED_ARCHS` is empty on both application targets.

---

## Where the libraries live

```
PDFViewer/PDFLib/
├── RDDLib.xcframework      ← PREMIUM library (101 MB)
│   ├── ios-arm64/libRDDLib.a
│   └── ios-arm64_x86_64-simulator/libRDDLib.a
├── RDPDFLib.xcframework    ← CLASSIC library (77 MB)
│   ├── ios-arm64/libRDPDFLib.a
│   └── ios-arm64_x86_64-simulator/libRDPDFLib.a
│
├── RDComm.h  RDPDF.h       ← Premium SDK C headers
├── PDFIOS.h                ← Classic SDK C header
├── RDSDKCompat.h           ← compatibility layer between the two
└── PDFObjc.h  PDFObjc.m    ← Objective-C wrapper, shared by both variants
```

The libraries are present **only** as `.xcframework`. Loose `.a` files are not part
of the repository.

### How one codebase talks to two SDKs

Every call the app makes goes through `PDFObjc.m`: no application source includes
the SDK C headers. That single point of contact is what makes the dual variant
possible.

The Premium SDK prefixes its C functions with `PDF_` (`PDF_Document_open`), the
Classic one does not (`Document_open`). 343 of the functions the wrapper calls have
identical signatures once the prefix is removed; `RDSDKCompat.h` maps those names,
and wraps the 4 that genuinely differ — the `newImage` family, which lost its
`interpolate` parameter in Classic. `Global_*` and `Page_render1` are spelled the
same in both libraries.

---

## Differences between the two variants

The API is 98% the same. Classic does not expose 63 functions that Premium has (and
Premium lacks a few that Classic has); the methods using them are compiled out of
the build that lacks them, and each group has an availability macro you can test in
your own code:

| Macro | Feature |
|---|---|
| `RD_HAS_XFDF` | XFDF annotation import/export |
| `RD_HAS_PAGE_EDITOR` | page content editor, character editing |
| `RD_HAS_HTML_EXPORT` | HTML export |
| `RD_HAS_PAGE_OBJECTS` | reading/replacing images in page objects |
| `RD_HAS_FORM_CREATION` | **creating** form fields (`addField*`) |
| `RD_HAS_EMBED_FILES` | embedded file attachments |
| `RD_HAS_PDFA` | PDF/A generation |
| `RD_HAS_SIGN_LOCK` | signature lock |
| `RD_HAS_SIGN_CONTENT` | raw signature content |
| `RD_HAS_RAW_OBJECTS` | creating a standalone `RDPDFObj` |
| `RD_HAS_OPTIMIZE` | document optimisation |
| `RD_HAS_IMPORT2PAGE` | partial page import |
| `RD_HAS_TAGGED_PDF` | tagged PDF (`newTagGroup`, `newTagBlock`, `tagBlockStart/End`) |
| `RD_HAS_OUTLINE_DEST2` | full outline destination (`RDPDFOutline.dest2:`) |
| `RD_HAS_DOC_ANNOT_ICON` | `+[RDPDFDoc drawAnnotIcon:::]` |
| `RD_HAS_DOCX` | DOCX documents (`DOCXDoc`, `DOCXLayoutView`) |

Available in Classic only:

| Macro | Feature |
|---|---|
| `RD_HAS_REFLOW_FONT` | `reflowPrepare2::::` (reflow with images/font) |
| `RD_HAS_DRAW_SCROLL` | `+[RDPDFGlobal drawScroll:::::::]` |
| `RD_HAS_FIELD_BTN_LABEL` | `RDPDFAnnot.fieldBtnLabel` |

Waiting for a newer Premium library. `RDPDFAnnot.fieldBtnLabel`,
`addFieldButtonSubmit`, `addFieldButtonReset`, `addFieldCombo2` and `addFieldList2`
exist in the `RDDLib` build shipped with RadaeePDF-Master-iOS, but not in
`RDDLib.xcframework` here. That build has no arm64-simulator slice, so it was not
imported. `RD_HAS_FIELD_BTN_LABEL` and `RD_HAS_FORM_BUTTON_EXT` are `0` for Premium.
Set them to `1` in `RDSDKCompat.h` once the xcframework is updated.

```objc
#if RD_HAS_XFDF
    NSString *xfdf = [doc exportXFDF:@"document.pdf"];
#endif
```

**Every example in this guide works on both variants**: filling form fields,
annotations, signing, search, text extraction and encryption are all available in
either build. Only creating form fields from scratch is Premium-only.

---

## Licensing and keys

Radaee license keys are tied **both to the library and to the bundle id**: the
Premium key does not activate Classic and vice versa, and neither activates if the
bundle id does not match.

`PDFViewer/RDAppDelegate.m` picks the right key for the variant being built:

```objc
#if RD_SDK_CLASSIC
    g_serial = @"…Classic key…";
#else
    g_serial = @"…Premium key…";
#endif
```

Both keys in this repository were issued for `com.radaee.reader`, which is therefore
the bundle id of all four builds (Premium/Classic × Debug/Release).
**As a consequence the two apps cannot be installed side by side** — installing one
replaces the other. Running them in parallel would require a Classic key issued by
Radaee for a dedicated bundle id.

A host application can always override the key at runtime:

```objc
[plugin activateLicenseWithSerialKey:@"YOUR-LICENSE-KEY-HERE"];
```

If activation fails after an SDK update, the key may predate the library: compare
the dates using `Global_getVerString()`.

---

## Repository layout

```
PDFViewer.xcodeproj          targets: PDFViewer-Master, PDFViewer-Classic
PDFViewer/
├── PDFLib/                  SDK: xcframeworks, headers, wrapper (see above)
├── PDFView/                 layout and rendering engine (RDV*, PDFLayoutView)
├── DOCXLayout/              DOCX layout and rendering engine (Premium target only)
├── Modules/                 full-text search, advanced signature, undo/redo, utilities
├── AnnotProps/ AnnotMenu/   annotation UI
├── FileList/ TreeTableView/ file browser and outline
└── RDLoPDFViewController.m  main reader view controller
```

---

## Adding the SDK to an existing project

1. Copy `PDFViewer/PDFLib/` into your project.
2. Drag **one** of the two xcframeworks into Xcode — `RDDLib.xcframework` (Premium)
   or `RDPDFLib.xcframework` (Classic) — under
   *Build Phases → Link Binary With Libraries*.
3. Add `PDFObjc.m` to your target's sources.
4. For Classic only, define `RD_SDK_CLASSIC=1` under
   *Build Settings → Preprocessor Macros*.
5. Copy the `fdat/` and `cmaps/` resources into your bundle.

> The two libraries **cannot coexist** in the same binary: they share 7554 C symbols
> (each embeds its own copy of OpenSSL). The choice is made at build time, never at
> runtime.


## Usage guide

> Every example below works with **both the Premium and the Classic build**: none of
> them uses a Premium-only API. Where a feature is available in one variant only, it
> is called out explicitly.

## Getting Started

### Initialize the Library

Activate the license once at startup, in the app delegate. Set `g_serial` before `[RDVGlobal Init]`.

**Objective-C**

```objc
#import "RDVGlobal.h"

// Declare the external global variable
extern NSString *g_serial;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Set the license key
    g_serial = @"YOUR-LICENSE-KEY-HERE";

    // Initialize RadaeePDF engine with the license
    [RDVGlobal Init];

    return YES;
}

@end
```

**Swift**

For Swift projects, you need to expose `g_serial` through a bridging header and create an Objective-C helper:

```objc
// In your Bridging Header or a helper file
#import "RDVGlobal.h"

extern NSString *g_serial;

// Helper function for Swift
void RadaeePDF_SetLicense(NSString *key) {
    g_serial = key;
    [RDVGlobal Init];
}
```

```swift
// In AppDelegate.swift
func application(_ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    // Activate RadaeePDF license at app startup
    RadaeePDF_SetLicense("YOUR-LICENSE-KEY-HERE")

    return true
}
```

**Important Notes:**
- Replace `YOUR-LICENSE-KEY-HERE` with your actual RadaeePDF license key
- The license key is a hexadecimal string provided by RadaeePDF
- Set `g_serial` before calling `[RDVGlobal Init]`
- The `[RDVGlobal Init]` method calls `Global_active()` to validate the license and initializes fonts, CMaps, and other resources

### Open and Display a PDF

#### Using RDPDFDoc Directly (Low-level API)

For direct PDF manipulation without the viewer, use `RDPDFDoc`:

**Swift**

```swift
func openPDFDirect(filePath: String, password: String) {
    let doc = RDPDFDoc()
    let result = doc.open(filePath, password)

    switch result {
    case 0:  // Success
        let pageCount = doc.pageCount()
        print("PDF opened successfully. Page count: \(pageCount)")
        // Perform operations...
        doc.close()
    case -1:
        print("Error: Password required")
    case -2:
        print("Error: Unknown encryption")
    case -3:
        print("Error: Damaged or invalid format")
    case -10:
        print("Error: Access denied or invalid file path")
    default:
        print("Error: Unknown error (\(result))")
    }
}
```

**Objective-C**

```objc
- (void)openPDFDirect:(NSString *)filePath password:(NSString *)password {
    RDPDFDoc *doc = [[RDPDFDoc alloc] init];
    int result = [doc open:filePath :password];

    switch (result) {
        case 0:  // Success
            NSLog(@"PDF opened successfully. Page count: %d", [doc pageCount]);
            // Perform operations...
            [doc close];
            break;
        case -1:
            NSLog(@"Error: Password required");
            break;
        case -2:
            NSLog(@"Error: Unknown encryption");
            break;
        case -3:
            NSLog(@"Error: Damaged or invalid format");
            break;
        case -10:
            NSLog(@"Error: Access denied or invalid file path");
            break;
        default:
            NSLog(@"Error: Unknown error (%d)", result);
            break;
    }
}
```

### Open PDF from Memory

**Swift**

```swift
func openPDFFromMemory(data: Data, password: String) {
    let doc = RDPDFDoc()
    let result = data.withUnsafeBytes { bytes -> Int32 in
        return doc.openMem(UnsafeMutableRawPointer(mutating: bytes.baseAddress!),
                          Int32(data.count),
                          password)
    }

    if result == 0 {
        print("PDF opened from memory successfully. Page count: \(doc.pageCount())")
        // Perform operations...
        doc.close()
    }
}
```

**Objective-C**

```objc
- (void)openPDFFromMemory:(NSData *)data password:(NSString *)password {
    RDPDFDoc *doc = [[RDPDFDoc alloc] init];
    int result = [doc openMem:(void *)[data bytes] :(int)[data length] :password];

    if (result == 0) {
        NSLog(@"PDF opened from memory. Page count: %d", [doc pageCount]);
        // Perform operations...
        [doc close];
    }
}
```

## Common Operations

### Get Page Count

**Swift**

```swift
let pageCount = doc.pageCount()
print("Document has \(pageCount) pages")
```

**Objective-C**

```objc
int pageCount = [doc pageCount];
NSLog(@"Document has %d pages", pageCount);
```

### Navigate to a Specific Page

With the reader on screen, `RDLoPDFViewController` moves to a page with `PDFGoto:`.

**Swift**

```swift
// Navigate to a specific page using RDLoPDFViewController
// First, get the reader controller from the presented view controller
if let readerCtrl = presentedViewController as? RDLoPDFViewController {
    readerCtrl.pdfGoto(5)  // Go to page 5 (0-based index)
}
```

**Objective-C**

```objc
// Navigate to a specific page using RDLoPDFViewController
// First, get the reader controller from the presented view controller
RDLoPDFViewController *readerCtrl = (RDLoPDFViewController *)self.presentedViewController;
if (readerCtrl) {
    [readerCtrl PDFGoto:5];  // Go to page 5 (0-based index)
}
```

**Using PDFLayoutView directly:**

If you have direct access to the `PDFLayoutView` (for custom implementations):

```objc
// Objective-C
[pdfLayoutView vGoto:5];  // Navigate to page 5
```

```swift
// Swift
pdfLayoutView.vGoto(5)  // Navigate to page 5
```

### Set View Mode

Configure the PDF view mode before opening a document. View modes control how pages are displayed.

**View Mode Values:**
- `0` - Vertical scroll
- `1` - Horizontal scroll (left to right)
- `2` - Curl effect (page flip animation)
- `3` - Single page
- `4` - Single page cover (first page single, others dual in landscape)
- `5` - Reflow
- `6` - Dual page in landscape
- `7` - Dual page with cover (like Acrobat)
- `8` - Dual page without cover

**Objective-C**

```objc
GLOBAL.g_view_mode = 0;  // Vertical scroll. Set before opening the reader.
```

### Enable Night Mode (Dark Mode)

Enable dark mode for better readability in low-light conditions.

```objc
GLOBAL.g_dark_mode = YES;
```

### Customizing Reader Appearance

Colors and layout flags are methods of `RDLoPDFViewController`:

```objc
[reader setThumbnailBGColor:0xFF333333];
[reader setReaderBGColor:0xFFE0E0E0];
[reader setThumbHeight:80.0];
[reader setFirstPageCover:YES];
[reader setDoubleTapZoomMode:2];
[reader setImmersive:YES];
```

### Text Highlighting (Professional License)

Add text markup annotations (highlight, underline, strikeout, squiggly):

**Markup Types:**
- `0` - Highlight
- `1` - Underline
- `2` - Strikeout
- `4` - Squiggly

**Swift**

```swift
func addMarkupAnnotation(to doc: RDPDFDoc, pageIndex: Int,
                         startCharIndex: Int, endCharIndex: Int,
                         markupType: Int) -> Bool {
    guard let page = doc.page(Int32(pageIndex)) else { return false }

    page.objsStart(false)

    // Get markup color based on type
    var color: UInt32
    switch markupType {
    case 0: color = GLOBAL.g_annot_highlight_clr  // Highlight (yellow)
    case 1: color = GLOBAL.g_annot_underline_clr  // Underline (blue)
    case 2: color = GLOBAL.g_annot_strikeout_clr  // Strikeout (red)
    case 4: color = GLOBAL.g_annot_squiggly_clr   // Squiggly (green)
    default: color = 0xFFFFFF00
    }

    // Add markup annotation between character indices
    page.addAnnotMarkup(Int32(startCharIndex), Int32(endCharIndex), Int32(markupType), Int32(color))

    doc.save()
    page.close()
    return true
}
```

**Objective-C**

```objc
- (BOOL)addMarkupAnnotationTo:(RDPDFDoc *)doc
                    pageIndex:(int)pageIndex
               startCharIndex:(int)startIndex
                 endCharIndex:(int)endIndex
                   markupType:(int)type {
    RDPDFPage *page = [doc page:pageIndex];
    if (!page) return NO;

    [page objsStart:NO];

    // Get markup color based on type
    int color;
    switch (type) {
        case 0: color = GLOBAL.g_annot_highlight_clr; break;  // Highlight
        case 1: color = GLOBAL.g_annot_underline_clr; break;  // Underline
        case 2: color = GLOBAL.g_annot_strikeout_clr; break;  // Strikeout
        case 4: color = GLOBAL.g_annot_squiggly_clr; break;   // Squiggly
        default: color = 0xFFFFFF00; break;
    }

    // Add markup annotation between character indices
    [page addAnnotMarkup:startIndex :endIndex :type :color];

    [doc save];
    [page close];
    return YES;
}
```

### Remove Annotation

**Swift**

```swift
func removeAnnotation(from doc: RDPDFDoc, pageIndex: Int, annotIndex: Int) -> Bool {
    guard let page = doc.page(Int32(pageIndex)) else { return false }

    page.objsStart(false)

    if let annot = page.annotAtIndex(Int32(annotIndex)) {
        annot.removeFromPage()
        doc.save()
        page.close()
        return true
    }

    page.close()
    return false
}
```

**Objective-C**

```objc
- (BOOL)removeAnnotationFrom:(RDPDFDoc *)doc pageIndex:(int)pageIndex annotIndex:(int)annotIndex {
    RDPDFPage *page = [doc page:pageIndex];
    if (!page) return NO;

    [page objsStart:NO];

    RDPDFAnnot *annot = [page annotAtIndex:annotIndex];
    if (annot) {
        [annot removeFromPage];
        [doc save];
        [page close];
        return YES;
    }

    [page close];
    return NO;
}
```

### Save Document

**Swift**

```swift
// Save changes to the same file
doc.save()

// Save to a new file
let success = doc.saveAs("/path/to/newfile.pdf", false)  // false = remove security settings
```

**Objective-C**

```objc
// Save changes to the same file
[doc save];

// Save to a new file
BOOL remSecurity = NO;  // Keep security settings
[doc saveAs:@"/path/to/newfile.pdf" :remSecurity];
```

### Encrypt Document

Encrypt a PDF with password protection:

**Permission Flags (combine with OR):**
As defined in PDF Reference 1.7:
- `0x4` (4) - bit 3: Print the document
- `0x8` (8) - bit 4: Modify document contents
- `0x10` (16) - bit 5: Extract text or images

For additional permission bits, refer to the PDF Reference 1.7 specification.

**Encryption Method:**
The `method` parameter is reserved. Pass `0` for default encryption.

**Objective-C**

```objc
unsigned char *ident = (unsigned char *)[@"RadaeePDF" cStringUsingEncoding:NSUTF8StringEncoding];
BOOL success = [doc encryptAs:@"/path/to/encrypted.pdf"
                              :@"user123"
                              :@"owner456"
                              :(4 | 16)
                              :0
                              :ident];
```

### Extract Text from PDF

Use `objsStart:` to load text objects, then `objsString:` to extract text. The `objsCount` property returns the total character count.

**Swift**

```swift
func extractText(from doc: RDPDFDoc) -> String {
    var text = ""
    let pageCount = doc.pageCount()

    for i in 0..<pageCount {
        if let page = doc.page(Int32(i)) {
            // Load text objects (false = left-to-right, true = right-to-left)
            page.objsStart(false)

            // Extract all text from page
            let charCount = page.objsCount()
            if let pageText = page.objsString(0, Int32(charCount)) {
                text += "Page \(i + 1):\n\(pageText)\n\n"
            }
            page.close()
        }
    }

    return text
}
```

**Objective-C**

```objc
- (NSString *)extractTextFromPDF:(NSString *)filePath {
    RDPDFDoc *doc = [[RDPDFDoc alloc] init];
    NSMutableString *text = [[NSMutableString alloc] init];

    if ([doc open:filePath :@""] == 0) {  // 0 = success
        for (int i = 0; i < [doc pageCount]; i++) {
            RDPDFPage *page = [doc page:i];

            // Load text objects (NO = left-to-right)
            [page objsStart:NO];

            // Extract all text from page
            int charCount = [page objsCount];
            NSString *pageText = [page objsString:0 :charCount];
            if (pageText) {
                [text appendFormat:@"Page %d:\n%@\n\n", i + 1, pageText];
            }
            [page close];
        }
        [doc close];
    }

    return text;
}
```

### Search Text in PDF

Use `find:` to create a search session. The `RDPDFFinder` object provides match count and character indices.

**Swift**

```swift
func searchText(in doc: RDPDFDoc, searchTerm: String, matchCase: Bool, wholeWord: Bool) -> [(page: Int, startIndex: Int, endIndex: Int)] {
    var results: [(page: Int, startIndex: Int, endIndex: Int)] = []
    let pageCount = doc.pageCount()

    for i in 0..<pageCount {
        if let page = doc.page(Int32(i)) {
            page.objsStart(false)

            // Create finder session
            if let finder = page.find(searchTerm, matchCase, wholeWord) {
                let matchCount = finder.count()

                for j in 0..<matchCount {
                    let startIdx = finder.objsIndex(Int32(j))
                    let endIdx = finder.objsEnd(Int32(j))
                    results.append((page: Int(i), startIndex: Int(startIdx), endIndex: Int(endIdx)))
                }
            }
            page.close()
        }
    }

    return results
}
```

**Objective-C**

```objc
- (NSArray *)searchText:(NSString *)searchTerm inDoc:(RDPDFDoc *)doc {
    NSMutableArray *results = [NSMutableArray array];

    for (int i = 0; i < [doc pageCount]; i++) {
        RDPDFPage *page = [doc page:i];
        [page objsStart:NO];

        // Create finder session (matchCase: YES, wholeWord: NO)
        RDPDFFinder *finder = [page find:searchTerm :YES :NO];
        if (finder) {
            int matchCount = [finder count];

            for (int j = 0; j < matchCount; j++) {
                int startIdx = [finder objsIndex:j];
                int endIdx = [finder objsEnd:j];

                [results addObject:@{
                    @"page": @(i),
                    @"startIndex": @(startIdx),
                    @"endIndex": @(endIdx)
                }];
            }
        }
        [page close];
    }

    return results;
}
```

### Add Sticky Note Annotation

Use `addAnnotNote:` to add a sticky note at a specific point. Access the annotation via `annotAtIndex:` to set properties.

**Swift**

```swift
func addStickyNote(to doc: RDPDFDoc, pageIndex: Int, x: Float, y: Float,
                   subject: String, content: String) -> Bool {
    guard let page = doc.page(Int32(pageIndex)) else { return false }

    page.objsStart(false)

    // Create point in PDF coordinates
    var point = PDF_POINT(x: x, y: y)

    if page.addAnnotNote(&point) {
        // Get the newly added annotation (last one)
        let annotCount = page.annotCount()
        if let annot = page.annotAtIndex(annotCount - 1) {
            annot.setPopupSubject(subject)
            annot.setPopupText(content)
        }
        doc.save()
        page.close()
        return true
    }

    page.close()
    return false
}
```

**Objective-C**

```objc
- (BOOL)addStickyNoteTo:(RDPDFDoc *)doc pageIndex:(int)pageIndex
                      x:(float)x y:(float)y
                subject:(NSString *)subject content:(NSString *)content {
    RDPDFPage *page = [doc page:pageIndex];
    if (!page) return NO;

    [page objsStart:NO];

    // Create point in PDF coordinates
    PDF_POINT point;
    point.x = x;
    point.y = y;

    if ([page addAnnotNote:&point]) {
        // Get the newly added annotation (last one)
        int annotCount = [page annotCount];
        RDPDFAnnot *annot = [page annotAtIndex:annotCount - 1];
        if (annot) {
            [annot setPopupSubject:subject];
            [annot setPopupText:content];
        }
        [doc save];
        [page close];
        return YES;
    }

    [page close];
    return NO;
}
```

### Add Ink Annotation (Handwriting)

Use `RDPDFInk` to capture stroke data, then `addAnnotInk:` to add it to the page.

**Swift**

```swift
func addInkAnnotation(to doc: RDPDFDoc, pageIndex: Int) -> Bool {
    guard let page = doc.page(Int32(pageIndex)) else { return false }

    page.objsStart(false)

    // Create ink with line width and color (0xAARRGGBB format)
    guard let ink = RDPDFInk(2.0, 0xFF0000FF) else {  // Blue color, 2pt width
        page.close()
        return false
    }

    // Draw a stroke
    ink.onDown(100, 100)  // Touch down
    ink.onMove(150, 120)  // Move
    ink.onMove(200, 100)  // Move
    ink.onUp(200, 100)    // Touch up

    if page.addAnnotInk(ink) {
        doc.save()
        page.close()
        return true
    }

    page.close()
    return false
}
```

**Objective-C**

```objc
- (BOOL)addInkAnnotationTo:(RDPDFDoc *)doc pageIndex:(int)pageIndex {
    RDPDFPage *page = [doc page:pageIndex];
    if (!page) return NO;

    [page objsStart:NO];

    // Create ink with line width and color (0xAARRGGBB format)
    RDPDFInk *ink = [[RDPDFInk alloc] init:2.0 :0xFF0000FF];  // Blue, 2pt width

    // Draw a stroke
    [ink onDown:100 :100];  // Touch down
    [ink onMove:150 :120];  // Move
    [ink onMove:200 :100];  // Move
    [ink onUp:200 :100];    // Touch up

    if ([page addAnnotInk:ink]) {
        [doc save];
        [page close];
        return YES;
    }

    [page close];
    return NO;
}
```

### Add Rectangle Annotation

Use `addAnnotRect:` to add a rectangle annotation. Parameters include the rectangle bounds, line width, stroke color, and fill color in `0xAARRGGBB` format.

**Swift**

```swift
func addRectAnnotation(to doc: RDPDFDoc, pageIndex: Int,
                       left: Float, top: Float, right: Float, bottom: Float,
                       lineWidth: Float, strokeColor: UInt32, fillColor: UInt32) -> Bool {
    guard let page = doc.page(Int32(pageIndex)) else { return false }

    page.objsStart(false)

    // Rectangle coordinates in PDF coordinates
    var rect = PDF_RECT()
    rect.left = left
    rect.top = top
    rect.right = right
    rect.bottom = bottom

    // Add rectangle: rect, lineWidth, strokeColor, fillColor (0xAARRGGBB)
    // fillColor alpha=0 means no fill
    if page.addAnnotRect(&rect, lineWidth, Int32(bitPattern: strokeColor), Int32(bitPattern: fillColor)) {
        doc.save()
        page.close()
        return true
    }

    page.close()
    return false
}

// Usage example
let success = addRectAnnotation(
    to: doc,
    pageIndex: 0,
    left: 100, top: 200, right: 300, bottom: 100,
    lineWidth: 2.0,
    strokeColor: 0xFFFF0000,  // Red stroke
    fillColor: 0x00000000     // No fill (alpha = 0)
)
```

**Objective-C**

```objc
- (BOOL)addRectAnnotationTo:(RDPDFDoc *)doc pageIndex:(int)pageIndex {
    RDPDFPage *page = [doc page:pageIndex];
    if (!page) return NO;

    [page objsStart:NO];

    // Rectangle coordinates (left, top, right, bottom) in PDF coordinates
    PDF_RECT rect;
    rect.left = 100;
    rect.top = 200;
    rect.right = 300;
    rect.bottom = 100;

    // Add rectangle: rect, lineWidth, strokeColor, fillColor (0xAARRGGBB)
    // fillColor alpha=0 means no fill
    if ([page addAnnotRect:&rect :2.0 :0xFFFF0000 :0x00000000]) {  // Red stroke, no fill
        [doc save];
        [page close];
        return YES;
    }

    [page close];
    return NO;
}
```

### Fill Form Fields

Form fields are accessed as annotations on each page. Use `annotCount` and `annotAtIndex:` to iterate through annotations, then check `fieldType` to identify form fields.

**Form Field Types (from `fieldType`):**
- `0` - Unknown (not a form field)
- `1` - Button field (push button, checkbox, radio button)
- `2` - Text field
- `3` - Choice field (list box, combo box)
- `4` - Signature field

**Check/Radio Status (from `getCheckStatus`):**
- `0` - Checkbox unchecked
- `1` - Checkbox checked
- `2` - Radio button unchecked
- `3` - Radio button checked

**Swift**

```swift
func fillFormFields(in doc: RDPDFDoc) {
    let pageCount = doc.pageCount()

    for pageIndex in 0..<pageCount {
        guard let page = doc.page(Int32(pageIndex)) else { continue }
        page.objsStart(false)

        let annotCount = page.annotCount()
        for i in 0..<annotCount {
            guard let annot = page.annotAtIndex(Int32(i)) else { continue }

            let fieldType = annot.fieldType()

            switch fieldType {
            case 1:  // Button field
                let checkStatus = annot.getCheckStatus()
                if checkStatus == 0 || checkStatus == 1 {
                    // Checkbox
                    annot.setCheckValue(true)
                } else if checkStatus == 2 || checkStatus == 3 {
                    // Radio button
                    annot.setRadio()
                }
            case 2:  // Text field
                annot.setEditText("Sample Value")
            case 3:  // Choice field (list/combo box)
                annot.setComboSel(0)  // Select first item
            case 4:  // Signature field
                break
            default:
                break
            }
        }
        page.close()
    }

    doc.save()
}
```

**Objective-C**

```objc
- (void)fillFormFields:(RDPDFDoc *)doc {
    int pageCount = [doc pageCount];

    for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        RDPDFPage *page = [doc page:pageIndex];
        if (!page) continue;

        [page objsStart:NO];

        int annotCount = [page annotCount];
        for (int i = 0; i < annotCount; i++) {
            RDPDFAnnot *annot = [page annotAtIndex:i];
            if (!annot) continue;

            int fieldType = [annot fieldType];

            switch (fieldType) {
                case 1: {  // Button field
                    int checkStatus = [annot getCheckStatus];
                    if (checkStatus == 0 || checkStatus == 1) {
                        // Checkbox
                        [annot setCheckValue:YES];
                    } else if (checkStatus == 2 || checkStatus == 3) {
                        // Radio button
                        [annot setRadio];
                    }
                    break;
                }
                case 2:  // Text field
                    [annot setEditText:@"Sample Value"];
                    break;
                case 3:  // Choice field (list/combo box)
                    [annot setComboSel:0];  // Select first item
                    break;
                case 4:  // Signature field
                    break;
            }
        }
        [page close];
    }

    [doc save];
}
```

## License levels

RadaeePDF offers different license levels with varying features. In this repository
the Premium variant (`RDDLib`) exposes 63 C functions that the Classic one
(`RDPDFLib`) does not — see
[Differences between the two variants](#differences-between-the-two-variants).

Visit [radaeepdf.com](https://www.radaeepdf.com/) for detailed licensing information.

## Documentation

- [RadaeePDF Support Portal](https://support.radaeepdf.com/)
- Upstream wikis:
  [Classic](https://github.com/RadaeePDF-Jugaad/RadaeePDF-Classic-iOS/wiki) ·
  [Master](https://github.com/RadaeePDF-Jugaad/RadaeePDF-Master-iOS)

## Support

For technical support and questions:
- Email: support@radaeepdf.com
- Website: [radaeepdf.com](https://www.radaeepdf.com/)

## License

This SDK is commercial software. Please ensure you have a valid license before using
it in production applications. See the [EULA](PDFViewer/fdat/EULA.pdf).

---

© 2026 RadaeePDF. All rights reserved.
