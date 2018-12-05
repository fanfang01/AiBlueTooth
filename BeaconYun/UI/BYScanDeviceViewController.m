//
//  BYScanViewController.m
//  BeaconYun
//
//  Created by SACRELEE on 2/24/17.
//  Copyright © 2017 MinewTech. All rights reserved.
//

#import "BYScanDeviceViewController.h"
#import "BYTableViewModel.h"
#import "BYSectionModel.h"
#import "BYHeaderView.h"
#import "BYCommonMacros.h"
#import "BYCellModel.h"
#import <Masonry.h>
#import "BYCommonTools.h"
#import "BYSetDeviceViewController.h"
#import "MinewModuleManager.h"
#import "MinewModule.h"
#import "BYDeviceDetailViewController.h"
#import "MinewModuleAPI.h"
#import "BYInfoViewController.h"
#import "MTPeripheralManager.h"
#import "AdvertiseView.h"
#import "StartAdvertiseViewController.h"
#import "SettingViewController.h"


#define INTERVAL_KEYBOARD 0

@interface BYScanDeviceViewController ()<MinewModuleManagerDelegate,UITextFieldDelegate>

@property (nonatomic, strong) BYTableViewModel *tvModel;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) BYSectionModel *sectionModel;

@property (nonatomic, strong) MinewModuleManager *manager;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) NSArray *moduleArray;

@property (nonatomic, strong) UIView *noneDeviceView;

@property(nonatomic,strong) NSMutableArray *tempArr ;

@end

@implementation BYScanDeviceViewController
{
    UITextField *_contentTF;
    NSString *_testString;
    NSString *_deviceName;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
//        self.edgesForExtendedLayout = UIRectEdgeNone;
//    }
    
    [self initGUI];
    [self initCore];
    
    //add notofication for keyBoard
    [self addNoticeForKeyboard];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    if (@available(iOS 11.0, *)) {
//
//    }else {
//        self.automaticallyAdjustsScrollViewInsets = NO;
//    }
}

- (void)initGUI
{
    self.title = NSLocalizedString(@"Devices", nil);
    self.view.backgroundColor = [BYCommonTools colorWithRgb:@"eeeeee"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"About"] style:UIBarButtonItemStyleDone target:self action:@selector(infoButtonClick:)];
    
    _sectionModel = [[BYSectionModel alloc]init];
    _sectionModel.rowHeight = 60.f;
    _sectionModel.rowAtitude = 4;
    _sectionModel.headerHeight = 40.f;
    BYHeaderView *header = [[BYHeaderView alloc]initWithType:HeaderViewTypeNormal title:NSLocalizedString(@"All Devices", nil)];
    header.tapped = ^(){ BYLog(@"don't touche me, Bitch!");};
    _sectionModel.header = header;
    
    // set tableview model
    _tvModel = [[BYTableViewModel alloc]init];
    _tvModel.globalSectionModel = _sectionModel;
    
    __weak NSArray *weakModules = _moduleArray;
    _tvModel.cellModel = ^( NSIndexPath *indexpath){
        
        __strong NSArray *strongModules = weakModules;
        
        MinewModule *module = strongModules[indexpath.row];
        
        BYCellModel *cm = [[BYCellModel alloc]init];
        cm.title = module.name;
        cm.detailText = @"Module Device";
        return cm;
    };
    
//    __weak BYScanDeviceViewController *weakSelf = self;
    _tvModel.cellSelect = ^(UITableView *tableView, NSIndexPath *indexPath){
        
//        __strong BYScanDeviceViewController *strongSelf = weakSelf;
//        strongSelf.tableView.userInteractionEnabled = NO;
//
//        BYDeviceDetailViewController *svc = [[BYDeviceDetailViewController alloc]init];
//        [strongSelf.navigationController pushViewController:svc animated:YES];
//
//        strongSelf.tableView.userInteractionEnabled = YES;
//        [MinewModuleAPI sharedInstance].lastModule = strongSelf.moduleArray[indexPath.row];
    };
    
//    __weak BYScanDeviceViewController *weakSelf = self;
//    _tvModel.cellSelect = ^(UITableView *tableView, NSIndexPath *indexPath){
//        
//        __strong BYScanDeviceViewController *strongSelf = weakSelf;
//        strongSelf.tableView.userInteractionEnabled = NO;
//        
//        BYSetDeviceViewController *svc = [[BYSetDeviceViewController alloc]init];
//        svc.module = strongSelf.moduleArray[indexPath.row];
//        [strongSelf.navigationController pushViewController:svc animated:YES];
//        
//        strongSelf.tableView.userInteractionEnabled = YES;
//    };

    
    
    // set tableview
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 64, ScreenWidth, ScreenHeight-64) style:UITableViewStyleGrouped];
    [self.view addSubview:_tableView];
    
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).offset(0);
        make.left.equalTo(self.view.mas_left).offset(0);
        make.right.equalTo(self.view.mas_right).offset(0);
        make.bottom.equalTo(self.view.mas_bottom).offset(0);
    }];
    _tableView.delegate = _tvModel;
    _tableView.dataSource = _tvModel;
    _tableView.backgroundColor = [BYCommonTools colorWithRgb:@"#eeeeee"];
    
    
//    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(10, ScreenHeight -180, 150, 50)];
//    _contentTF = tf;
//    tf.placeholder = @"请输入测试广播数据";
//    tf.borderStyle = UITextBorderStyleRoundedRect;
//    tf.layer.borderColor = [UIColor blueColor].CGColor;
//    tf.layer.borderWidth = 1;
//    tf.font = [UIFont systemFontOfSize:13];
//    tf.delegate = self;
//    [self.view addSubview:tf];
    
    UIButton *scanButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.view addSubview:scanButton];
    [scanButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-40);
        make.size.mas_equalTo(CGSizeMake( 100, 50));
        make.left.equalTo(self.view.mas_left).offset(sScreenWidth / 2.0f - 100 / 2.0);
    }];
    scanButton.layer.cornerRadius = 25.f;
    scanButton.layer.masksToBounds = YES;
    scanButton.layer.borderColor = [UIColor colorWithRed:0.25 green:0.32 blue:0.71 alpha:1.00].CGColor;
    scanButton.layer.borderWidth = 0.4f;
    scanButton.backgroundColor = [UIColor whiteColor];
    scanButton.titleLabel.font = [UIFont fontWithName:sIconsFont size:20.f];
    scanButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [scanButton setTitle:@"开始扫描" forState:UIControlStateNormal];
    [scanButton setTitleColor:[UIColor colorWithRed:0.25 green:0.32 blue:0.71 alpha:1.00] forState:UIControlStateNormal];
    [scanButton addTarget:self action:@selector(scanButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton *adverButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.view addSubview:adverButton];
    [adverButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-40);
        make.size.mas_equalTo(CGSizeMake( 100, 50));
        make.left.equalTo(scanButton.mas_right).offset(10);
    }];

    adverButton.titleLabel.font = [UIFont fontWithName:sIconsFont size:20.f];
    [adverButton setTitle:@"开始广播" forState:UIControlStateNormal];
    [adverButton setTitleColor:[UIColor colorWithRed:0.25 green:0.32 blue:0.71 alpha:1.00] forState:UIControlStateNormal];
    [adverButton addTarget:self action:@selector(startToAdertise) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *setButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.view addSubview:setButton];
    [setButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-40);
        make.size.mas_equalTo(CGSizeMake( 100, 50));
        make.right.equalTo(scanButton.mas_left).offset(-10);
    }];
    
    setButton.titleLabel.font = [UIFont fontWithName:sIconsFont size:20.f];
    [setButton setTitle:@"开始设置" forState:UIControlStateNormal];
    [setButton setTitleColor:[UIColor colorWithRed:0.25 green:0.32 blue:0.71 alpha:1.00] forState:UIControlStateNormal];
    [setButton addTarget:self action:@selector(startToSetup) forControlEvents:UIControlEventTouchUpInside];
    
    
//    UILabel *scanTip = [[UILabel alloc]init];
//    [self.view addSubview:scanTip];
//    [scanTip mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.size.mas_equalTo(CGSizeMake( 50, 20));
//        make.left.equalTo(scanButton.mas_left).offset(0);
//        make.top.equalTo(scanButton.mas_bottom).offset(5);
//    }];
//    scanTip.textAlignment = NSTextAlignmentCenter;
//    scanTip.textColor = [UIColor colorWithRed:0.25 green:0.32 blue:0.71 alpha:1.00];
//    scanTip.text = NSLocalizedString(@"Scan", nil);
//    scanTip.font = [UIFont systemFontOfSize:14.f];
}

//- (void)reloadData {
//    __weak NSArray *weakModules = _moduleArray;
//
//    _tvModel.cellModel = ^( NSIndexPath *indexpath){
//
//        __strong NSArray *strongModules = weakModules;
//
//        MinewModule *module = strongModules[indexpath.row];
//
//        BYCellModel *cm = [[BYCellModel alloc]init];
//        cm.title = module.name;
//        cm.detailText = _testString;
//        return cm;
//    };
//
//}

- (void)initCore
{
    _manager = [MinewModuleManager sharedInstance];
    _manager.delegaate = self;
    [_manager startScan];

    if (_timer)
        [_timer invalidate];
        
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.4 target:self selector:@selector(reloadTableView) userInfo:nil repeats:YES];
    
    [_timer fire];
}


- (void)reloadTableView
{
    _moduleArray = [_manager.allModules copy];
    _sectionModel.rowAtitude = _moduleArray.count;
    
#warning 添加RGB的测试
//    if (!_tempArr) {
//        _tempArr = [NSMutableArray array];
//    }
//    [_tempArr removeAllObjects];
//
//    for (MinewModule *module in _moduleArray) {
//        if ([module.name isEqualToString:@"Minew_RGB"]) {
//            [_tempArr addObject:module];
//        }
//    }
//    _sectionModel.rowAtitude = _tempArr.count;

    
    
    BYHeaderView *header = [[BYHeaderView alloc]initWithType:HeaderViewTypeNormal title:[NSString stringWithFormat:@"%@: %lu",NSLocalizedString(@"All Devices", nil), (unsigned long)_moduleArray.count]];
    header.tapped = ^(){ BYLog(@"don't touche me, Bitch!");};
    _sectionModel.header = header;
    
    __weak NSArray *weakModules = _moduleArray;
    _tvModel.cellModel = ^( NSIndexPath *indexpath){
        
        __strong NSArray *strongModules = weakModules;
        
        MinewModule *module = strongModules[indexpath.row];
        
        BYCellModel *cm = [[BYCellModel alloc]init];
        cm.title = module.name;
        cm.detailText = [NSString stringWithFormat:@"RSSI: %lddBm", (long)module.rssi];
        return cm;
    };
    
    [_tableView reloadData];
}

- (void) startToAdertise {
//    [_manager stopScan];
//    MTPeripheralManager *pm = [MTPeripheralManager sharedInstance];
//
//    NSString *adverStr = [self hexStringFromString:_contentTF.text];
//    NSLog(@"转换后的16进制字符串===%@",adverStr);
//    if (_contentTF.text.length > 0) {
//        NSString *first = [_contentTF.text substringToIndex:1];
////        if ([first integerValue] >= [@"D" integerValue]) {
////            first = @"D";
////        }
//        //        _searchstr = [NSString stringWithFormat:@"0x180%@",first];
//
//        pm.searchstr = [NSString stringWithFormat:@"0x180%@",first];
//    }else {
//        pm.searchstr = @"0x180D";
//    }
////    NSString *testStr = _contentTF.text.length>0?_contentTF.text:@"TestUUID_8888";
//    [pm startAdvtising];
    
//    [_manager stopScan];
    
    StartAdvertiseViewController *adVC = [[StartAdvertiseViewController alloc] init];
    
    [self.navigationController pushViewController:adVC animated:YES];
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

- (void)scanButtonClick:(UIButton *)sender
{
    [_manager stopScan];
    [_manager startScan];
}


- (void)startToSetup {
    SettingViewController *setVC = [[SettingViewController alloc] init];
    
    [self.navigationController pushViewController:setVC animated:YES];

}

- (void)infoButtonClick:(UIButton *)sender
{
    BYInfoViewController *bvc = [[BYInfoViewController alloc]init];
    [self.navigationController pushViewController:bvc animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_contentTF resignFirstResponder];
    return YES;
}


#pragma mark - 键盘通知
- (void)addNoticeForKeyboard {
    
    //注册键盘出现的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    //注册键盘消失的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

///键盘显示事件
- (void) keyboardWillShow:(NSNotification *)notification {
    //获取键盘高度，在不同设备上，以及中英文下是不同的
    CGFloat kbHeight = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    //计算出键盘顶端到inputTextView panel底端的距离(加上自定义的缓冲距离INTERVAL_KEYBOARD)
    CGFloat offset = (_contentTF.frame.origin.y+_contentTF.frame.size.height+INTERVAL_KEYBOARD) - (self.view.frame.size.height - kbHeight);
    
    // 取得键盘的动画时间，这样可以在视图上移的时候更连贯
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    //将视图上移计算好的偏移
    if(offset > 0) {
        [UIView animateWithDuration:duration animations:^{
            self.view.frame = CGRectMake(0.0f, -offset, self.view.frame.size.width, self.view.frame.size.height);
        }];
    }
}

///键盘消失事件
- (void) keyboardWillHide:(NSNotification *)notify {
    // 键盘动画时间
    double duration = [[notify.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    //视图下沉恢复原状
    [UIView animateWithDuration:duration animations:^{
        self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [_contentTF resignFirstResponder];
}
@end
