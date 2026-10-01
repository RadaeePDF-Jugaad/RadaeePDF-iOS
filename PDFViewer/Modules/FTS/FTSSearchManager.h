//
//  FTSSearchManager.h
//  MobileReplica
//
//  Created by Emanuele Bortolami on 14/09/17.
//  Copyright © 2017 GEAR.it S.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FTS_DB @"fts.db"

@interface FTSOccurrence : NSObject

@property (nonatomic) int page;
@property (strong, nonatomic) NSString *document;
@property (strong, nonatomic) NSString *text;
@property (nonatomic) double rect_l;
@property (nonatomic) double rect_t;
@property (nonatomic) double rect_r;
@property (nonatomic) double rect_b;
@property (nonatomic) int resultCount;

- (NSString *)getJSONFormat;
- (NSDictionary *)getDictionaryFormat;

@end

@interface FTSSearchManager : NSObject

@property (nonatomic) int selectedIndex;

+ (FTSSearchManager *)sharedInstance;

- (void)searchInit:(NSString *)hash;
- (void)searchText:(NSString *)text success:(void (^)(NSMutableArray *occurrences))success;
- (void)clearSearch;

- (void)selectOccurrenceAtIndex:(int)index;

- (BOOL)hasPrevOccurrences;
- (BOOL)hasNextOccurrences;

- (NSMutableArray *)getFTSOccurrences;
- (NSString *)getFTSTerm;
- (FTSOccurrence *)getSelectedOccurrence;

- (void)createDatabaseAtPath:(NSString *)dbpath;
- (BOOL)createFTSStruct:(NSString *)ftsPath withHash:(NSString *)hash;
- (void)cleanFTSForHash:(NSString *)hash;
- (void)insertFTSRecord:(NSDictionary *)page;
- (BOOL)documentExist:(NSString *)hash;

@end
