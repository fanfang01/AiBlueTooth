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

- (void)touchDownToSearchDevice {
    [self startToScan];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (scanCount != 0) {
        [_manager stopScan];
        _showLabel.text = NSLocalizedString(@"请点击上方按钮开始扫描", nil);
    }
    scanCount = 0;
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
    
#ifdef debug

#else
#endif
}

#pragma mark --- 动画开始
- (void)scanAction {
    [_scanBGImageView.layer removeAnimationForKey:@"transform"];
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
    [_scanBGImageView.layer addAnimation:theAnimation forKey:@"transform"];
    
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
            if (scanCount == 0) {
                if (module.canConnect) {
                    [_manager connecnt:module];
                    _globalManager.connectState = ConnectStateBLE;
                    _testModule = module;
                    scanCount ++;
                }else {//广播蓝牙
                    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:NSLocalizedString(@"成功扫描到设备%@", nil),module.name]];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [SVProgressHUD dismiss];
                    });
                    _globalManager.connectState = ConnectStateAdvertise;
                    [weakSelf startToAdertise];

                    scanCount ++;
                    //                [strongSelf.manager stopScan];
                }
                
            }
        });
        
    };

    if (_timer)
        [_timer invalidate];
        
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.4 target:self selector:@selector(reloadTableView) userInfo:nil repeats:YES];
    
    [_timer fire];
}

- (void)reloadTableView
{
    _moduleArray = [_manager.allModules copy];
    
#warning 添加HToy的测试  记录所有的设备
    if (!_tempArr) {
        _tempArr = [NSMutableArray array];
    }
    [_tempArr removeAllObjects];

    for (MinewModule *module in _moduleArray) {
        if ([module.name isEqualToString:@"HToy"]) {
            [_tempArr addObject:module];
        }
    }
    
    if (_tempArr.count > 0) {
//        MinewModule *module = [_tempArr firstObject];
        
    }
}

- (void) startToAdertise {
    
    StartAdvertiseViewController *adVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"StartAdvertiseViewController"];
    adVC.testmodule = _testModule;
    
    [self.navigationController pushViewController:adVC animated:YES];
    
    
//    [_manager stopScan];
}

- (NSString *)hexStringFromString:(NSString *)string
{
    NSData *myD = [string dataUsingEncoding:NSUTF8StringEncoding];
    Byte *bytes = (Byte *)[myD bytes];
    //下面是Byte 转换为16进制。
    NSString *hexStr=@"";
    for(int i=0;i<[myD length];i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];//16进制数
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    return hexStr;
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
    if (status == LinkStatusConnected) {
        NSLog(@"连接成功%@",module.peripheral);
        
        [self startToAdertise];
        scanCount ++;
    }
}
@end
