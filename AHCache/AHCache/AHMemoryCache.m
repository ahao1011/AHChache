//
//  AHMemoryCache.m
//  AHCache
//
//  Created by AH on 2018/8/9.
//  Copyright © 2018年 AH. All rights reserved.
//



#define AH_LOCK(...) pthread_mutex_lock(&_lock); \
__VA_ARGS__; \
pthread_mutex_unlock(&_lock);


#import "AHMemoryCache.h"
#import "AHHeader.h"
#import <pthread.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>


NS_ASSUME_NONNULL_BEGIN

static inline dispatch_queue_t AHReleaseQueueOnMemoryCache(){

//    dispatch_queue_t queue = dispatch_queue_create("com.ahcache", DISPATCH_QUEUE_CONCURRENT);
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

}

/**链表节点*/
@interface AHLinkNode : NSObject{
    @package
    __weak AHLinkNode *_Nullable _pre;
    __weak AHLinkNode *_Nullable _next;
    NSString *_nodeId;
    id _key;
    id _value;
    NSInteger _index;
    NSTimeInterval _time;
}

- (instancetype)initWithKey:(id)key value:(id)value time:(NSTimeInterval)time;
@end

@implementation AHLinkNode
- (NSString *)description{

    NSString * string = [NSString stringWithFormat:@"<AHLinkNode%@: _pre = %@ _next = %@ _nodeId=%@ key=%@ value=%@ index=%zd >",self,_pre,_next,_nodeId,_key,_value,_index];
    return string;
}
- (instancetype)initWithKey:(id)key value:(id)value time:(NSTimeInterval)time
{
    self = [super init];
    if (self) {

        self->_key = key;
        self->_value = value;
        self->_time = time;
    }
    return self;
}
@end

@interface AHLink : NSObject{
    @package
    CFMutableDictionaryRef _dic;
    NSInteger _nodeCount;
    AHLinkNode *_head;
    AHLinkNode *_tail;
    BOOL _releaseOnMainThread;
}

- (void)insertNodeAtHead:(AHLinkNode*)node;
- (void)moveNodeToHead:(AHLinkNode*)node;
- (void)removeNode:(AHLinkNode*)node;
- (AHLinkNode*)removeTailNode;
- (void)removeAllNode;
@end
/**打印链表*/
static inline void printAHLink(AHLink*link){

#ifdef DEBUG
    if (link->_nodeCount <=0) {
        MYLog(@"开始打印链表:\n");
        AHLinkNode *node = link->_head;
        NSLog(@"%@\n",node);
        while (node->_next !=nil) {
            node = node->_next;
            NSLog(@"%@\n",node);
        }
    }
#else

#endif

}
@implementation AHLink

- (instancetype)init
{
    self = [super init];
    if (self) {
        _nodeCount = 0;
        _dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _releaseOnMainThread = NO;


    }
    return self;
}

/**插入某node到双向链表头部*/
- (void)insertNodeAtHead:(AHLinkNode *)node{

    NSCAssert(node!=nil, @"insertNodeAtHead: node不能为空");
    if (node==nil) return;
    if (_head==node) return;
    CFDictionarySetValue(_dic, (__bridge const void*)(node->_key),  (__bridge const void*)node ->_value);
    _nodeCount++;
    if (_head) {
        _head->_pre = node;
        node->_next = _head;
        node->_pre = nil;
        node->_index  = _head->_index+1;
        _head = node;
    }else{
        node -> _index = 0;
        _head = _tail = node;
    }
}
- (void)moveNodeToHead:(AHLinkNode *)node{

    NSCAssert(node!=nil, @"moveNodeToHead:node不能为空");
    if (node==nil) return;
    if (_head==node) return;
    if (node==_tail) {
        _tail = node->_pre;
        _tail->_next=nil;
    }else{
        AHLinkNode *nodePre = node->_pre; // A
        AHLinkNode *nodeNext = node->_next;  // C
        nodePre->_next = nodeNext;
        nodeNext->_pre = nodePre;
    }
    _head->_pre = node;
    node->_next = _head;
    node->_pre = nil;
    _head = node;
    printAHLink(self);
}

- (void)removeNode:(AHLinkNode *)node{

    NSCAssert(node!=nil, @"removeNode:node不能为空");
    if (node==nil) return ;
    if (! CFDictionaryContainsKey(_dic, (__bridge const void*)node->_key)) return;
    CFDictionaryRemoveValue(_dic,(__bridge const void*)node->_key);
    _nodeCount--;
    if (node==_tail) {
        node->_pre ->_next = nil;
        _tail = node->_pre;
    }else if (node==_head) {
        node->_next->_pre = nil;
        _head = node->_next;
    }else{
        AHLinkNode *nodePre = node->_pre; // A
        AHLinkNode *nodeNext = node->_next;  // C
        nodePre->_next = nodeNext;
        nodeNext->_pre = nodePre;
    }
}

- (AHLinkNode *)removeTailNode{

    if (_tail==nil) return nil;
    AHLinkNode *node = _tail;

    CFDictionaryRemoveValue(_dic, (__bridge const void*)_tail->_key);

    if (_nodeCount==1) {
        _tail = _head = nil;
    }else{
        _tail = _tail->_pre;
        _tail->_next = nil;
    }
    return node;
}

- (void)removeAllNode{
    _nodeCount=0;
    _head = nil;
    _tail = nil;
    if (CFDictionaryGetCount(_dic)>0) {

        NSDictionary *redic = (__bridge_transfer  NSDictionary*)_dic;
        _dic = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks    , &kCFTypeDictionaryValueCallBacks);
        dispatch_queue_t queue = _releaseOnMainThread?dispatch_get_main_queue():AHReleaseQueueOnMemoryCache();
        dispatch_async(queue, ^{
            [redic count];
        });
        
    }
}


- (void)dealloc{
    CFRelease(_dic);
}

@end



@interface AHMemoryCache(){

    pthread_mutex_t _lock;
    AHLink *_link;
    dispatch_queue_t _seaQueue;  // 串行
    dispatch_queue_t _conQueue;  // 并行
}


@end



@implementation AHMemoryCache

- (instancetype)init
{
    self = [super init];
    if (self) {

        _coutLimit = LONG_MAX;
        _effectiveTime = DBL_MAX;
        _autoTrimInterval = 5.0;
        _releaseOnMainThread = NO;
        _removeAllMemoryCacheOnMemoryWaring = YES;
        _removeAllMemoryCacheOnEnterBackground = NO;

         pthread_mutex_init(&_lock,NULL);
        _seaQueue = dispatch_queue_create("com.AHCache.serial", DISPATCH_QUEUE_SERIAL);
        _conQueue = dispatch_queue_create("com.AHCache.concurrent", DISPATCH_QUEUE_CONCURRENT);
        _link = [[AHLink alloc]init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ReceiveMemoryWarningNotification) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(EnterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];

        
    }
    return self;
}
#pragma mark - 通知
- (void)ReceiveMemoryWarningNotification{
    // 内存警告
}
- (void)EnterBackgroundNotification{
    // 进入后台

}

#pragma mark - set get
- (void)setCoutLimit:(NSInteger)coutLimit{


    if (coutLimit==_coutLimit || !coutLimit) {return;}
    _coutLimit = coutLimit;
    [self AH_trimToCount:_coutLimit];
}

- (void)setEffectiveTime:(NSTimeInterval)effectiveTime{
    if (effectiveTime==_effectiveTime || !effectiveTime) {
        return;
    }
    _effectiveTime = effectiveTime;
    [self AH_trimToEffectTime:_effectiveTime];
}
- (void)setReleaseOnMainThread:(BOOL)releaseOnMainThread{

    AH_LOCK(
            _releaseOnMainThread= releaseOnMainThread;
            _link->_releaseOnMainThread = releaseOnMainThread;
    )
}

//  暂不使用 
//- (void)setAutoTrimInterval:(NSTimeInterval)autoTrimInterval{
//
//}

- (NSInteger)totalCount{
    AH_LOCK(NSInteger count = _link->_nodeCount;) return count;
}

#pragma mark - 方法

- (BOOL)AH_containsKey:(id)key{
    NSCAssert(key!=nil, @"AH_containsKey key不能为空");
    if (!key) return NO;
    AH_LOCK(BOOL isHave = CFDictionaryContainsKey(_link->_dic, (__bridge const void*)key));
    return isHave;

}
- (BOOL)AH_containsObject:(id)obj{
    NSCAssert(obj!=nil, @"AH_containsObject obj不能为空");
    if (!obj) return NO;
    AH_LOCK(BOOL isHave = CFDictionaryContainsValue(_link->_dic, (__bridge const void*)obj));
    return isHave;
}
- (nullable id)AH_objectForKey:(id)key{
    NSCAssert(key!=nil, @"AH_objectForKey key不能为空");
    if (!key) return nil;
    AH_LOCK(
            AHLinkNode *node = CFDictionaryGetValue(_link->_dic, (__bridge const void*)key);
            if(node){
                node->_time = CACurrentMediaTime();
                [_link moveNodeToHead:node];
            }
    )
    return node;
}
- (void)AH_setObject:(id)obj forKey:(id)key{

     NSCAssert(key!=nil, @"AH_setObject key不能为空");
     NSCAssert(obj!=nil, @"AH_setObject obj不能为空");
    if(!key||!obj)return;
    AH_LOCK(

    // 去key-> obj
            AHLinkNode *node = CFDictionaryGetValue(_link->_dic, (__bridge void const*)key);
    // obj存在 更新time  value 取出来并在双向链表中移至头部
            if(node){
                node->_time = CACurrentMediaTime();
                node->_value = obj;
                [_link moveNodeToHead:node];

            }
    // obj不存在, 插入到双向链表头部
            else{

                [_link insertNodeAtHead:[[AHLinkNode alloc]initWithKey:key value:obj time:CACurrentMediaTime()]];
            }

    // 检查totalCount 是否达到最大值限定, 未达到不做操作 , 达到了清除链表尾部node
            if(_link->_nodeCount>_coutLimit){
                AHLinkNode *node = [_link removeTailNode];
                dispatch_queue_t queue = self.isReleaseOnMainThread?dispatch_get_main_queue():AHReleaseQueueOnMemoryCache();
                dispatch_async(queue, ^{
                    [node class];
                });
            }

    )

}
- (void)AH_removeObjectForKey:(id)key{

    NSCAssert(key!=nil, @"AH_removeObjectForKey key不能为空");
    if (!key)return;
   AH_LOCK(
         AHLinkNode *node = CFDictionaryGetValue(_link->_dic, (__bridge const void*)key);
           if(node){
               [_link removeNode:node];
               dispatch_queue_t queue = self.isReleaseOnMainThread?dispatch_get_main_queue():AHReleaseQueueOnMemoryCache();
               dispatch_async(queue, ^{
                   [node class];
               });
           }
    )

    

}
- (void)AH_removeAllObject{

    AH_LOCK([_link removeAllNode]);
}



- (void)AH_trimToCount:(NSInteger)count{

    if (!count) [self AH_removeAllObject];
    if (self.coutLimit<=count)return;
    BOOL finish = NO;
    NSMutableArray *arr = [NSMutableArray array];

    while (!finish) {

        if (pthread_mutex_trylock(&_lock)) {

            if (_link->_nodeCount>count) { // 清除_link->_nodeCount-count
                AHLinkNode *node = [_link removeTailNode];
                if (node) {
                    [arr addObject:node];
                }
            }else{
                finish = YES;
            }
            pthread_mutex_unlock(&_lock);

        }else{
            usleep(10*1000);
        }
    }
    if (arr.count>0) {
        dispatch_queue_t queue = self.isReleaseOnMainThread?dispatch_get_main_queue():AHReleaseQueueOnMemoryCache();
        dispatch_async(queue, ^{
            [arr class];
        });
    }
}
- (void)AH_trimToEffectTime:(NSTimeInterval)effect{

    if (!_link->_nodeCount) return;
    if (!effect) [self AH_removeAllObject];

    BOOL  finish = NO;
    NSTimeInterval now = CACurrentMediaTime();
    NSMutableArray *arr = [NSMutableArray array];
    while (!finish) {

        if (pthread_mutex_trylock(&_lock)) {
            if (now-_link->_tail->_time>effect) {
                // 清理尾部节点
                AHLinkNode *node = [_link removeTailNode];
                if (node) [arr addObject:node];

            }else{
                finish = YES;
            }

        }else{
            usleep(10*1000);
        }


    }
    dispatch_queue_t queue = self.isReleaseOnMainThread?dispatch_get_main_queue():AHReleaseQueueOnMemoryCache();
    dispatch_async(queue, ^{

        [arr class];
    });
}


@end

NS_ASSUME_NONNULL_END
