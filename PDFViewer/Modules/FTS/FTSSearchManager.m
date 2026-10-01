//
//  FTSSearchManager.m
//  MobileReplica
//
//  Created by Emanuele Bortolami on 14/09/17.
//  Copyright © 2017 GEAR.it S.r.l. All rights reserved.
//

#import "FTSSearchManager.h"
#import "TextExtractor.h"
#import "FMDB.h"


@implementation FTSOccurrence

- (NSString *)getJSONFormat
{
    NSDictionary *blockJson = [self getDictionaryFormat];
    
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:blockJson options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
}

- (NSDictionary *)getDictionaryFormat
{
    NSMutableDictionary *blockJson = [NSMutableDictionary dictionary];
    
    [blockJson setObject:[NSNumber numberWithInt:self.page] forKey:@"page_index"];
    [blockJson setObject:self.document forKey:@"document"];
    [blockJson setObject:self.text forKey:@"text"];
    [blockJson setObject:[NSNumber numberWithDouble:self.rect_l] forKey:@"rect_l"];
    [blockJson setObject:[NSNumber numberWithDouble:self.rect_t] forKey:@"rect_t"];
    [blockJson setObject:[NSNumber numberWithDouble:self.rect_r] forKey:@"rect_r"];
    [blockJson setObject:[NSNumber numberWithDouble:self.rect_b] forKey:@"rect_b"];
    [blockJson setObject:[NSNumber numberWithInt:self.resultCount] forKey:@"resultCount"];
    
    return blockJson;
}

@end

@interface FTSSearchManager() {
    
    NSString *dbPath;
    
    NSString *termString;
    
    // Filters
    
    NSString *hashFilter;
    
    NSMutableArray *occurrences;
}

@end

@implementation FTSSearchManager

+ (FTSSearchManager *)sharedInstance
{
    static FTSSearchManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FTSSearchManager alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

- (NSMutableArray *)getFTSOccurrences
{
    return occurrences;
}

- (NSString *)getFTSTerm
{
    return termString;
}

- (FTSOccurrence *)getSelectedOccurrence
{
    return [occurrences objectAtIndex:_selectedIndex];
}

- (void)clearSearch
{
    termString = hashFilter = @"";
    _selectedIndex = 0;
    [occurrences removeAllObjects];
}

- (void)selectOccurrenceAtIndex:(int)index
{
    _selectedIndex = index;
}

- (BOOL)hasNextOccurrences
{
    return ((_selectedIndex + 1) < occurrences.count);
}

- (BOOL)hasPrevOccurrences
{
    return (occurrences.count > 0 && (_selectedIndex - 1) >= 0);
}

- (void)searchInit:(NSString *)hash
{
    [self clearSearch];
    
    hashFilter = hash;
    occurrences = [NSMutableArray array];
}

- (void)searchText:(NSString *)text success:(void (^)(NSMutableArray *))success
{
    termString = text;
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inDatabase:^(FMDatabase * _Nonnull db) {
        // If hash is not set, it is a global query
        BOOL isGlobalQuery = !(hashFilter.length > 0);
        
        NSString *ftsQuery = (isGlobalQuery) ? @"SELECT docid, document, MIN(page) AS first_page, rect_left, rect_top, rect_right, rect_bottom, text, snippet, count(*) AS result_count FROM (" : @"";
        
        ftsQuery = [ftsQuery stringByAppendingString:@"SELECT docid, document, page, rect_left, rect_top, rect_right, rect_bottom, text, snippet(fts, '<b>', '</b>', '...', 6, 10) AS snippet FROM FTS "];
        
        if (hashFilter.length > 0) {
            ftsQuery = [ftsQuery stringByAppendingFormat:@"WHERE document = '%@' ", hashFilter];
        }
        
        ftsQuery = [ftsQuery stringByAppendingFormat:@"%@ text MATCH '", (hashFilter.length > 0) ? @"AND" : @"WHERE"];
        
        for (NSString *matchTerm in [text componentsSeparatedByString:@" "]) {
            ftsQuery = [ftsQuery stringByAppendingFormat:@"%@* ", matchTerm];
        }
        
        ftsQuery = [ftsQuery stringByAppendingString:@"' ORDER BY document, page, rect_top desc, rect_left"];
        
        // Add the inner join with Documents table if is a global query
        ftsQuery = (isGlobalQuery) ? [ftsQuery stringByAppendingString:@") GROUP BY document"] : [ftsQuery stringByAppendingString:@""];
        
        FMResultSet *resultSet = [db executeQuery:ftsQuery];
        
        while ([resultSet next]) {
            FTSOccurrence *occurrence = [[FTSOccurrence alloc] init];
            
            occurrence.page = [resultSet intForColumn:@"page"];
            occurrence.text = [resultSet stringForColumn:@"snippet"];
            occurrence.rect_l = [resultSet doubleForColumn:@"rect_left"];
            occurrence.rect_t = [resultSet doubleForColumn:@"rect_top"];
            occurrence.rect_r = [resultSet doubleForColumn:@"rect_right"];
            occurrence.rect_b = [resultSet doubleForColumn:@"rect_bottom"];
            
            occurrence.document = @"";
            occurrence.resultCount = 1;
            
            if (isGlobalQuery) {
                occurrence.page = [resultSet intForColumn:@"first_page"];
                occurrence.document = [resultSet stringForColumn:@"document"];
                occurrence.resultCount = [resultSet intForColumn:@"result_count"];
            }
            
            [occurrences addObject:occurrence];
        }
        
        [db close];
        
        success(occurrences);
    }];
}

#pragma mark - Database FTS

- (void)createDatabaseAtPath:(NSString *)dbpath
{
    dbPath = dbpath;
    [self createDatabase];
}

- (void)createDatabase
{
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    if ([db open]) {
        if (![db tableExists:@"FTS"]) {
            [db executeUpdate:@"CREATE VIRTUAL TABLE FTS USING fts4 (document TEXT,page INTEGER,rect_left DOUBLE,rect_top DOUBLE,rect_right DOUBLE,rect_bottom DOUBLE,text TEXT)"];
        }
        [db close];
    }
}

- (BOOL)createFTSStruct:(NSString *)ftsPath withHash:(NSString *)hash
{
    NSError *errorParser;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:ftsPath]) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[[NSFileManager defaultManager] contentsAtPath:ftsPath] options:NSJSONReadingMutableContainers error:&errorParser];
        
        if (!errorParser) {
            
            // Remove all pages of the current issue (in case of update)
            //[self cleanFTSForHash:hash];
            
            if ([self documentExist:hash]) {
                return NO;
            }
            
            // Insert the new FTS info
            for (NSMutableDictionary *page in [dict objectForKey:@"pages"]) {
                [page setObject:hash forKey:@"hash"];
                
                [self insertFTSRecord:page];
            }
            
            [[NSFileManager defaultManager] removeItemAtPath:ftsPath error:nil];
            return YES;
        }
    }
    
    return NO;
}

- (void)insertFTSRecord:(NSDictionary *)page
{
    NSLog(@"%@", [page objectForKey:@"hash"]);
    NSLog(@"%@", [page objectForKey:@"page"]);
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        for (NSDictionary *block in [page objectForKey:@"blocks"]) {
            
            @try {
                // Insert the new record
                BOOL result = [db executeUpdate:@"INSERT INTO FTS (document, page, rect_left, rect_top, rect_right, rect_bottom, text) VALUES (?, ?, ?, ?, ?, ?, ?)",
                 [page objectForKey:@"hash"],
                 [page objectForKey:@"page"],
                 [block objectForKey:@"rect_l"],
                 [block objectForKey:@"rect_t"],
                 [block objectForKey:@"rect_r"],
                 [block objectForKey:@"rect_b"],
                 [block objectForKey:@"text"]
                 ];
                
                
                if (!result) {
                    NSException *exception = [NSException exceptionWithName:@"insert_error" reason:@"" userInfo:nil];
                    @throw exception;
                }
            } @catch (NSException *exception) {
                *rollback = YES;
                return;
            }
        }
    }];
}

- (void)cleanFTSForHash:(NSString *)hash
{
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inDatabase:^(FMDatabase * _Nonnull db) {
        [db executeUpdate:@"DELETE FROM FTS WHERE document = ?", hash];
        [db close];
    }];
}

- (BOOL)documentExist:(NSString *)hash
{
    __block BOOL exist = NO;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inDatabase:^(FMDatabase * _Nonnull db) {
        
        // Insert the new record
        exist = [db boolForQuery:@"SELECT COUNT(*) FROM FTS WHERE document = ? LIMIT 1", hash];
        [db close];
    }];
    
    return exist;
}

@end
