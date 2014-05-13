//
//  MAKRAzureMapsService.m
//  AzureMaps
//
//  Created by Alexander Repty on 09.05.14.
//  Copyright (c) 2014 alexrepty. All rights reserved.
//

#import "MAKRAzureMapsService.h"

NSString *const MAKRAzureMapsItemKeyID = @"id";
NSString *const MAKRAzureMapsItemKeyUserID = @"MAKRAzureMapsItemKeyUserID";
NSString *const MAKRAzureMapsItemKeyLatitude = @"MAKRAzureMapsItemKeyLatitude";
NSString *const MAKRAzureMapsItemKeyLongitude = @"MAKRAzureMapsItemKeyLongitude";
NSString *const MAKRAzureMapsItemKeyTitle = @"MAKRAzureMapsItemKeyTitle";
NSString *const MAKRAzureMapsItemKeyImageURL = @"MAKRAzureMapsItemKeyImageURL";

NSString *const MAKRAzureMapsServiceBlobContainer = @"azuremaps";

NSString *const MAKRAzureMapsDidUpdateItemsNotification = @"MAKRAzureMapsDidUpdateItemsNotification";
NSString *const MAKRAzureMapsUserSignedInNotification = @"MAKRAzureMapsUserSignedInNotification";

#define URL_STRING @"https://azure-maps.azure-mobile.net/"
#define APPLICATION_KEY @"GRUVwdzPgkUVneHJRJntAHFoUmEAbe95"

@interface MAKRAzureMapsService ()

@property(nonatomic,strong) MSTable *itemTable;
@property(nonatomic,strong) MSTable *containersTable;
@property(nonatomic,strong) MSTable *blobsTable;
@property(nonatomic) NSInteger busyCount;

@end

@implementation MAKRAzureMapsService

+ (instancetype)sharedService {
    static MAKRAzureMapsService* service;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[MAKRAzureMapsService alloc] init];
    });
    
    return service;
}

- (id)init {
	self = [super init];
	if (self) {
		// Initialize the Mobile Service client with your URL and key
		MSClient *newClient = [MSClient clientWithApplicationURLString:URL_STRING
														applicationKey:APPLICATION_KEY];
		
		// Add a Mobile Service filter to enable the busy indicator
		self.client = [newClient clientWithFilter:self];
		
		// Create an MSTable instance to allow us to work with the TodoItem table
		self.itemTable = [self.client tableWithName:@"Item"];
		
		self.containersTable = [self.client tableWithName:@"BlobContainers"];
		self.blobsTable = [self.client tableWithName:@"BlobBlobs"];
		
		self.items = [[NSMutableArray alloc] init];
		self.busyCount = 0;
	}
    return self;
}

- (void)refreshDataOnSuccess:(MAKRCompletionBlock)completion {
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"MAKRAzureMapsItemKeyImageURL != ''"];
	
    // Query the TodoItem table and update the items property with the results from the service
    [self.itemTable readWithPredicate:predicate completion:^(NSArray *results, NSInteger totalCount, NSError *error) {
		NSLog(@"Read items: %d entries.", results.count);
		[self logErrorIfNotNil:error];
		
		self.items = [results mutableCopy];
		
		// Let the caller know that we finished
		if (completion) {
			completion();
		}
		
		[self refreshBlobsOnSuccess:MAKRAzureMapsServiceBlobContainer withCompletion:^() {
			[[NSNotificationCenter defaultCenter] postNotificationName:MAKRAzureMapsDidUpdateItemsNotification object:nil];
		}];
	}];
}

-(void)addItem:(NSDictionary *)item completion:(MAKRCompletionWithIndexBlock)completion {
    // Insert the item into the Item table and add to the items array on completion
    [self.itemTable insert:item completion:^(NSDictionary *result, NSError *error) {
		[self logErrorIfNotNil:error];
		
		NSUInteger index = [self.items count];
		[self.items insertObject:result atIndex:index];
		
		// Let the caller know that we finished
		completion(index);
	}];
}

- (void)updateItem:(NSDictionary *)item atIndex:(NSInteger)index completion:(MAKRCompletionBlock)completion {
	NSParameterAssert(item);
	
    // Update the item in the TodoItem table and remove from the items array on completion
    [self.itemTable update:item completion:^(NSDictionary *item, NSError *error) {
        [self logErrorIfNotNil:error];
        
        [self refreshDataOnSuccess:nil];
        
        // Let the caller know that we have finished
        completion(index);
    }];
}

- (void)busy:(BOOL)busy {
    // assumes always executes on UI thread
    if (busy) {
        if (self.busyCount == 0 && self.busyUpdate != nil) {
            self.busyUpdate(YES);
        }
        self.busyCount ++;
    } else {
        if (self.busyCount == 1 && self.busyUpdate != nil) {
            self.busyUpdate(FALSE);
        }
        self.busyCount--;
    }
}

- (void)logErrorIfNotNil:(NSError *) error {
    if (error) {
        NSLog(@"ERROR %@", error);
    }
}

- (void)refreshContainersOnSuccess:(MAKRCompletionBlock)completion {
    [self.containersTable readWithCompletion:^(NSArray *results, NSInteger totalCount, NSError *error) {
        [self logErrorIfNotNil:error];
        
        self.containers = [results mutableCopy];
        
        // Let the caller know that we finished
        completion();
    }];
}

- (void)createContainer:(NSString *)containerName withPublicSetting:(BOOL)isPublic withCompletion:(MAKRCompletionBlock)completion {
    NSDictionary *item = @{ @"containerName" : containerName };
    
    NSDictionary *params = @{ @"isPublic" : [NSNumber numberWithBool:isPublic] };
    
    [self.containersTable insert:item parameters:params completion:^(NSDictionary *result, NSError *error) {
        
        [self logErrorIfNotNil:error];
        
        NSLog(@"Results: %@", result);
        
        // Let the caller know that we finished
        completion();
    }];
}

- (void)deleteContainer:(NSString *)containerName withCompletion:(MAKRCompletionBlock)completion {
    NSDictionary *idItem = @{ @"id" :@1 };
    NSDictionary *params = @{ @"containerName" : containerName };
    
    [self.containersTable delete:idItem parameters:params completion:^(NSNumber *itemId, NSError *error) {
        [self logErrorIfNotNil:error];
        
        NSLog(@"Results: %@", itemId);
        
        // Let the caller know that we finished
        completion();
    }];
}

- (void)refreshBlobsOnSuccess:(NSString *)containerName withCompletion:(MAKRCompletionBlock)completion {
    NSString *queryString = [NSString stringWithFormat:@"container=%@", containerName];
    
    [self.blobsTable readWithQueryString:queryString completion:^(NSArray *results, NSInteger totalCount, NSError *error) {
        
        [self logErrorIfNotNil:error];
        
        self.blobs = [results mutableCopy];
        
        // Let the caller know that we finished
        completion();
    }];
}

- (void)deleteBlob:(NSString *)blobName fromContainer:(NSString *)containerName withCompletion:(MAKRCompletionBlock)completion {
    NSDictionary *idItem = @{ @"id" :@1 };
    NSDictionary *params = @{ @"containerName" : containerName, @"blobName" : blobName };
    
    [self.blobsTable delete:idItem parameters:params completion:^(NSNumber *itemId, NSError *error) {
        [self logErrorIfNotNil:error];
        
        NSLog(@"Results: %@", itemId);
        
        // Let the caller know that we finished
        completion();
    }];
}

- (void)sasURLForNewBlob:(NSString *)blobName forContainer:(NSString *)containerName withCompletion:(MAKRCompletionWithSASBlock)completion {
    NSDictionary *item = @{  };
    NSDictionary *params = @{ @"containerName" : containerName, @"blobName" : blobName };
    
    [self.blobsTable insert:item parameters:params completion:^(NSDictionary *item, NSError *error) {
        NSLog(@"Item: %@", item);
        
        completion([item objectForKey:@"sasUrl"]);
    }];
}

#pragma mark -
#pragma mark MSFilter Methods

- (void)handleRequest:(NSURLRequest *)request
                 next:(MSFilterNextBlock)next
             response:(MSFilterResponseBlock)response {
    // A wrapped response block that decrements the busy counter
    MSFilterResponseBlock wrappedResponse = ^(NSHTTPURLResponse *innerResponse, NSData *data, NSError *error) {
        [self busy:NO];
        response(innerResponse, data, error);
    };
    
    // Increment the busy counter before sending the request
    [self busy:YES];
    next(request, wrappedResponse);
}

@end