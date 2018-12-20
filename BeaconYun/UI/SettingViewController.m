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

@property (nonatomic, strong ) NSMutableArray *bindDevicesArray;
@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initCore];
    [self initData];
    [self initView];
    
    
}

- (void)initCore {
    _manager = [MinewModuleManager sharedInstance];
    
    _bindDevicesArray = [NSMutableArray arrayWithArray:_manager.allModules];
    NSLog(@"全部扫描到的设备为:%ld",_bindDevicesArray.count);
}

- (void) initView {
    UIImageView *backImg = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [backImg setImage:[UIImage imageNamed:@"all_background"]];
    [self.view addSubview:backImg];
    
    CGFloat buttonWidth = (ScreenWidth-40)/2;
    CGFloat buttonHeight = 50;

    for (NSInteger i=0; i<_bindDevicesArray.count; i++) {
        MinewModule *module = _bindDevicesArray[i];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setFrame:CGRectMake(10+(buttonWidth+20)*(i%2), 100+(buttonHeight+10)*(i/2), buttonWidth, buttonHeight)];

        [button setTitle:_dataArray[i] forState:UIControlStateNormal];
        [button setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        button.backgroundColor = [UIColor lightGrayColor];
        button.layer.cornerRadius = 10;
        button.layer.masksToBounds = YES;
        [self.view addSubview:button];
        button.tag = 100 + i;
        if (module.isBind) {
            button.selected = YES;
        }
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void) initData {
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
        for (NSInteger i=0; i<_bindDevicesArray.count; i++) {
            MinewModule *module = _bindDevicesArray[i];
            [_dataArray addObject:[NSString stringWithFormat:@"%@ %ld",module.name,i+1]];
        }
//        _dataArray = [NSMutableArray arrayWithObjects:@"模式1",@"模式2",@"模式3",@"模式4",@"模式5",@"模式6",@"模式7",@"模式8",@"模式9",@"模式10", nil];
    }
}

- (void)buttonClick:(UIButton *)btn {
    NSInteger index = btn.tag - 100;
    MinewModule *module = _bindDevicesArray[index];
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
        if (count>1) {
            [_manager removeBindModule:module];
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"你已取消选择%@",stateString]];
        }else {
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"只剩最后一个,不能再取消了"]];
            btn.selected = YES;
        }
    

    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
}
@end
