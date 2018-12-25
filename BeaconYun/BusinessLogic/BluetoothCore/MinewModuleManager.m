//
//  MinewModuleManager.m
//  MinewModuleDemo
//
//  Created by SACRELEE on 11/16/16.
//  Copyright © 2016 SACRELEE. All rights reserved.
//

#import "MinewModuleManager.h"
#import "MinewCommonTool.h"
#import "MinewModule.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BYCommonMacros.h"


#define sBindDataPath [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define sBindDataFile [sBindDataPath stringByAppendingString:@"/data.archive"]


@interface MinewModuleManager () <CBCentralManagerDelegate>

@end

@implementation MinewModuleManager
{
    CBCentralManager *_centralManager;
    dispatch_queue_t _bluetoothQueue;
    NSMutableArray *_scannedModules;
    NSMutableArray *_appearModules;
    NSMutableDictionary *_bindModulesDict;
    NSMutableDictionary *_bindUUIDs;
    NSMutableDictionary *_connectingModuleDict;
    NSTimer *_timer;
    BOOL _scanning;
}

#pragma mark *******************************Init
+(MinewModuleManager *)sharedInstance
{
    static MinewModuleManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc]init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initializeCore];
    }
    return self;
}

- (void)initializeCore
{
    _scannedModules = [[NSMutableArray alloc]init];
    _appearModules = [[NSMutableArray alloc]init];
    if (!_bindModulesDict) {
        _bindModulesDict = [[NSMutableDictionary alloc]init];
    }
    NSUserDefaults *stand = [NSUserDefaults standardUserDefaults];
    NSDictionary *dic = [stand objectForKey:BIND_DATA];
    if (dic) {
        _bindModulesDict = [NSMutableDictionary dictionaryWithDictionary:dic];
    }
    _bindUUIDs = [[NSMutableDictionary alloc]init];
    _connectingModuleDict = [NSMutableDictionary dictionary];
    
    _bluetoothQueue = dispatch_queue_create("com.minew.tech", DISPATCH_QUEUE_SERIAL);
    _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:_bluetoothQueue options:@{CBCentralManagerOptionShowPowerAlertKey: @NO}];
    
    
    // try to retrieve devices
    
//    NSDictionary *moduleDict = [NSKeyedUnarchiver unarchiveObjectWithFile:sBindDataFile];
//    NSArray *tmpUUIDs = moduleDict.allKeys;
//    
//    if (tmpUUIDs.count)
//    {
//        NSMutableArray *nsuuids = [NSMutableArray arrayWithCapacity:tmpUUIDs.count];
//        
//        for ( NSInteger i = 0; i < tmpUUIDs.count; i ++ )
//        {
//            [nsuuids addObject:[[NSUUID alloc]initWithUUIDString:tmpUUIDs[i]]];
//        }
//        
//        NSArray *peris = [_centralManager retrievePeripheralsWithIdentifiers:nsuuids];
//        
//        for ( NSInteger i = 0; i < peris.count; i ++)
//        {
//            CBPeripheral *per = peris[i];
//            
//            MinewModule *module = [[MinewModule alloc]initWithPeripheral:per infoDict:moduleDict[per.identifier.UUIDString]];
//            [_bindModulesDict setValue:module forKey:per.identifier.UUIDString];
//            [_bindUUIDs setValue:@1 forKey:per.identifier.UUIDString];
//        }
//    }
}


- (void)initializeTimer
{
    if ( !_timer)
    {
        _timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(handleModules) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
        [_timer fire];
    }
}

- (NSArray *)bindModules
{
    return [NSArray arrayWithArray:_bindModulesDict.allValues];
}

- (void)invalidateTimer
{
    [_timer invalidate];
    _timer = nil;
}

- (NSArray *)allModules
{
    return _scannedModules;
}

- (void)addBindModule:(MinewModule *)module
{
    
//    [_bindModulesDict setValue:module forKey:module.UUID];
    
    if (module ) {
        NSDictionary *info = @{@"customName": module.name,@"is_bind":@(module.isBind),@"macString":module.macString,@"macByte":@(module.macBytes)};

        [_bindModulesDict setValue:info forKey:module.macString];
    }
    NSUserDefaults *stand = [NSUserDefaults standardUserDefaults];
    [stand setObject:_bindModulesDict forKey:BIND_DATA];
    
    BOOL archiveSuccess = [NSKeyedArchiver archiveRootObject:_bindModulesDict toFile:sBindDataFile];
    if (archiveSuccess)
        NSLog(@"====Archive Bind UUIDs success!");
    else
        NSLog(@"====Archive Bind UUIDs failed!");
}

- (void)removeBindModule:(MinewModule *)module
{
    [_bindModulesDict removeObjectForKey:module.macString];
    
//    [_bindUUIDs removeObjectForKey:module.macString];
    [NSKeyedArchiver archiveRootObject:_bindModulesDict toFile:sBindDataFile];
    
    NSUserDefaults *stand = [NSUserDefaults standardUserDefaults];
    [stand setObject:_bindModulesDict forKey:BIND_DATA];
}


#pragma mark ********************************Public
- (void)startScan
{
    _scanning = YES;
    [self initializeTimer];
//    [_scannedModules removeAllObjects];
    
    //指定扫描特定的服务
//    CBUUID *uuid1 = [CBUUID UUIDWithString:@"FFF0"];
//    NSArray *uuidArr = @[uuid1];
    
    [MinewCommonTool onThread:_bluetoothQueue execute:^{
        [_centralManager scanForPeripheralsWithServices:nil options:@{ CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
    }];
}

- (void)stopScan
{
//    [_scannedModules removeAllObjects];
    [_appearModules removeAllObjects];
    
    _scanning = NO;
    [self invalidateTimer];
    
    
    [MinewCommonTool onThread:_bluetoothQueue execute:^{
        [_centralManager stopScan];
    }];
}

// connect to a module
- (void)connecnt:(MinewModule *)module
{
    [self connectTo:(MinewModule *)module];
}

// disconnect from a module
- (void)disconnect:(MinewModule *)module
{
    [self disconnectFrom:(MinewModule *)module];
}


#pragma mark **************************************Bluetooth delegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (_scanning && central.state == CBManagerStatePoweredOn)
        [self startScan];
    
    if ([self.delegaate respondsToSelector:@selector(manager:didChangeBluetoothStatus:)])
    {
        [MinewCommonTool onMainThread:^{
            [self.delegaate manager:self didChangeBluetoothStatus:central.state == CBManagerStatePoweredOn? BluetoothStatusPowerOn:(central.state == CBManagerStatePoweredOff? BluetoothStatusPowerOff: BluetoothStatusUnknown)];
        }];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"还在持续扫描");
    
    NSString *name = peripheral.name;
    
    NSString *adName = advertisementData[CBAdvertisementDataLocalNameKey];
    
    if ([adName isEqualToString:@"HToy"])
    {

        MinewModule *module = [self moduleExist:peripheral.identifier.UUIDString];
        
        if (!module)
        {
            module = [[MinewModule alloc]init];
            module.peripheral = peripheral;
            
            [_appearModules addObject:module];
            [_scannedModules addObject:module];
            
            module.isBind = NO;
//            //扫描到就绑定，默认全部绑定
//            if (_bindModulesDict.count <= MAX_DEVICE) {
//                module.isBind = YES;
//                [self addBindModule:module];
//            }

            
            if ([self.delegaate respondsToSelector:@selector(manager:appearModules:)])
                [MinewCommonTool onMainThread:^{
                    [self.delegaate manager:self appearModules:_appearModules];
                }];
            NSLog(@"开始添加设备");
        }

       module.inRange = YES;
       module.name = adName? adName:( name? name: @"Unnamed");
       module.rssi = [RSSI integerValue];
        
        NSData *data = advertisementData[CBAdvertisementDataManufacturerDataKey];
        module.manufactureData = data;
    
        NSLog(@"收到的数据====%@",advertisementData);
        if (self.findDevice) {
            self.findDevice(module);
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    MinewModule *module = _connectingModuleDict[peripheral.identifier.UUIDString];;
    
    if (module)
    {
        if (module.activeDisconnect)
            module.activeDisconnect = NO;
        else
        {
            [module didDisconnect];
            [self callBack:module connect:LinkStatusDisconnect];
        }
        
        [_connectingModuleDict removeObjectForKey:peripheral.identifier.UUIDString];
    }
    else
        NSLog(@"The manager did disconnect from a unknown peripheral.");
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    MinewModule *module = _connectingModuleDict[peripheral.identifier.UUIDString];
    
    if (module)
    {
        [module didConnectFailed];
        [self callBack:module connect:LinkStatusConnectFailed];
        
        [_connectingModuleDict removeObjectForKey:peripheral.identifier.UUIDString];
    }
    else
        NSLog(@"The manager did fail to connect a unknown peripheral.");
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    MinewModule *module = _connectingModuleDict[peripheral.identifier.UUIDString];
    
    if (module)
    {
        [module didConnect];
        [self callBack:module connect:LinkStatusConnected];
        
    }
    else
    {
        NSLog(@"The manager did connect a unkonwn peripheral.");
        [_centralManager cancelPeripheralConnection:peripheral];
    }
}



#pragma mark ***************************************module handler
- (void)connectTo:(MinewModule *)module
{
    if (module.peripheral)
    {
        module.connecting = YES;
        [_connectingModuleDict setValue:module forKey:module.UUID];
        
        [self callBack:module connect:LinkStatusConnecting];
        [_centralManager connectPeripheral:module.peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: @YES}];
    }
    else
        NSLog(@"the give beacon didn't have a peripheral instance, can't connect.");
}

- (void)disconnectFrom:(MinewModule *)module
{
    if ( module.peripheral)
    {
        module.activeDisconnect = YES;
        [_centralManager cancelPeripheralConnection:module.peripheral];
    }
    else
        NSLog(@"the given beacon didn't have a peripheral instance, can't disconnect.");
}


- (MinewModule *)moduleExist:(NSString *)uuid
{
    
    for ( NSInteger i = 0; i < _scannedModules.count; i ++)
    {
        MinewModule *module = _scannedModules[i];
        if ([module.UUID isEqualToString:uuid])
            return module;
    }
    
    return nil;
}

- (void)handleModules
{
    // handle disappear beacons
    static BOOL disappearHandling = NO;
    if ( !disappearHandling)
    {
        static NSInteger count = 0;
        
        if ( count > 8)
        {
            disappearHandling = YES;
            
            NSArray *moduleArray = _scannedModules;
            NSMutableArray *disappearmodules = [[NSMutableArray alloc]init];
            
            for ( NSInteger i = 0; i < moduleArray.count; i ++)
            {
                MinewModule *module = moduleArray[i];
                
                NSTimeInterval interval = [module.updateTime timeIntervalSinceNow];
                
                if ( interval < -10)
                {
                    module.inRange = NO;
                    [disappearmodules addObject:module];
                }
            }
            
            if ( disappearmodules.count && [self.delegaate respondsToSelector:@selector(manager:disappearModules:)])
            {
                [MinewCommonTool onMainThread:^{
                    [self.delegaate manager:self disappearModules:disappearmodules];
                }];
            }
            
            disappearHandling = NO;
            count = -1;
        }
        count ++;
    }
    
    
    // handle appear beacons
//    static BOOL appearHandling = NO;
//    if (!appearHandling)
//    {
//        
//        static NSInteger count = 0;
//        if (count > 3)
//        {
//            appearHandling = YES;
//            
//            if ( _appearModules.count&& _appearModules)
//            {
//                [CommonTool onMainThread:^{
//                    _appearModulesBlock(_appearModules);
//                }];
//            }
//            
//            [_appearModules removeAllObjects];
//            appearHandling = NO;
//            count = -1;
//        }
//        count ++;
//    }
//    
//    
//    if ( _scannedModules.count && _scannedModulesBlock)
//    {
//        [CommonTool onMainThread:^{
//            _scannedModulesBlock(_scannedModules);
//        }];
//        
//    }
}


- (void)callBack:(MinewModule *)module connect:(LinkStatus)status
{
    if ([self.delegaate respondsToSelector:@selector(manager:didChangeModule:linkStatus:)])
    {
       [MinewCommonTool onMainThread:^{
           [self.delegaate manager:self didChangeModule:module linkStatus:status];
       }];
    }
}


@end
