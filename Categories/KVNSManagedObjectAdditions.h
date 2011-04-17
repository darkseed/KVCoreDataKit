//
//  NSManagedObjectAdditions.h
//  Flow
//
//  Created by Kyle Van Essen on 11-01-12.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NSManagedObject (KVCoreDataKitAdditions)

-(id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+(id)instanceWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
