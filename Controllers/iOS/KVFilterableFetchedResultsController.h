//
//  FLTaskListResultsController.h
//  Flow
//
//  Created by Kyle Van Essen on 11-01-19.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import <CoreData/CoreData.h>

#if TARGET_OS_IPHONE
static NSString *const FLAllScopesName = @"All";
static NSString *const FLAllScopesKey = @"all";

@interface KVFilterableFetchedResultsController : NSObject {
	
}

-(id)initWithFetchedResultsController:(NSFetchedResultsController *)resultsController searchScopes:(NSDictionary *)searchScopes;

@property(nonatomic, copy) NSString *searchString;
@property(nonatomic, copy) NSString *selectedScope;

@property(nonatomic, copy, readonly) NSDictionary *searchScopes;
@property(nonatomic, readonly) NSArray *scopeNames;

@property(nonatomic, retain, readonly) NSFetchedResultsController *fetchedResultsController;

@end
#endif
