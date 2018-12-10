//
//  AdvertiseView.m
//  BeaconYun
//
//  Created by 樊芳 on 2018/12/3.
//  Copyright © 2018 MinewTech. All rights reserved.
//

#import "AdvertiseView.h"
#import "ShakeSelectView.h"

@interface AdvertiseView ()
@property (strong, nonatomic) NSMutableArray *imageArray;
/**
 * 记录全部的 按钮
 */
@property (strong, nonatomic) NSMutableArray *totalsBtnArray;

@end

@implementation AdvertiseView
{
    NSMutableArray *_dataArray;
    UIButton *_currentSelBtn;
    ShakeSelectView *_currenthakeView;
    UIScrollView *_scrollView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initData];
        
        [self initView];
    }
    
    return self;
}

- (void)initData {
//    if (!_dataArray) {
//        _dataArray = [NSMutableArray arrayWithObjects:@"模式1",@"模式2",@"模式3",@"模式4",@"模式5",@"模式6",@"模式7",@"模式8",@"模式9",@"模式10", nil];
//    }
    if (!_imageArray) {
        _imageArray = [NSMutableArray arrayWithObjects:
                       @{@"icon":@"icon_Randomcolor",@"title":NSLocalizedString(@"模式1", nil)},
                       @{@"icon":@"icon_Randomcolor",@"title":NSLocalizedString(@"模式2", nil)},
                       @{@"icon":@"icon_Randomcolor",@"title":NSLocalizedString(@"模式3", nil)},
                       @{@"icon":@"icon_Randomcolor",@"title":NSLocalizedString(@"模式4", nil)},
                       @{@"icon":@"icon_Randomcolor",@"title":NSLocalizedString(@"模式5", nil)},
                       @{@"icon":@"icon_Randomcolor",@"title":NSLocalizedString(@"模式6", nil)},
                       @{@"icon":@"icon_Randomcolor",@"title":NSLocalizedString(@"模式7", nil)},
                       @{@"icon":@"icon_Randomcolor",@"title":NSLocalizedString(@"模式8", nil)},
                       @{@"icon":@"icon_Randomcolor",@"title":NSLocalizedString(@"模式9", nil)},
                       @{@"icon":@"icon_Randomcolor",@"title":NSLocalizedString(@"模式10", nil)},
                       @{@"icon":@"icon_Suspendplay",@"title":NSLocalizedString(@"增大强度", nil)},
                       @{@"icon":@"icon_Thenext",@"title":NSLocalizedString(@"减小强度", nil)},
                       @{@"icon":@"icon_Switchlight",@"title":NSLocalizedString(@"开／关灯", nil)},
                       nil];
    }
    if (!_totalsBtnArray) {
        _totalsBtnArray = [NSMutableArray array];
    }
}

- (void)initView {
//    CGFloat buttonWidth = (screenWidth-40)/2;
//    CGFloat buttonHeight = 50;
//
//    for (NSInteger i=0; i<_dataArray.count; i++) {
//        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
//        [button setFrame:CGRectMake(10+(buttonWidth+20)*(i%2), 100+(buttonHeight+10)*(i/2), buttonWidth, buttonHeight)];
//
//        [button setTitle:_dataArray[i] forState:UIControlStateNormal];
//        [button setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
//        button.backgroundColor = [UIColor lightGrayColor];
//        button.layer.cornerRadius = 10;
//        button.layer.masksToBounds = YES;
//        [self addSubview:button];
//        button.tag = 100 + i;
//        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
//    }
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    [self addSubview:_scrollView];
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.contentSize = CGSizeMake(ScreenWidth, [UIScreen mainScreen].bounds.size.height);
    
    UIImageView *backImg = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [backImg setImage:[UIImage imageNamed:@"icon_backimg"]];
    [_scrollView addSubview:backImg];

    if (ScreenHeight<667) {
        _scrollView.contentSize = CGSizeMake(ScreenWidth, 667);
        backImg.frame = CGRectMake(0, 0, ScreenWidth, 667);
    }


    
//    UIImageView *phoneImgView = [[UIImageView alloc] init];
//    [self addSubview:phoneImgView];
//    [phoneImgView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.equalTo(self.mas_top).offset(20);
//        make.centerX.equalTo(self.mas_centerX);
//        make.size.mas_equalTo(CGSizeMake(175, 175));
//    }];
//    [phoneImgView setImage:[UIImage imageNamed:@"icon_Shakeashake"]];
    
    NSInteger count = self.imageArray.count;
    for (NSInteger i = 0; i < count; i++) {
        [self createImageView:i];
    }
    
}

- (UIView *)createImageView:(NSInteger)index
{
    CGFloat viewHeight = 80;
    CGFloat viewWidth = 66;
    //    CGFloat imageWidth = 46;
    CGFloat verSpacing = 30;
    CGFloat horSpacing = 54;
    CGFloat imageSpacing = (ScreenWidth - horSpacing*2-viewWidth*3)/2;
    
    ShakeSelectView *shakeView = [[ShakeSelectView alloc] initWithFrame:CGRectMake(horSpacing+(viewWidth+imageSpacing)*(index%3), 50 + (viewHeight+verSpacing)*(index/3), viewWidth, viewHeight)];
    if (index == _imageArray.count-1) {
        shakeView.frame = CGRectMake((ScreenWidth-viewWidth)/2., 50 + (viewHeight+verSpacing)*(index/3), viewWidth, viewHeight);
    }
    [self.totalsBtnArray addObject:shakeView.selButton];
    if (0 == index) {
        _currentSelBtn = shakeView.selButton;
        _currenthakeView = shakeView;
    }
    
    [_scrollView addSubview:shakeView];
    
    shakeView.titleName = self.imageArray[index][@"title"];
    shakeView.btnImageName = self.imageArray[index][@"icon"];
    
    [shakeView setShakeToSelect:^(UIButton *btn) {
        _currenthakeView.isSelect = NO;
        _currenthakeView = shakeView;

        NSInteger index = [self.totalsBtnArray indexOfObject:btn];
        if (self.buttonBlock) {
            self.buttonBlock(index);
        }
    }];
    return shakeView;
}

//- (void)buttonClick:(UIButton *)btn {
//    NSInteger index = btn.tag - 100;
//    if (self.buttonBlock) {
//        self.buttonBlock(index);
//    }
//}
@end