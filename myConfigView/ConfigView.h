//
//  ConfigView.h
//  TT_ICT
//
//  Created by Weidong Cao on 2019/6/11.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "mySerialPanel.h"
#import "myVisaPanel.h"
#import "mySocketPanel.h"

@protocol ConfigViewDelegate<NSObject>

-(void)msgFromConfigView:(NSString *)msg;

@end

@interface myConfigView : NSViewController<ConfigViewDelegate,SerialPanelDelegate,VisaPanelDelegate,SocketPanelDelegate>
{
    IBOutlet NSButton *backBtn;
    IBOutlet NSPopUpButton *devicesPopBtn;
    IBOutlet NSViewController *configVC;
    
    IBOutlet NSButton *_takeSamplesBtn;
    IBOutlet NSTextField *_printLocationTF;
    IBOutlet NSButton *_getPositonsBtn;
    IBOutlet NSPopUpButton *_positionUpBtn;
    IBOutlet NSButton *_monitorBtn;
    
}

@property (nonatomic,weak) id<ConfigViewDelegate> delegate;
@property (nonatomic,strong) NSString *dictKey;

-(void)initView;
-(void)closeDevices;

/*DUT serial port*/
//thiCommand:send a Command
//thisTimeOut:received data until "\n"
//return: received data (if timeout,will be "TIMEOUT")
-(NSString *)sendCmd:(NSString *)thisCommand TimeOut:(double )thisTimeOut withName:(NSString *)name;
-(BOOL)justSendCmd:(NSString *)command withName:(NSString *)name;

-(IBAction)backBtnAction:(id)sender;

-(IBAction)devicesPopBtnAction:(id)sender;

//mouse keyboard part
@property (nonatomic,strong) MySerialPanel *MK_SerialPanel;
@property (nonatomic,strong) NSString *winOwner;

-(IBAction)takeSamplesAction:(id)sender;
-(IBAction)getPositionsAction:(id)sender;
-(IBAction)positionUpBtnAction:(id)sender;
-(IBAction)monitorBtnAction:(id)sender;
//check connect is OK?
-(BOOL)mouseIsOK;
//load samples data
//step:1--0.212321 2-0.321451 3-0.643320
-(void)loadSamplesData;
//mouse goto (0,0)
-(NSString *)gotoZero;
//mouse move to target (x,y)
-(NSString *)justMoveWithTargetX:(float )target_x TargetY:(float )target_y;
//mouse move to (x,y) and click left button
-(NSString *)moveAndClickWithTargetX:(float )target_x TargetY:(float )target_y;
//keyboard input string
-(NSString *)inputString:(NSString *)str;

@end
//封装一个device类
@interface MY_DEVICE : NSObject
@property (nonatomic,strong) NSString *Desctription;
@property (nonatomic,strong) NSString *Name;
@property (nonatomic,assign) BOOL Enable;
@property (nonatomic,assign) int ID;
@property (nonatomic,strong) NSString *Type;
@property (nonatomic,strong) NSString *Addr;
@property (nonatomic,assign) int BaudRate;
@property (nonatomic,strong) NSString *Mode;
@property (nonatomic,strong) NSString *IP;
@property (nonatomic,assign) int Port;
@property (nonatomic,assign) BOOL isOpened;
@property (nonatomic,strong) MySerialPanel *serial;
@property (nonatomic,strong) MyVisaPanel *instrument;
@property (nonatomic,strong) MySocketPanel *socket;
//声明device类方法
-(NSString *)sendCmd:(NSString *)thisCommand withTimeOut:(double)thisTimeOut;
-(BOOL)justSendCmd:(NSString *)command;
-(void)closeDevice;

@end
