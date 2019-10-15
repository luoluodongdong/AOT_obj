//
//  mySerialPanel.h
//  SoftwareApp
//
//  Created by 曹伟东 on 2019/4/15.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol VisaPanelDelegate<NSObject>
//-(void)receivedDataEvent:(NSString *)data withID:(int )myID;
-(BOOL)saveConfigEvent:(NSDictionary *)info;

@end


@interface MyVisaPanel: NSViewController<VisaPanelDelegate>
{
    IBOutlet NSPopUpButton *_portBtn;
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

@property (nonatomic,weak) id<VisaPanelDelegate> delegate;

@property (nonatomic) NSString *_description;
@property (nonatomic) int _id;
@property (nonatomic) int _instrFD;

-(void)initView;
-(BOOL)autoOpenInstrument:(NSString *)addr timeout:(int )to;
-(BOOL)sendCommand:(NSString *)cmd;
-(NSString *)queryInstr:(NSString *)cmd;

//PUBLIC FUNC
-(NSString *)getInstrName;
-(BOOL)resetInstrument;
-(void)closeInstrument;

//3497XX
//cable:@"2"/4 channels:@"@101:113"
-(NSString *)meas34970ResWithCable:(NSString *)cable withChannels:(NSString *)channels;

//DMM 34465
-(BOOL)initDMM;
//cable:@"2"/4
-(NSString *)measDMMResWithCable:(NSString *)cable;
-(NSString *)measDMMDiode;
//config:@"AUTO,DEF"
-(NSString *)measDMMCap:(NSString *)config;
//config:@"DC AUTO,DEF"
-(NSString *)measDMMVolt:(NSString *)config;
//config:@"DC AUTO,DEF"
-(NSString *)measDMMCurr:(NSString *)config;

//LOAD 63600
-(BOOL)loadON;
-(BOOL)loadOFF;
//mode:@"CCH" channel:@"L1" current:@"2.4" A
-(BOOL)loadWithMode:(NSString *)mode Channel:(NSString *)ch Curr:(NSString *)cu;
-(NSString *)loadMeasPow:(NSString *)channel;
-(NSString *)loadMeasVolt:(NSString *)channel;
-(NSString *)loadMeasCurr:(NSString *)channel;

//POWER 3615
-(BOOL)initPower;
//ch:@"1"/2/3  vl:(1/2)@"5.0"---36.0 (3)0.0-7.0  cr:@"0.2"
-(BOOL)outputPowerChannel:(NSString *)ch Volt:(NSString *)vl Curr:(NSString *)cr;
-(NSString *)measPOWERVolt:(NSString *)channel;
-(NSString *)measPOWERCurr:(NSString *)channel;
-(BOOL)outputPowerOFF;


-(IBAction)openBtnAction:(id)sender;
-(IBAction)scanBtnAction:(id)sender;
-(IBAction)backBtnAction:(id)sender;
-(IBAction)saveBtnAction:(id)sender;
-(IBAction)sendBtnAction:(id)sender;

@end
