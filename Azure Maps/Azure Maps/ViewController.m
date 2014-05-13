//
//  ViewController.m
//  Azure Maps
//
//  Created by Claus Höfele on 13.05.14.
//  Copyright (c) 2014 Claus Höfele. All rights reserved.
//

#import "ViewController.h"

#import "UserService.h"
#import "MAKRAzureMapsService.h"

#import <MapKit/MapKit.h>

@interface PointAnnotation : MKPointAnnotation
@property (nonatomic) UIImage *image;
@end
@implementation PointAnnotation
@end

@interface ViewController ()<CLLocationManagerDelegate, MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager startUpdatingLocation];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(userSignedIn:) name:MAKRAzureMapsUserSignedInNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(itemsUpdated:) name:MAKRAzureMapsDidUpdateItemsNotification object:nil];
    
    UserService *userService = [UserService sharedService];
    [userService autoLoginWithCompletion:^(MSUser *user, NSError *error) {
        if (error) {
            NSLog(@"Auto login failed");
        } else {
            MAKRAzureMapsService *mapsService = [MAKRAzureMapsService sharedService];
            mapsService.client.currentUser = user;
            
            [NSNotificationCenter.defaultCenter postNotificationName:MAKRAzureMapsUserSignedInNotification object:nil];
            
            NSLog(@"Auto login succeeded");
        }
    }];
}

- (void)userSignedIn:(NSNotification *)notification
{
    [MAKRAzureMapsService.sharedService refreshDataOnSuccess:nil];
}

- (void)itemsUpdated:(NSNotification *)notification
{
    MAKRAzureMapsService *service = MAKRAzureMapsService.sharedService;
    NSArray *items = service.items;
    for (NSDictionary *item in items) {
        NSString *imageURLString = item[MAKRAzureMapsItemKeyImageURL];
        if (imageURLString == nil) {
            continue;
        }
        
        PointAnnotation *annotation = [[PointAnnotation alloc] init];

        double latitude = [item[MAKRAzureMapsItemKeyLatitude] doubleValue];
        double longitude = [item[MAKRAzureMapsItemKeyLongitude] doubleValue];
        annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        annotation.title = item[MAKRAzureMapsItemKeyTitle];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSDictionary *blob;
            
            for (NSDictionary *currentBlob in service.blobs) {
                if ([currentBlob[@"name"] isEqualToString:item[MAKRAzureMapsItemKeyID]]) {
                    blob = currentBlob;
                    break;
                }
            }
            
            NSString *urlString = blob[@"url"];
            NSURL *imageURL = [NSURL URLWithString:urlString];
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
            if (imageURL == nil) {
                NSLog(@"Error loading image");
            } else {
                annotation.image = [UIImage imageWithData:imageData];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.mapView addAnnotation:annotation];
                });
            }
        });
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *annotationView;
    if ([annotation isKindOfClass:PointAnnotation.class]) {
        PointAnnotation *pointAnnotation = (PointAnnotation *)annotation;
        
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"annotation"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:pointAnnotation.image];
        imageView.frame = CGRectMake(0, 0, 44, 44);
        [annotationView addSubview:imageView];
        annotationView.frame = imageView.frame;
    }

    return annotationView;
}

@end
