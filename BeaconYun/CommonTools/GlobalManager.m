//
//  GlobalManager.m
//  BeaconYun
//
//  Created by 樊芳 on 2019/7/2.
//  Copyright © 2019 MinewTech. All rights reserved.
//

#import "GlobalManager.h"
#import "MinewModuleManager.h"
#import "MinewModule.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface GlobalManager ()
@property (nonatomic, strong)MinewModuleManager *manager;
@end

@implementation GlobalManager
{
    NSTimer *_reloadTimer;
}
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
        [self initCore];
        //只想实现一个后台检测不断重新扫描的过程
        [self initTimer];
        
    }
    return self;
}

- (void)initCore {
    _manager = [MinewModuleManager sharedInstance];
}
//后台持续1s扫描
- (void)initTimer {
    if (!_reloadTimer) {
        _reloadTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshScannedDevices) userInfo:nil repeats:YES];
    }
}

- (void)refreshScannedDevices {
    _allDevicesArray = [NSMutableArray arrayWithArray:_manager.allModules];
    _bindArray = _manager.bindModules;
    
    for (NSDictionary *info in _bindArray) {
        NSString *macString = info[@"macString"];
        MinewModule *module = [self isExistsModuleInScannedList:macString];
        if (module) {//如果没有连接的话，去连接
//            if (!module.connected && !module.connecting) {//未连接，开始去连接
//                [_manager connecnt:module];
//                NSLog(@"需要重新去扫描的设备:%@",module.peripheral);
//            }
            CBPeripheral *peripheral = module.peripheral;
            if (peripheral.state != CBPeripheralStateConnected && peripheral.state != CBPeripheralStateConnecting) {
                [_manager connecnt:module];
            }
        }
    }
    
}

- (void)invalidateTimer {
    [_reloadTimer invalidate];
    _reloadTimer = nil;
}

//在绑定的队列里，是否存在在扫描的队列里
- (MinewModule *)isExistsModuleInScannedList:(NSString *)macString {
    for (MinewModule *module in _allDevicesArray) {
        if ([module.macString isEqualToString:macString]) {
            return module;
        }
    }
    
    return nil;
}
@end
