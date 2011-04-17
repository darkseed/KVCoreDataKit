//
//  KVCoreDataManager.h
//  Flow
//
//  Created by Kyle Van Essen on 11-01-12.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

static NSString *const KVCoreDataManagerObjectsUpdatedOnBackgroundQueueNotification = @"KVCoreDataManagerObjectsUpdatedOnBackgroundQueueNotification";

@interface KVCoreDataManager : NSObject {

}

#pragma mark Initialzation

-(id)initWithPersistentStoreLocation:(NSURL *)URL managedObjectModelName:(NSString *)objectModelName error:(NSError **)error;

#pragma mark Managed Object Contexts

-(NSManagedObjectContext *)newManagedObjectContext;
-(void)assertManagedObjectContextIsMainManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

#pragma mark Queuing Operations

-(void)addBackgroundOperationWithBlock:(void (^)(NSManagedObjectContext *newManagedObjectContext))block;

-(void)addBackgroundOperationWithBlock:(void (^)(NSManagedObjectContext *newManagedObjectContext))block
				  mergeCompletionBlock:(void (^)())completionBlock;

#pragma mark Saving Managed Object Contexts

-(void)saveMainManagedObjectContext:(NSError **)saveError;
-(void)saveAndMergeManagedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)saveError;

#pragma mark Properties

@property(retain, readonly) NSManagedObjectContext *mainManagedObjectContext;
@property(retain, readonly) NSManagedObjectModel *managedObjectModel;
@property(retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property(retain, readonly) NSPersistentStore *persistentStore;

@property(assign, getter=isSaving, readonly) BOOL saving;

@property(readonly) NSOperationQueue *backgroundQueue;

@end
