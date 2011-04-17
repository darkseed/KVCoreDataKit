//
//  KVCoreDataManager.m
//  Flow
//
//  Created by Kyle Van Essen on 11-01-12.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import "KVCoreDataManager.h"
#import "KVCoreDataKit.h"

@interface KVCoreDataManager ()

@property(assign, getter=isSaving, readwrite) BOOL saving;

-(void)_mergeChangesIntoMainContextFromContextDidSaveNotification:(NSNotification *)notification;
-(void)_postObjectsDidUpdateOnBackgroundQueueNotification:(NSSet *)updatedObjects;

@end

@implementation KVCoreDataManager

@synthesize mainManagedObjectContext = _mainManagedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize persistentStore = _persistentStore;
@synthesize saving =_saving;
@synthesize backgroundQueue = _backgroundQueue;

#pragma mark -
#pragma mark Initialzation
#pragma mark -

-(id)initWithPersistentStoreLocation:(NSURL *)URL managedObjectModelName:(NSString *)objectModelName error:(NSError **)error
{
	if ((self = [self init]))
	{
		_backgroundQueue = [[NSOperationQueue alloc] init];
		[_backgroundQueue setMaxConcurrentOperationCount:1];
		
		NSURL *modelURL = [[NSBundle mainBundle] URLForResource:objectModelName withExtension:@"mom"];

		if (modelURL)
			_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
		else
			_managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
		
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
		
		NSError *persistentStoreError = nil;
	   _persistentStore = [[self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
																		configuration:nil
																				  URL:URL
																			   options:nil
																				 error:&persistentStoreError] retain];
		
		if (error)
		{
			*error = persistentStoreError;
			NSAssert(persistentStoreError == nil, ([NSString stringWithFormat:@"%@", persistentStoreError]));
		}
		
		_mainManagedObjectContext = [self newManagedObjectContext];
	}
	
	return self;
}

-(void)dealloc
{
	[_managedObjectModel release];
	[_mainManagedObjectContext release];
	[_persistentStoreCoordinator release];
	[_persistentStore release];
	[_backgroundQueue release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Managed Object Contexts
#pragma mark -

-(NSManagedObjectContext *)newManagedObjectContext
{
	NSManagedObjectContext *newManagedObjectContext = [[NSManagedObjectContext alloc] init];
	[newManagedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
	[newManagedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
	[newManagedObjectContext setUndoManager:nil];
	
	return newManagedObjectContext;
}

-(void)assertManagedObjectContextIsMainManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
	NSAssert((managedObjectContext == _mainManagedObjectContext), @"Managed object context is not the main context.");
}

#pragma mark -
#pragma mark Queuing Operations
#pragma mark -

-(void)addBackgroundOperationWithBlock:(void (^)(NSManagedObjectContext *newManagedObjectContext))block
{	
	[self addBackgroundOperationWithBlock:block mergeCompletionBlock:nil];
}

-(void)addBackgroundOperationWithBlock:(void (^)(NSManagedObjectContext *newManagedObjectContext))block
				  mergeCompletionBlock:(void (^)())completionBlock
{
	NSAssert(block != nil, @"Must provide a background operation block.");
	
	NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSManagedObjectContext *newManagedObjectContext = [self newManagedObjectContext];
		
		if (block)
			block(newManagedObjectContext);
		
		[self saveAndMergeManagedObjectContext:newManagedObjectContext error:NULL];
		
		if (completionBlock)
			completionBlock();
		
		[newManagedObjectContext release];
		[pool release];
	}];
	
	[_backgroundQueue addOperation:operation];
}

#pragma mark -
#pragma mark Saving Managed Object Contexts
#pragma mark -

-(void)saveMainManagedObjectContext:(NSError **)saveError
{
	NSAssert([NSThread isMainThread], @"Cannot save main managed object context off main thread.");
	
	self.saving = YES;
	[self.mainManagedObjectContext save:saveError];
	self.saving = NO;
}

-(void)saveAndMergeManagedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)saveError
{	
	BOOL isSameCoordinator = ([managedObjectContext persistentStoreCoordinator] == [self.mainManagedObjectContext persistentStoreCoordinator]);
	NSAssert(isSameCoordinator, @"Managed object context does not have the same persistent store coordinator as the main context.");
	
	if (managedObjectContext != self.mainManagedObjectContext)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(managedObjectContextDidSaveNotification:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:managedObjectContext];
	}
	
	self.saving = YES;
	[managedObjectContext save:saveError];
	self.saving = NO;
	
	if (managedObjectContext != self.mainManagedObjectContext)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSManagedObjectContextDidSaveNotification
													  object:managedObjectContext];
	}
}

#pragma mark -
#pragma mark Notifications
#pragma mark -

-(void)managedObjectContextDidSaveNotification:(NSNotification *)notification
{		
	if (dispatch_get_current_queue() == dispatch_get_main_queue())
		[self _mergeChangesIntoMainContextFromContextDidSaveNotification:notification];
	else
	{
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self _mergeChangesIntoMainContextFromContextDidSaveNotification:notification];
		});
	}
}

-(void)_mergeChangesIntoMainContextFromContextDidSaveNotification:(NSNotification *)notification
{
	[self.mainManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
	[self.mainManagedObjectContext processPendingChanges];
	
	[self _postObjectsDidUpdateOnBackgroundQueueNotification:[[notification userInfo] objectForKey:NSUpdatedObjectsKey]];
}

-(void)_postObjectsDidUpdateOnBackgroundQueueNotification:(NSSet *)updatedObjects
{
	if (![updatedObjects count])
		return;
	
	NSSet *objectIDs = [updatedObjects valueForKey:@"objectID"];
	NSMutableSet *objects = [[NSMutableSet alloc] initWithCapacity:[objectIDs count]];
	
	for (NSManagedObjectID *objectID in objectIDs)
		[objects addObject:[self.mainManagedObjectContext objectWithID:objectID]];
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:objects forKey:NSUpdatedObjectsKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:KVCoreDataManagerObjectsUpdatedOnBackgroundQueueNotification
														object:self.mainManagedObjectContext
													  userInfo:userInfo];
	
	[objects release];
}

@end
