//
//  AHDiskCacheRef.h
//  AHCache
//
//  Created by AH on 2018/9/4.
//  Copyright © 2018年 AH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHHeader.h"

NS_ASSUME_NONNULL_BEGIN


@class AHDiskCacheRefItem;
@interface AHDiskCacheRef : NSObject
@property (nonatomic,copy,readonly) NSString *path;
@property (nonatomic,assign) AHDiskCacheRefType type;
#pragma mark - 初始化
-(instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithPath:(NSString*)path type:(AHDiskCacheRefType)type;
+ (instancetype)diskCacheRefWithPath:(NSString*)path type:(AHDiskCacheRefType)type;

#pragma mark - 增
- (BOOL)AH_saveItem:(AHDiskCacheRefItem*)item;
#pragma mark - 删
- (BOOL)AH_removeItemForKey:(NSString*)key;
- (BOOL)AH_removeItemsForKeys:(NSArray*)keys;
- (BOOL)AH_removeItemsLargerThanSize:(int)size;
- (BOOL)AH_removeItemsToCount:(int)count;
/**ps:最不常用的数据 最先被淘汰*/
- (BOOL)AH_removeItemsToTotalSize:(int)size;
- (BOOL)AH_removeItemsBeforeModifiedTime:(int)time;
- (BOOL)AH_removeItemsBeforeVisitTime:(int)time;
- (BOOL)AH_removeAllItems;
- (BOOL)AH_removeAllItemsWithProgress:(nullable void (^)(int64_t count, int64_t totalCount)) progress error:(NSError *_Nullable __autoreleasing)error;

#pragma mark - 查

- (nullable AHDiskCacheRefItem*)getItemForKey:(NSString*)key;




@end

@interface AHDiskCacheRefItem :NSObject

@property (nonatomic,copy) NSString  * _Nullable itemName;
@property (nonatomic,copy) NSString *itemKey;
@property (nonatomic,copy) NSData *itemValue;
@property (nonatomic,assign) int itemSize;
/**最近的修改时间 时间戳 写时间 */
@property (nonatomic,assign,readonly) int itemModifiedTime;
/**最近的访问时间 时间戳 读时间*/
@property (nonatomic,assign,readonly) int itemVisitTime;
@property (nonatomic,strong) NSData * _Nullable itemExtentData;

- (instancetype)initWithKey:(NSString *)key value:(NSData*)value name:(NSString* _Nullable)name size:(int)size extentData:(NSData*)extentData;
- (instancetype)initWithKey:(NSString *)key value:(NSData*)value extentData:(NSData* _Nullable)extentData;
- (instancetype)initWithKey:(NSString *)key value:(NSData*)value;

@end

NS_ASSUME_NONNULL_END
