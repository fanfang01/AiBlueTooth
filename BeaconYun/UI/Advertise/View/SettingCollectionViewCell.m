//
//  SettingCollectionViewCell.m
//  BeaconYun
//
//  Created by 樊芳 on 2019/1/2.
//  Copyright © 2019 MinewTech. All rights reserved.
//

#import "SettingCollectionViewCell.h"

@implementation SettingCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.contentView.layer.cornerRadius = 5.;
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    if (selected) {
        NSLog(@"选中...");
        
    }else {
        NSLog(@"");
    }
}

- (void)setModule:(MinewModule *)module
{
    _module = module;
    self.deviceMacNameLabel.text = module.macString;

    if (module.isBind) {
        self.contentView.backgroundColor = RGB(254, 145, 212);
        self.deviceImageView.image = [UIImage imageNamed:@"device_select"];
        self.deviceBackImageView.hidden = NO;
    }else {
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.deviceImageView.image = [UIImage imageNamed:@"device_unselect"];
        self.deviceBackImageView.hidden = YES;
    }
}

@end
