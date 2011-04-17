//
//  NSFetchedResultsControllerAdditions.h
//  Flow
//
//  Created by Kyle Van Essen on 11-01-18.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import <CoreData/CoreData.h>

#if TARGET_OS_IPHONE
@interface NSFetchedResultsController (KVCoreDataKitAdditions)

-(void)refetchWithPredicate:(NSPredicate *)newPredicate;

-(NSArray *)objectsPassingPredicate:(NSPredicate *)predicate;
-(BOOL)hasObjectsPassingPredicate:(NSPredicate *)predicate;

@property(nonatomic, readonly) BOOL hasObjects;
@property(nonatomic, readonly) NSUInteger count;

@end
#endif
