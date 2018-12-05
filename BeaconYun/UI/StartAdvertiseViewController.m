//
//  StartAdvertiseViewController.m
//  BeaconYun
//
//  Created by 樊芳 on 2018/12/3.
//  Copyright © 2018 MinewTech. All rights reserved.
//

#import "StartAdvertiseViewController.h"
#import "AdvertiseView.h"
#import "MTPeripheralManager.h"





@interface StartAdvertiseViewController ()
@property (nonatomic, strong) AdvertiseView *advertiseView;

@property (nonatomic, strong) NSMutableArray *commandAray;

@property (nonatomic, strong) MTPeripheralManager *pm;


@end

@implementation StartAdvertiseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"发送广播";
    [self initData];
    
//    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"back2"]];
    UIImageView *backImg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    backImg.image = [[UIImage imageNamed:@"back2"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    [self.view addSubview:backImg];

    MTPeripheralManager *pm = [MTPeripheralManager sharedInstance];
    pm.searchstr = [_commandAray firstObject];
    _pm = pm;
    
    [self initView];

}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    //退出页面，停止广播
    [_pm stopAdvertising];
}

- (void)initData {
    
    if (!_commandAray) {
        _commandAray = [NSMutableArray arrayWithObjects:@"00000000-aff4-0085-0021-fcfbfa002401",@"00000000-aff4-0085-0021-fcfbfa002402",
                        @"00000000-aff4-0085-0021-fcfbfa002403",@"00000000-aff4-0085-0021-fcfbfa002404",
                        @"00000000-aff4-0085-0021-fcfbfa002405",@"00000000-aff4-0085-0021-fcfbfa002406",
                        @"00000000-aff4-0085-0021-fcfbfa002407",@"00000000-aff4-0085-0021-fcfbfa002408",
                        @"00000000-aff4-0085-0021-fcfbfa002409",@"00000000-aff4-0085-0021-fcfbfa002410",nil];
    }
}

- (void)initView {
    
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
            NSLog(@"开始广播%@",strongSelf.commandAray[index]);
            
            strongSelf.pm.searchstr = strongSelf.commandAray[index];
            
            
            [strongSelf.pm startAdvtising];
        };
    }
    return _advertiseView;
}

@end
