//
//  ConfigView.m
//  TT_ICT
//
//  Created by Weidong Cao on 2019/6/11.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import "ConfigView.h"

@implementation MY_DEVICE

-(NSString *)sendCmd:(NSString *)thisCommand withTimeOut:(double)thisTimeOut{
    NSString *response=@"";
    if ([_Type isEqualToString:@"SERIAL"] ) {
        BOOL isTimeOut=[_serial sendCmd:thisCommand received:&response withTimeOut:thisTimeOut];
        if (isTimeOut) {
            return @"TIMEOUT";
        }else{
            return response;
        }
    }
    else if([_Type isEqualToString:@"INSTR"]){
        NSString *response=[_instrument queryInstr:thisCommand];
        if ([response isEqualToString:@""]) {
            return @"TIMEOUT";
        }else{
            return response;
        }
    }
    else if([_Type isEqualToString:@"SOCKET"]){
        _socket.timeout=thisTimeOut;
        response=[_socket query:thisCommand];
        if ([response isEqualToString:@""]) {
            return @"TIMEOUT";
        }else{
            return response;
        }
    }
    return @"";
}
-(BOOL)justSendCmd:(NSString *)command{
    if ([_Type isEqualToString:@"SERIAL"] ) {
        return [_serial sendCommand:command];
    }
    else if([_Type isEqualToString:@"INSTR"]){
        return [_instrument sendCommand:command];
    }
    else if([_Type isEqualToString:@"SOCKET"]){
        return [_socket sendCommand:command];
    }
    return NO;
}
-(void)closeDevice{
    if ([_Type isEqualToString:@"SERIAL"]) {
        //Serial port
        if (_serial.serialPort.isOpen) {
            [_serial.serialPort close];
        }
    }
    else if([_Type isEqualToString:@"INSTR"]){
        //visa panel
        [_instrument closeInstrument];
        
    }
    else if([_Type isEqualToString:@"SOCKET"]){
        //socket panel
        [_socket stopSocket];
        
    }
}
@end

@interface myConfigView ()
{
    NSTimer *mouseXYtimer;
    NSMutableDictionary *dbPlist_rootSet;
    NSDictionary *positionSet;
    NSMutableArray *_disSamplesArr;
}

//@property (nonatomic,strong) MySerialPanel *mySerialPanel;
@property (nonatomic,strong) NSString *configPlist;
@property (nonatomic,strong) NSDictionary *rootSet;
@property (nonatomic,strong) NSDictionary *ConfigDict;
@property (nonatomic,strong) NSMutableDictionary *devicesDic;
//@property (atomic,strong) NSString *recData;
@end

@implementation myConfigView
- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *desc=[NSString stringWithFormat:@"%@ Config View",_dictKey];
    [backBtn setToolTip:@"Return Main View"];
    [self setTitle:desc];
    [self.view setAutoresizesSubviews:NO];
    [devicesPopBtn removeAllItems];
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *filePath;
    filePath=[rawfilePath stringByAppendingPathComponent:_configPlist];
    _rootSet=[[NSDictionary alloc] initWithContentsOfFile:filePath];
    //NSString *slot_key=[NSString stringWithFormat:@"Slot-%d",self.slot_ID];
    
    _ConfigDict=[_rootSet objectForKey:_dictKey];
    NSArray *keysArr=[_ConfigDict allKeys];
    for (NSString *key in keysArr) {
        NSDictionary *dev=[_ConfigDict objectForKey:key];
        BOOL dev_enable=[[dev objectForKey:@"Enable"] boolValue];
        if (NO == dev_enable) {
            continue;
        }
        [devicesPopBtn addItemWithTitle:key];
    }
    
    //NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    filePath=[rawfilePath stringByAppendingPathComponent:@"positions.plist"];
    dbPlist_rootSet=[[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    
    [_positionUpBtn removeAllItems];
    NSArray *keys=[dbPlist_rootSet allKeys];
    [_positionUpBtn addItemsWithTitles:keys];
    [_positionUpBtn selectItemAtIndex:0];
    positionSet=[dbPlist_rootSet objectForKey:[keys objectAtIndex:2]];
    
}

-(void)initView{
    //configVC=[[NSViewController alloc] init];
    _devicesDic=[[NSMutableDictionary alloc] initWithCapacity:1];
    
    _configPlist=@"config.plist";
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *filePath;
    filePath=[rawfilePath stringByAppendingPathComponent:_configPlist];
    _rootSet=[[NSDictionary alloc] initWithContentsOfFile:filePath];
    //NSString *slot_key=[NSString stringWithFormat:@"Slot-%d",self.slot_ID];
    _ConfigDict=[_rootSet objectForKey:_dictKey];
    
    NSArray *keysArr=[_ConfigDict allKeys];
    NSLog(@"my config keys:%@",keysArr);
    BOOL ALL_DEVICES_IS_READY = YES;
    for (NSString *key in keysArr) {
        NSDictionary *dev=[_ConfigDict objectForKey:key];
        MY_DEVICE *myDevice=[[MY_DEVICE alloc] init];
        myDevice.Name=[dev objectForKey:@"Name"];
        myDevice.Desctription=[dev objectForKey:@"Description"];
        myDevice.Enable=[[dev objectForKey:@"Enable"] boolValue];
        myDevice.ID=[[dev objectForKey:@"ID"] intValue];
        myDevice.Type=[dev objectForKey:@"Type"];
        
        if (NO == myDevice.Enable) {
            continue;
        }
        
        if ([myDevice.Type isEqualToString:@"SERIAL"]) {
            myDevice.Addr=[dev objectForKey:@"Addr"];
            myDevice.BaudRate=[[dev objectForKey:@"BaudRate"] intValue];
            //*****************Serialport Pannel 1**************//
            MySerialPanel *mySerialPanel=[[MySerialPanel alloc] initWithNibName:@"mySerialPanel" bundle:nil];
            mySerialPanel._description=myDevice.Desctription;
            mySerialPanel._id=myDevice.ID;
            mySerialPanel.delegate=self;
            //_mySerialPanel.serialPort.usesRTSCTSFlowControl=TRUE;
            //_mySerialPanel.serialPort.usesDTRDSRFlowControl=TRUE;
            [mySerialPanel initView];
            BOOL result=[mySerialPanel autoOpenSerial:myDevice.Addr baud:myDevice.BaudRate];
            NSLog(@"auto open serial result:%hhd",result);
            if (!result) {
                NSLog(@"Auto open serial fail!");
                ALL_DEVICES_IS_READY = NO;
                [self alarmPanel:[NSString stringWithFormat:@"[%@]Auto Open %@ port error!",_dictKey,myDevice.Addr]];
            }
            //PIN status output
            mySerialPanel.serialPort.DTR=TRUE;
            mySerialPanel.serialPort.RTS=TRUE;
            //******************End***************************//
            myDevice.isOpened = result;
            myDevice.serial=mySerialPanel;
            [_devicesDic setObject:myDevice forKey:myDevice.Name];
        }
        else if([myDevice.Type isEqualToString:@"INSTR"]){
            myDevice.Addr=[dev objectForKey:@"Addr"];
            myDevice.BaudRate=[[dev objectForKey:@"BaudRate"] intValue];
            
            MyVisaPanel *myVisaPanel=[[MyVisaPanel alloc] initWithNibName:@"myVisaPanel" bundle:nil];
            myVisaPanel._description=myDevice.Desctription;
            myVisaPanel._id=myDevice.ID;
            myVisaPanel.delegate=self;
            [myVisaPanel initView];
            
            BOOL result=[myVisaPanel autoOpenInstrument:myDevice.Addr timeout:2000];
            if (!result) {
                NSLog(@"Auto open instrument fail!");
                ALL_DEVICES_IS_READY = NO;
                [self alarmPanel:[NSString stringWithFormat:@"[%@]Auto Open %@ instrument error!",_dictKey,myDevice.description]];
            }
            myDevice.isOpened = result;
            myDevice.instrument=myVisaPanel;
            [_devicesDic setObject:myDevice forKey:myDevice.Name];
            
        }
        else if([myDevice.Type isEqualToString:@"SOCKET"]){
            myDevice.IP=[dev objectForKey:@"IP"];
            myDevice.Port=[[dev objectForKey:@"Port"] intValue];
            NSString *dev_mode=[dev objectForKey:@"Mode"];
            
            //******************Socket Panel***************************//
            MySocketPanel *mySocketPanel=[[MySocketPanel alloc] initWithNibName:@"mySocketPanel" bundle:nil];
            mySocketPanel._description=myDevice.Desctription;
            mySocketPanel._id=myDevice.ID;
            mySocketPanel.delegate=self;
            mySocketPanel.mode=dev_mode;
            mySocketPanel.timeout=2.0;
            [mySocketPanel initView];
            BOOL result=[mySocketPanel autoStartSocket:myDevice.IP port:myDevice.Port];
            if (!result) {
                ALL_DEVICES_IS_READY = NO;
                [self alarmPanel:[NSString stringWithFormat:@"[%@]Auto Open %@ port error!",_dictKey,myDevice.Desctription]];
            }
            //******************End***************************//
            myDevice.isOpened = result;
            myDevice.socket=mySocketPanel;
            [_devicesDic setObject:myDevice forKey:myDevice.Name];
        }
        
    }
    NSLog(@"%@",_devicesDic);
    MY_DEVICE *myDevice=[_devicesDic objectForKey:@"MK"];
    _MK_SerialPanel = myDevice.serial;
    if (YES == ALL_DEVICES_IS_READY) {
        [self.delegate msgFromConfigView:@"STATUS:1"];
    }else{
        [self.delegate msgFromConfigView:@"STATUS:0"];
    }
    
}
//close all opened devices
-(void)closeDevices{
    NSLog(@"closeDevices working...");
    NSArray *dev_keys=[_devicesDic allKeys];
    for(NSString *item in dev_keys){
        MY_DEVICE *myDevice=[_devicesDic objectForKey:item];
        [myDevice closeDevice];
    }
}
//return unit view
-(IBAction)backBtnAction:(id)sender{
    [self.delegate msgFromConfigView:@"Close ConfigView"];
    
    [self dismissViewController:self];
}

-(IBAction)devicesPopBtnAction:(id)sender{
    
    NSString *click_key=[[devicesPopBtn selectedItem] title];
    NSLog(@"PopUpBtn selected:%@",click_key);
    NSDictionary *dev=[_ConfigDict objectForKey:click_key];
    NSString *dev_name=[dev objectForKey:@"Name"];
    NSString *dev_type=[dev objectForKey:@"Type"];
    
    MY_DEVICE *myDevice=[_devicesDic objectForKey:dev_name];
    if ([dev_type isEqualToString:@"SERIAL"]) {
        [configVC presentViewControllerAsSheet:myDevice.serial];
    }
    else if([dev_type isEqualToString:@"INSTR"]){
        [configVC presentViewControllerAsSheet:myDevice.instrument];
    }
    else if([dev_type hasSuffix:@"SOCKET"]){
        [configVC presentViewControllerAsSheet:myDevice.socket];
    }
    else{
        NSString *msg=[NSString stringWithFormat:@"Error:unkown device:%@ Please check DevicesConfig.plist!",dev_type];
        [self alarmPanel:msg];
    }
}
//send cmd with timeout,return response string
-(NSString *)sendCmd:(NSString *)thisCommand TimeOut:(double)thisTimeOut withName:(NSString *)name{
    MY_DEVICE *myDevice=[_devicesDic objectForKey:name];
    return [myDevice sendCmd:thisCommand withTimeOut:thisTimeOut];
}
-(BOOL)justSendCmd:(NSString *)command withName:(NSString *)name{
    MY_DEVICE *myDevice=[_devicesDic objectForKey:name];
    return [myDevice justSendCmd:command];
}
#pragma mySerialPanel delegate event
//receive data
- (void)receivedDataEvent:(NSString *)data id:(int)myID {
    NSLog(@"id:%d rec data:%@",myID,data);
    //_recData=[_recData stringByAppendingString:data];
    //NSString *msg=[NSString stringWithFormat:@"SERIAL#%@",data];
    //[self.delegate msgFromConfigView:msg];
}
#pragma socket panel delegate event
-(void)receivedData:(NSString *)data{
    NSString *msg=[NSString stringWithFormat:@"SOCKET#%@",data];
    [self.delegate msgFromConfigView:msg];
}
//save config info---serial/instrument/socket
-(BOOL)saveConfigEvent:(NSDictionary *)info{
    NSString *dev_type=[info objectForKey:@"Type"];
    int myID = [[info objectForKey:@"ID"] intValue];
    int index = myID / 1000;
    NSString *dev_key=[NSString stringWithFormat:@"Device%d",index];
    NSDictionary *dev_dic=[_ConfigDict objectForKey:dev_key];
    NSString *dev_name=[dev_dic objectForKey:@"Name"];
    if ([dev_type isEqualToString:@"SERIAL"]) {
        [dev_dic setValue:[info objectForKey:@"Addr"] forKey:@"Addr"];
        [dev_dic setValue:[info objectForKey:@"BaudRate"] forKey:@"BaudRate"];
    }
    else if([dev_type isEqualToString:@"INSTR"]){
        [dev_dic setValue:[info objectForKey:@"Addr"] forKey:@"Addr"];
    }
    else if([dev_type isEqualToString:@"SOCKET"]){
        [dev_dic setValue:[info objectForKey:@"Mode"] forKey:@"Mode"];
        [dev_dic setValue:[info objectForKey:@"IP"] forKey:@"IP"];
        [dev_dic setValue:[info objectForKey:@"Port"] forKey:@"Port"];
    }
    [_ConfigDict setValue:dev_dic forKey:dev_key];
    //NSString *slot_key=[NSString stringWithFormat:@"Slot-%d",self.slot_ID];
    [_rootSet setValue:_ConfigDict forKey:_dictKey];
    NSString *portFilePath=[[NSBundle mainBundle] resourcePath];
    portFilePath =[portFilePath stringByAppendingPathComponent:_configPlist];
    [_rootSet writeToFile:portFilePath atomically:NO];
    
    MY_DEVICE *myDevice=[_devicesDic objectForKey:dev_name];
    myDevice.isOpened = YES;
    [_devicesDic setObject:myDevice forKey:dev_name];
    BOOL all_devices_is_ready = YES;
    for (MY_DEVICE *myDev in [_devicesDic allValues]) {
        if (!myDev.isOpened) {
            all_devices_is_ready = NO;
            break;
        }
    }
    if (all_devices_is_ready) {
        //send "ok" msg to unit/TT view
        [self.delegate msgFromConfigView:@"STATUS:1"];
    }else{
        //send "ng" msg to unit/TT view
        [self.delegate msgFromConfigView:@"STATUS:0"];
    }
    if([dev_name isEqualToString:@"MK"]){
        MY_DEVICE *myDevice=[_devicesDic objectForKey:@"MK"];
        _MK_SerialPanel = myDevice.serial;
    }
    return YES;
}

- (BOOL)commitEditingAndReturnError:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    
}
//alarm information display
-(long)alarmPanel:(NSString *)thisEnquire{
    NSLog(@"start run alarm window");
    NSAlert *theAlert=[[NSAlert alloc] init];
    [theAlert addButtonWithTitle:@"OK"]; //1000
    [theAlert setMessageText:@"Error!"];
    [theAlert setInformativeText:thisEnquire];
    [theAlert setAlertStyle:0];
    [theAlert setIcon:[NSImage imageNamed:@"Error_256px_5.png"]];
    NSLog(@"End run alarm window");
    return [theAlert runModal];
}

- (void)msgFromConfigView:(NSString *)msg {
}

- (void)debugPrint:(NSString *)log withID:(int)myID {
    NSString *msg = [NSString stringWithFormat:@"[socket-log]:%@",log];
    [self.delegate msgFromConfigView:msg];
}


//mouse keyboard part
-(IBAction)takeSamplesAction:(id)sender{
    if(![_MK_SerialPanel.serialPort isOpen]) return;
    
    
    
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self->mouseXYtimer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(printMouseXY) userInfo:nil repeats:true];
        [[NSRunLoop currentRunLoop] addTimer:self->mouseXYtimer forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
    });
    [_printLocationTF setBackgroundColor:[NSColor greenColor]];
    
    [NSThread detachNewThreadSelector:@selector(takeSamplesThread) toTarget:self withObject:nil];
    
}
-(void)takeSamplesThread{
    NSLog(@"lalala...");
    dbPlist_rootSet=[[NSMutableDictionary alloc] initWithCapacity:1];
    [self gotoZero];
    for (int i=1; i<128; i++) {
        NSString *cmd=[NSString stringWithFormat:@"M:%d,0\r\n",i];
        //NSData *command=[cmd dataUsingEncoding:NSUTF8StringEncoding];
        NSString *rec=@"";
        [_MK_SerialPanel sendCmd:cmd received:&rec withTimeOut:2.0];
        //[_MK_SerialPanel SendAndReceiveData:command ret:&rec delay:0.05];
        //NSString *cmd=@"set LED on";
        NSLog(@"rec:%@",rec);
        float point_x=[self getPointX];
        NSString *key=@"";
        if (i<10) {
            key=[NSString stringWithFormat:@"00%d",i];
        }else if(i>9 && i<100){
            key=[NSString stringWithFormat:@"0%d",i];
        }else{
            key=[NSString stringWithFormat:@"%d",i];
        }
        
        NSString *value=[NSString stringWithFormat:@"%f",point_x];
        [dbPlist_rootSet setValue:value forKey:key];
        NSLog(@"point_x:%f",point_x);
        cmd=[NSString stringWithFormat:@"M:-%d,0\r\n",i];
        //command=[cmd dataUsingEncoding:NSUTF8StringEncoding];
        [_MK_SerialPanel sendCmd:cmd received:&rec withTimeOut:2.0];
        //[_serialPort SendAndReceiveData:command ret:&rec delay:0.05];
        //NSString *cmd=@"set LED on";
        NSLog(@"rec:%@",rec);
        [NSThread sleepForTimeInterval:0.05f];
        
    }
    
    NSLog(@"...lalala");
    
    [NSThread sleepForTimeInterval:1.0f];
    
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *filePath=[rawfilePath stringByAppendingPathComponent:@"samples.plist"];
    [dbPlist_rootSet writeToFile:filePath atomically:false];
    
    [self performSelectorOnMainThread:@selector(stopTakeSamples) withObject:nil waitUntilDone:NO];
}
-(void)stopTakeSamples{
    [_printLocationTF setBackgroundColor:[NSColor whiteColor]];
    [mouseXYtimer invalidate];
    [self printAlarmWindow:@"Take Samples datas finished!"];
}
-(float)getPointX{
    CGEventRef ourEvent = CGEventCreate(NULL);
    NSPoint point = CGEventGetLocation(ourEvent);
    CFRelease(ourEvent);
    return point.x;
}
-(float)getPointY{
    CGEventRef ourEvent = CGEventCreate(NULL);
    NSPoint point = CGEventGetLocation(ourEvent);
    CFRelease(ourEvent);
    return point.y;
}
-(NSString *)gotoZero{
    float point_x=[self getPointX];
    NSString *cmd=@"M:-127,0\r\n";
    //NSData *command=[cmd dataUsingEncoding:NSUTF8StringEncoding];
    while (point_x != 0) {
        NSString *rec=@"";
        [_MK_SerialPanel sendCmd:cmd received:&rec withTimeOut:2.0];
        //[_serialPort SendAndReceiveData:command ret:&rec delay:0.05];
        //NSString *cmd=@"set LED on";
        NSLog(@"rec:%@",rec);
        point_x=[self getPointX];
        [NSThread sleepForTimeInterval:0.05f];
    }
    float point_y=[self getPointY];
    cmd=@"M:0,-127\r\n";
    //command=[cmd dataUsingEncoding:NSUTF8StringEncoding];
    while (point_y != 0) {
        NSString *rec=@"";
        [_MK_SerialPanel sendCmd:cmd received:&rec withTimeOut:2.0];
        //[_serialPort SendAndReceiveData:command ret:&rec delay:0.05];
        //NSString *cmd=@"set LED on";
        NSLog(@"rec:%@",rec);
        point_y=[self getPointY];
        
        [NSThread sleepForTimeInterval:0.05f];
    }
    [NSThread sleepForTimeInterval:0.2f];
    return @"OK,goto zero";
}
-(BOOL)mouseIsOK{
    //NSData *command=[@"Ready" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *rec=@"";
    [_MK_SerialPanel sendCmd:@"Ready\r\n" received:&rec withTimeOut:2.0];
    //[_serialPort SendAndReceiveData:command ret:&rec delay:0.05];
    //NSString *cmd=@"set LED on";
    NSLog(@"mouse is ok->rec:%@",rec);
    if([rec containsString:@"OK"]){
        return YES;
    }
    
    return NO;
}
-(IBAction)monitorBtnAction:(id)sender{
    if ([[_monitorBtn title] isEqualToString:@"Monitor"]) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            self->mouseXYtimer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(printMouseXY) userInfo:nil repeats:true];
            [[NSRunLoop currentRunLoop] addTimer:self->mouseXYtimer forMode:NSRunLoopCommonModes];
            [[NSRunLoop currentRunLoop] run];
        });
        [_monitorBtn setTitle:@"STOP"];
        [_printLocationTF setBackgroundColor:[NSColor greenColor]];
    }else{
        [mouseXYtimer invalidate];
        [_printLocationTF setBackgroundColor:[NSColor whiteColor]];
        [_monitorBtn setTitle:@"Monitor"];
    }
    
    
}
-(IBAction)positionUpBtnAction:(id)sender{
    
    
}

-(IBAction)getPositionsAction:(id)sender{
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *filePath=[rawfilePath stringByAppendingPathComponent:@"positions.plist"];
    dbPlist_rootSet=[[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    NSArray *keys=[dbPlist_rootSet allKeys];
    NSInteger index=[_positionUpBtn indexOfSelectedItem];
    NSDictionary *subKey= [keys objectAtIndex:index];
    positionSet=[dbPlist_rootSet objectForKey:subKey];
    
    CGEventRef ourEvent = CGEventCreate(NULL);
    NSPoint point = CGEventGetLocation(ourEvent);
    CFRelease(ourEvent);
    
    NSString *str_x=[NSString stringWithFormat:@"%f",point.x];
    NSString *str_y=[NSString stringWithFormat:@"%f",point.y];
    
    [positionSet setValue:str_x forKey:@"X"];
    [positionSet setValue:str_y forKey:@"Y"];
    NSLog(@"positionSet:%@",positionSet);
    [dbPlist_rootSet setObject:positionSet forKey:subKey];
    //[rootSet setValue:positionSet forKey:subKey];
    
    [dbPlist_rootSet writeToFile:filePath atomically:false];
    
    NSString *positionName=[_positionUpBtn titleOfSelectedItem];
    [self printAlarmWindow:[NSString stringWithFormat:@"Save %@ OK!",positionName]];
}
-(void)printMouseXY{
    CGEventRef ourEvent = CGEventCreate(NULL);
    NSPoint point = CGEventGetLocation(ourEvent);
    CFRelease(ourEvent);
    NSString *msg=[NSString stringWithFormat:@"Location? x= %f, y = %f", (float)point.x, (float)point.y];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_printLocationTF setStringValue:msg];
    });
    
    //NSLog(@"Location? x= %f, y = %f", (float)point.x, (float)point.y);
    
}

-(void)loadSamplesData{
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *filePath=[rawfilePath stringByAppendingPathComponent:@"samples.plist"];
    dbPlist_rootSet=[[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    NSArray *keys=[dbPlist_rootSet allKeys];
    NSArray *values=[dbPlist_rootSet allValues];
    //sort all keys "001","002"...
    NSArray *sortedKeys=[keys sortedArrayUsingFunction:intSort context:NULL];
    
    NSInteger count= [values count];
    _disSamplesArr =[[NSMutableArray alloc] initWithCapacity:count];
    for (NSString *dis in sortedKeys) {
        float value=[[dbPlist_rootSet objectForKey:dis] floatValue];
        //NSLog(@"key:%@ value:%f",dis,value);
        NSNumber *number = [NSNumber numberWithFloat:value];
        [_disSamplesArr addObject:number];
    }
    NSLog(@"samples:%@",_disSamplesArr);
}
-(NSString *)inputString:(NSString *)str{
    if(![_MK_SerialPanel.serialPort isOpen]) return @"NG,not ready";
    
    NSString *cmd=[NSString stringWithFormat:@"K:%@\r\n",str];
    
    //NSData *command=[cmd dataUsingEncoding:NSUTF8StringEncoding];
    NSString *rec=@"NG";
    [_MK_SerialPanel sendCmd:cmd received:&rec withTimeOut:2.0];
    //[_serialPort SendAndReceiveData:command ret:&rec delay:0.5];
    NSLog(@"rec:%@",rec);
    return rec;
}
-(NSString *)moveAndClickWithTargetX:(float )target_x TargetY:(float )target_y{
    NSString *feedback=[self justMoveWithTargetX:target_x TargetY:target_y];
    
    if ([feedback containsString:@"OK"]) {
        [NSThread sleepForTimeInterval:0.05];
        NSString *cmd=@"C:L\r\n";
        //NSData *command=[cmd dataUsingEncoding:NSUTF8StringEncoding];
        NSString *rec=@"";
        [_MK_SerialPanel sendCmd:cmd received:&rec withTimeOut:2.0];
        //[_serialPort SendAndReceiveData:command ret:&rec delay:0.05];
        NSLog(@"rec:%@",rec);
    }
    return feedback;
}
-(NSString *)justMoveWithTargetX:(float )target_x TargetY:(float )target_y{
    if(![_MK_SerialPanel.serialPort isOpen]) return @"NG,not ready";
    
    float current_x=[self getPointX];
    float current_y=[self getPointY];
    
    float distance_x=target_x-current_x;
    float distance_y=target_y-current_y;
    
    int step_x=0;
    int step_y=0;
    
    while (fabsf(distance_x) >1 || fabsf(distance_y) > 1) {
        if (fabsf(distance_x) >1 ) {
            step_x = [self getStep:distance_x];
        }else{
            step_x = 0;
        }
        if (fabsf(distance_y) > 1) {
            step_y = [self getStep:distance_y];
        }else{
            step_y = 0;
        }
        
        NSString *cmd=[NSString stringWithFormat:@"M:%d,%d\r\n",step_x,step_y];
        //NSData *command=[cmd dataUsingEncoding:NSUTF8StringEncoding];
        NSString *rec=@"";
        [_MK_SerialPanel sendCmd:cmd received:&rec withTimeOut:2.0];
        //[_serialPort SendAndReceiveData:command ret:&rec delay:0.05];
        
        
        current_x=[self getPointX];
        current_y=[self getPointY];
        
        distance_x=target_x-current_x;
        distance_y=target_y-current_y;
        NSLog(@"dis_x:%f y:%f",distance_x,distance_y);
    }
    
    NSString *feedback=[NSString stringWithFormat:@"OK,dis_x:%f dis_y:%f",distance_x,distance_y];
    NSLog(@"%@",feedback);
    return feedback;
}
-(int)getStep:(float )distance{
    int step = 0;
    int sign = 1;
    if(distance <0) sign = -1;
    
    distance=fabsf(distance);
    //distance = 3.5  // 13
    
    //2,3,4,5...12
    bool _find_step = false;
    for (int i = 0; i< 127; i++) {
        float sample=[[_disSamplesArr objectAtIndex:i] floatValue];
        if (distance-sample > 0) {
            continue;
        }else{
            step=i-1;
            _find_step = true;
            break;
        }
    }
    
    if(!_find_step) step = 127;
    
    if(step < 0) step = 0;
    
    step=sign * step;
    return step;
}
-(long)printAlarmWindow:(NSString *)info{
    NSLog(@"start run window");
    NSAlert *theAlert=[[NSAlert alloc] init];
    [theAlert addButtonWithTitle:@"OK"]; //1000
    //[theAlert addButtonWithTitle:@"No"]; //1001
    
    [theAlert setMessageText:@"Alarm!"];
    [theAlert setInformativeText:info];
    //[theAlert setAlertStyle:0];
    //[theAlert setIcon:[NSImage imageNamed:@"alarm1.png"]];
    
    NSLog(@"End run window");
    //[theAlert beginSheetModalForWindow: modalDelegate:nil didEndSelector:nil contextInfo:nil];
    //int choice = [theAlert runModal];
    
    return [theAlert runModal];
    
}
//sort plist test item name
NSInteger intSort(id num1, id num2, void *context)
{
    int startPos=0;
    NSString *S1 = num1;
    S1=[S1 substringWithRange:NSMakeRange(startPos,3)];
    int v1=[S1 intValue];
    
    NSString *S2 =num2;
    S2=[S2 substringWithRange:NSMakeRange(startPos,3)];
    int v2=[S2 intValue];
    if (v1 < v2)
        return NSOrderedAscending;
    else if (v1 > v2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}
-(void)viewWillDisappear{
    //self._isShowView=NO;
    
    NSLog(@"myMouse view disappear!");
}
@end
