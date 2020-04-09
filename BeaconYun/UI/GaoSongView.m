//
//  GaoSongView.m
//  BeaconYun
//
//  Created by 樊芳 on 2020/3/3.
//  Copyright © 2020 MinewTech. All rights reserved.
//

#import "GaoSongView.h"

@interface GaoSongView ()
@property (nonatomic,strong)UIImageView *logoImgView;
@end

@implementation GaoSongView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _logoImgView = [[UIImageView alloc] init];
        [self addSubview:_logoImgView];
        
        [_logoImgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.mas_centerX);
            make.size.mas_equalTo(CGSizeMake(183, 60));
            make.bottom.equalTo(self.mas_bottom).offset(-15);
        }];
        _logoImgView.image = [UIImage imageNamed:@"gaosongLogo"];
    }
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
