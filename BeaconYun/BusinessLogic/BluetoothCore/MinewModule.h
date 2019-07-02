//
//  MinewModule.h
//  MinewModuleDemo
//
//  Created by SACRELEE on 11/16/16.
//  Copyright © 2016 SACRELEE. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ConnectionState) {
    StateConnected,
    StateDisconnected,
};

//typedef NS_ENUM(NSUInteger,ConnectState) {
//    ConnectStateUnkown = 0,
//    ConnectStateAdvertise,
//    ConnectStateBLE
//};


struct InstructionSend {
    uint8_t Command_id;
    uint8_t key;//设备模式设置
    uint8_t Status;//状态 0:待机 1:工作
    uint8_t Mode;//具体的工作模式
};

@class MinewModule;

typedef void(^Connection)(NSDictionary *dataDict, MinewModule *module);
typedef void(^Receive)(NSData *data);
typedef void(^Send)(BOOL result);

@class CBPeripheral;

@interface MinewModule : NSObject
//工作模式
//@property (nonatomic,assign)ConnectState connectState;

@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, strong) NSString *UUID;

@property (nonatomic, assign) BOOL connecting;

@property (nonatomic, assign) BOOL activeDisconnect;

@property (nonatomic, strong) NSDate *updateTime;

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSString *customName;

//目前只有MacAddress
@property (nonatomic, strong) NSData *manufactureData;
@property (nonatomic, strong) NSString *macString;
@property (nonatomic, assign) uint16_t macBytes;

@property (nonatomic, assign) NSInteger rssi;

@property (nonatomic, assign) NSInteger battery;

@property (nonatomic, assign) BOOL inRange;

@property (nonatomic, assign) BOOL isBind;

//是否可以被连接
@property (nonatomic, assign) BOOL canConnect;

@property (nonatomic, assign) BOOL connected;

@property (nonatomic, copy) Connection connectionHandler;

@property (nonatomic, copy) Receive receiveHandler;

@property (nonatomic, copy) Send writeHandler;


- (instancetype)initWithPeripheral:(CBPeripheral *)per infoDict:(NSDictionary *)info;

// write data to module
- (void)writeData:(NSData *)data hex:(BOOL)hex;


- (void)didConnect;
- (void)didDisconnect;
- (void)didConnectFailed;

@end
