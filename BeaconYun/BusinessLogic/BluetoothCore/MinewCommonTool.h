//
//  CommonTool.h
//  YlwlBeaconManager
//
//  Created by SACRELEE on 16/8/11.
//  Copyright © 2016年 com.YLWL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MinewCommonTool : NSObject

@property (nonatomic, assign) NSInteger producetNumber;

// delete char in a string
+ (NSString *)deleteCharacter:(char)cha ofString:(NSString *)string;

// exchange hexstring to decimal
+ (NSInteger)decimalFromHexString:(NSString *)hexStr;

// signed hex to integer
+ (NSInteger)signedHexToInteger:(NSString *)hexStr;

// replace a char with another in a string
+ (NSString *)replaceCharacter:(char)originCha withCharacter:(char)newCha ofString:(NSString *)string;

// execute block on mainthread
+ (void)onMainThread:(void(^)())block;

// execute block on a special thread
+ (void)onThread:(dispatch_queue_t)queue execute:(void(^)())block;

// get real data string of bluetooth advertisement
+ (NSString *)getDataString:(NSObject *)data;

// calculate distance by a rssi value
+ (float)distanceByRSSI:(NSInteger)rssi;

//get current language
+ (NSString *)getCurrentLanguage;

//16 进制转 10进制
+ (NSNumber *) numberHexString:(NSString *)aHexString;

//NSString 转16进制
- (NSString *)hexStringFromString:(NSString *)string;

+ (NSInteger)getProductNumber;

+ (void)saveProductNumber:(NSInteger)num;


@end
