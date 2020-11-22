//
// Created by d0gg3r on 2020-11-20.
// Copyright (c) 2020 BioS. All rights reserved.
//

#import "DBManager.h"

@implementation DBManager {
    const char* dbPath;
    const char* insertCaseString;
    const char* insertTagString;
    const char* deleteCaseString;
    const char* deleteTagString;
    const char* updateCaseString;
    const char* updateTagString;
    const char* getCaseString;
    const char* getTagString;
    NSArray* casesTableColumns;
}

- (instancetype)init {
    self = [super init];
    if (self){
        
        sqlite3* db;
        
        const char* casesTableString = "CREATE TABLE IF NOT EXISTS cases (hash TEXT NOT NULL, name TEXT, gender INTEGER, birthdate TEXT, attachments TEXT, notes TEXT, tags TEXT);";
        sqlite3_stmt* casesTableStatement;
        const char* tagsTableString = "CREATE TABLE IF NOT EXISTS tags (name TEXT NOT NULL, color INTEGER DEFAULT 8421504 NOT NULL);";
        sqlite3_stmt* tagsTableStatement;

        insertCaseString = "INSERT INTO cases (hash, name, gender, birthdate, attachments, notes, tags) VALUES (?, ?, ?, ?, ?, ?, ?);";
        insertTagString = "INSERT INTO tags (name, color) VALUES (?, ?);";
        deleteCaseString = "DELETE FROM cases WHERE hash = ?;";
        deleteTagString = "DELETE FROM tags WHERE name = ?;";
        updateCaseString = "UPDATE cases SET name = ?, gender = ?, birthdate = ?, attachments = ?, notes = ?, tags = ? WHERE hash = ?;";
        casesTableColumns = @[@"name", @"gender", @"birthdate", @"attachments", @"notes", @"tags"];
        updateTagString = "UPDATE tags SET color = ? WHERE name = ?;";
        getCaseString = "SELECT rowid, a.* FROM cases a WHERE hash = ?;";
        getTagString = "SELECT rowid, a.* FROM tags a WHERE name = ?;";

        dbPath = [NSBundle pathForResource:@"unordinary" ofType:@"sqlite3" inDirectory:NSBundle.mainBundle.bundlePath].UTF8String;
        if (dbPath != nil) {

            // Open database
            if (sqlite3_open(dbPath, &db) == SQLITE_OK) {

                // Create table `cases`
                if (sqlite3_prepare_v2(db, casesTableString, -1, &casesTableStatement, NULL) == SQLITE_OK) {
                    if (sqlite3_step(casesTableStatement) == SQLITE_DONE) {
                        sqlite3_finalize(casesTableStatement);
                    } else NSLog(@"Error creating cases table: %s", sqlite3_errmsg(db));
                } else NSLog(@"Error preparing statement 1: %s", sqlite3_errmsg(db));

                // Create table `tags`
                if (sqlite3_prepare_v2(db, tagsTableString, -1, &tagsTableStatement, NULL) == SQLITE_OK) {
                    if (sqlite3_step(tagsTableStatement) == SQLITE_DONE) {
                        sqlite3_finalize(tagsTableStatement);
                    } else NSLog(@"Error creating tags table: %s", sqlite3_errmsg(db));
                } else NSLog(@"Error preparing statement 2: %s", sqlite3_errmsg(db));
            } else NSLog(@"Error opening db: %s", sqlite3_errmsg(db));
        } else NSLog(@"Error retrieving db path");
    }
    NSLog(@"Initialized!");
    return self;
}

- (const char*)addCaseWithData:(NSDictionary *)data {
    sqlite3_stmt* insertCaseStatement;
    sqlite3_stmt* getCaseStatement;
    sqlite3* db;
    const char *hash = NULL;
    BOOL success = NO;
    @try {
        if (sqlite3_open(dbPath, &db) == SQLITE_OK) {
            // "INSERT INTO cases (hash, name, gender, birthdate, attachments, notes, tags) VALUES (?, ?, ?, ?, ?, ?, ?);"
            if (sqlite3_prepare_v2(db, insertCaseString, -1, &insertCaseStatement, NULL) != SQLITE_OK) {
                NSLog(@"Error preparing insert case statement: %s", sqlite3_errmsg(db));
                return NULL;
            }
            if (sqlite3_prepare_v2(db, getCaseString, -1, &getCaseStatement, NULL) != SQLITE_OK) {
                NSLog(@"Error preparing insert case statement: %s", sqlite3_errmsg(db));
                return NULL;
            }
            BOOL unique = NO;
            while (unique == NO) {
                struct timespec tms;
                clock_gettime(CLOCK_REALTIME, &tms);
                int64_t micros = tms.tv_sec * 1000000;
                micros += tms.tv_nsec / 1000;
                hash = [DBManager hashForString:[NSString stringWithFormat:@"%lli", micros]].UTF8String;
                if (sqlite3_bind_text(getCaseStatement, 1, hash, -1, NULL) != SQLITE_OK) return NULL;
                if (sqlite3_step(getCaseStatement) != SQLITE_ROW) unique = YES; // Unique!
                sqlite3_reset(insertCaseStatement);
            }
            if (sqlite3_bind_text(insertCaseStatement, 1, hash, -1, NULL) != SQLITE_OK) return NULL;
            if (sqlite3_bind_text(insertCaseStatement, 2, ((NSString *) data[@"name"]).UTF8String, -1, NULL) != SQLITE_OK) return NULL;
            if (sqlite3_bind_int(insertCaseStatement, 3, ((NSNumber *) data[@"gender"]).intValue) != SQLITE_OK) return NULL;
            if (sqlite3_bind_text(insertCaseStatement, 4, ((NSString *) data[@"birthdate"]).UTF8String, -1, NULL) != SQLITE_OK) return NULL;
            if (sqlite3_bind_text(insertCaseStatement, 5, ((NSString *) data[@"attachments"]).UTF8String, -1, NULL) != SQLITE_OK) return NULL;
            if (sqlite3_bind_text(insertCaseStatement, 6, ((NSString *) data[@"notes"]).UTF8String, -1, NULL) != SQLITE_OK) return NULL;
            if (sqlite3_bind_text(insertCaseStatement, 7, [((NSArray *) data[@"tags"]) componentsJoinedByString:@";"].UTF8String, -1, NULL) != SQLITE_OK) return NULL;
            if (sqlite3_step(insertCaseStatement) != SQLITE_DONE) return NULL;
            success = YES;
        } else NSLog(@"Error opening database: %s", sqlite3_errmsg(db));
    } @finally {
        sqlite3_finalize(getCaseStatement);
        sqlite3_finalize(insertCaseStatement);
        sqlite3_close(db);
        return success ? hash : NULL;
    }
}
- (BOOL)deleteCaseWithHash:(const char*)hash {
    sqlite3* db;
    sqlite3_stmt* deleteCaseStatement;
    BOOL success = NO;
    @try {
        if (sqlite3_open(dbPath, &db) == SQLITE_OK) {
            if (sqlite3_prepare_v2(db, deleteCaseString, -1, &deleteCaseStatement, NULL) != SQLITE_OK) {
                NSLog(@"Error preparing delete case statement: %s", sqlite3_errmsg(db));
                return NO;
            }
            if (sqlite3_bind_text(deleteCaseStatement, 1, hash, -1, NULL) != SQLITE_OK) return NO;
            if (sqlite3_step(deleteCaseStatement) != SQLITE_DONE) return NO;
            success = YES;
        }
    } @finally {
        sqlite3_finalize(deleteCaseStatement);
        sqlite3_close(db);
        return success;
    }
}
- (NSDictionary*)getCaseWithHash:(const char*)hash {
    sqlite3* db;
    sqlite3_stmt* getCaseStatement;
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithCapacity:8];
    BOOL success = NO;

    @try {
        if (sqlite3_open(dbPath, &db) == SQLITE_OK) {
            if (sqlite3_prepare_v2(db, getCaseString, -1, &getCaseStatement, NULL) != SQLITE_OK) {
                NSLog(@"Error preparing get case statement: %s", sqlite3_errmsg(db));
                return NULL;
            }
            //(rowid, hash, name, gender, birthdate, attachments, notes, tags)
            if (sqlite3_bind_text(getCaseStatement, 1, hash, -1, NULL) != SQLITE_OK) return NULL;
            if (sqlite3_step(getCaseStatement) != SQLITE_ROW) return NULL;

            for (int i = 0; i < 8; i++) {
                int type = sqlite3_column_type(getCaseStatement, i);
                switch (type) {
                    case SQLITE_TEXT:
                        data[[NSString stringWithFormat:@"%s", sqlite3_column_name(getCaseStatement, i)]] = [NSString stringWithFormat:@"%s", sqlite3_column_text(getCaseStatement, i)];
                        break;
                    case SQLITE_INTEGER:
                        data[[NSString stringWithFormat:@"%s", sqlite3_column_name(getCaseStatement, i)]] = @(sqlite3_column_int(getCaseStatement, i));
                        break;
                    default:
                        break;
                }
            }
            success = YES;
        }
    } @finally {
        sqlite3_finalize(getCaseStatement);
        sqlite3_close(db);
        return success ? data : NULL;
    }
}
-(AddTagReturnStatus)addTagWithName:(NSString*)name color:(int)color {
    //insertTagString = "INSERT INTO tags (name, color) VALUES (?, ?);";

    sqlite3* db;
    sqlite3_stmt* insertTagStatement;
    sqlite3_stmt* getTagStatement;
    AddTagReturnStatus status = AddTagReturnStatusError;
    @try {
        if (sqlite3_open(dbPath, &db) == SQLITE_OK) {
            if (sqlite3_prepare_v2(db, insertTagString, -1, &insertTagStatement, NULL) != SQLITE_OK) {
                NSLog(@"Error preparing insert tag statement: %s", sqlite3_errmsg(db));
                return NULL;
            }
            if (sqlite3_prepare_v2(db, getTagString, -1, &getTagStatement, NULL) != SQLITE_OK) {
                NSLog(@"Error preparing get tag statement: %s", sqlite3_errmsg(db));
                return NULL;
            }
            if (sqlite3_bind_text(getTagStatement, 1, name.UTF8String, -1, NULL) != SQLITE_OK) return NULL;
            if (sqlite3_step(getTagStatement) == SQLITE_ROW){
                status = AddTagReturnStatusExists;
                return NULL;
            }

            if (sqlite3_bind_text(insertTagStatement, 1, name.UTF8String, -1, NULL) != SQLITE_OK) return NULL;
            if (sqlite3_bind_int(insertTagStatement, 2, color) != SQLITE_OK) return NULL;
            if (sqlite3_step(insertTagStatement) != SQLITE_DONE) return NULL;
            status = AddTagReturnStatusOK;
        } else NSLog(@"Error opening database: %s", sqlite3_errmsg(db));
    } @finally {
        sqlite3_finalize(insertTagStatement);
        sqlite3_finalize(getTagStatement);
        sqlite3_close(db);
        return status;
    }

}
-(BOOL)deleteTagWithName:(NSString*)name {
    //deleteTagString = "DELETE FROM tags WHERE name = ?;";
    sqlite3* db;
    sqlite3_stmt* deleteTagStatement;
    BOOL success = NO;
    @try {
        if (sqlite3_open(dbPath, &db) == SQLITE_OK){
            if (sqlite3_prepare_v2(db, deleteTagString, -1, &deleteTagStatement, NULL) != SQLITE_OK) {
                NSLog(@"Error preparing delete tag statement: %s", sqlite3_errmsg(db));
                return NULL;
            }
            if (sqlite3_bind_text(deleteTagStatement, 1, name.UTF8String, -1, NULL) != SQLITE_OK) return NO;
            if (sqlite3_step(deleteTagStatement) != SQLITE_DONE) return NULL;
            success = YES;
        } else NSLog(@"Error opening database: %s", sqlite3_errmsg(db));
    } @finally {
        sqlite3_finalize(deleteTagStatement);
        sqlite3_close(db);
        return success;
    }

}
-(NSInteger)getTagColorWithName:(NSString*)name {
    //getTagString = "SELECT rowid, a.* FROM tags a WHERE name = ?;";
    sqlite3* db;
    sqlite3_stmt* getTagStatement;
    NSInteger color = -1;
    @try {
        if (sqlite3_open(dbPath, &db) == SQLITE_OK){
            if (sqlite3_prepare_v2(db, getTagString, -1, &getTagStatement, NULL) != SQLITE_OK) {
                NSLog(@"Error preparing get tag statement: %s", sqlite3_errmsg(db));
                return -1;
            }
            if (sqlite3_bind_text(getTagStatement, 1, name.UTF8String, -1, NULL) != SQLITE_OK) return -1;
            if (sqlite3_step(getTagStatement) != SQLITE_ROW) return -1;
            color = sqlite3_column_int(getTagStatement, 2);
        } else NSLog(@"Error opening database: %s", sqlite3_errmsg(db));
    } @finally {
        sqlite3_finalize(getTagStatement);
        sqlite3_close(db);
        return color;
    }


}
#pragma clang diagnostic push // IDE SETTINGS
#pragma ide diagnostic ignored "OCDFAInspection" // IDE SETTINGS
-(NSDictionary*)getResultFromQuery:(const char*)query { // Used for search - custom search method with parameters hard to implement
    sqlite3* db;
    sqlite3_stmt* queryStatement;
    NSMutableDictionary* data = [[NSMutableDictionary alloc] init];
    SearchResult result = SearchResultError;
    @try {
        if (sqlite3_open(dbPath, &db) == SQLITE_OK){
            if (sqlite3_prepare_v2(db, query, -1, &queryStatement, NULL) != SQLITE_OK){
                NSLog(@"Error preparing search query: %s", sqlite3_errmsg(db));
                result = SearchResultBadQuery;
                return NULL;
            }
            
            while(sqlite3_step(queryStatement) == SQLITE_ROW){
                NSMutableDictionary* current = [[NSMutableDictionary alloc]init];
            for (int i = 0; i < 8; i++) {
                int type = sqlite3_column_type(queryStatement, i);
                switch (type) {
                    case SQLITE_TEXT:
                        current[[NSString stringWithFormat:@"%s", sqlite3_column_name(queryStatement, i)]] = [NSString stringWithFormat:@"%s", sqlite3_column_text(queryStatement, i)];
                        break;
                    case SQLITE_INTEGER:
                        current[[NSString stringWithFormat:@"%s", sqlite3_column_name(queryStatement, i)]] = @(sqlite3_column_int(queryStatement, i));
                        break;
                    default:
                        break;
                }
            }
                
                [data setValue:current forKey:[NSString stringWithFormat:@"%lu", (unsigned long)data.count]];
            }
            result = SearchResultOK;
        } else NSLog(@"Error opening database: %s", sqlite3_errmsg(db));
    } @finally {
        sqlite3_finalize(queryStatement);
        sqlite3_close(db);
        if (result != SearchResultError){
            data[@"result"] = @(result);
            return data;
        }
        return NULL;
    }
}
#pragma clang diagnostic pop // IDE SETTINGS
#pragma clang diagnostic push // IDE SETTINGS
#pragma ide diagnostic ignored "OCDFAInspection" // IDE SETTINGS
-(BOOL)updateCaseWithHash:(const char*)hash toData:(NSDictionary*)data {

    //updateCaseString = "UPDATE cases SET name = ?, gender = ?, birthdate = ?, attachments = ?, notes = ?, tags = ? WHERE hash = ?;";
    sqlite3* db;
    sqlite3_stmt* updateCaseStatement;
    sqlite3_stmt* getCaseStatement;
    BOOL success = NO;
    @try {
        if (sqlite3_open(dbPath, &db) == SQLITE_OK) {
            if (sqlite3_prepare_v2(db, updateCaseString, -1, &updateCaseStatement, NULL) != SQLITE_OK) {
                NSLog(@"Error preparing update case query: %s", sqlite3_errmsg(db));
                return NULL;
            }
            if (sqlite3_prepare_v2(db, getCaseString, -1, &getCaseStatement, NULL) != SQLITE_OK){
                NSLog(@"Error preparing get case query: %s", sqlite3_errmsg(db));
                return NULL;
            }
            if (sqlite3_bind_text(getCaseStatement, 1, hash, -1, NULL) != SQLITE_OK) return NULL;
            if (sqlite3_step(getCaseStatement) != SQLITE_ROW){
                NSLog(@"No cases found for given hash!");
                return NULL;
            }

            for (id dataKey in data){
                id dataValue = data[dataKey];
                if ([[dataValue class] isSubclassOfClass:[NSString class]]){
                    if (sqlite3_bind_text(updateCaseStatement, (int) [casesTableColumns indexOfObject:dataKey]+1, ((NSString*)dataValue).UTF8String, -1, NULL) != SQLITE_OK) return NULL;
                } else if ([[dataValue class] isSubclassOfClass:[NSNumber class]]){
                    if (sqlite3_bind_int(updateCaseStatement, (int) [casesTableColumns indexOfObject:dataKey]+1, ((NSNumber*)dataValue).intValue) != SQLITE_OK) return NULL;
                } else if ([[dataValue class] isSubclassOfClass:[NSArray class]]) {
                    if (sqlite3_bind_text(updateCaseStatement, (int) [casesTableColumns indexOfObject:dataKey]+1, [((NSArray*)dataValue) componentsJoinedByString:@";"].UTF8String, -1, NULL) != SQLITE_OK) return NULL;
                } else {
                    NSLog(@"Received unexpected data type!");
                    return NULL;
                }
            }
            if (sqlite3_bind_text(updateCaseStatement, 7, hash, -1, NULL) != SQLITE_OK) return NULL;
            if (sqlite3_step(updateCaseStatement) != SQLITE_DONE) return NULL;
            success = YES;
        } else NSLog(@"Error opening database: %s", sqlite3_errmsg(db));
    } @finally {
        sqlite3_finalize(updateCaseStatement);
        sqlite3_finalize(getCaseStatement);
        sqlite3_close(db);
        return success;
    }

}
#pragma clang diagnostic pop // IDE SETTINGS
//updateTagString = "UPDATE tags SET color = ? WHERE name = ?;";
-(BOOL)updateColorWithName:(NSString*)name toColor:(int)color {
    sqlite3* db;
    sqlite3_stmt* updateTagStatement;
    BOOL success = NO;
    @try {
        if (sqlite3_open(dbPath, &db) == SQLITE_OK) {
            if (sqlite3_prepare_v2(db, updateTagString, -1, &updateTagStatement, NULL) != SQLITE_OK){
                NSLog(@"Error preparing update tag query: %s", sqlite3_errmsg(db));
                return NULL;
            }
            if (sqlite3_bind_int(updateTagStatement, 1, color) != SQLITE_OK) return NULL;
            if (sqlite3_bind_text(updateTagStatement, 2, name.UTF8String, -1, NULL) != SQLITE_OK) return NULL;
            if (sqlite3_step(updateTagStatement) != SQLITE_DONE) return NULL;
            success = YES;
        } else NSLog(@"Error opening database: %s", sqlite3_errmsg(db));
    } @finally {
        sqlite3_finalize(updateTagStatement);
        sqlite3_close(db);
        return success;
    }
}
+ (NSString *)hashForString:(NSString*)string {

    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_MD5_DIGEST_LENGTH];

    CC_MD5(data.bytes, (CC_LONG)data.length, digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }

    return output;
}
@end
