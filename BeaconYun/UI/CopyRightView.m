//
//  CopyRightView.m
//  BeaconYun
//
//  Created by 樊芳 on 2019/10/25.
//  Copyright © 2019 MinewTech. All rights reserved.
//

#import "CopyRightView.h"

@implementation CopyRightView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self initView];
    }
    return self;
}

- (void)initView {
    _iconLabelName = [[UILabel alloc] init];
    [self addSubview:_iconLabelName];
    [_iconLabelName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).offset(60);
        make.top.equalTo(self.mas_bottom).offset(-70);
        make.size.mas_equalTo(CGSizeMake(70, 50));
    }];
    _iconLabelName.textColor = [UIColor cyanColor];
    _iconLabelName.text = @"Dexin";
    _iconLabelName.font = [UIFont boldSystemFontOfSize:22];
    
    _chLabelName = [[UILabel alloc] init];
    [self addSubview:_chLabelName];
    [_chLabelName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_iconLabelName.mas_right).offset(5);
        make.top.equalTo(self.mas_bottom).offset(-70);
        make.size.mas_equalTo(CGSizeMake(240, 30));
    }];
    _chLabelName.textColor = [UIColor blackColor];
    _chLabelName.text = @"深圳德鑫能源有限公司";
    _chLabelName.font = [UIFont systemFontOfSize:20];
    
    _enLabelName = [[UILabel alloc] init];
    [self addSubview:_enLabelName];
    [_enLabelName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_iconLabelName.mas_right).offset(5);
        make.top.equalTo(_chLabelName.mas_bottom);
        make.size.mas_equalTo(CGSizeMake(240, 20));
    }];
    _enLabelName.textColor = [UIColor blackColor];
    _enLabelName.text = @"Shenzhen Dexin Energy Co.Ltd";
    _enLabelName.font = [UIFont systemFontOfSize:14];
}
@end
