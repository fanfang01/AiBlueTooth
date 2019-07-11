//
//  StartAdvertiseViewController.h
//  BeaconYun
//
//  Created by 樊芳 on 2018/12/3.
//  Copyright © 2018 MinewTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MinewModule.h"

NS_ASSUME_NONNULL_BEGIN


@interface StartAdvertiseViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *onOffBtn;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (nonatomic, strong) MinewModule *testmodule;

@property (weak, nonatomic) IBOutlet UIButton *firstButton;
@property (weak, nonatomic) IBOutlet UIImageView *bakImgView;

@property (weak, nonatomic) IBOutlet UIButton *sendFirstButton;
@property (weak, nonatomic) IBOutlet UIButton *thirdFirstButton;
@property (weak, nonatomic) IBOutlet UIButton *lastButton;


@end

NS_ASSUME_NONNULL_END
