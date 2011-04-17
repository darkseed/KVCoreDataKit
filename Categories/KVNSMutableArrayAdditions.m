//
//  KVNSArrayAdditions.m
//  KVCoreDataKit
//
//  Created by Kyle Van Essen on 11-04-16.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import "KVNSMutableArrayAdditions.h"


@implementation NSMutableArray (KVCoreDataKitAdditions)

-(void)moveObjectAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex
{
	if (oldIndex == newIndex)
		return;
	
	id item = [self objectAtIndex:oldIndex];
	
	if (newIndex == [self count])
	{
		[self addObject:item];
		[self removeObjectAtIndex:oldIndex];
	}
	else
	{
		[item retain];
		[self removeObjectAtIndex:oldIndex];
		[self insertObject:item atIndex:newIndex];
		[item release];
	}
}

@end
