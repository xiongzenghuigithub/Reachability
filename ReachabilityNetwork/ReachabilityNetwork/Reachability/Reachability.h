//
//  Reachability.h
//  ReachabilityNetwork
//
//  Created by xiongzenghui on 14/11/8.
//  Copyright (c) 2014年 xiongzenghui. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <SystemConfiguration/SystemConfiguration.h>

#include "netdb.h"

#pragma mark - 全局通知变量
extern NSString * const kReachabilityChangedNotification;

@class Reachability;
typedef void (^ReachableCompletion)(Reachability * reachability);
typedef void (^UnReachableCompletion)(Reachability * reachability);

@interface Reachability : NSObject

/**
 *  一个Reachability对象保存一个网络连接引用
 */
@property (nonatomic, assign) SCNetworkReachabilityRef reachabilityRef;

 /**
  *  保存传入的Block
  */
@property (nonatomic, copy)ReachableCompletion reachableBlock;
@property (nonatomic, copy)UnReachableCompletion unReachableBlock;

/**
 *  根据HostName创建Reachability对象 -- 得到一个SCNetworkReachabilityRef结构体变量
 */
+ (Reachability *)reachabilityWithHostName:(NSString *) hostName
                       ReachableCompletion:(ReachableCompletion) reachaComplet
                        UnReachableComplet:(UnReachableCompletion) unReachaComple;

- (Reachability *)initWithReachabilityRef:(SCNetworkReachabilityRef)reachaRef;

/**
 *  判断当前Reachability保存的网络连接是否可达
 */
- (BOOL)isReachable; //得到SCNetworkReachabilityFlags
/**
 *  判断当前Reachability保存的网络连接, 通过3G网络 , 是否可达
 */
- (BOOL)isReachableViaWWAN;
/**
 *  判断当前Reachability保存的网络连接, 通过WiFi网络 , 是否可达
 */
- (BOOL)isReachableViaWiFi;

/**
 *  开始监听网络连接
 */
- (BOOL)startObserve;

/**
 *  停止监听网络连接
 */
- (BOOL)stopObserve;

/**
 *  网络连接发生改变时, 1)执行传入的Block 2)发出通知
 */
- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags;

@end
