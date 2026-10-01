//
//  AdvSignatureViewController.h
//  PDFViewer
//
//  Created by Emanuele Bortolami on 05/04/18.
//

#import <UIKit/UIKit.h>

#define TEMP_SIGNATURE @"radaee_signature_temp.png"
#define SIGNATURE_ENABLED

@protocol ADVSignatureDelegate <NSObject>

- (void)advDidSign:(id)rotation;
- (void)advDidCancelSign:(id)rotation;

@end

@interface AdvSignatureViewController : UIViewController

@property (weak, nonatomic) id <ADVSignatureDelegate> delegate;

@end
