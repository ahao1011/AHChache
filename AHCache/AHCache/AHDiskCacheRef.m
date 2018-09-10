//
//  AHDiskCacheRef.m
//  AHCache
//
//  Created by AH on 2018/9/4.
//  Copyright © 2018年 AH. All rights reserved.
//

#import "AHDiskCacheRef.h"

@implementation AHDiskCacheRef





#pragma mark - error
- (NSError*)getErrorWithCode:(AHCacheError)code domain:(NSString*)domain info:(NSDictionary*)info{

    NSError *error = [NSError errorWithDomain:domain code:code userInfo:info];

    return error;
}
- (NSError*)getDiskErrorWithCode:(AHCacheError)code{

    NSDictionary *info = @{
                           NSLocalizedDescriptionKey:NSLocalizedString(@"diskCache 操作失败", nil),
                           NSLocalizedFailureReasonErrorKey:NSLocalizedString(@"diskCache 存储出现问题,请检查AHDiskCachei类方法实现", nil),
                           NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"建议检查AHDiskCachei方法实现", nil)

                           };
    return [NSError errorWithDomain:AHCacheErrorDomain code:code userInfo:info];
}

@end

@implementation AHDiskCacheRefItem

- (instancetype)initWithKey:(NSString *)key value:(NSData *)value name:(NSString *)name size:(int)size extentData:(NSData *)extentData{

    self = [super init];
    if (self) {
        _itemKey = key;
        _itemValue = value;
        if (name.length>0) {
            _itemName = name;
        }
        _itemSize =size;
        _itemExtentData = extentData;
    }
    return self;
}
- (instancetype)initWithKey:(NSString *)key value:(NSData *)value extentData:(NSData *)extentData{
    return [self initWithKey:key value:value name:nil size:(int)value.length extentData:extentData];
}
- (instancetype)initWithKey:(NSString *)key value:(NSData *)value{
    return  [self initWithKey:key value:value extentData:nil];
}



@end
