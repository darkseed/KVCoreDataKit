//
//  NSManagedObjectAdditions.m
//  Flow
//
//  Created by Kyle Van Essen on 11-01-12.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import "KVNSManagedObjectAdditions.h"
#import "KVNSManagedObjectContextAdditions.h"

@implementation NSManagedObject (KVCoreDataKitAdditions)

-(id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
	NSEntityDescription *entity = [managedObjectContext entityForClass:[self class]];
	
	if ((self = [self initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext]))
	{
	}
	
	return self;
}

+(id)instanceWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
	return [[[[self class] alloc] initWithManagedObjectContext:managedObjectContext] autorelease];
}

@end
