//
//  KVFetchedResultsController.h
//  FlowKit
//
//  Created by Kyle Van Essen on 11-04-15.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef enum
{
	KVArrayControllerChangeInsert = 1,
	KVArrayControllerChangeDelete,
	KVArrayControllerChangeMove,
	KVArrayControllerChangeUpdate
} KVArrayControllerChangeType;

@protocol KVArrayControllerDelegate;

@interface KVArrayController : NSObject {
	
	NSMutableArray *_sortedObjects;
	NSMutableSet *_fetchedObjects;
	
}

-(id)initWithFetchRequests:(NSArray *)fetchRequests
		   sortDescriptors:(NSArray *)sortDescriptors
	  managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

-(BOOL)performFetch:(NSArray **)errors;

-(id)objectAtIndex:(NSUInteger)index;
-(NSUInteger)indexOfObject:(id)object;

@property(retain, readonly) NSArray *fetchRequests;
@property(retain, readonly) NSArray *sortDescriptors;
@property(assign, readonly) NSManagedObjectContext *managedObjectContext;

@property(retain, readonly) NSArray *sortedObjects;
@property(retain, readonly) NSSet *fetchedObjects;

@property(assign) id <KVArrayControllerDelegate> delegate;

@end

@protocol KVArrayControllerDelegate <NSObject>

-(void)arrayControllerWillChangeContent:(KVArrayController *)controller;
-(void)arrayControllerDidChangeContent:(KVArrayController *)controller;

-(void)arrayController:(KVArrayController *)controller
	   didChangeObject:(id)object
			   atIndex:(NSUInteger)index
		 forChangeType:(KVArrayControllerChangeType)changeType
			  newIndex:(NSUInteger)newIndex;

@end

