//
//  FLTaskListResultsController.m
//  Flow
//
//  Created by Kyle Van Essen on 11-01-19.
//  Copyright 2011 Vibealicious. All rights reserved.
//

#import "KVFilterableFetchedResultsController.h"
#import "KVCoreDataKit.h"

#if TARGET_OS_IPHONE

@interface KVFilterableFetchedResultsController ()

-(void)_rebuildFilterPredicate;
-(void)_reloadFetchedResultsController;

@property(nonatomic, copy, readwrite) NSDictionary *searchScopes;

@property(nonatomic, copy, readwrite) NSString *sectionNameKeyPath;
@property(nonatomic, copy, readwrite) NSPredicate *basePredicate;
@property(nonatomic, copy, readwrite) NSPredicate *searchFilterPredicate;

@property(nonatomic, retain, readwrite) NSFetchedResultsController *fetchedResultsController;

@end

@implementation KVFilterableFetchedResultsController

@synthesize searchString = _searchString;
@synthesize selectedScope = _selectedScope;
@synthesize searchScopes = _searchScopes;

@synthesize sectionNameKeyPath = _sectionNameKeyPath;
@synthesize basePredicate = _basePredicate;
@synthesize searchFilterPredicate = _searchFilterPredicate;
@synthesize fetchedResultsController = _fetchedResultsController;

-(id)initWithFetchedResultsController:(NSFetchedResultsController *)resultsController searchScopes:(NSDictionary *)searchScopes
{
	if ((self = [super init]))
	{
		self.searchString = @"";
		self.searchScopes = searchScopes;
		
		NSFetchRequest *newFetchRequest = [[resultsController.fetchRequest copy] autorelease];
		
		self.fetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:newFetchRequest
																			 managedObjectContext:[resultsController managedObjectContext]
																			   sectionNameKeyPath:[resultsController sectionNameKeyPath]
																						cacheName:nil] autorelease];
		
		self.basePredicate = [resultsController.fetchRequest predicate];
		self.sectionNameKeyPath = self.fetchedResultsController.sectionNameKeyPath;
	}
	
	return self;
}

-(void)dealloc
{
	[_fetchedResultsController release];
	[_searchString release];
	[_selectedScope release];
	[_searchScopes release];
	[_sectionNameKeyPath release];
	[_basePredicate release];
	[_searchFilterPredicate release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Setters / Getters
#pragma mark -

-(void)setSearchString:(NSString *)newSearchString
{
	if ([self.searchString isEqualToString:newSearchString])
		return;
	
	[_searchString release];
	_searchString = [newSearchString copy];
	
	if (self.searchString)
		[self _rebuildFilterPredicate];
}

-(void)setSelectedScope:(NSString *)newSelectedScope
{
	if ([self.selectedScope isEqualToString:newSelectedScope])
		return;
	
	[_selectedScope release];
	_selectedScope = [newSelectedScope copy];
	
	if (self.selectedScope)
		[self _rebuildFilterPredicate];
}

-(NSArray *)scopeNames
{
	if ([self.searchScopes count] < 2)
		return nil;
	
	NSMutableArray *scopeNames = [NSMutableArray arrayWithArray:[self.searchScopes allKeys]];
	[scopeNames addObject:FLAllScopesName];
	
	[scopeNames sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	return scopeNames;
}

-(void)setSectionNameKeyPath:(NSString *)newSectionNameKeyPath
{
	if ([self.sectionNameKeyPath isEqualToString:newSectionNameKeyPath])
		return;
	
	[_sectionNameKeyPath release];
	_sectionNameKeyPath = [newSectionNameKeyPath copy];
	
	NSFetchedResultsController *newFetchedResultsController;
	newFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchedResultsController.fetchRequest
																	  managedObjectContext:[self.fetchedResultsController managedObjectContext]
																		sectionNameKeyPath:self.sectionNameKeyPath
																				 cacheName:nil];
	
	id delegate = self.fetchedResultsController.delegate;
	self.fetchedResultsController = newFetchedResultsController;
	
	[self _rebuildFilterPredicate];
	
	self.fetchedResultsController.delegate = delegate;
}

#pragma mark -
#pragma mark Updating Fetch Request
#pragma mark -

-(void)_rebuildFilterPredicate
{
	NSString *predicateFormat = @"%K contains[c] %@";
	
	if ([self.selectedScope isEqualToString:FLAllScopesName] || !self.selectedScope)
	{
		NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:[self.searchScopes count]];
		
		for (NSString *key in [self.searchScopes allValues])
			[predicates addObject:[NSPredicate predicateWithFormat:predicateFormat, key, self.searchString]];
		
		self.searchFilterPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
	}
	else 
	{
		self.searchFilterPredicate = [NSPredicate predicateWithFormat:predicateFormat,
								[self.searchScopes objectForKey:self.selectedScope],
								self.searchString];
	}
	
	[self _reloadFetchedResultsController];
}

-(void)_reloadFetchedResultsController
{
	NSMutableArray *subPredicates = [NSMutableArray array];
	
	if (self.basePredicate) [subPredicates addObject:self.basePredicate];
	if (self.searchFilterPredicate) [subPredicates addObject:self.searchFilterPredicate];
	
	NSPredicate *fetchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
	
	[self.fetchedResultsController refetchWithPredicate:fetchPredicate];
}

@end
#endif
