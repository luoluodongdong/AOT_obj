//
//  mySerialPanel.h
//  SoftwareApp
//
//  Created by 曹伟东 on 2019/4/15.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ORSSerialPort.h"
#import "ORSSerialPortManager.h"
#import "ORSSerialRequest.h"
#import "ORSSerialBuffer.h"

@protocol SerialPanelDelegate<NSObject>
-(void)receivedDataEvent:(NSString *)data id:(int )myID;
-(BOOL)saveConfigEvent:(NSDictionary *)info;

@end

@class ORSSerialPortManager;

@interface MySerialPanel: NSViewController<ORSSerialPortDelegate,SerialPanelDelegate>
{
    IBOutlet NSPopUpButton *_portBtn;
    IBOutlet NSPopUpButton *_baudBtn;
    IBOutlet NSButton *_openBtn;
    IBOutlet NSButton *_backBtn;
    IBOutlet NSButton *_scanBtn;
    IBOutlet NSButton *_saveBtn;
    IBOutlet NSTextField *_descriptionLB;
    //test part
    IBOutlet NSTextField *_commandTF;
    IBOutlet NSButton *_sendBtn;
    IBOutlet NSTextField *_logTF;
}

@property (nonatomic,weak) id<SerialPanelDelegate> delegate;
@property (nonatomic, strong) ORSSerialPortManager *serialPortManager;
@property (nonatomic, strong) ORSSerialPort *serialPort;

@property (nonatomic) NSString *_description;
@property (nonatomic) int _id;

-(void)initView;
-(BOOL)autoOpenSerial:(NSString *)serialName baud:(int )baudRate;
-(BOOL)sendCommand:(NSString *)cmd;
-(BOOL)sendCmd:(NSString *)cmd received:(NSString **)data withTimeOut:(double )to;

-(IBAction)openBtnAction:(id)sender;
-(IBAction)scanBtnAction:(id)sender;
-(IBAction)backBtnAction:(id)sender;
-(IBAction)saveBtnAction:(id)sender;
-(IBAction)sendBtnAction:(id)sender;

@end
