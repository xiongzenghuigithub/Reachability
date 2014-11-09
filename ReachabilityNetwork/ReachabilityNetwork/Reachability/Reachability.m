//
//  Reachability.m
//  ReachabilityNetwork
//
//  Created by xiongzenghui on 14/11/8.
//  Copyright (c) 2014年 xiongzenghui. All rights reserved.
//

#import "Reachability.h"

NSString * const kReachabilityChangedNotification = @"kReachabilityChangedNotification";

@interface Reachability ()

@property (nonatomic , strong) dispatch_queue_t reachabilityQueue;
@property (nonatomic , strong) Reachability * retainOBJ;

@end


@implementation Reachability

- (Reachability *)initWithReachabilityRef:(SCNetworkReachabilityRef)reachaRef {
    if (self = [super init]) {
        _reachabilityRef = reachaRef;
        return self;
    }
    return nil;
}

+ (Reachability *)reachabilityWithHostName:(NSString *) hostName
                       ReachableCompletion:(ReachableCompletion) reachaComplet
                        UnReachableComplet:(UnReachableCompletion) unReachaComple
{
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
    if (reachabilityRef != NULL) {
        @autoreleasepool {
            Reachability * r = [[Reachability alloc] initWithReachabilityRef:reachabilityRef];
            r.reachableBlock = [reachaComplet copy];
            r.unReachableBlock = [unReachaComple copy];
            return r;
        }
    }
    return nil;
}

- (BOOL)isReachable {
    SCNetworkReachabilityFlags flags;
    BOOL didReceiveFlags = SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags);
    
    //没接收到Flags , 不可达
    if (didReceiveFlags == NO) {
        return NO;
    }
    
    //是否可达
    BOOL isReachable = ((flags & kSCNetworkFlagsReachable) != 0);
    
    if (isReachable == NO) {
        return NO;
    }
    
    //是否需要建立连接
    BOOL needsConnection = ((flags & (kSCNetworkReachabilityFlagsConnectionRequired | kSCNetworkReachabilityFlagsTransientConnection)) != 0);
    
    if (needsConnection == NO) {
        return NO;
    }
    
    //是3G网络时，设置为不可达
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == true) {
        if ([self isReachableViaWWAN]) {
            return NO;
        }
    }
    
    //可达、已经建立连接、不是3G网
    return YES;
}

- (BOOL)isReachableViaWWAN {
    
    SCNetworkReachabilityFlags flags;
    BOOL didReiceiveFlags = SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags);
    
    if (didReiceiveFlags == NO) {
        return NO;
    }
    
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    
    if (isReachable == NO) {
        return NO;
    }
    
    BOOL isViaWWAN = ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0);
    
    if (isViaWWAN == NO) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isReachableViaWiFi {
    
    SCNetworkReachabilityFlags flags;
    BOOL didReceiveFlags = SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags);
    if (didReceiveFlags == NO) {
        return NO;
    }
    
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    if (isReachable == NO) {
        return NO;
    }
    
    //通过3G网络连接 --> 不是通过WiFi网络连接
    BOOL isViaWWAN = ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0);
    if (isViaWWAN == YES) {
        return NO;
    }
    
    return YES;
}

#pragma mark - 网络连接状态改变的回调函数
void didReceiveReachabilityStatusChanged(SCNetworkReachabilityRef	target,
                                         SCNetworkReachabilityFlags	flags,
                                         void * info)
{
    NSLog(@"接收到网络连接改变的回调");
    Reachability * reachability = (__bridge Reachability*)info;
    @autoreleasepool {
        [reachability reachabilityChanged:flags];
    }
}

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags {//变化后的flags
    
    //1. 是否建立连接
    BOOL isReachable = ((flags & kSCNetworkFlagsReachable) != 0);
    BOOL isNeedConnection = ((flags & kSCNetworkFlagsConnectionRequired) != 0);
    BOOL isConnected = (isReachable && !isNeedConnection) ? YES : NO;
    
    if (isConnected == NO) {
        return;
    }
    
    //2. 变化成3G网络时，让手机设置为 未连接 到主机
#if TARGET_OS_IPHONE
    if(flags & kSCNetworkReachabilityFlagsIsWWAN) {
        isConnected = NO;
    }
#endif
    
    //3. 执行保存的Block
    if (isConnected == YES) {
        
        if (self.reachableBlock != nil) {
            self.reachableBlock(self);
        }
    }
    else {
        if (self.unReachableBlock != nil) {
            self.unReachableBlock(self);
        }
    }
    
    //4. 发出连接状态改变的通知
    dispatch_async(dispatch_get_main_queue(), ^{//将当前Reachability对象当做参数
        [[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:self];
    });
}


- (BOOL)startObserve {
    
    //1. 设置回调函数所在哪个对象
    SCNetworkReachabilityContext ctx = {0 , NULL, NULL, NULL, NULL};
    ctx.info = (__bridge void*)self;
    
    //2. 保存网络连接的队列
    self.reachabilityQueue = dispatch_queue_create("com.tonymillion.reachability", NULL);
    if (self.reachabilityQueue == nil) {
        return NO;
    }
    
    //3. 对当前Reachability对象retain一次 (增加一个指针引用)
    self.retainOBJ = self;
    
    //4. 设置回调函数
    if (SCNetworkReachabilitySetCallback(self.reachabilityRef, didReceiveReachabilityStatusChanged, &ctx) == false) {
        self.reachabilityQueue = nil;
        self.retainOBJ = nil;
        return NO;
    }
    
    //5. 开启监听 (将监听的连接放入队列)
    if (SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, self.reachabilityQueue) == false) {
        SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);//取消回调函数
        self.reachabilityQueue = nil;
        self.retainOBJ = nil;
        return NO;
    }
    
    return YES;
}

- (BOOL)stopObserve {
    
    //1. 设置回调函数
    SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);
    
    //2. 停止监听
    if (SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, self.reachabilityQueue) == false) {
        return NO;
    }
    
    //3. release对象
    if (self.reachabilityQueue != nil) {
        self.reachabilityQueue = nil;
    }
    
    self.retainOBJ = nil;
    
    return YES;
}


@end
