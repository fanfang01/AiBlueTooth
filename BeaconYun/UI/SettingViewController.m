//
//  SettingViewController.m
//  BeaconYun
//
//  Created by 樊芳 on 2018/12/4.
//  Copyright © 2018 MinewTech. All rights reserved.
//

#import "SettingViewController.h"
#import "MinewModuleManager.h"
#import "MinewModule.h"
#import "SettingCollectionViewCell.h"

@interface SettingViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,MinewModuleManagerDelegate>

@property (nonatomic, strong ) MinewModuleManager *manager;

@property (nonatomic, strong ) NSMutableArray *allDevicesArray;
@property (nonatomic, strong ) NSMutableArray *bindArray;

//存储各自的设备
@property (nonatomic, strong ) NSMutableArray *scannedBtnArray;

@property (nonatomic, strong ) NSMutableArray *notinBoundsBtnArray;

// 记录消失的设备
@property (nonatomic, strong) NSMutableArray *disappearModules;

@end

@implementation SettingViewController
{
    NSTimer *_reloadTimer ;
    CGFloat _buttonWidth ;
    CGFloat _buttonHeight ;
    CGFloat _viewHeight ;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _buttonWidth = (ScreenWidth-40)/2;
    _buttonHeight = 50;
    _viewHeight = 100;
    
    [self initCore];
    [self initData];
    
    [self initView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStylePlain target:self action:@selector(clearAllSelectedDevices)];
    
    [self initTimer];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self invalidateTimer];
    
    [_manager startScan];
}


- (void)initCore {
    _manager = [MinewModuleManager sharedInstance];
    _manager.delegaate = self;
    _bindArray = [_manager.bindModules mutableCopy];
    _allDevicesArray = [NSMutableArray arrayWithArray:_manager.allModules];
    
    NSLog(@"全部扫描到的设备为:%ld",_allDevicesArray.count);
}

//后台持续1s扫描
- (void)initTimer {
    if (!_reloadTimer) {
        _reloadTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(refreshScannedDevices) userInfo:nil repeats:YES];
    }
}

- (void)refreshScannedDevices {
    _bindArray = [_manager.bindModules mutableCopy];
    _allDevicesArray = [NSMutableArray arrayWithArray:_manager.allModules];
    
    //持续刷新
    [self updateView];
}

- (void)invalidateTimer {
    [_reloadTimer invalidate];
    _reloadTimer = nil;
}

- (void) initView {
    UIImageView *backImg = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [backImg setImage:[UIImage imageNamed:@"all_background"]];
    [self.view addSubview:backImg];
    
    NSInteger sumCount = _allDevicesArray.count;

    for (NSInteger i=0; i < _allDevicesArray.count; i++) {
//        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(10+(_buttonWidth+20)*(i%2), 100+(_buttonHeight+10)*(i/2), _buttonWidth, _viewHeight)];
//        [self.view addSubview:view];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
//        [button setFrame:CGRectMake(0, 0, _buttonWidth, 100)];
        [button setFrame:CGRectMake(10+(_buttonWidth+20)*(i%2), 100+(_buttonHeight+10)*(i/2), _buttonWidth, _buttonHeight)];
        
        [button setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        button.backgroundColor = [UIColor lightGrayColor];
        button.layer.cornerRadius = 10;
        button.layer.masksToBounds = YES;
        [self.view addSubview:button];
        button.titleLabel.numberOfLines = 0;
        button.tag = 100 + i;
        
//        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, _buttonHeight, _buttonWidth, _buttonHeight)];
//        label.textColor = UIColor.blueColor;
//        label.font = [UIFont systemFontOfSize:14];
//        [view addSubview:label];
        
        if (i < _allDevicesArray.count) {
            MinewModule *module = _allDevicesArray[i];
//            [button setTitle:[NSString stringWithFormat:@"设备 %ld",i] forState:UIControlStateNormal];
            [button setTitle:[NSString stringWithFormat:@"设备 %ld\n%@",i+1 ,module.macString] forState:UIControlStateNormal];

            if ([self isExistsModule:module]) {
                button.selected = YES;
                NSLog(@"应该被绑定的设备是:%@",module.macString);

            }
//            label.text = [NSString stringWithFormat:@"Mac:%@",module.macString];

        }
        
        [_scannedBtnArray addObject:button];
        
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        
    }
//    NSLog(@"共有%ld个未扫描到的设备",bindNotinRangeArr.count);
    
//    NSArray *bindNotinRangeArr = [[MinewModuleManager sharedInstance] isExisModuleOutofSacnnedModules];
//
//    for (NSInteger i = 0; i < bindNotinRangeArr.count ; i++) {
//        NSDictionary *info = bindNotinRangeArr[i];
//
//        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
//        [button setFrame:CGRectMake(10+(_buttonWidth+20)*(i%2), 100+(_buttonHeight+10)*(i/2+_allDevicesArray.count%2), _buttonWidth, _buttonHeight)];
//
//        [button setTitle:info[@"customName"] forState:UIControlStateNormal];
//        [button setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
//        button.backgroundColor = [UIColor lightGrayColor];
//        button.layer.cornerRadius = 10;
//        button.layer.masksToBounds = YES;
//        [self.view addSubview:button];
//        button.tag = 110 + i;
//
//        [button addTarget:self action:@selector(offlineModuleAction:) forControlEvents:UIControlEventTouchUpInside];
//
//        [_notinBoundsBtnArray addObject:button];
//
//    }

}

- (void)offlineModuleAction:(UIButton *)btn {
    [SVProgressHUD showErrorWithStatus:@"此设备没有开机或不在范围内,不可选择"];
}

- (void)createButton:(NSInteger)index {
    CGFloat buttonWidth = (ScreenWidth-40)/2;
    CGFloat buttonHeight = 50;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setFrame:CGRectMake(10+(buttonWidth+20)*(index%2), 100+(buttonHeight+10)*(index/2), buttonWidth, buttonHeight)];
    
    [button setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    button.backgroundColor = [UIColor lightGrayColor];
    button.layer.cornerRadius = 10;
    button.layer.masksToBounds = YES;
    [self.view addSubview:button];
    button.tag = 100 + index;
    button.titleLabel.numberOfLines = 0;
    
    MinewModule *module = _allDevicesArray[index];
    [button setTitle:[NSString stringWithFormat:@"设备 %ld\n%@",index+1 ,module.macString] forState:UIControlStateNormal];
    if ([self isExistsModule:module]) {
        button.selected = YES;
    }
    
    [_scannedBtnArray addObject:button];
    
    [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
}


- (void)updateView {
    //扫描，删除 不在范围内的设备
    if (_scannedBtnArray.count > _allDevicesArray.count) {
        for (NSInteger i=_scannedBtnArray.count-1; i>=_allDevicesArray.count; i--) {
            if (_scannedBtnArray.count > i) {
                [_scannedBtnArray removeObjectAtIndex:i];
            }
        }
    }
    //扫描，新增新设备
    for (NSInteger i = 0; i<_allDevicesArray.count; i++) {
        MinewModule *module = [_allDevicesArray objectAtIndex:i];
        if (_scannedBtnArray.count > i) {
            UIButton *btn = _scannedBtnArray[i];
            NSString *titleString = btn.titleLabel.text;
            NSString *subString = [[titleString componentsSeparatedByString:@"\n"] lastObject];
            
            if ([subString isEqualToString:module.macString]) {
                btn.selected = [self isExistsModule:module];
            }

            //当所有的设备都清空了
            if (_bindArray.count == 0) {
                btn.selected = NO;
            }
       
//            btn.selected = module.isBind;
        }else {
            [self createButton:i];
        }
        
    }

    //扫描，移除断链设备
}

- (void) initData {
    
    if (!_scannedBtnArray) {
        _scannedBtnArray = [NSMutableArray array];
    }
    if (!_notinBoundsBtnArray) {
        _notinBoundsBtnArray = [NSMutableArray array];
    }
}

- (void)buttonClick:(UIButton *)btn {
    NSInteger index = btn.tag - 100;

    MinewModule *module = _allDevicesArray[index];

    btn.selected = !btn.selected;
    module.isBind = btn.selected;
    if (btn.selected) {
        btn.backgroundColor = [UIColor lightGrayColor];
        [_manager addBindModule:module];
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"你已选择%@",btn.titleLabel.text]];
    }else {
        btn.backgroundColor = [UIColor lightTextColor];
        NSInteger count = _manager.bindModules.count;
        if (count > 0) {
            [_manager removeBindModule:module];
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"你已取消选择%@",btn.titleLabel.text]];
        }else {
//            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"只剩最后一个,不能再取消了"]];
//            btn.selected = YES;
        }
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
}

//在扫描的队列里，是否存在绑定的设备
- (BOOL)isExistsModule:(MinewModule *)module {
    
        for (NSDictionary *info in _bindArray) {
            if ([info[@"macString"] isEqualToString:module.macString]) {
                return YES;
            }
        }
    return NO;
}

- (void) clearAllSelectedDevices {
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:@"你确定要清除所有的绑定的设备吗?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[MinewModuleManager sharedInstance] removeAllBindModules];
        _bindArray = [_manager.bindModules mutableCopy];
        [_bindArray removeAllObjects];
        
        for (MinewModule *module in _allDevicesArray) {
            module.isBind = NO;
        }
        
        [self updateView];
        
//        for (UIView *subView in self.view.subviews) {
//            if ([subView isKindOfClass:[UIButton class]]) {
//                [subView removeFromSuperview];
//            }
//        }
//        _bindArray = _manager.bindModules;
//        for (MinewModule *module in _allDevicesArray) {
//            module.isBind = NO;
//        }
//        [self initView];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alertVC addAction:confirmAction];
    [alertVC addAction:cancelAction];
    [self.navigationController presentViewController:alertVC animated:YES completion:nil];
}
#pragma mark
@end
