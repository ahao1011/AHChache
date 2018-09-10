//
//  AHMemoryCache.h
//  AHCache
//
//  Created by AH on 2018/8/9.
//  Copyright © 2018年 AH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AHMemoryCache : NSObject

/**总数量*/
@property (nonatomic,assign,readonly) NSInteger totalCount;
/**数量限制,当>countLimit时会自动释放 设置为0则表示每次都全部清除*/
@property (nonatomic,assign) NSInteger coutLimit;
/**设置有效的时间段, 当前时间-tail.time 若不在该有效时间段内则清除,直到tail.time在有效时间段内*/
@property (nonatomic,assign) NSTimeInterval effectiveTime;
/**自动清理内存的频率 暂不使用*/
@property (nonatomic,assign) NSTimeInterval autoTrimInterval;
/**默认为NO*/
@property (nonatomic,assign,getter=isReleaseOnMainThread) BOOL releaseOnMainThread;
/**是否在收到内存警告时,主动释放 默认为YES*/
@property (nonatomic,assign,getter=shouldRemoveAllMemoryCacheOnMemoryWaring) BOOL removeAllMemoryCacheOnMemoryWaring;
/**是否在app进入后台时,主动释放 默认为NO*/
@property (nonatomic,assign,getter=shouldRemoveAllMemoryCacheOnEnterBackground) BOOL removeAllMemoryCacheOnEnterBackground;

NS_ASSUME_NONNULL_BEGIN

- (BOOL)AH_containsKey:(id)key;
- (BOOL)AH_containsObject:(id)obj;
- (nullable id)AH_objectForKey:(id)key;
- (void)AH_setObject:(id)obj forKey:(id)key;
- (void)AH_removeObjectForKey:(id)key;
- (void)AH_removeAllObject;
- (void)AH_trimToCount:(NSInteger)count;
- (void)AH_trimToEffectTime:(NSTimeInterval)effect;

NS_ASSUME_NONNULL_END




@end
