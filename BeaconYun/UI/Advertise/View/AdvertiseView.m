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
//                       @{@"icon":@"icon_Suspendplay",@"title":NSLocalizedString(@"增大强度", nil)},
//                       @{@"icon":@"icon_Thenext",@"title":NSLocalizedString(@"减小强度", nil)},
//                       @{@"icon":@"icon_Switchlight",@"title":NSLocalizedString(@"开／关", nil)},
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
    [backImg setImage:[UIImage imageNamed:@"all_background"]];
    [_scrollView addSubview:backImg];
    

    if (ScreenHeight < 667) {
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
    for (NSInteger i = 0; i <= count; i++) {
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
    
    
    if (index == self.imageArray.count ) {
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(horSpacing+(viewWidth+imageSpacing)*2-50, 50 + (viewHeight+verSpacing)*(index/3)+20, 50, 37)];
        nameLabel.text = @"开/关";
        nameLabel.font = [UIFont systemFontOfSize:13];
        nameLabel.textColor = [UIColor whiteColor];
        [_scrollView addSubview:nameLabel];
        
        UISwitch *onSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(nameLabel.frame.origin.x+50, 60, 37, 41)];
        onSwitch.center = CGPointMake(nameLabel.center.x+(50+41)/2, nameLabel.center.y);
        _onSwitch = onSwitch;
        onSwitch.onTintColor = [UIColor cyanColor];
        [_scrollView addSubview:onSwitch];
        
    }else {
        ShakeSelectView *shakeView = [[ShakeSelectView alloc] initWithFrame:CGRectMake(horSpacing+(viewWidth+imageSpacing)*(index%3), 50 + (viewHeight+verSpacing)*(index/3), viewWidth, viewHeight)];
//        if (index == _imageArray.count-1) {
//            shakeView.frame = CGRectMake(horSpacing+(viewWidth+imageSpacing)*2, 50 + (viewHeight+verSpacing)*(index/3), viewWidth, viewHeight);
//        }
        [self.totalsBtnArray addObject:shakeView.selButton];
        if (0 == index) {
            _currentSelBtn = shakeView.selButton;
            _currenthakeView = shakeView;
        }
        
        [_scrollView addSubview:shakeView];
        
        shakeView.titleName = self.imageArray[index][@"title"];
        shakeView.btnImageName = self.imageArray[index][@"icon"];
        
        [shakeView setShakeToSelect:^(UIButton *btn) {
            
            
            NSInteger index = [self.totalsBtnArray indexOfObject:btn];
            _currenthakeView.isSelect = NO;//取消上一个view的选中效果
            _currenthakeView = shakeView;
            
            
            if (self.buttonBlock) {
                self.buttonBlock(index);
            }
            
        }];
        return shakeView;

    }
    return nil;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    if (selectedIndex < 0) {
        if (selectedIndex == -1) {

            _currenthakeView.isSelect = NO;
            _currenthakeView = nil;
            return;
        }else {
            selectedIndex = 0;
        }
    }
    if (selectedIndex == self.imageArray.count ) {
        selectedIndex = 10;
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"最大模式为%ld",(long)self.imageArray.count]];
        [self SVDismiss];
        return;
    }
    if (selectedIndex > self.imageArray.count) {
        selectedIndex = self.imageArray.count - 1;
    }
    _selectedIndex = selectedIndex;
    
    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"当前模式为%ld",(long)_selectedIndex+1]];
    [self SVDismiss];

    UIButton *selBtn = self.totalsBtnArray[selectedIndex];
    ShakeSelectView *shakeView = (ShakeSelectView *)[selBtn.superview superview];
    _currenthakeView.isSelect = NO;
    
    shakeView.isSelect = YES;
    _currenthakeView = shakeView;
    
}

- (void)SVDismiss {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
}

@end
