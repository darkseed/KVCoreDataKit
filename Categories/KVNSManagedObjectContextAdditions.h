//
//  NSManagedObjectContextAdditions.h
//  Flow
//
//  Created by Kyle Van Essen on 11-01-12.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (KVCoreDataKitAdditions)

-(NSEntityDescription *)entityForClass:(Class)className;
-(NSEntityDescription *)entityWithName:(NSString *)name;

-(NSFetchRequest *)fetchRequestWithClass:(Class)className;
-(NSFetchRequest *)fetchRequestForEntityWithName:(NSString *)entityName;

-(NSArray *)executeFetchWithEntity:(NSEntityDescription *)entity
						 predicate:(NSPredicate *)predicate
				   sortDescriptors:(NSArray *)sortDescriptors
							 error:(NSError **)error;

-(void)executeFetchRequest:(NSFetchRequest *)request completionHandler:(void (^)(NSArray *objects, NSError *error))completionHandler;

-(NSArray *)objectsFromSeparateManagedObjectContextObjects:(id <NSFastEnumeration>)separateObjects;

@end
