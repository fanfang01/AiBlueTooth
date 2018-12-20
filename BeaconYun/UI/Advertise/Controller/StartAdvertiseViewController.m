//
//  StartAdvertiseViewController.m
//  BeaconYun
//
//  Created by 樊芳 on 2018/12/3.
//  Copyright © 2018 MinewTech. All rights reserved.
//

#import "StartAdvertiseViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "AdvertiseView.h"
#import "MTPeripheralManager.h"
#import "WakeUpManager.h"
#import "RecognizeManager.h"
#import "MinewModuleManager.h"
#import "MinewModule.h"

//定义广播数据的结构体
struct MyAdvDtaModel {
    uint8_t fixedContent[2];
    uint8_t productType;
    uint8_t command_id;
    uint8_t key;
    uint8_t event_id;
    uint16_t values;
};

//BDRecognizerViewDelegate

@interface StartAdvertiseViewController ()
@property (nonatomic, strong) AdvertiseView *advertiseView;

//中文唤醒
@property (nonatomic, strong) NSMutableArray *commandAray;

//英文指令
@property (nonatomic, strong) NSMutableArray *enCommandAray;

@property (nonatomic, strong) MTPeripheralManager *pm;

@property (nonatomic, strong) WakeUpManager *wakeupManager;

@property (nonatomic, strong) RecognizeManager *recognizeManager;

@property (nonatomic, strong) MinewModuleManager *minewManager;
@property (nonatomic, strong) NSMutableArray *uuidArray;
@end

@implementation StartAdvertiseViewController
{
    BOOL _is_on;//记录开关的状态

    NSTimer *_advTimer;//

    NSInteger _countDownTime;//用于广播几秒后停止的倒计时
    
    NSInteger _currentTime;//记录当前广播了多久了;
    NSInteger _currentIndex;//配合语音部分的使用
    
    NSTimer *_advCouplesTimer;
    NSInteger _couplesTimeCount;
}

static NSInteger count = 0;

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    //退出页面，停止广播
    [_pm stopAdvertising];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"开始操作";
    
    _is_on = NO;// 默认机器是关机状态
    //设定5秒后停止广播
    _countDownTime = 5;
    _currentTime = 0;
    _currentIndex = 0;//default 当前选中的模式
    
    [self initData];

    MTPeripheralManager *pm = [MTPeripheralManager sharedInstance];
    _pm = pm;
    _minewManager = [MinewModuleManager sharedInstance];
    
    [self initView];
    
    [self wakeupConfiguration];
//    [self recognizeConfiguration];

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
}

- (void)wakeupConfiguration {
    _wakeupManager = [WakeUpManager sharedInstance];
    
    [_wakeupManager startWakeup];
    
    __weak StartAdvertiseViewController *weakSelf = self;
    _wakeupManager.voiceWakeUp = ^(NSString * _Nonnull keywords) {
        
        __strong StartAdvertiseViewController *strongSelf = weakSelf;
        
        [strongSelf voiceToAdvertise:keywords];
        
    };
}

- (void)recognizeConfiguration {
    _recognizeManager = [RecognizeManager sharedInstance];
    __weak StartAdvertiseViewController *weakSelf = self;
    
    _recognizeManager.voiceReco = ^(NSString * _Nonnull voice) {
        __strong StartAdvertiseViewController *strongSelf = weakSelf;
        [strongSelf voiceToRecognize:voice];
    };
}

- (void)applicationDidBecomeActive {
    [_wakeupManager startWakeup];
}

- (void)applicationDidEnterBackground {
    NSLog(@"进入后台");
}

- (void)initData {
    if (!_uuidArray) {
        _uuidArray = [NSMutableArray array];
    }
   
    if (!_commandAray) {
        _commandAray = [NSMutableArray arrayWithObjects:
                        @{@"key":@"模式1"},
                        @{@"key":@"模式2"},
                        @{@"key":@"模式3"},
                        @{@"key":@"模式4"},
                        @{@"key":@"模式5"},
                        @{@"key":@"模式6"},
                        @{@"key":@"模式7"},
                        @{@"key":@"模式8"},
                        @{@"key":@"模式9"},
                        @{@"key":@"模式10"},
                        @{@"key":@"快点快点"},
                        @{@"key":@"慢点慢点"},
                        @{@"key":@"小康你好"}
                        ,nil];
    }
    if (!_enCommandAray) {
        _enCommandAray = [NSMutableArray arrayWithObjects:@{@"key":@[@"quick",@"fast",@"increase"]},@{@"key":@[@"slow"]},@{@"key":@[@"power on"]},@{@"key":@[@"power off"]} ,@{@"key":@[@"power on"]} ,nil];
    }
}

- (void)initView {
    
    UIImageView *backImg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    backImg.image = [[UIImage imageNamed:@"all_background"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.view addSubview:backImg];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.advertiseView];
    
}


- (AdvertiseView *)advertiseView
{
    if (!_advertiseView) {
        _advertiseView = [[AdvertiseView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
        
        __weak StartAdvertiseViewController *weakSelf = self;
        _advertiseView.buttonBlock = ^(NSInteger index) {
            __strong StartAdvertiseViewController *strongSelf = weakSelf;
            
            _currentIndex = index;
            
            [strongSelf sendData:index];
        };
        [_advertiseView.onSwitch addTarget:self action:@selector(switchOnOff:) forControlEvents:UIControlEventValueChanged];
    }
    return _advertiseView;
}

#pragma mark -- 发送广播数据
- (void)sendData:(NSInteger)index {
    [self stopTimer];
    
    count ++;
    if (count > 255) {
        count = 0;
    }
    [_uuidArray removeAllObjects];
    for (MinewModule *module in _minewManager.bindModules) {
        NSMutableData *cmdData = [NSMutableData dataWithCapacity:0];
        
        struct MyAdvDtaModel adv = {0,0,0,0,0,0};
        adv.fixedContent[0] = 171;
        adv.fixedContent[1] = 172;
        adv.productType = 16;
        
        adv.command_id = 1;
        adv.key = index+1;
        adv.event_id = count;
        adv.values = module.macBytes;
        
        if (index < 12) {
            _is_on = YES;
            [self.advertiseView.onSwitch setOn:YES];
        }
        
        if (12 == index) {//为开关机的状态
            if (_is_on) {//开机信息
                adv.key = _currentIndex+1;
                self.advertiseView.selectedIndex = _currentIndex;
            }else {      //关机信息
                adv.key = 16;
                self.advertiseView.selectedIndex = -1;
            }
        }
        //    else if (10 == index) {//处理增大强度模式
        //        adv.key = 18;
        //    }else if (11 == index) {//处理减小强度模式
        //        adv.key = 19;
        //    }
        
        NSString *str = [NSString stringWithFormat:@"%02x%02x-%02x%02x%02x%02x%04x",adv.fixedContent[0],adv.fixedContent[1],adv.productType,adv.command_id,adv.key,adv.event_id,adv.values];
        [cmdData appendData:[str dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSString *string = [[NSString alloc] initWithData:cmdData encoding:NSUTF8StringEncoding];
        NSString *advString = [@"00000000-aff4-0085-" stringByAppendingString:string];
        NSLog(@"开始广播=%@",advString);
        
        CBUUID *newUuid = [CBUUID UUIDWithString:advString];
        [_uuidArray addObject:newUuid];
    }
    
    NSLog(@"uuid的数组大小为:%ld",_uuidArray.count);
    [self advertiseCouplesOfUUIDs];
    

    
    [self startAdvTimer];
    
}

- (void)advertiseCouplesOfUUIDs {
    [self startCouplesTimer];
}

- (void)startCouplesTimer {
    _couplesTimeCount = 0;
    _advCouplesTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(couplesAdvStart) userInfo:nil repeats:YES];
}

- (void)couplesAdvStart {
    NSInteger count = _uuidArray.count;
    static NSInteger i = 0;
    if (count == i) {
        i = 0;
    }else{
        _pm.advUUID = [_uuidArray objectAtIndex:i];
        [_pm startAdvtising];
        NSLog(@"i的大小==%ld",i);
        i ++;
    }
}

- (void)stopCouplesTimer {
    [_advCouplesTimer invalidate];
    _advCouplesTimer = nil;
}

#pragma mark -- 获取设备的信息
- (void)getDeviceInfo {
    //0x21
    [self sendData:33];
}

#pragma mark --- 语音发送广播
//后续 还可以更精准一点过滤   语音发送广播
- (void)voiceToAdvertise:(NSString *)key {
    NSMutableArray *keyArr = [self getALLKeys];
    NSString *recordKey = @"";
    for (NSString *okey in keyArr) {
        if ([okey containsString:key] || [key containsString:okey]) {
            recordKey = okey;
            NSInteger index = [keyArr indexOfObject:recordKey];
            if (index >= 0) {
                //开始广播
//                _currentIndex = index;
                if (index == 10) {//fast //发送的是当前的模式
                    _currentIndex ++;
                    self.advertiseView.selectedIndex = _currentIndex;
                    [self sendData:_currentIndex];
                    break;
                }else if (index == 11) {//slow //发送的是当前的模式
                    if (_currentIndex>0) {
                        _currentIndex --;
                        self.advertiseView.selectedIndex = _currentIndex;
                        [self sendData:_currentIndex];
                        break;
                    }
                }else if (index == 12) {
                    _is_on = !_is_on;
                    [self.advertiseView.onSwitch setOn:_is_on];
                }
                [self sendData:index];

                break;
            }
            
        }
    }
}

//voice recognize 发送指令
- (void)voiceToRecognize:(NSString *)key {
    NSString *recordKey = @"";
    for (NSInteger i =0; i<_enCommandAray.count; i++) {
        NSArray *array = _enCommandAray[i][@"key"];
        for (NSString *okey in array) {
            if ([okey containsString:key] || [key containsString:okey]) {
                recordKey = okey;
                NSInteger index = [array indexOfObject:recordKey];
                if (index >= 0) {
                    //开始广播
                    //                _currentIndex = index;
                    if (index == 0) {//fast //发送的是当前的模式
                        _currentIndex ++;
                        self.advertiseView.selectedIndex = _currentIndex;
                        [self sendData:_currentIndex];
                        break;
                    }else if (index == 1) {//slow //发送的是当前的模式
                        if (_currentIndex>0) {
                            _currentIndex --;
                            self.advertiseView.selectedIndex = _currentIndex;
                            [self sendData:_currentIndex];
                            break;
                        }
                    }else if (index == 2) {//off
                        _is_on = !_is_on;
                        [self.advertiseView.onSwitch setOn:_is_on];
                        [self sendData:10];
                        break;
                    }else if (3 == index) {//on
                        _is_on = !_is_on;
                        [self.advertiseView.onSwitch setOn:_is_on];
                        [self sendData:11];
                    }
                    
                    break;
                }
                
            }
        }
    }
}



- (NSMutableArray *)getALLKeys {
    NSMutableArray *tempArr = [NSMutableArray array];
    for (NSDictionary *dic in _commandAray) {
        NSString *str = dic[@"key"];
        [tempArr addObject:str];
    }
    return tempArr;
}

#pragma mark -- Timer
- (void)startAdvTimer {
    if (!_advTimer) {
        _advTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startCountTimer) userInfo:nil repeats:YES];
    }
}

- (void)startCountTimer {
    if (_currentTime < _countDownTime ) {
        _currentTime ++;
        NSLog(@"广播还在继续");
    }else {
        [self stopTimer];
    }
}

- (void)stopTimer {
    [self.pm stopAdvertising];
    _currentTime = 0;
    [_advTimer invalidate];
    _advTimer = nil;
    
    
    [self stopCouplesTimer];
    NSLog(@"广播已经停止");
}

- (void)switchOnOff:(UISwitch *)sw {
    _is_on = sw.on;
    NSLog(@"开关的状态：sw.isOn==%d  _is_on==%d",sw.isOn,_is_on);
    [self sendData:12];
}
@end
