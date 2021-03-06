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
@property (nonatomic, strong) NSMutableArray *disappearModules;
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
    NSInteger _scanTime;
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
    _disappearModules = [NSMutableArray array];
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
    
    //特定在子线程刷新
    _bluetoothQueue = dispatch_queue_create("com.ask.tech", DISPATCH_QUEUE_SERIAL);
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

//config global for scan and deal with disappear modules
- (void)initializeTimer
{
    if ( !_timer)
    {
        _timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(handleModules) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
        [_timer fire];
    }
}

- (void)stopTimer {
    [_timer invalidate];
    _timer = nil;
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
    [stand synchronize];
    
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
    [stand synchronize];
}

- (void)removeAllBindModules {
    
    NSUserDefaults *stand = [NSUserDefaults standardUserDefaults];
    
    [stand removeObjectForKey:BIND_DATA];
    [_bindModulesDict removeAllObjects];
    
    [stand synchronize];
}

#pragma mark ******************************** Public
- (void)startScan
{
    _scanning = YES;
    
    //开这个定时器，运行在setting 程序会卡顿，setting有1s的实时页面刷新操作。来回存储设备信息，或者前后台进入 会卡顿
    //这个，全程扫描、全程监测有没有在范围内、全程5s重新扫描，清楚之前已经扫描到的设备。
    [self initializeTimer];
    [_scannedModules removeAllObjects];
    
    //指定扫描特定的服务
//    CBUUID *uuid1 = [CBUUID UUIDWithString:@"FFF0"];
//    NSArray *uuidArr = @[uuid1];
    
    [MinewCommonTool onThread:_bluetoothQueue execute:^{
        [_centralManager scanForPeripheralsWithServices:nil options:@{ CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
    }];
}

- (void)stopScan
{
    [_scannedModules removeAllObjects];
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
    NSLog(@"开始连接%@",module.peripheral);
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
//    NSLog(@"还在持续扫描");
    
    NSString *name = peripheral.name;
    
    NSString *adName = advertisementData[CBAdvertisementDataLocalNameKey];
    NSString *connectable = advertisementData[CBAdvertisementDataIsConnectable];
    NSData *manufactureData = advertisementData[CBAdvertisementDataManufacturerDataKey];
    Byte *testByte = (Byte *)[manufactureData bytes];
//    NSLog(@"advertisementDat==%@",advertisementData);
    if ( manufactureData.length >= 8 ) {
        uint8_t validate = testByte[1];
        if (validate >=160 && validate <=207) {
//            NSLog(@"在此范围内....");
            //简单的测试
            if (validate == 160) {
                _isDexinProduct = YES;
                
            }
        }else {
            return ;
        }
        uint16_t macBytes = 0;
        NSString *macString = @"";
        NSString *headString = @"";
        if ([manufactureData length]) {
            NSString *dataString = [MinewCommonTool getDataString:manufactureData];
            macString = [dataString substringWithRange:NSMakeRange(4, dataString.length-4)];
            headString = [dataString substringWithRange:NSMakeRange(0, 2)];
            Byte *testByte = (Byte *)[manufactureData bytes];
            
            for (NSInteger i=2; i < [manufactureData length] ; i++) {
                macBytes += testByte[i];
            }
        }
        NSInteger sum = [[MinewCommonTool numberHexString:[NSString stringWithFormat:@"%02x",macBytes%256]] integerValue];
//        NSLog(@"testByte[0] == %ld macBytes=%02x sum=%ldmodule.macString=%@",testByte[0],macBytes%256,sum, macString);

        if (sum == testByte[0]) {
            if ( [GlobalManager sharedInstance].connectState == ConnectStateAdvertise) {
                return;
            }
            [GlobalManager sharedInstance].connectState = ConnectStateBLE;

            NSLog(@"校验成功...");
            MinewModule *module = [self moduleExist:peripheral.identifier.UUIDString];
            if (!module) {
                module = [[MinewModule alloc] init];
                [_appearModules addObject:module];
                [_scannedModules addObject:module];
            }
            module.productNumber = validate;
            module.macBytes = macBytes;
            module.macString = macString;
            module.canConnect = [connectable boolValue];
            module.peripheral = peripheral;
            module.name = adName? adName:( name? name: @"Unnamed");
            module.updateTime = [NSDate date];
            [_appearModules addObject:module];
            if (self.findDevice) {
                self.findDevice(module);
            }

        }
        
//        NSLog(@"ble的返回数据===%@",advertisementData);
    }
    
    if ([adName isEqualToString:@"HToy"])
    {
        if ([GlobalManager sharedInstance].connectState == ConnectStateBLE) {
            return ;
        }
        MinewModule *module = [self moduleExist:peripheral.identifier.UUIDString];
        module.canConnect = [connectable boolValue];
        [GlobalManager sharedInstance].connectState = ConnectStateAdvertise;
        if (!module)
        {
            module = [[MinewModule alloc] init];
            module.peripheral = peripheral;
            
            [_appearModules addObject:module];
            [_scannedModules addObject:module];
            
            //default device is not binded
            module.isBind = NO;
            
            //if scanned ,delegate it in a heartbeat.
            if ([self.delegaate respondsToSelector:@selector(manager:appearModules:)])
                [MinewCommonTool onMainThread:^{
                    [self.delegaate manager:self appearModules:_appearModules];
                }];
            NSLog(@"开始添加设备");
        }
        //如果再次扫描到了，
        if ([_disappearModules containsObject:module]) {
            [_disappearModules removeObject:module];
        }
       module.updateTime = [NSDate date];
       module.inRange = YES;
       module.name = adName? adName:( name? name: @"Unnamed");
       module.rssi = [RSSI integerValue];
        
        NSData *data = advertisementData[CBAdvertisementDataManufacturerDataKey];
        module.manufactureData = data;
    
//        NSLog(@"收到的数据====%@",advertisementData);
        if (self.findDevice) {
            self.findDevice(module);
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    MinewModule *module = _connectingModuleDict[peripheral.identifier.UUIDString];
    
    if (module)
    {
        [module didDisconnect];
        [self callBack:module connect:LinkStatusDisconnect];
        
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
    NSLog(@"连接成功%@",module.peripheral);
    if (self.connectedModudels.count == 0) {
        self.firstConnectedModule = module;
        if (self.firstModuleConnect) {
            self.firstModuleConnect(module);
        }
        if (module.productNumber) {
            [MinewCommonTool saveProductNumber:module.productNumber];
        }
//        if (module.productNumber == 160) {
//            [MinewCommonTool saveDexinUserDefault:YES];
//        }else {
//            [MinewCommonTool saveDexinUserDefault:NO];
//        }
//        if (module.productNumber == 161) {
//            [MinewCommonTool saveGaoSongnUserDefault:YES];
//        }
        
    }
    if (![self.connectedModudels containsObject:module]) {
        [self.connectedModudels addObject:module];
    }
    NSLog(@"ble蓝牙设备连接成功.....");
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
    if ( module.peripheral )
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

- (MinewModule *)moduleExistInDisappearModule:(NSString *)macString
{
    
    for ( NSInteger i = 0; i < _scannedModules.count; i ++)
    {
        MinewModule *module = _scannedModules[i];
        if ([module.macString isEqualToString:macString])
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

        if ( count > 3)
        {
            disappearHandling = YES;

            NSArray *moduleArray = _scannedModules;
            [_disappearModules removeAllObjects];

            for ( NSInteger i = 0; i < moduleArray.count; i ++)
            {
                MinewModule *module = moduleArray[i];

                NSTimeInterval interval = [module.updateTime timeIntervalSinceNow];

                if ( interval < -3 && module.peripheral.state != CBPeripheralStateConnected)
                {
                    module.inRange = NO;
                    [_disappearModules addObject:module];
                }
            }

            for (MinewModule *disModule in _disappearModules) {
                [_scannedModules removeObject:disModule];
            }

            if (  [self.delegaate respondsToSelector:@selector(manager:disappearModules:)])
            {
                [MinewCommonTool onMainThread:^{
                    [self.delegaate manager:self disappearModules:_disappearModules];
                }];
            }


            disappearHandling = NO;
            count = -1;
        }
        count ++;
    }

    //设置10s
    if (_scanTime < 5) {
        _scanTime ++;
    }else {
//        [self startScan];
        _scanTime = 0;
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

- (NSArray *)isExisModuleOutofSacnnedModules {
    NSMutableArray *tempArr = [NSMutableArray array];
    
    for (NSInteger i = 0; i < self.bindModules.count; i++) {
        NSDictionary *info = self.bindModules[i];
        
        for (NSInteger j=0; j<_scannedModules.count; j++) {
            MinewModule *module = _scannedModules[j];
            
            if ([info[@"macString"] isEqualToString:module.macString]) {
                break;
            }else {
                if (j == _scannedModules.count-1) {
                    [tempArr addObject:info];
                }
            }
        }
    }
    
    return tempArr;
}

- (NSArray *)advertiseModuleArray {
    NSMutableArray *array = [_scannedModules mutableCopy];
    
    NSArray *tempArr = [self isExisModuleOutofSacnnedModules];
    
    for (NSInteger i = 0; i < tempArr.count; i++) {
        NSDictionary *info = tempArr[i];
        
        for (NSInteger j=0; j<_scannedModules.count; j++) {
            MinewModule *module = _scannedModules[j];
            
            if ([info[@"macString"] isEqualToString:module.macString]) {
                [array removeObject:module];
            }
        }
    }
    
    return array;
}

@end
