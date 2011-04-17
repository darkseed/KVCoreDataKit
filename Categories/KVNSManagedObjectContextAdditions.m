//
//  NSManagedObjectContextAdditions.m
//  Flow
//
//  Created by Kyle Van Essen on 11-01-12.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import "KVNSManagedObjectContextAdditions.h"

@implementation NSManagedObjectContext (KVCoreDataKitAdditions)

#pragma mark -
#pragma mark Entities
#pragma mark -

-(NSEntityDescription *)entityForClass:(Class)className
{
	return [self entityWithName:NSStringFromClass(className)];
}

-(NSEntityDescription *)entityWithName:(NSString *)name
{
	return [NSEntityDescription entityForName:name inManagedObjectContext:self];
}

#pragma mark -
#pragma mark Fetch Requests
#pragma mark -

-(NSFetchRequest *)fetchRequestWithClass:(Class)className
{
	return [self fetchRequestForEntityWithName:NSStringFromClass(className)];
}

-(NSFetchRequest *)fetchRequestForEntityWithName:(NSString *)entityName
{
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	[fetchRequest setEntity:[self entityWithName:entityName]];
	
	return fetchRequest;
}

#pragma mark -
#pragma mark Fetching
#pragma mark -

-(NSArray *)executeFetchWithEntity:(NSEntityDescription *)entity
						 predicate:(NSPredicate *)predicate
				   sortDescriptors:(NSArray *)sortDescriptors
							 error:(NSError **)error
{
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:predicate];
	[fetchRequest setSortDescriptors:sortDescriptors];

	return [self executeFetchRequest:fetchRequest error:error];
}

-(void)executeFetchRequest:(NSFetchRequest *)request completionHandler:(void (^)(NSArray *objects, NSError *error))completionHandler
{
	NSAssert(request != nil, @"Must provide a fetch request.");
	NSAssert(completionHandler != nil, @"Must provide a completion handler");
	
	dispatch_queue_t currentQueue = dispatch_get_current_queue();
	NSPersistentStoreCoordinator *persistentStoreCoordinator = [self persistentStoreCoordinator];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
		NSManagedObjectContext *newManagedObjectContext = [[NSManagedObjectContext alloc] init];
		[newManagedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
		
		NSError *fetchError = nil;
		NSArray *fetchedObjects = [newManagedObjectContext executeFetchRequest:request error:&fetchError];
	
		dispatch_sync(currentQueue, ^{
			completionHandler([self objectsFromSeparateManagedObjectContextObjects:fetchedObjects], fetchError);
		});
		
		[newManagedObjectContext release];
		
	});
}

#pragma mark -
#pragma mark Context Object Conversion
#pragma mark -

-(NSArray *)objectsFromSeparateManagedObjectContextObjects:(id <NSFastEnumeration>)separateObjects
{	
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[(id)separateObjects count]];
	
	for (NSManagedObject *separateObject in separateObjects)
		[objects addObject:[self objectWithID:[separateObject objectID]]];
	
	return objects;
}

@end
