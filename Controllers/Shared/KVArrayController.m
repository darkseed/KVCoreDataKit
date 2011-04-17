//
//  KVFetchedResultsController.m
//  FlowKit
//
//  Created by Kyle Van Essen on 11-04-15.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import "KVArrayController.h"
#import "KVCoreDataKit.h"

@interface KVArrayController ()

@property(retain, readwrite) NSArray *fetchRequests;
@property(retain, readwrite) NSArray *sortDescriptors;
@property(assign, readwrite) NSManagedObjectContext *managedObjectContext;

@property(retain, readwrite) NSArray *sortedObjects;
@property(retain, readwrite) NSSet *fetchedObjects;

@property(retain, readwrite) NSDictionary *fetchRequestsByEntityName;

-(void)processInsertedObjects:(NSSet *)insertedObjects
			   updatedObjects:(NSSet *)updatedObjects
			   deletedObjects:(NSSet *)deletedObjects;

-(NSMutableArray *)newPassingObjectsFromInsertedObjects:(NSSet *)insertedObjects;
-(NSMutableArray *)newContainedObjectsFromDeletedObjects:(NSSet *)deletedObjects;
-(NSMutableArray *)newContainedObjectsFromUpdatedObjects:(NSSet *)updatedObjects;

-(void)didInsertObject:(id)object;
-(void)didRemoveObject:(id)object atIndex:(NSUInteger)index;
-(void)didUpdateObject:(id)object oldIndex:(NSUInteger)oldIndex newIndex:(NSUInteger)newIndex;

-(void)primitiveAddObject:(id)object;
-(void)primitiveRemoveObject:(id)object;

-(void)sort;

-(NSFetchRequest *)fetchRequestForEntity:(NSEntityDescription *)entity;

@end

@implementation KVArrayController

@synthesize fetchRequests = _fetchRequests;
@synthesize sortDescriptors = _sortDescriptors;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize sortedObjects = _sortedObjects;
@synthesize fetchedObjects = _fetchedObjects;
@synthesize delegate = _delegate;
@synthesize fetchRequestsByEntityName = _fetchRequestsByEntityName;

#pragma mark -
#pragma mark Initialization
#pragma mark -

-(id)initWithFetchRequests:(NSArray *)fetchRequests
		   sortDescriptors:(NSArray *)sortDescriptors
	  managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
	if ((self = [super init]))
	{
		NSAssert([fetchRequests count] > 0, @"Must pass in a non-empty array of NSFetchRequests.");
		NSAssert([sortDescriptors count] > 0, @"Must pass in a non-empty array of NSSortDescriptors.");
		NSAssert(managedObjectContext != nil, @"Must supply a NSManagedObjectContext for fetching objects.");
		
		self.fetchRequests = [NSArray arrayWithArray:fetchRequests];
		self.sortDescriptors = [NSArray arrayWithArray:sortDescriptors];
		
		self.fetchRequestsByEntityName = [NSDictionary dictionaryWithObjects:self.fetchRequests
																	 forKeys:[self.fetchRequests valueForKeyPath:@"entity.name"]];
		
		self.managedObjectContext = managedObjectContext;
	}
	
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_fetchRequests release];
	[_sortDescriptors release];
	
	[_sortedObjects release];
	[_fetchedObjects release];
	
	[_fetchRequestsByEntityName release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Perform Fetch
#pragma mark -

-(BOOL)performFetch:(NSArray **)errors
{	
	NSMutableArray *fetchErrors = [NSMutableArray array];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(managedObjectContextObjectsDidChangeNotification:)
												 name:NSManagedObjectContextObjectsDidChangeNotification
											   object:self.managedObjectContext];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(managedObjectContextDidSaveNotification:)
												 name:NSManagedObjectContextDidSaveNotification
											   object:nil];
	
	self.fetchedObjects = [NSMutableSet set];
	self.sortedObjects = [NSMutableArray array];
	
	for (NSFetchRequest *fetchRequest in self.fetchRequests)
	{
		NSError *fetchError = nil;
		NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
		
		if (fetchedObjects)
		{
			[_sortedObjects addObjectsFromArray:fetchedObjects];
			[_fetchedObjects addObjectsFromArray:fetchedObjects];
		}
		
		if (fetchError)
			[fetchErrors addObject:fetchError];
	}
	
	[self sort];
	
	if ([fetchErrors count])
	{
		self.fetchedObjects = nil;
		self.sortedObjects = nil;
		*errors = fetchErrors;
	}
	
	return [fetchErrors count] == 0;
}

#pragma mark -
#pragma mark Querying
#pragma mark -

-(id)objectAtIndex:(NSUInteger)index
{
	return [self.sortedObjects objectAtIndex:index];
}

-(NSUInteger)indexOfObject:(id)object
{
	return [self.sortedObjects indexOfObject:object];
}

#pragma mark -
#pragma mark NSManagedObjectContext Notifications
#pragma mark -

-(void)managedObjectContextObjectsDidChangeNotification:(NSNotification *)notification
{
	if ([notification object] != self.managedObjectContext)
		return;
	
	NSSet *insertedObjects = [[notification userInfo] objectForKey:NSInsertedObjectsKey];
	NSSet *updatedObjects = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
	NSSet *deletedObjects = [[notification userInfo] objectForKey:NSDeletedObjectsKey];
	
	[self processInsertedObjects:insertedObjects updatedObjects:updatedObjects deletedObjects:deletedObjects];
}

-(void)managedObjectContextDidSaveNotification:(NSNotification *)notification
{
	NSManagedObjectContext *otherManagedObjectContext = [notification object];
	
	if ([otherManagedObjectContext persistentStoreCoordinator] != [self.managedObjectContext persistentStoreCoordinator])
		return;
	
	if (otherManagedObjectContext == self.managedObjectContext)
		return;
	
	NSSet *separateContextUpdatedObjects = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
	
	NSArray *updatedObjects = [self.managedObjectContext objectsFromSeparateManagedObjectContextObjects:separateContextUpdatedObjects];
	[self processInsertedObjects:nil updatedObjects:[NSSet setWithArray:updatedObjects] deletedObjects:nil];
}

#pragma mark -
#pragma mark Change Processing
#pragma mark -

static NSString *const KVObjectKey = @"KVObjectKey";
static NSString *const KVObjectOldIndexKey = @"KVObjectOldIndexKey";
static NSString *const KVObjectNewIndexKey = @"KVObjectNewIndexKey";

-(void)processInsertedObjects:(NSSet *)insertedObjects
			   updatedObjects:(NSSet *)updatedObjects
			   deletedObjects:(NSSet *)deletedObjects
{	
	NSMutableArray *passingInsertedObjects = [self newPassingObjectsFromInsertedObjects:insertedObjects];
	NSMutableArray *containedDeletedObjects = [self newContainedObjectsFromDeletedObjects:deletedObjects];
	NSMutableArray *containedUpdatedObjects = [self newContainedObjectsFromUpdatedObjects:updatedObjects];
	
	BOOL willUpdate = ([passingInsertedObjects count] || [containedDeletedObjects count] || [containedUpdatedObjects count]);
	
	if (willUpdate && [self.delegate respondsToSelector:@selector(arrayControllerWillChangeContent:)])
		[self.delegate arrayControllerWillChangeContent:self];
	
	if ([containedUpdatedObjects count])
	{
		NSMutableArray *originalSortedObjects = [[NSMutableArray alloc] initWithArray:self.sortedObjects];
		NSMutableArray *containedUpdatedObjectDictionaries = [[NSMutableArray alloc] init];
		
		[self sort];
		
		for (NSManagedObject *object in containedUpdatedObjects)
		{
			NSUInteger oldIndex = [originalSortedObjects indexOfObject:object];
			NSUInteger newIndex = [self.sortedObjects indexOfObject:object];
			
			NSDictionary *objectDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
																				  object,
																				  [NSNumber numberWithInteger:oldIndex],
																				  [NSNumber numberWithInteger:newIndex],
																				  nil]
																		 forKeys:[NSArray arrayWithObjects:
																				  KVObjectKey,
																				  KVObjectOldIndexKey,
																				  KVObjectNewIndexKey,
																				  nil]];
			
			[containedUpdatedObjectDictionaries addObject:objectDictionary];
			
			[originalSortedObjects moveObjectAtIndex:oldIndex toIndex:newIndex];
		}
		
		for (NSDictionary *objectDictionary in containedUpdatedObjectDictionaries)
		{
			id object = [objectDictionary objectForKey:KVObjectKey];
			NSUInteger oldIndex = [[objectDictionary objectForKey:KVObjectOldIndexKey] integerValue];
			NSUInteger newIndex = [[objectDictionary objectForKey:KVObjectNewIndexKey] integerValue];
			
			[self didUpdateObject:object oldIndex:oldIndex newIndex:newIndex];
		}
		
		[originalSortedObjects release];
		[containedUpdatedObjectDictionaries release];
	}
	
	if ([passingInsertedObjects count])
	{
		for (NSManagedObject *object in passingInsertedObjects)
			[self primitiveAddObject:object];
		
		[self sort];
		
		for (NSManagedObject *object in passingInsertedObjects)
			[self didInsertObject:object];
	}
	
	if ([containedDeletedObjects count])
	{
		for (NSManagedObject *object in containedDeletedObjects)
		{
			NSUInteger oldIndex = [self.sortedObjects indexOfObject:object];
			[object retain];
			
			[self primitiveRemoveObject:object];
			
			[self didRemoveObject:object atIndex:oldIndex];
			[object release];
		}
	}
	
	[passingInsertedObjects release];
	[containedDeletedObjects release];
	[containedUpdatedObjects release];
	
	if (willUpdate && [self.delegate respondsToSelector:@selector(arrayControllerDidChangeContent:)])
		[self.delegate arrayControllerDidChangeContent:self];
}

-(NSMutableArray *)newPassingObjectsFromInsertedObjects:(NSSet *)insertedObjects
{
	if (![insertedObjects count])
		return nil;
	
	NSMutableArray *passingInsertedObjects = [[NSMutableArray alloc] init];
	
	for (NSManagedObject *object in insertedObjects)
	{
		NSFetchRequest *fetchRequest = [self fetchRequestForEntity:[object entity]];
		
		if (!fetchRequest)
			continue;
		
		if ([[fetchRequest predicate] evaluateWithObject:object])
			[passingInsertedObjects addObject:object];
	}
	
	[passingInsertedObjects sortUsingDescriptors:self.sortDescriptors];
	
	return passingInsertedObjects;
}

-(NSMutableArray *)newContainedObjectsFromDeletedObjects:(NSSet *)deletedObjects
{
	if (![deletedObjects count])
		return nil;
	
	NSMutableArray *containedDeletedObjects = [[NSMutableArray alloc] init];
	
	for (NSManagedObject *object in deletedObjects)
	{
		if ([self.fetchedObjects containsObject:object])
			[containedDeletedObjects addObject:object];
	}
	
	[containedDeletedObjects sortUsingDescriptors:self.sortDescriptors];
	
	return containedDeletedObjects;
}

-(NSMutableArray *)newContainedObjectsFromUpdatedObjects:(NSSet *)updatedObjects
{
	if (![updatedObjects count])
		return nil;
	
	NSMutableArray *containedUpdatedObjects = [[NSMutableArray alloc] init];
	
	for (NSManagedObject *object in updatedObjects)
	{
		if ([self.fetchedObjects containsObject:object])
			[containedUpdatedObjects addObject:object];
	}
	
	[containedUpdatedObjects sortUsingDescriptors:self.sortDescriptors];
	
	return containedUpdatedObjects;
}

#pragma mark -
#pragma mark Inserting / Deleting
#pragma mark -

-(void)didInsertObject:(id)object
{
	if ([self.delegate respondsToSelector:@selector(arrayController:didChangeObject:atIndex:forChangeType:newIndex:)])
	{
		[self.delegate arrayController:self
					   didChangeObject:object
							   atIndex:NSNotFound
						 forChangeType:KVArrayControllerChangeInsert
							  newIndex:[self.sortedObjects indexOfObject:object]];
	}
}

-(void)didRemoveObject:(id)object atIndex:(NSUInteger)index
{
	if ([self.delegate respondsToSelector:@selector(arrayController:didChangeObject:atIndex:forChangeType:newIndex:)])
	{
		[self.delegate arrayController:self
					   didChangeObject:object
							   atIndex:index
						 forChangeType:KVArrayControllerChangeDelete
							  newIndex:NSNotFound];
	}
}

-(void)didUpdateObject:(id)object oldIndex:(NSUInteger)oldIndex newIndex:(NSUInteger)newIndex
{
	if ([self.delegate respondsToSelector:@selector(arrayController:didChangeObject:atIndex:forChangeType:newIndex:)])
	{
		if (newIndex == oldIndex)
		{
			[self.delegate arrayController:self
						   didChangeObject:object
								   atIndex:newIndex
							 forChangeType:KVArrayControllerChangeUpdate
								  newIndex:NSNotFound];
		}
		else
		{
			[self.delegate arrayController:self
						   didChangeObject:object
								   atIndex:oldIndex
							 forChangeType:KVArrayControllerChangeMove
								  newIndex:newIndex];
		}
	}
}

-(void)primitiveAddObject:(id)object
{
	[_sortedObjects addObject:object];
	[_fetchedObjects addObject:object];
}

-(void)primitiveRemoveObject:(id)object
{
	[_sortedObjects removeObject:object];
	[_fetchedObjects removeObject:object];
}

-(void)sort
{
	[_sortedObjects sortUsingDescriptors:self.sortDescriptors];
}

-(NSFetchRequest *)fetchRequestForEntity:(NSEntityDescription *)entity
{
	return [self.fetchRequestsByEntityName objectForKey:[entity name]];
}

@end
