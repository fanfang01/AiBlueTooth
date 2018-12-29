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

@interface SettingViewController ()
@property (nonatomic, strong ) NSMutableArray *dataArray;

@property (nonatomic, strong ) MinewModuleManager *manager;

@property (nonatomic, strong ) NSMutableArray *allDevicesArray;
@property (nonatomic, strong ) NSMutableArray *bindArray;
@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initCore];
    [self initData];
    
    UIImageView *backImg = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [backImg setImage:[UIImage imageNamed:@"all_background"]];
    [self.view addSubview:backImg];
    
    [self initView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStylePlain target:self action:@selector(clearAllSelectedDevices)];
}

- (void)initCore {
    _manager = [MinewModuleManager sharedInstance];
    _bindArray = _manager.bindModules;
    _allDevicesArray = [NSMutableArray arrayWithArray:_manager.allModules];
    
    NSLog(@"全部扫描到的设备为:%ld",_allDevicesArray.count);
}

- (void) initView {
    
    
    CGFloat buttonWidth = (ScreenWidth-40)/2;
    CGFloat buttonHeight = 50;

    for (NSInteger i=0; i<_allDevicesArray.count; i++) {
        MinewModule *module = _allDevicesArray[i];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setFrame:CGRectMake(10+(buttonWidth+20)*(i%2), 100+(buttonHeight+10)*(i/2), buttonWidth, buttonHeight)];

        [button setTitle:_dataArray[i] forState:UIControlStateNormal];
        [button setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        button.backgroundColor = [UIColor lightGrayColor];
        button.layer.cornerRadius = 10;
        button.layer.masksToBounds = YES;
        [self.view addSubview:button];
        button.tag = 100 + i;
        
        if ([self isExistsModule:module]) {
            button.selected = YES;
        }
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    NSArray *bindNotinRangeArr = [[MinewModuleManager sharedInstance] isExisModuleOutofSacnnedModules];
    for (NSInteger i=0; i<bindNotinRangeArr.count; i++) {
        NSDictionary *info = bindNotinRangeArr[i];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setFrame:CGRectMake(10+(buttonWidth+20)*(i%2), 100+(buttonHeight+10)*(i/2+_allDevicesArray.count%2), buttonWidth, buttonHeight)];
        
        [button setTitle:info[@"customName"] forState:UIControlStateNormal];
        [button setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        button.backgroundColor = [UIColor lightGrayColor];
        button.layer.cornerRadius = 10;
        button.layer.masksToBounds = YES;
        [self.view addSubview:button];
        button.tag = 110 + i;
        
        [button addTarget:self action:@selector(offlineModuleAction:) forControlEvents:UIControlEventTouchUpInside];
    }

    NSLog(@"共有%ld个未扫描到的设备",bindNotinRangeArr.count);
}

- (void)offlineModuleAction:(UIButton *)btn {
//    NSInteger index = btn.tag - 110;
    [SVProgressHUD showErrorWithStatus:@"此设备没有开机或不在范围内,不可选择"];
}

- (void) initData {
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
        for (NSInteger i=0; i<_allDevicesArray.count; i++) {
//            MinewModule *module = _allDevicesArray[i];
            [_dataArray addObject:[NSString stringWithFormat:@"%@ %ld",@"设备",(long)i+1]];
        }
//        _dataArray = [NSMutableArray arrayWithObjects:@"模式1",@"模式2",@"模式3",@"模式4",@"模式5",@"模式6",@"模式7",@"模式8",@"模式9",@"模式10", nil];
    }
}

- (void)buttonClick:(UIButton *)btn {
    NSInteger index = btn.tag - 100;
    MinewModule *module = _allDevicesArray[index];
    NSString *stateString = _dataArray[index];

    btn.selected = !btn.selected;
    module.isBind = btn.selected;
    if (btn.selected) {
        btn.backgroundColor = [UIColor lightGrayColor];
        [_manager addBindModule:module];
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"你已选择%@",stateString]];
    }else {
        btn.backgroundColor = [UIColor lightTextColor];
        NSInteger count = _manager.bindModules.count;
        if (count > 0) {
            [_manager removeBindModule:module];
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"你已取消选择%@",stateString]];
        }else {
//            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"只剩最后一个,不能再取消了"]];
//            btn.selected = YES;
        }
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
//    for (NSData *data in _bindArray) {
//        MinewModule *mo = [NSKeyedUnarchiver unarchiveObjectWithData:data];
//        if ([mo.macString isEqualToString:module.macString]) {
//            return YES;
//        }
//    }
    return NO;
}

- (void) clearAllSelectedDevices {
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:@"你确定要清除所有的绑定的设备吗?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[MinewModuleManager sharedInstance] removeAllBindModules];
        
        for (UIView *subView in self.view.subviews) {
            if ([subView isKindOfClass:[UIButton class]]) {
                [subView removeFromSuperview];
            }
        }
        _bindArray = _manager.bindModules;
        for (MinewModule *module in _allDevicesArray) {
            module.isBind = NO;
        }
        [self initView];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alertVC addAction:confirmAction];
    [alertVC addAction:cancelAction];
    [self.navigationController presentViewController:alertVC animated:YES completion:nil];
}
@end
