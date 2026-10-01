//
//  AdvSignatureViewController.m
//  PDFViewer
//
//  Created by Emanuele Bortolami on 05/04/18.
//

#import "AdvSignatureViewController.h"
#import "SignatureView.h"
#import "ImageCropView.h"
#import "RDVGlobal.h"

@interface AdvSignatureViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, ImageCropViewControllerDelegate> {
    
    SignatureView *sigView;
    UIToolbar *toolbar;
    
    UIImage *currentOriginalImage;
    UIImage *currentEditedImage;
    
    UIImageView *currentImageView;
    
    BOOL isStarting;
    
    id rotationVal;
}

@end

@implementation AdvSignatureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(getImage)];
    UIBarButtonItem *reset = [[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStyleDone target:self action:@selector(resetImage)];
    UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithTitle:@"Camera" style:UIBarButtonItemStyleDone target:self action:@selector(showCamera)];
    UIBarButtonItem *library = [[UIBarButtonItem alloc] initWithTitle:@"Library" style:UIBarButtonItemStyleDone target:self action:@selector(showMedia)];
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(dismissView)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    toolbar = [[UIToolbar alloc] init];
    [toolbar setItems:@[done, flex, camera, flex, library, flex, reset, flex, cancel]];
    
    sigView = [[SignatureView alloc] init];
    self.view = sigView;
    
    [sigView addSubview:toolbar];
    
    isStarting = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        rotationVal = [[UIDevice currentDevice] valueForKey:@"orientation"];
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeRight) forKey:@"orientation"];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [toolbar setFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    
    // Create path.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:TEMP_SIGNATURE];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] && isStarting) {
        currentImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:filePath]];
        CGFloat ratio = currentImageView.frame.size.width / currentImageView.frame.size.height;
        
        CGFloat width = currentImageView.frame.size.width;
        if (width > 200) {
            width = 200;
        }
        
        [currentImageView setFrame:CGRectMake(0, 0, width, width / ratio)];
        [currentImageView setCenter:sigView.center];
        [sigView addSubview:currentImageView];
    }
    
    isStarting = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskLandscapeRight;
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
}

#pragma mark - Reset

- (void)resetImage
{
    [sigView erase];
    [currentImageView removeFromSuperview];
    currentImageView = nil;
    
    // Create path.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:TEMP_SIGNATURE];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
}

#pragma mark - Return image

- (void)dismissView
{
    [_delegate advDidCancelSign:rotationVal];
}

- (void)getImage
{
    if (currentImageView) {
        // Create path.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:TEMP_SIGNATURE];
        
        // Save image.
        [UIImagePNGRepresentation([self imageWithImage:currentImageView.image scaledToSize:currentImageView.frame.size]) writeToFile:filePath atomically:NO];
    } else {
        // Save image to temp path
        [sigView signatureImage:CGPointZero text:@"" fitSignature:GLOBAL.g_fit_signature_to_field];
    }
    
    [_delegate advDidSign:rotationVal];
}

#pragma mark - Image from library
- (void)showMedia
{
    [self startMediaBrowserFromViewController:self usingDelegate:self];
}

- (BOOL) startMediaBrowserFromViewController: (UIViewController*) controller
                               usingDelegate: (id <UIImagePickerControllerDelegate,
                                               UINavigationControllerDelegate>) delegate {
    
    if (([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)
        || (delegate == nil)
        || (controller == nil))
        return NO;
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    
    // Displays saved pictures and movies, if both are available, from the
    // Camera Roll album.
    mediaUI.mediaTypes =
    [UIImagePickerController availableMediaTypesForSourceType:
     UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    mediaUI.allowsEditing = NO;
    
    mediaUI.delegate = delegate;
    
    [controller presentViewController:mediaUI animated:YES completion:nil];
    return YES;
}

#pragma mark - Image from camera

- (void)showCamera
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - ImagePicker Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [self resetImage];
    
    currentOriginalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    currentEditedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    
    [self dismissViewControllerAnimated:YES completion:^{
        ImageCropViewController *vc = [[ImageCropViewController alloc] initWithImage:currentOriginalImage];
        vc.delegate = self;
        vc.blurredBackground = YES;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
        }
        
        [self presentViewController:nav animated:YES completion:nil];
    }];
}

#pragma mark - Image Crop Delegate

- (void)ImageCropViewControllerSuccess:(UIViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage
{
    [self dismissViewControllerAnimated:YES completion:^{
        currentEditedImage = [self changeWhiteColorTransparent:croppedImage];
        currentImageView = [[UIImageView alloc] initWithImage:currentEditedImage];
        CGFloat ratio = currentImageView.frame.size.width / currentImageView.frame.size.height;
        
        CGFloat width = currentImageView.frame.size.width;
        if (width > 200) {
            width = 200;
        }
        
        [currentImageView setFrame:CGRectMake(0, 0, width, width / ratio)];
        [currentImageView setCenter:sigView.center];
        [sigView addSubview:currentImageView];
    }];
}

- (void)ImageCropViewControllerDidCancel:(UIViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Image editing

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)changeWhiteColorTransparent:(UIImage *)image
{
    CGImageRef rawImageRef=image.CGImage;
    
    CGFloat colorMasking[6] = {130, 255, 130, 255, 130, 255}; // RGB -> min e max del range da eliminare (da tarare)
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGImageRef maskedImageRef=CGImageCreateWithMaskingColors(rawImageRef, colorMasking);
    {
        //if in iphone
        CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0.0, image.size.height);
        CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
    }
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, image.size.width, image.size.height), maskedImageRef);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    CGImageRelease(maskedImageRef);
    UIGraphicsEndImageContext();
    return result;
}

@end
