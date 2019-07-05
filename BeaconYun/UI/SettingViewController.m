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

@property (nonatomic, strong) UICollectionView *deviceCollectionView;

@end

@implementation SettingViewController
{
    NSTimer *_reloadTimer ;
    CGFloat _buttonWidth ;
    CGFloat _buttonHeight ;
    CGFloat _viewHeight ;
    GlobalManager *_globalManager;
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
    
//    [self invalidateTimer];
    
//    [_manager startScan];
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
    _bindArray = _manager.bindModules;
    _allDevicesArray = [NSMutableArray arrayWithArray:_manager.allModules];
    
    _globalManager = [GlobalManager sharedInstance];
    
    NSLog(@"全部扫描到的设备为:%ld",_allDevicesArray.count);
}

#pragma mark ---- 后台持续1s扫描
- (void)initTimer {
    if (!_reloadTimer) {
        _reloadTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshScannedDevices) userInfo:nil repeats:YES];
    }
}

- (void)refreshScannedDevices {
    _allDevicesArray = [NSMutableArray arrayWithArray:_manager.allModules];

    [self reloadData];
}

- (void)invalidateTimer {
    [_reloadTimer invalidate];
    _reloadTimer = nil;
}

- (void) initView {
    
    //设置渐变色
    CAGradientLayer *gradient = [CAGradientLayer layer];
    //设置开始和结束位置(设置渐变的方向)
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(0, 1);
    gradient.frame = CGRectMake(0,0,ScreenWidth,ScreenHeight);
    gradient.colors = [NSArray arrayWithObjects:(id)RGB(156, 100, 183).CGColor,(id)RGB(124, 71, 170).CGColor,(id)RGB(107, 55, 162).CGColor,(id)RGB(86, 35, 153).CGColor,nil];
    [self.view.layer insertSublayer:gradient atIndex:0];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake((ScreenWidth-17*3)/2, 60);
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 15;
    
//    self.collectionView.collectionViewLayout = layout;
//    self.collectionView.delegate = self;
//    self.collectionView.dataSource = self;
//    [self.collectionView registerNib:[UINib nibWithNibName:@"SettingCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"SettingCollectionViewCell"];

    self.collectionView.hidden = YES;
    
    [self.view addSubview:self.deviceCollectionView];
    

}

- (UICollectionView *)deviceCollectionView
{
    if (!_deviceCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake((ScreenWidth-17*3)/2, 65);
        layout.minimumLineSpacing = 10;
        layout.minimumInteritemSpacing = 15;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.sectionInset = UIEdgeInsetsMake(15, 15, 0, 15);
        
        _deviceCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 64, ScreenWidth, ScreenHeight) collectionViewLayout:layout];
        _deviceCollectionView.backgroundColor = [UIColor clearColor];
        _deviceCollectionView.dataSource = self;
        _deviceCollectionView.delegate = self;
        [_deviceCollectionView registerNib:[UINib nibWithNibName:@"SettingCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"SettingCollectionViewCell"];
        
    }
    return _deviceCollectionView ;
}

- (void) initData {
    
    if (!_scannedBtnArray) {
        _scannedBtnArray = [NSMutableArray array];
    }
    if (!_notinBoundsBtnArray) {
        _notinBoundsBtnArray = [NSMutableArray array];
    }
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

//在绑定的队列里，是否存在在扫描的队列里
- (MinewModule *)isExistsModuleInScannedList:(NSString *)macString {
    for (MinewModule *module in _scannedBtnArray) {
        if ([module.macString isEqualToString:macString]) {
            return module;
        }
    }
    
    return nil;
}

#pragma mark ----   清除所有的设备
- (void) clearAllSelectedDevices {
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"提示", nil) message:NSLocalizedString(@"你确定要清除所有的绑定的设备吗?", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        _bindArray = _manager.bindModules;
        NSMutableArray *tempArray = [self bindArray];
        
        for (MinewModule *module in _allDevicesArray) {
            module.isBind = NO;
        }
        [[MinewModuleManager sharedInstance] removeAllBindModules];

        [self reloadData];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"取消", nil) style:UIAlertActionStyleCancel handler:nil];
    
    [alertVC addAction:confirmAction];
    [alertVC addAction:cancelAction];
    [self.navigationController presentViewController:alertVC animated:YES completion:nil];
}

- (void)reloadData {
    _bindArray = _manager.bindModules;
    [self.deviceCollectionView reloadData];
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
//        cell.deviceNameLabel.text = [NSString stringWithFormat:@"设备%lu",(indexPath.row)+1];

        cell.module = module;
    }

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MinewModule *module = _allDevicesArray[indexPath.row];
    module.isBind = !module.isBind;
    if (module.isBind) {
        if (_manager.bindModules.count >= 6) {
            [SVProgressHUD showSuccessWithStatus:@"已超过最大的添加设备数..."];
            module.isBind = NO;
            return ;
        }else {
            [_manager addBindModule:module];
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:NSLocalizedString(@"你已选择%@", nil),module.name]];
        }
    }else {
        [_manager removeBindModule:module];
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:NSLocalizedString(@"你已取消选择%@", nil),module.name]];

    }
    switch (_globalManager.connectState) {
        case ConnectStateBLE:
        {
            if (module.isBind) {
                [_manager connecnt:module];
            }else {
                [_manager disconnect:module];
            }
        }
            break;
        case ConnectStateAdvertise:
        {

        }
            break;
        default:
            break;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
    //reload
    [self reloadData];
    NSLog(@"你当前选择的是:%ld行",indexPath.row);
}

@end
