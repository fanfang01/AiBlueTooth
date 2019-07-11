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
#import "SettingViewController.h"
#import "MinewModuleApi.h"

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
static NSInteger i = 0;

@interface StartAdvertiseViewController ()

//中文唤醒
@property (nonatomic, strong) NSMutableArray *commandAray;

//英文指令
@property (nonatomic, strong) NSMutableArray *enCommandAray;

@property (nonatomic, strong) MTPeripheralManager *pm;

@property (nonatomic, strong) WakeUpManager *wakeupManager;

@property (nonatomic, strong) RecognizeManager *recognizeManager;

@property (nonatomic, strong) MinewModuleManager *minewManager;

@property (nonatomic, strong) NSMutableArray *uuidArray;//存放需要发送的UUID

@property (nonatomic, strong) MinewModuleAPI *api;

@property (nonatomic, strong) NSMutableArray <MinewModule *>*selectModuleArray;

@property (nonatomic, strong) FLAnimatedImageView *animatedImgView;

@property (nonatomic,assign) BOOL is_on;//记录开关的状态
@end

@implementation StartAdvertiseViewController
{

    NSTimer *_advTimer;//

    NSInteger _countDownTime;//用于广播几秒后停止的倒计时
    
    NSInteger _currentTime;//记录当前广播了多久了;
    NSInteger _currentIndex;//配合语音部分的使用
    
    NSTimer *_advCouplesTimer;
    NSInteger _couplesTimeCount;
    GlobalManager *_globalManager;
    CGFloat _buttonWidth;
}

static NSInteger count = 0;

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    //退出页面，停止广播
    [_pm stopAdvertising];
    
//    [_minewManager disconnect:_testmodule];
    
    //页面消失的时候，尝试去断连
    NSMutableArray *modules = [self allBindArrays];
    for (MinewModule *module in modules) {
        if (module.peripheral.state == CBPeripheralStateConnected) {
            [_minewManager disconnect:module];
        }
    }
    
    [self stopTimer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    
    if (@available(iOS 11.0, *)) {
        UIScrollView.appearance.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    
    //获取设备信息
    [self getDeviceInfo];
    
    [_globalManager initTimer];
    
    if (_globalManager.connectState == ConnectStateBLE) {
        if ([self allBindArrays].count==0) {
            [self showNoDeviceAlert];
        }
    }else if (_globalManager.connectState == ConnectStateAdvertise) {
        [self isExistsBindDevicesToAdvertise];
    }

    
}

#pragma mark --- 判断用户有没有绑定的设备 --- 蓝牙
- (void)isExistsBindDevicesToAdvertise {
    MinewModuleManager *manager = [MinewModuleManager sharedInstance];
    NSArray *bindArray = manager.bindModules;
    
    if (0 == bindArray.count) {
        [self showNoDeviceAlert];
    }
}

- (void)showNoDeviceAlert {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"温馨提示", nil) message:NSLocalizedString(@"你还没有绑定设备，快去绑定吧!", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self startToSetup];
    }];
    
    [alertVC addAction:confirmAction];
    
    [self.navigationController presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark ---- 返回上一个页面
- (IBAction)backLastVC:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark --- 点击按钮
- (IBAction)buttonClick:(UIButton *)sender {
    
    NSInteger index = sender.tag-100;
    _currentIndex = index;
    
    switch (_globalManager.connectState) {
        case ConnectStateBLE:{
            [self bleSendData:index];
            break;
        }
        case ConnectStateAdvertise:{
            [self sendData:index];
            break;
        }
        default:
            break;
    }

}

- (void)addAnimationView:(NSInteger)index button:(UIButton *)button {
    [self.animatedImgView removeFromSuperview];
    
    self.animatedImgView.frame = CGRectMake(0, 0, _buttonWidth, _buttonWidth);
    [button addSubview:self.animatedImgView];
}

#pragma mark --- 跳往设置界面
- (IBAction)settingDevice:(UIButton *)sender {
    [self startToSetup];
}

- (IBAction)onOffAction:(UIButton *)sender {
    self.is_on = !sender.selected;
    
    switch (_globalManager.connectState) {
        case ConnectStateBLE:
        {
            if (_is_on) {
                [self sendPowerOnIns];
            }else {
                [self sendPowerOffIns];
            }
        }
            break;
        case ConnectStateAdvertise:
        {
            [self sendData:12];
        }
            break;
        default:
            break;
    }
}

- (void)setIs_on:(BOOL)is_on
{
    _is_on = is_on;
    _onOffBtn.selected = _is_on;
}

#pragma mark --- 发送关机和开机的指令
- (void)sendPowerOnIns {
    //加载GIF动画
    UIButton *button = [self.view viewWithTag:100+_currentIndex];
    [self addAnimationView:_currentIndex button:button];
    
    struct InstructionSend instruction = {0,0,0,0};
    instruction.Command_id = 3;
    instruction.key = 1;
    instruction.Status = 1;
    instruction.Mode = _currentIndex;
    
    NSString *ins = [NSString stringWithFormat:@"%02x%02x%02x%02x",instruction.Command_id,instruction.key,instruction.Status,instruction.Mode];
    NSMutableArray *tempArray = [self allBindArrays];
//    if (tempArray.count == 0) {
//        [self showNoDeviceAlert];
//    }
    for (MinewModule *module in tempArray) {
        [_api sendData:ins hex:YES module:module completion:^(id result, BOOL keepAlive) {
            
        }];
    }
}

- (void)sendPowerOffIns {
    [self.animatedImgView removeFromSuperview];
    
    struct InstructionSend instruction = {0,0,0,0};
    instruction.Command_id = 3;
    instruction.key = 1;
    instruction.Status = 0;
    instruction.Mode = 1;
    
    NSString *ins = [NSString stringWithFormat:@"%02x%02x%02x%02x",instruction.Command_id,instruction.key,instruction.Status,instruction.Mode];

    NSMutableArray *tempArray = [self allBindArrays];
//    if (tempArray.count == 0) {
//        [self showNoDeviceAlert];
//    }
    for (MinewModule *module in tempArray) {
        [_api sendData:ins hex:YES module:module completion:^(id result, BOOL keepAlive) {
            
        }];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"开始操作", nil);
    
    _is_on = NO;// 默认机器是关机状态
    
    _buttonWidth = 72;
    
    _countDownTime = 5;//设定5秒后停止广播
    _currentTime = 0;
    _currentIndex = 1;//default 当前选中的模式
    
    [self initCore];
    [self initData];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"设置", nil) style:UIBarButtonItemStylePlain target:self action:@selector(startToSetup)];

    [self initView];
    
//    [self.view addSubview:self.animatedImgView];
    
    [self wakeupConfiguration];
//    [self recognizeConfiguration];

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
}

- (void)viewDidLayoutSubviews
{
    if (ScreenHeight >= 812) {//判断是不是iPhoneX max
        
        CGFloat horSpoacing = 28;
        CGFloat verSpacing = 53;
        CGFloat spacing = 53;
        _buttonWidth = (ScreenWidth-horSpoacing*2-spacing*2)/3;
        for (NSInteger i=1; i<=10; i++) {
            UIButton *button = [self.view viewWithTag:100+i];
            button.frame = CGRectMake(horSpoacing+(_buttonWidth+spacing)*((i-1)%3), statusBarHeight+80+(_buttonWidth+verSpacing)*((i-1)/3), _buttonWidth, _buttonWidth);
            if (10 == i) {
                button.frame = CGRectMake(horSpoacing+(_buttonWidth+spacing), statusBarHeight+80+(_buttonWidth+verSpacing)*((i-1)/3), _buttonWidth, _buttonWidth);
                _onOffBtn.frame = CGRectMake(horSpoacing+(_buttonWidth+spacing), statusBarHeight+80+(_buttonWidth+verSpacing)*((i-1+3)/3), _buttonWidth, _buttonWidth);
            }
        }

    }else if (ScreenHeight <= 586) {
        CGFloat horSpoacing = 28;
        CGFloat verSpacing = 23;
        CGFloat spacing = 53;
        _buttonWidth = (ScreenWidth-horSpoacing*2-spacing*2)/3;
        for (NSInteger i=1; i<=10; i++) {
            UIButton *button = [self.view viewWithTag:100+i];
            button.frame = CGRectMake(horSpoacing+(_buttonWidth+spacing)*((i-1)%3), statusBarHeight+80+(_buttonWidth+verSpacing)*((i-1)/3), _buttonWidth, _buttonWidth);
            if (10 == i) {
                button.frame = CGRectMake(horSpoacing+(_buttonWidth+spacing), statusBarHeight+80+(_buttonWidth+verSpacing)*((i-1)/3), _buttonWidth, _buttonWidth);
                _onOffBtn.frame = CGRectMake(horSpoacing+(_buttonWidth+spacing), statusBarHeight+80+(_buttonWidth+verSpacing)*((i-1+3)/3), _buttonWidth, _buttonWidth);
            }
        }
    }
    
    [self.view layoutIfNeeded];
    
    [super viewDidLayoutSubviews];
}

- (void)initCore {
    _api = [MinewModuleAPI sharedInstance];
    _pm = [MTPeripheralManager sharedInstance];
    _minewManager = [MinewModuleManager sharedInstance];
    
    _globalManager = [GlobalManager sharedInstance];
}

//跳往设置界面
- (void)startToSetup {
    
    [self stopTimer];
    
    SettingViewController *setVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"SettingViewController"];
    
    [self.navigationController pushViewController:setVC animated:YES];
    
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
        if ([[MinewCommonTool getCurrentLanguage] containsString:@"zh"]) {
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
                            @{@"key":@"小爱你好"}
                            ,nil];
        }else {
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
                            @{@"key":@"逼溃克离"},
                            @{@"key":@"逼斯喽离"},
                            @{@"key":@"哈喽哈尼"}
                            ,nil];
        }
    }
    
}

- (void)initView {
 
    
    [_onOffBtn setImage:[UIImage imageNamed:@"switch_off"] forState:UIControlStateNormal];
    [_onOffBtn setImage:[UIImage imageNamed:@"switch_on"] forState:UIControlStateSelected];
    
    
    
    
//    self.view.backgroundColor = [UIColor colorWithPatternImage:[[UIImage imageNamed:@"bg"] imageWithRenderingMode:UIImageRenderingModeAutomatic]];
    
    //设置渐变色
    CAGradientLayer *gradient = [CAGradientLayer layer];
    //设置开始和结束位置(设置渐变的方向)
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(0, 1);
    gradient.frame = CGRectMake(0,0,ScreenWidth,ScreenHeight);
    gradient.colors = [NSArray arrayWithObjects:(id)RGB(156, 100, 183).CGColor,(id)RGB(124, 71, 170).CGColor,(id)RGB(107, 55, 162).CGColor,(id)RGB(86, 35, 153).CGColor,nil];
//    [self.view.layer insertSublayer:gradient atIndex:0];
    
//    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
//    imgView.image = [UIImage imageNamed:@"bg"];
//
//    [self.view addSubview:imgView];
//    [self.view insertSubview:imgView belowSubview:_bakImgView];
    
    _bakImgView.image = [UIImage imageNamed:@""];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[[UIImage imageNamed:@"bg_bg"] imageWithRenderingMode:UIImageRenderingModeAutomatic]];
    
}

//test 剔除不在范围内的 Module
- (NSMutableArray *)allInBoundsModules {
    NSMutableArray *allBindArr = [NSMutableArray arrayWithArray:_minewManager.bindModules];
    //test 剔除不在范围内的 Module
    NSArray *outOfBoundsArr = [_minewManager isExisModuleOutofSacnnedModules];
    [allBindArr removeObjectsInArray:outOfBoundsArr];
    return allBindArr;
}

#pragma mark ---- ble模式发送数据
- (void)bleSendData:(NSInteger)index {
    
    NSLog(@"当前作用的是第%ld",index);
    self.is_on = YES;
    UIButton *sender = [self.view viewWithTag:100+index];
    [self addAnimationView:index button:sender];

    struct InstructionSend instruction = {0,0,0,0};
    instruction.Command_id = 3;
    instruction.key = 1;
    instruction.Status = 1;
    instruction.Mode = index;
    
    NSString *ins = [NSString stringWithFormat:@"%02x%02x%02x%02x",instruction.Command_id,instruction.key,instruction.Status,instruction.Mode];
//      单个设备发送指令....
//    [_api sendData:ins hex:YES module:_testmodule completion:^(id result, BOOL keepAlive) {
//
//    }];
    
    //多个设备发送指令....
    NSMutableArray *tempArray = [self allBindArrays];
    
    for (MinewModule *module in tempArray) {
        [_api sendData:ins hex:YES module:module completion:^(id result, BOOL keepAlive) {
            
        }];
    }
}

- (NSMutableArray *)allBindArrays {
    NSMutableArray *tempArray = [NSMutableArray array];
    //找到目前所有的已经绑定的设备
    for (NSDictionary *info in _minewManager.bindModules) {
        NSString *macString = info[@"macString"];
        MinewModule *module = [self isExistsModuleInScannedList:macString];
        if (module) {
            [tempArray addObject:module];
        }
    }
    return tempArray;
}

//在绑定的队列里，是否存在在扫描的队列里
- (MinewModule *)isExistsModuleInScannedList:(NSString *)macString {
    for (MinewModule *module in _minewManager.allModules) {
        if ([module.macString isEqualToString:macString]) {
            return module;
        }
    }
    
    return nil;
}

#pragma mark -- 发送广播数据
- (void)sendData:(NSInteger)index {
    
    if (index <= 10) {
        UIButton *button = [self.view viewWithTag:100+index];
        [self addAnimationView:index button:button];
    }
    
    [self isExistsBindDevicesToAdvertise];

    [self stopTimer];
    
    count ++;
    if (count > 255) {
        count = 0;
    }
    [_uuidArray removeAllObjects];
    
    NSMutableArray *allBindArr = [NSMutableArray arrayWithArray:_minewManager.bindModules];
    
    NSArray *outOfBoundsArr = [_minewManager isExisModuleOutofSacnnedModules];
    [allBindArr removeObjectsInArray:outOfBoundsArr];
    
    for (NSDictionary *info in allBindArr) {
        NSMutableData *cmdData = [NSMutableData dataWithCapacity:0];
        
        struct MyAdvDtaModel adv = {0,0,0,0,0,0};
        adv.fixedContent[0] = 171;
        adv.fixedContent[1] = 172;
        adv.productType = 16;
        
        adv.command_id = 1;
        adv.key = index;
        adv.event_id = count;
        adv.values = [info[@"macByte"] intValue];
        
        if (index < 12) {
            self.is_on = YES;
        }
        
        if (12 == index) {//为开关机的状态
            if (_is_on) {//开机信息
                adv.key = _currentIndex;
                UIButton *button = [self.view viewWithTag:100+_currentIndex];
                [self addAnimationView:index button:button];
            }else {      //关机信息
                adv.key = 16;
                [self.animatedImgView removeFromSuperview];
            }
        }
        
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

#pragma mark -- 获取设备的信息
- (void)getDeviceInfo {
    //0x21
    struct InstructionSend instruction = {0,0,0,0};
    instruction.Command_id = 2;
    instruction.key = 2;
    instruction.Status = 0;
    instruction.Mode = 0;
    
    NSString *ins = [NSString stringWithFormat:@"%02x%02x%02x%02x",instruction.Command_id,instruction.key,instruction.Status,instruction.Mode];
    [_api sendData:ins hex:YES module:_testmodule completion:^(id result, BOOL keepAlive) {
        
    }];
}

#pragma mark --- 语音发送广播
//后续 还可以更精准一点过滤   语音发送广播
- (void)voiceToAdvertise:(NSString *)key {
    
    if ([key isEqualToString:@"小爱你好"] || [key isEqualToString:@"哈喽哈尼"]) {
        self.is_on = !_is_on;
        if (_globalManager.connectState == ConnectStateBLE) {
            if (_is_on) {
                [self sendPowerOnIns];
            }else {
                [self sendPowerOffIns];
            }
        }else if (_globalManager.connectState == ConnectStateAdvertise){
            [self sendData:12];
        }
        if ([key isEqualToString:@"哈喽哈尼"] ) {
            [SVProgressHUD showSuccessWithStatus:@"Hello honey!"];
        }else {
            [SVProgressHUD showSuccessWithStatus:key];
        }
    }else if ([key isEqualToString:@"快点快点"] || [key isEqualToString:@"逼溃克离"]) {
        if (_currentIndex >= 10) {
            [SVProgressHUD showSuccessWithStatus:@"已经是最大了"];
        }else {
            _currentIndex ++;
        }
        if (_globalManager.connectState == ConnectStateBLE) {
            [self bleSendData:_currentIndex];
        }else if (_globalManager.connectState == ConnectStateAdvertise) {
            [self sendData:_currentIndex];
        }
        if ([key isEqualToString:@"逼溃克离"] ) {
            [SVProgressHUD showSuccessWithStatus:@"Be quickly!"];
        }else {
            [SVProgressHUD showSuccessWithStatus:key];
        }
    }else if ([key isEqualToString:@"慢点慢点"] || [key isEqualToString:@"逼斯喽离"]) {
        if (_currentIndex<=1) {
            [SVProgressHUD showSuccessWithStatus:@"已经最小了"];
        }else {
            _currentIndex --;
        }
        if (_globalManager.connectState == ConnectStateBLE) {
            [self bleSendData:_currentIndex];
        }else if (_globalManager.connectState == ConnectStateAdvertise) {
            [self sendData:_currentIndex];
        }
        if ([key isEqualToString:@"逼斯喽离"] ) {
            [SVProgressHUD showSuccessWithStatus:@"Be slowly!"];
        }else {
            [SVProgressHUD showSuccessWithStatus:key];
        }
    }
}

#pragma mark --- 发送指令
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
                        if (_globalManager.connectState == ConnectStateBLE) {
                            [self bleSendData:_currentIndex];
                        }else if (_globalManager.connectState == ConnectStateAdvertise) {
                            [self sendData:_currentIndex];
                        }
                        break;
                    }else if (index == 1) {//slow //发送的是当前的模式
                        if (_currentIndex>0) {
                            _currentIndex --;
                            if (_globalManager.connectState == ConnectStateBLE) {
                                [self bleSendData:_currentIndex];
                            }else if (_globalManager.connectState == ConnectStateAdvertise) {
                                [self sendData:_currentIndex];
                            }
                            break;
                        }
                    }else if (index == 2) {//off
                        self.is_on = !_is_on;
//                        [self.advertiseView.onSwitch setOn:_is_on];
                        if (_globalManager.connectState == ConnectStateBLE) {
                            [self sendPowerOffIns];
                        }else if (_globalManager.connectState == ConnectStateAdvertise) {
                            [self sendData:12];
                        }
                        break;
                    }else if (3 == index) {//on
                        self.is_on = !_is_on;
                        if (_globalManager.connectState == ConnectStateBLE) {
                            [self sendPowerOnIns];
                        }else if (_globalManager.connectState == ConnectStateAdvertise) {
                            [self sendData:11];
                        }
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

#pragma mark -- 广播总时长的Timer 倒计时
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

#pragma mark --- 多个设备广播的情况
- (void)startCouplesTimer {
    _couplesTimeCount = 0;
    _advCouplesTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(couplesAdvStart) userInfo:nil repeats:YES];
}

- (void)couplesAdvStart {
    NSInteger count = _uuidArray.count;
    if (count == i) {
        i = 0;
    }else {
        _pm.advUUID = [_uuidArray objectAtIndex:i];
        [_pm startAdvtising];
        NSLog(@"i的大小==%ld",i);
        i ++;
    }
}

- (void)stopCouplesTimer {
    i = 0; //每次恢复成0，每次保证从0开始。 又一次测试的崩溃，原因可能在此

    [_advCouplesTimer invalidate];
    _advCouplesTimer = nil;
}

#pragma mark --- 加载GIF动画
- (FLAnimatedImageView *)animatedImgView
{
    if (!_animatedImgView) {
        FLAnimatedImageView *imgView = [[FLAnimatedImageView alloc] initWithFrame:CGRectMake(0, 0, _buttonWidth, _buttonWidth)];
        _animatedImgView = imgView;
//        imgView.backgroundColor = [UIColor redColor];
        imgView.contentMode = UIViewContentModeScaleAspectFit;
        NSString * bundlePath = [[ NSBundle mainBundle] pathForResource:@"Animation" ofType:@"bundle"];
        NSString *imgPath= [bundlePath stringByAppendingPathComponent:[NSString stringWithFormat:@"test.gif"]];
        NSData *imageData = [NSData dataWithContentsOfFile:imgPath];
        imgView.animatedImage = [FLAnimatedImage animatedImageWithGIFData:imageData];
    }
    return _animatedImgView;
}
@end
