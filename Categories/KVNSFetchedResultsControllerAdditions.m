//
//  NSFetchedResultsControllerAdditions.m
//  Flow
//
//  Created by Kyle Van Essen on 11-01-18.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import "KVNSFetchedResultsControllerAdditions.h"
#import "KVNSManagedObjectContextAdditions.h"

#if TARGET_OS_IPHONE
@implementation NSFetchedResultsController (KVCoreDataKitAdditions)

-(void)refetchWithPredicate:(NSPredicate *)newPredicate
{
	if ([newPredicate isEqual:[self.fetchRequest predicate]])
		return;
	
	if (self.cacheName)
		[NSFetchedResultsController deleteCacheWithName:self.cacheName];
	
	[self.fetchRequest setPredicate:newPredicate];
	[self performFetch:nil];
}

-(NSArray *)objectsPassingPredicate:(NSPredicate *)predicate
{
	return [self.fetchedObjects filteredArrayUsingPredicate:predicate];
}

-(BOOL)hasObjectsPassingPredicate:(NSPredicate *)predicate
{
	return [[self objectsPassingPredicate:predicate] count] > 0;
}

-(BOOL)hasObjects
{
	return [self count] > 0;
}

-(NSUInteger)count
{
	return [self.fetchedObjects count];
}

@end
#endif