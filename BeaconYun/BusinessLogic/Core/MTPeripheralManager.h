//
//  MTPeripheralManager.h
//  Peripheral
//
//  Created by SACRELEE on 3/21/18.
//  Copyright © 2018 MinewTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef void(^StartChargeBlock)(void);

@interface MTPeripheralManager : NSObject

@property (nonatomic, strong, readonly) NSString *macString;
@property (nonatomic, copy) NSString *advstr;

@property (nonatomic, strong) CBUUID *advUUID;

@property (nonatomic, strong) NSMutableArray *advUUIDArray;
// 
@property (nonatomic, strong) NSData *lightData;

+ (instancetype)sharedInstance;

- (void)startAdvtising;

- (void)stopAdvertising;

- (void)didStartCharge:(StartChargeBlock)handler;

@end
