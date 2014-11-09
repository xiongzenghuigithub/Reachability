//
//  ViewController.m
//  ReachabilityNetwork
//
//  Created by xiongzenghui on 14/11/8.
//  Copyright (c) 2014年 xiongzenghui. All rights reserved.
//

#import "ViewController.h"
#import "Reachability.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    Reachability * r = [Reachability reachabilityWithHostName:@"www.baidu.com" ReachableCompletion:nil UnReachableComplet:nil];
    BOOL isReachable = [r isReachable];
    
    [r startObserve];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
