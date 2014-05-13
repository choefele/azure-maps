//
//  AddItemViewController.m
//  Azure Maps
//
//  Created by Claus Höfele on 13.05.14.
//  Copyright (c) 2014 Claus Höfele. All rights reserved.
//

#import "AddItemViewController.h"

#import "MAKRAzureMapsService.h"

#import <CoreLocation/CoreLocation.h>

@interface AddItemViewController ()<UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic) NSInteger cameraButtonIndex;
@property (nonatomic) NSInteger photoLibraryIndex;
@property (nonatomic) NSInteger photoAlbumsIndex;

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic, copy) NSDictionary *item;
@property (nonatomic) NSInteger itemIndex;

@end

@implementation AddItemViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager startUpdatingLocation];
    
    MAKRAzureMapsService *mapsService = [MAKRAzureMapsService sharedService];
    [mapsService refreshContainersOnSuccess:^{
        if (mapsService.containers.count == 0) {
            [mapsService createContainer:MAKRAzureMapsServiceBlobContainer withPublicSetting:YES withCompletion:nil];
        }
    }];
}

- (IBAction)chooseImage
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:nil];
    
    self.cameraButtonIndex = NSNotFound;
    self.photoLibraryIndex = NSNotFound;
    self.photoAlbumsIndex = NSNotFound;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.cameraButtonIndex = [actionSheet addButtonWithTitle:@"Camera"];
    }

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.photoLibraryIndex = [actionSheet addButtonWithTitle:@"Photo Library"];
    }

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        self.photoAlbumsIndex = [actionSheet addButtonWithTitle:@"Photo Album"];
    }
    
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        UIImagePickerControllerSourceType sourceType;
        if (buttonIndex == self.cameraButtonIndex) {
            sourceType = UIImagePickerControllerSourceTypeCamera;
        } else if (buttonIndex == self.photoLibraryIndex) {
            sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        } else if (buttonIndex == self.photoAlbumsIndex) {
            sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        }
        
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.sourceType = sourceType;
        imagePickerController.delegate = self;
        [self presentViewController:imagePickerController animated:YES completion:NULL];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    self.imageView.image = image;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)uploadImage
{
    NSString *title = self.titleTextField.text;
    UIImage *image = self.imageView.image;

    if (title.length > 0 && image) {
        MAKRAzureMapsService *mapsService = [MAKRAzureMapsService sharedService];
        MSUser *user = mapsService.client.currentUser;

        CLLocation *location = self.locationManager.location;
        NSDictionary *item = @{MAKRAzureMapsItemKeyUserID: user.userId,
                               MAKRAzureMapsItemKeyTitle: title,
                               MAKRAzureMapsItemKeyLatitude: @(location.coordinate.latitude),
                               MAKRAzureMapsItemKeyLongitude: @(location.coordinate.longitude)};
        [mapsService addItem:item completion:^(NSUInteger index) {
            self.itemIndex = index;
            self.item = MAKRAzureMapsService.sharedService.items[index];
            
            [self startUploadingImageForItem:self.item];
        }];
    }
}

- (void)startUploadingImageForItem:(NSDictionary *)item
{
    MAKRAzureMapsService *mapsService = [MAKRAzureMapsService sharedService];
    [mapsService sasURLForNewBlob:item[MAKRAzureMapsItemKeyID] forContainer:MAKRAzureMapsServiceBlobContainer withCompletion:^(NSString *sasUrl) {
        NSData *imageData = UIImageJPEGRepresentation(self.imageView.image, 0.9);
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:sasUrl]];
        request.HTTPMethod = @"PUT";
        [request addValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
        request.HTTPBody = imageData;
        
        [NSURLConnection sendAsynchronousRequest:request queue:NSOperationQueue.mainQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (connectionError) {
                NSLog(@"%@", connectionError);
            } else {
                NSMutableDictionary *mutableItem = [NSMutableDictionary dictionaryWithDictionary:self.item];
                mutableItem[MAKRAzureMapsItemKeyImageURL] = sasUrl;
                self.item = mutableItem;
                
                [mapsService updateItem:self.item atIndex:self.itemIndex completion:^{
                    [self.navigationController popToRootViewControllerAnimated:YES];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshBlobd" object:mutableItem];
                }];
            }
        }];
    }];
}

@end
