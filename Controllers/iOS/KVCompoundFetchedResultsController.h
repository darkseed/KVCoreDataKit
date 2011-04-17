//
//  KVGroupedFetchedResultsController.h
//  Flow
//
//  Created by Kyle Van Essen on 11-01-17.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import <CoreData/CoreData.h>

#if TARGET_OS_IPHONE
@protocol KVCompoundFetchedResultsControllerDelegate;

@interface KVCompoundFetchedResultsController : NSObject <NSFetchedResultsControllerDelegate> {

	NSManagedObjectContext *managedObjectContext;
	NSArray * fetchRequests;
	NSArray *sortDescriptors;
	NSArray *fetchedResultsControllers;
	NSMutableArray *sortedObjects;
	
	id <KVCompoundFetchedResultsControllerDelegate> delegate;
}

-(id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
					fetchRequests:(NSArray *)newFetchRequests
				  sortDescriptors:(NSArray *)newSortDescriptors;

-(void)performFetch;

@property(nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, readonly) NSArray * fetchRequests;
@property(nonatomic, readonly) NSArray *sortDescriptors;
@property(nonatomic, readonly) NSArray *sortedObjects;
@property(nonatomic, readonly) NSSet *containedObjects;
@property(nonatomic, assign) id <KVCompoundFetchedResultsControllerDelegate> delegate;

@end

@protocol KVCompoundFetchedResultsControllerDelegate <NSObject>

@optional
-(void)compoundControllerWillChangeContent:(KVCompoundFetchedResultsController *)controller;
-(void)compoundControllerDidChangeContent:(KVCompoundFetchedResultsController *)controller;

-(void)compoundController:(KVCompoundFetchedResultsController *)controller
		  didChangeObject:(id)anObject
				  atIndex:(NSUInteger)index
			forChangeType:(NSFetchedResultsChangeType)type
				 newIndex:(NSUInteger)newIndex;

@end
#endif

