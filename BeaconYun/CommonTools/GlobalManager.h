//
//  GlobalManager.h
//  BeaconYun
//
//  Created by 樊芳 on 2019/7/2.
//  Copyright © 2019 MinewTech. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger,ConnectState) {
    ConnectStateUnkown = 0,
    ConnectStateAdvertise,
    ConnectStateBLE
};

NS_ASSUME_NONNULL_BEGIN

@interface GlobalManager : NSObject
//记录当前所在的位置
@property (nonatomic, assign) ConnectState connectState;

@property (nonatomic,strong) NSMutableArray *allDevicesArray;

@property (nonatomic,strong) NSMutableArray *bindArray;


+ (instancetype)sharedInstance;

//全局定时扫描 和 断开扫描
- (void)invalidateTimer;

- (void)initTimer;

@end

NS_ASSUME_NONNULL_END
