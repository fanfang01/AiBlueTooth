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
#import <SVProgressHUD.h>

@interface SettingViewController ()<MinewModuleManagerDelegate,UICollectionViewDelegate,UICollectionViewDataSource>

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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //hide navigationBar
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initData];

    [self initCore];
    
    [self initView];
    
    [self initTimer];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self invalidateTimer];
    
    [_manager startScan];
}

- (IBAction)backLastVC:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -- 清空设备操作
- (IBAction)deleteAllDevices:(UIButton *)sender {
    [self clearAllSelectedDevices];
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
//    [self updateView];
}

- (void)invalidateTimer {
    [_reloadTimer invalidate];
    _reloadTimer = nil;
}

- (void) initView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake((ScreenWidth-17*3)/2, 60);
    layout.minimumLineSpacing = 8;
    layout.minimumInteritemSpacing = 14;
    
    self.collectionView.collectionViewLayout = layout;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:@"SettingCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"SettingCollectionViewCell"];

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
        btn.backgroundColor = [UIColor cyanColor];
        [_manager addBindModule:module];
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:NSLocalizedString(@"你已选择%@", nil),btn.titleLabel.text]];
    }else {
        btn.backgroundColor = [UIColor lightTextColor];
        NSInteger count = _manager.bindModules.count;
        if (count > 0) {
            [_manager removeBindModule:module];
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:NSLocalizedString(@"你已取消选择%@", nil),btn.titleLabel.text]];
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
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"提示", nil) message:NSLocalizedString(@"你确定要清除所有的绑定的设备吗?", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[MinewModuleManager sharedInstance] removeAllBindModules];
        _bindArray = [_manager.bindModules mutableCopy];
        [_bindArray removeAllObjects];
        
        for (MinewModule *module in _allDevicesArray) {
            module.isBind = NO;
        }
        
//        [self updateView];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"取消", nil) style:UIAlertActionStyleCancel handler:nil];
    
    [alertVC addAction:confirmAction];
    [alertVC addAction:cancelAction];
    [self.navigationController presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark---- UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _allDevicesArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SettingCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SettingCollectionViewCell" forIndexPath:indexPath];
    if (_allDevicesArray.count > indexPath.row) {
        MinewModule *module = _allDevicesArray[indexPath.row];
        if ([self isExistsModule:module]) {
            module.isBind = YES;
        }
        cell.module = module;
        cell.deviceNameLabel = [NSString stringWithFormat:@"设备%lu",(unsigned long)(indexPath.row)+1];
    }

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MinewModule *module = _allDevicesArray[indexPath.row];
    module.isBind = !module.isBind;
    if (module.isBind) {
        [_manager addBindModule:module];
    }else {
        [_manager removeBindModule:module];
    }
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    NSLog(@"你当前选择的是:%ld行",indexPath.row);
}
@end
