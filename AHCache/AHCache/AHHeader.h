//
//  AHHeader.h
//  BannNewVersion
//
//  Created by ah on 16/3/25.
//  Copyright © 2016年 ah. All rights reserved.
//

// 常见公共类以及宏

#ifndef AHHeader_h
#define AHHeader_h


// __weakSelf
#define WS(weakSelf) __weak typeof(&*self) weakSelf = self;
#define WEAK_SELF __weak typeof(self) weakSelf = self

//  日志打印
#ifdef DEBUG  // 调试阶段
#define MYLog(...)
#else // 发布阶段
#define LRString [NSString stringWithFormat:@"%s", __FILE__].lastPathComponent
#define MYLog(...) printf("%s: %s 第%d行: %s\n\n",[[NSString lr_stringDate] UTF8String], [LRString UTF8String] ,__LINE__, [[NSString stringWithFormat:__VA_ARGS__] UTF8String]);
#endif

static NSString *cacheHandleStart = @"cacheHandleStart";
static NSString *cacheHandleEnd= @"cacheHandleEnd";



/**disk储存类型*/

typedef NS_ENUM (NSInteger,AHDiskCacheRefType){

    /**文件储存*/
    AHDiskCacheRefTypeDefault   =  0,
    /**被用户*/
    AHDiskCacheRefTypeSqlite    = 1 << 1,
    /**被系统*/
    AHDiskCacheRefTypeFile      = 1 << 2
};

/**错误error集合*/
#define AHCacheErrorDomain @"com.AHCache.domain"

typedef NS_ENUM(NSInteger,AHCacheError) {

    /**写入失败*/
    AHCacheErrorWrite   =0,
    /**读取失败*/
    AHCacheErrorRead    = 1 << 1,
    /**查询失败*/
    AHCacheErrorQuery   = 1 << 2
};

#endif /* AHHeader_h */
