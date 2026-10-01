//
//  RDAnnotSettingsViewController.h
//  PDFViewer
//
//  Settings view controller with sliders for annotation properties
//

#import <UIKit/UIKit.h>
#import "PDFObjc.h"
#import "RDVGlobal.h"
#import "RDUtils.h"
#import "RDAnnotPickerViewController.h"

typedef NS_ENUM(NSInteger, RDAnnotSettingsType) {
    RDAnnotSettingsTypeLine = 0,
    RDAnnotSettingsTypeArrow = 1,
    RDAnnotSettingsTypeRectangle = 2,
    RDAnnotSettingsTypeEllipse = 3,
    RDAnnotSettingsTypeText = 4
};

@interface RDAnnotSettingsViewController : UIViewController

@property (nonatomic) RDAnnotSettingsType settingsType;
@property (nonatomic, copy) void (^onApply)(void);
@property (nonatomic, strong) RDPDFAnnot *annot;
@property (nonatomic, strong) RDPDFPage *page;

- (instancetype)initWithType:(RDAnnotSettingsType)type;
// Convenience to pass the target annotation directly
- (instancetype)initWithAnnot:(RDPDFAnnot *)annot type:(RDAnnotSettingsType)type;
- (instancetype)initWithAnnot:(RDPDFAnnot *)annot page:(RDPDFPage *)page type:(RDAnnotSettingsType)type;

@end
