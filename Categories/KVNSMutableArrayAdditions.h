//
//  KVNSArrayAdditions.h
//  KVCoreDataKit
//
//  Created by Kyle Van Essen on 11-04-16.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSMutableArray (KVCoreDataKitAdditions)

-(void)moveObjectAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex;

@end
