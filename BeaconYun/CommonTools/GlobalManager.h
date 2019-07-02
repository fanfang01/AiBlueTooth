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

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
