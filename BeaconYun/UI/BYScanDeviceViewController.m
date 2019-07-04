//
//  BYScanViewController.m
//  BeaconYun
//
//  Created by SACRELEE on 2/24/17.
//  Copyright © 2017 MinewTech. All rights reserved.
//

#import "BYScanDeviceViewController.h"
#import "BYCommonMacros.h"
#import "BYCommonTools.h"
#import "MinewModuleManager.h"
#import "MinewModule.h"
#import "MinewModuleAPI.h"
#import "BYInfoViewController.h"

#import "MTPeripheralManager.h"
#import "AdvertiseView.h"
#import "StartAdvertiseViewController.h"


#define INTERVAL_KEYBOARD 0

@interface BYScanDeviceViewController ()<MinewModuleManagerDelegate,UITextFieldDelegate,CAAnimationDelegate>

@property (nonatomic, strong) MinewModuleManager *manager;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) NSArray *moduleArray;

@property (nonatomic, strong) UIView *noneDeviceView;

@property(nonatomic,strong) NSMutableArray *tempArr ;//存放当前扫描到的设备

@property (nonatomic, strong) UILabel *showLabel;

@end

// iPhone bind device mac Address
@implementation BYScanDeviceViewController
{
    NSString *_testString;
    NSString *_deviceName;
    UIImageView *_scanBGImageView;
    UILabel *_titleLabel;
    MinewModule *_testModule;
    GlobalManager *_globalManager;
    NSTimer *_enterTimer;
    NSInteger _enterTimeCount;
}

static NSInteger scanCount;
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    scanCount = 0;
//    [self initGUI];
    [self initCore];
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchDownToSearchDevice)];
    [self.searchView addGestureRecognizer:tapGes];
    
    self.view.backgroundColor = RGB(140, 90, 161);
//    self.view.backgroundColor = RGB(223, 217,148);
    
    //add notification for keyBoard
//    [self addNoticeForKeyboard];
    

}

- (void)initEnterTimer {
    if (!_enterTimer) {
        _enterTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countDownTimeCount) userInfo:nil repeats:YES];
    }
}

- (void)countDownTimeCount {
    _enterTimeCount ++;
}

- (void)invalidateTimer {
    _enterTimeCount = 0;
    
    [_enterTimer invalidate];
    _enterTimer = nil;
}

- (void)touchDownToSearchDevice {
    scanCount = 0;
    [self startToScan];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (scanCount != 0) {
        [_manager stopScan];
        NSLog(@"全部停止扫描....");
        _showLabel.text = NSLocalizedString(@"请点击上方按钮开始扫描", nil);
    }
    scanCount = 0;
    //在设置页面代理被设置到那里了，这里接受不到连接成功的回调
    _manager.delegaate = self;
    NSLog(@"viewDidAppear设备再次出现scanCount==%ld",scanCount);
    
    [_globalManager invalidateTimer];
    
    NSMutableArray *tempArray = [self allBindArrays];
    for (MinewModule *module in tempArray) {
        [_manager disconnect:module];
    }
}

- (NSMutableArray *)allBindArrays {
    NSMutableArray *tempArray = [NSMutableArray array];
    //找到目前所有的已经绑定的设备
    for (NSDictionary *info in _manager.bindModules) {
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
    for (MinewModule *module in _manager.allModules) {
        if ([module.macString isEqualToString:macString]) {
            return module;
        }
    }
    
    return nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)initGUI
{

    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    backgroundImageView.image = [UIImage imageNamed:@"all_background"];
    [self.view addSubview:backgroundImageView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 60)];
    _titleLabel = titleLabel;

    titleLabel.center = CGPointMake(ScreenWidth/2, 70);
    titleLabel.text = NSLocalizedString(@"使用前请先打开手机蓝牙", nil);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = COLOR_RGBA(160, 160, 160, 1);
    [self.view addSubview:titleLabel];
    
    UIImageView *scanBGImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    scanBGImageView.userInteractionEnabled = NO;
    scanBGImageView.layer.cornerRadius = 50.;
    scanBGImageView.layer.masksToBounds = YES;
    _scanBGImageView = scanBGImageView;
    scanBGImageView.center = CGPointMake(ScreenWidth/2.0, ScreenHeight/2.0);
    scanBGImageView.image = [UIImage imageNamed:@"scan"];
    [self.view addSubview:scanBGImageView];
    
    UIControl *scanControl = [[UIControl alloc] initWithFrame:scanBGImageView.frame];
    [scanControl addTarget:self action:@selector(startToScan) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:scanControl];
    
    UILabel *showLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, 60)];
    _showLabel = showLabel;
    
    showLabel.center = CGPointMake(scanBGImageView.center.x, ScreenHeight - 160);
    showLabel.numberOfLines = 0;
    showLabel.textAlignment = NSTextAlignmentCenter;
    showLabel.textColor = COLOR_RGBA(160, 160, 160, 1);
    showLabel.font = [UIFont boldSystemFontOfSize:18.0f];
    [self.view addSubview:showLabel];
    showLabel.text = NSLocalizedString(@"请点击上方按钮开始扫描", nil);
}

- (void)startToScan {
    [_manager stopScan];
    [_manager startScan];
    [self scanAction];
    
    [self invalidateTimer];
    [self initEnterTimer];
    
#ifdef debug

#else
#endif
}

#pragma mark --- 动画开始
- (void)scanAction {
    [_scanRoundImgView.layer removeAnimationForKey:@"transform"];
    CAKeyframeAnimation *theAnimation = [CAKeyframeAnimation animation];
    theAnimation.values = [NSArray arrayWithObjects:
                           [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0, 0,0,1)],
                           [NSValue valueWithCATransform3D:CATransform3DMakeRotation(3.13, 0,0,1)],
                           [NSValue valueWithCATransform3D:CATransform3DMakeRotation(6.26, 0,0,1)],
                           nil];
    theAnimation.cumulative = YES;
    theAnimation.duration = 1.5;
    theAnimation.repeatCount = MAXFLOAT;
    theAnimation.removedOnCompletion = YES;
    theAnimation.delegate = self;
    [_scanRoundImgView.layer addAnimation:theAnimation forKey:@"transform"];
    
    _showLabel.text = NSLocalizedString(@"开始扫描", nil);
}

- (void)initCore
{
    _manager = [MinewModuleManager sharedInstance];
    _manager.delegaate = self;
//    [_manager startScan];
    [self startToScan];
    
    _globalManager = [GlobalManager sharedInstance];
    
    __weak BYScanDeviceViewController *weakSelf = self;
    _manager.findDevice = ^(MinewModule *module) {
        __strong BYScanDeviceViewController *strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.showLabel.text = [NSString stringWithFormat:NSLocalizedString(@"扫描到%@", nil),module.name];
            if (!module.canConnect) {//表明是广播蓝牙的设备...
                //优先扫描ble的设备
            }
            NSLog(@"扫描到设备,此时的scanCount==%ld",(long)scanCount);
            if (scanCount == 0) {
                if (module.canConnect) {
//                    [strongSelf.manager connecnt:module];
                    strongSelf->_globalManager.connectState = ConnectStateBLE;
                    
                    if (_enterTimeCount<3) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((3-_enterTimeCount) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [strongSelf startToAdertise];
                            _testModule = module;
                        });
                    }
                    scanCount ++;

                    
                }else {//广播蓝牙
                    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:NSLocalizedString(@"成功扫描到设备%@", nil),module.name]];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [SVProgressHUD dismiss];
                    });
                    NSLog(@"广播蓝牙方式进入");
                    if (_enterTimeCount < 3) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((3-_enterTimeCount) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            strongSelf->_globalManager.connectState = ConnectStateAdvertise;
                            [strongSelf startToAdertise];
                            
                        });
                    }
                    scanCount ++;

                }
                
            }
        });
        
    };
}



- (void) startToAdertise {
    
    [self invalidateTimer];
    
    StartAdvertiseViewController *adVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"StartAdvertiseViewController"];
    adVC.testmodule = _testModule;
    
    [self.navigationController pushViewController:adVC animated:YES];
    
}


- (void)infoButtonClick:(UIButton *)sender
{
    BYInfoViewController *bvc = [[BYInfoViewController alloc]init];
    [self.navigationController pushViewController:bvc animated:YES];
}

#pragma mark - animation
- (void)animationDidStart:(CAAnimation *)anim {
    NSLog(@"%@",anim);
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    NSLog(@"%@ | %d",anim,flag);
}

- (void)manager:(MinewModuleManager *)manager didChangeModule:(MinewModule *)module linkStatus:(LinkStatus)status {
    NSLog(@"收到连接的回调.....");
//    if (status == LinkStatusConnected) {
//        NSLog(@"连接成功%@",module.peripheral);
//        NSLog(@"连接成功此时的scanCount==%ld",scanCount);
//        if (scanCount == 1) {
//            [MinewCommonTool onMainThread:^{
//                [self startToAdertise];
//            }];
//            scanCount ++;
//        }
//
//    }
}
@end
