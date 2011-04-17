//
//  KVGroupedFetchedResultsController.m
//  Flow
//
//  Created by Kyle Van Essen on 11-01-17.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import "KVCompoundFetchedResultsController.h"
#import "KVCoreDataKit.h"

#if TARGET_OS_IPHONE
@interface KVCompoundFetchedResultsController (Private)

-(void)addObject:(id)newObject;
-(void)removeObject:(id)oldObject;
-(void)objectUpdated:(id)object;

-(void)sort;

@end

@implementation KVCompoundFetchedResultsController

@synthesize managedObjectContext;
@synthesize fetchRequests;
@synthesize sortDescriptors;
@synthesize sortedObjects;
@synthesize containedObjects;
@synthesize delegate;

-(id)initWithManagedObjectContext:(NSManagedObjectContext *)newManagedObjectContext
					fetchRequests:(NSArray *)newFetchRequests
				  sortDescriptors:(NSArray *)newSortDescriptors
{
	if ((self = [super init]))
	{
		managedObjectContext = newManagedObjectContext;
		sortDescriptors = [newSortDescriptors copy];
		
		fetchRequests = [newFetchRequests copy];
		[fetchRequests makeObjectsPerformSelector:@selector(setSortDescriptors:) withObject:self.sortDescriptors];
		
		sortedObjects = [[NSMutableArray alloc] init];
	}
	
	return self;
}

-(void)dealloc
{
	managedObjectContext = nil;
	
	[fetchRequests release];
	fetchRequests = nil;
	
	[sortDescriptors release];
	sortDescriptors = nil;
	
	[fetchedResultsControllers release];
	fetchedResultsControllers = nil;
	
	[sortedObjects release];
	sortedObjects = nil;
	
	self.delegate = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Perform Initial Fetch
#pragma mark -

-(void)performFetch
{
	[sortedObjects removeAllObjects];
	
	if (!fetchedResultsControllers)
	{
		NSMutableArray *newFetchedResultsControllers = [[NSMutableArray alloc] init];
		
		for (NSFetchRequest *fetchRequest in self.fetchRequests)
		{		
			NSFetchedResultsController *fetchedResultsController;
			fetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																			managedObjectContext:self.managedObjectContext
																			  sectionNameKeyPath:nil
																					   cacheName:nil] autorelease];
			
			fetchedResultsController.delegate = self;
			[newFetchedResultsControllers addObject:fetchedResultsController];
		}
		
		fetchedResultsControllers = newFetchedResultsControllers;
	}
	
	for (NSFetchedResultsController *fetchedResultsController in fetchedResultsControllers)
	{
		[fetchedResultsController performFetch:nil];
		[sortedObjects addObjectsFromArray:[fetchedResultsController fetchedObjects]];
	}
	
	[self sort];
}

@end

@implementation KVCompoundFetchedResultsController (Private)

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate
#pragma mark -

-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	if ([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)])
		[self.delegate compoundControllerWillChangeContent:self];
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	if ([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)])
		[self.delegate compoundControllerDidChangeContent:self];
}

-(void)controller:(NSFetchedResultsController *)controller
  didChangeObject:(id)object
	  atIndexPath:(NSIndexPath *)indexPath
	forChangeType:(NSFetchedResultsChangeType)type
	 newIndexPath:(NSIndexPath *)newIndexPath
{
	if (type == NSFetchedResultsChangeInsert)
		[self addObject:object];
	
	else if (type == NSFetchedResultsChangeDelete)
		[self removeObject:object];
	
	else if (type == NSFetchedResultsChangeUpdate || type == NSFetchedResultsChangeMove)
		[self objectUpdated:object];
}

-(void)addObject:(id)newObject
{
	if (!newObject)
		return;
	
	[sortedObjects addObject:newObject];
	
	[self sort];
	
	if ([self.delegate respondsToSelector:@selector(compoundController:didChangeObject:atIndex:forChangeType:newIndex:)])
	{
		[self.delegate compoundController:self
						  didChangeObject:newObject
								  atIndex:NSNotFound
							forChangeType:NSFetchedResultsChangeInsert
								 newIndex:[self.sortedObjects indexOfObject:newObject]];
	}
}

-(void)removeObject:(id)oldObject
{
	if (!oldObject)
		return;
	
	NSUInteger oldIndex = [self.sortedObjects indexOfObject:oldObject];
	
	[oldObject retain];
	
	[sortedObjects removeObject:oldObject];
	
	if ([self.delegate respondsToSelector:@selector(compoundController:didChangeObject:atIndex:forChangeType:newIndex:)])
	{
		[self.delegate compoundController:self
						  didChangeObject:oldObject
								  atIndex:oldIndex
							forChangeType:NSFetchedResultsChangeDelete
								 newIndex:NSNotFound];
	}
	
	[oldObject release];
}

-(void)objectUpdated:(id)object
{
	if (!object)
		return;
	
	NSUInteger oldIndex = [self.sortedObjects indexOfObject:object];
	[self sort];
	NSUInteger newIndex = [self.sortedObjects indexOfObject:object];
	
	if ([self.delegate respondsToSelector:@selector(compoundController:didChangeObject:atIndex:forChangeType:newIndex:)])
	{
		if (oldIndex == newIndex)
		{
			[self.delegate compoundController:self
							  didChangeObject:object
									  atIndex:oldIndex
								forChangeType:NSFetchedResultsChangeUpdate
									 newIndex:NSNotFound];
		}
		else
		{
			[self.delegate compoundController:self
							  didChangeObject:object
									  atIndex:oldIndex
								forChangeType:NSFetchedResultsChangeMove
									 newIndex:newIndex];
		}
	}
}

-(void)sort
{
	[sortedObjects sortUsingDescriptors:self.sortDescriptors];
}

@end
#endif

