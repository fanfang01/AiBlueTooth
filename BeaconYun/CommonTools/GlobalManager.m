//
//  GlobalManager.m
//  BeaconYun
//
//  Created by 樊芳 on 2019/7/2.
//  Copyright © 2019 MinewTech. All rights reserved.
//

#import "GlobalManager.h"

@implementation GlobalManager
+ (instancetype)sharedInstance {
    static GlobalManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}
@end
