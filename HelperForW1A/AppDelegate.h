//
//  AppDelegate.h
//  HelperForW1A
//
//  Created by 曹伟东 on 2019/1/21.
//  Copyright © 2019年 曹伟东. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "inputHelper.h"
#import "ScanWindowsTitle.h"
//parse Testplan.csv
#import "parseCSV.h"
#import "myPassWord.h"
#import "colorPlug.h"
//slot view
#import "SlotView.h"
#import "ConfigView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate,ConfigViewDelegate,PassWordDelegate,SlotViewDelegate>
{
    //main NSWindow ViewVontroller
    IBOutlet NSViewController *_mainVC;
    
    IBOutlet NSTabView *_tabView;
    IBOutlet NSTextField *_swNameTF;
    IBOutlet NSTextField *_swVersionTF;
    IBOutlet NSTextField *_passLabel;
    IBOutlet NSTextField *_failLabel;
    IBOutlet NSTextField *_yieldLabel;
    IBOutlet NSTextField *_watchdogLabel;
    IBOutlet NSButton *_clearYieldBtn;
    
    IBOutlet NSTextField *winTitleTF;
    IBOutlet NSTextField *workStatusTF;
    IBOutlet NSTextField *mouseX;
    IBOutlet NSTextField *mouseY;
    IBOutlet NSButton *startMouse;
    IBOutlet NSTextView *_logView;
    
    IBOutlet NSButton *_homeBtn;
    IBOutlet NSButton *_logBtn;
    IBOutlet NSButton *_setBtn;
    IBOutlet NSButton *_lockBtn;
    
    IBOutlet NSButton *_testButton;
    IBOutlet NSButton *_scanWinBtn;
    
    //GRR Mode
    IBOutlet NSTextField *_grrLabel;
    IBOutlet NSPopUpButton *_testModeBtn;
    myPassWord *_passwordVC;
    
    //Color View
    colorPlugView *_colorView;
    IBOutlet NSButton *_callColorViewBtn;
    
    //Devices panel View
    IBOutlet NSButton *setDevicesPanelBtn;
    IBOutlet NSButton *_setOffsetBtn;
    
    myConfigView *_configView;
    //upload Atmel32U4
    IBOutlet NSButton *_uplaodMCUBtn;
    //Queue for print logs
    dispatch_queue_t _printQueue;
    //Queue for replySerial
    dispatch_queue_t _replySerialQueue;
    
}

-(IBAction)setDevicesPanelBtnAction:(id)sender;
-(IBAction)btnStartMouse:(id)sender;
-(IBAction)testButtonAction:(id)sender;
-(IBAction)ScanWinBtnAction:(id)sender;

-(IBAction)homeBtnAction:(id)sender;
-(IBAction)logBtnAction:(id)sender;
-(IBAction)setBtnAction:(id)sender;

-(IBAction)lockBtnAction:(id)sender;
-(IBAction)clearYieldBtnAction:(id)sender;
-(IBAction)callColViewAction:(id)sender;

//mouse view

-(IBAction)setOffsetAction:(id)sender;
//upload mcu FW
-(IBAction)uploadMCUBtnAction:(id)sender;

/*Test Plan Item Index*/
#define TP_TESTITEMS_INDEX  0
#define TP_GROUP_INDEX      1
#define TP_FUNC_INDEX       2
#define TP_ACTION_INDEX        3
#define TP_POSITION_INDEX     4
#define TP_INPUT_INDEX     5
#define TP_PARAM1_INDEX     6
#define TP_PARAM2_INDEX        7
#define TP_PARAM3_INDEX  8
#define TP_RESPONSE_INDEX         9
#define TP_TIMEOUT_INDEX       10
#define TP_DELAY_INDEX      11
#define TP_EXITENABLE_INDEX 12
#define TP_SKIP_INDEX       13
//test plan struct
typedef struct TESTPLAN_DATA {
    NSMutableArray *itemsData;
    NSMutableArray *groupData;
    NSMutableArray *funcData;
    NSMutableArray *actionData;
    NSMutableArray *positionData;
    NSMutableArray *inputData;
    NSMutableArray *param1Data;
    NSMutableArray *param2Data;
    NSMutableArray *param3Data;
    NSMutableArray *responseData;
    NSMutableArray *timeoutData;
    NSMutableArray *delayData;
    NSMutableArray *exitEnableData;
    NSMutableArray *skipData;
} TP_DATA;

@end

//positionXY class
@interface PositionXY : NSObject
@property (nonatomic,assign) float x;
@property (nonatomic,assign) float y;
@end
