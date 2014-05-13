//
//  MAKRAzureMapsService.h
//  AzureMaps
//
//  Created by Alexander Repty on 09.05.14.
//  Copyright (c) 2014 alexrepty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WindowsAzureMobileServices/WindowsAzureMobileServices.h>

typedef void (^MAKRCompletionBlock) ();
typedef void (^MAKRCompletionWithIndexBlock) (NSUInteger index);
typedef void (^MAKRCompletionWithSASBlock) (NSString *sasUrl);
typedef void (^BusyUpdateBlock) (BOOL busy);

extern NSString *const MAKRAzureMapsItemKeyID;
extern NSString *const MAKRAzureMapsItemKeyUserID;
extern NSString *const MAKRAzureMapsItemKeyLatitude;
extern NSString *const MAKRAzureMapsItemKeyLongitude;
extern NSString *const MAKRAzureMapsItemKeyTitle;
extern NSString *const MAKRAzureMapsItemKeyImageURL;

extern NSString *const MAKRAzureMapsServiceBlobContainer;

extern NSString *const MAKRAzureMapsDidUpdateItemsNotification;
extern NSString *const MAKRAzureMapsUserSignedInNotification;

@interface MAKRAzureMapsService : NSObject <MSFilter>

@property(nonatomic,strong) NSMutableArray *items;
@property(nonatomic,strong) NSArray *containers;
@property(nonatomic,strong) NSArray *blobs;
@property(nonatomic,strong) MSClient *client;
@property(nonatomic,copy) BusyUpdateBlock busyUpdate;

+ (instancetype)sharedService;

- (void)refreshDataOnSuccess:(MAKRCompletionBlock)completion;

- (void)addItem:(NSDictionary *)item
     completion:(MAKRCompletionWithIndexBlock)completion;

- (void)updateItem:(NSDictionary *)item
		   atIndex:(NSInteger)index
		completion:(MAKRCompletionBlock)completion;

- (void)handleRequest:(NSURLRequest *)request
                 next:(MSFilterNextBlock)next
             response:(MSFilterResponseBlock)response;

- (void)refreshContainersOnSuccess:(MAKRCompletionBlock)completion;

- (void)createContainer:(NSString *)containerName
	  withPublicSetting:(BOOL)isPublic
		 withCompletion:(MAKRCompletionBlock)completion;

- (void)deleteContainer:(NSString *)containerName
		 withCompletion:(MAKRCompletionBlock)completion;

- (void)refreshBlobsOnSuccess:(NSString *)containerName
			   withCompletion:(MAKRCompletionBlock)completion;

- (void)deleteBlob:(NSString *)blobName
	 fromContainer:(NSString *)containerName
	withCompletion:(MAKRCompletionBlock)completion;

- (void)sasURLForNewBlob:(NSString *)blobName
			forContainer:(NSString *)containerName
		  withCompletion:(MAKRCompletionWithSASBlock)completion;

@end