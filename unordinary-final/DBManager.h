//
// Created by d0gg3r on 2020-11-20.
// Copyright (c) 2020 BioS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"
#import <CommonCrypto/CommonCrypto.h>


@interface DBManager : NSObject

typedef NS_ENUM(NSInteger, AddTagReturnStatus){
    AddTagReturnStatusOK,
    AddTagReturnStatusError,
    AddTagReturnStatusExists
};
typedef NS_ENUM(NSInteger, SearchResult){
    SearchResultOK,
    SearchResultError,
    SearchResultNoResults,
    SearchResultBadQuery
};

-(instancetype)init;
-(const char*)addCaseWithData:(NSDictionary*)data;
-(BOOL)deleteCaseWithHash:(const char*)hash;
-(NSDictionary*)getCaseWithHash:(const char*)hash;
-(AddTagReturnStatus)addTagWithName:(NSString*)name color:(int)color;
-(BOOL)deleteTagWithName:(NSString*)name;
-(int)getTagColorWithName:(NSString*)name;
-(NSDictionary *)getResultFromQuery:(const char*)query;
-(BOOL)updateCaseWithHash:(const char*)hash toData:(NSDictionary*)data;
-(BOOL)updateColorWithName:(NSString *)name toColor:(int)color;

+ (NSString*)hashForString:(NSString*)string;

@end