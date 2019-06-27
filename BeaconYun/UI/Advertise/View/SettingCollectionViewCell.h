//
//  SettingCollectionViewCell.h
//  BeaconYun
//
//  Created by 樊芳 on 2019/1/2.
//  Copyright © 2019 MinewTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MinewModule.h"

NS_ASSUME_NONNULL_BEGIN

@interface SettingCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *deviceImageView;
@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceMacNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *deviceBackImageView;

@property (nonatomic, strong) MinewModule *module;
@end

NS_ASSUME_NONNULL_END
