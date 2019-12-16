//
//  AppDelegate.m
//  HelperForW1A
//
//  Created by 曹伟东 on 2019/1/21.
//  Copyright © 2019年 曹伟东. All rights reserved.
//

#import "AppDelegate.h"
//桃色
#define NSDebug6Color [NSColor colorWithRed:255.0/255.0 green:218.0/255.0 blue:185.0/255.0 alpha:1.0]

#define NSNormalColor [NSColor windowBackgroundColor]

//typedef NS_ENUM(NSInteger, ORSSerialRequestType) {
//    ORSSerialRequestTypeMatchStr = 1,
//    ORSSerialRequestTypeEndStr,
//    ORSSerialRequestTypeReceivedStr,
//    ORSSerialRequestTypeOther,
//};

@implementation PositionXY

@end

@interface AppDelegate ()
{
    NSTimer *mouseXYtimer;
    BOOL MOUSE_XY_FLAG;
    //int displayH;
    
    NSArray *_comArr;
    NSDictionary *_rootSet; //Root Set Dictionary
    NSDictionary *_testSet; //Test Set Dictionary
    
    NSString *_swName;
    NSString *_swVersion;
    NSString *_scriptName;
    NSString *_logString;
    NSString *_comPath;
    int _baudRate;
    NSString *receiveStr;

    NSString *_strBackupFolder;
    NSTimer *_checkColorTimer;

    NSString *_snString;
    NSString *_snPreFix;
    NSString *_winOwner;
    //GRR mode
    NSString *_grr_PWD;
    bool _GRR_MODE;
    long _passCount;
    long _failCount;

    //password VC
    NSString *_passWord;
    BOOL _isLock;
    //testing duration max time /seconds
    int _testTimeOut;
    
    //color detect config
    
    int _point_times;
    //NSPoint _check_point;
    //int _VALUE_PASS,_VALUE_FAIL,_VALUE_ERROR,_VALUE_IDLE,_VALUE_TESTING;
    float _offset_X,_offset_Y;

    //duration time
    NSDate *_start_time;
    //thread sync
    //dispatch_semaphore_t _sync_signal;
    //dispatch_time_t _overTime;
}

//atomic for threading safe
@property (atomic) BOOL _is_BUSY; //*
@property (atomic) BOOL _use_checkColor_Timer; //*
@property (atomic) BOOL _is_testing; //*
@property (atomic) int _test_flag; // 0x00 --IDLE; 0x01 --TEST; 0x02 --PASS; 0x03 --FAIL
@property (atomic) int _WatchCount; //max value:120
//testplan data
@property (nonatomic,assign) TP_DATA testplan_data;
//positions data
@property (nonatomic,strong) NSMutableDictionary *positionsDict;
//slots array
@property (nonatomic,assign) int SLOT_COUNT;
@property (nonatomic,strong) NSMutableArray *slotsArr;
@property (nonatomic,strong) NSMutableArray *monitorPointsArr;
@property (nonatomic,strong) NSMutableArray *resultsArr;

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self._test_flag=0x00;
    //_sync_signal=dispatch_semaphore_create(1);

    MOUSE_XY_FLAG=false;
    //displayH = getDisplayHeight();
    [_swNameTF setStringValue:_swName];
    [_swVersionTF setStringValue:_swVersion];
    
    _isLock=YES;
    self._is_testing=NO;
    
    //_logString=@"";
    self._is_BUSY=NO;
    self._WatchCount=0;
    //_monitorPath=@"/vault/Atlas/Archive";
    [winTitleTF setStringValue:_winOwner];
    [self updateYield:@"NO"];
    //check fixture IP and launch software application
    //[NSThread detachNewThreadSelector:@selector(checkIPAndLaunchSW) toTarget:self withObject:nil];
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *showIpSh=[rawfilePath stringByAppendingString:@"/ShowIP/ShowIP.sh"];
    const char *showIpCmd=[showIpSh UTF8String];
    system(showIpCmd);
    
//    NSString *ipTemp=[self scanIPs];
//    //ipTemp = [ipTemp stringByReplacingOccurrencesOfString:@" " withString:@""];
//    NSArray *ipArr=[ipTemp componentsSeparatedByString:@"\n"];
//    NSLog(@"==>>ipArr:%@",ipArr);
//    ["192.168.43.115",
//    "10.36.101.133",
//    ""]
    
    _snString=@"DLC8515002GKQV6AS";
    [_grrLabel setHidden:YES];
    [_testModeBtn removeAllItems];
    [_testModeBtn addItemsWithTitles:@[@"Normal",@"GRR"]];
    [_testModeBtn selectItemAtIndex:0];
    [_testModeBtn setTarget:self];
    [_testModeBtn setAction:@selector(handleModeBtn:)];
    _GRR_MODE=false;
    
    //*************Config View**************************//
    _configView=[[myConfigView alloc] initWithNibName:@"ConfigView" bundle:nil];
    _configView.dictKey=@"Devices";
    
    _configView.winOwner=_winOwner;
    _configView.delegate=self;
    
    [_configView initView];
    [_configView loadSamplesData];
    //*****************End Config View******************//
    
    //*******color view********//
    //_checkColorTimer=nil;
    _colorView=[[colorPlugView alloc]initWithNibName:@"colorPlugView" bundle:nil];
    _colorView.displayH = getDisplayHeight();
    _colorView.displayW = getDisplayWidth();
    NSLog(@"H:%d W:%d",_colorView.displayH,_colorView.displayW);
    _colorView._plistFile=@"color_config.plist";
    //*******end*color view*end********//
    //check color timer
    self._use_checkColor_Timer = NO;
    _checkColorTimer=[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkColorLoopFunc) userInfo:nil repeats:YES];
    
    
    NSLog(@"_mainVC:%@",_mainVC);
    
    _resultsArr=[[NSMutableArray alloc] initWithCapacity:_SLOT_COUNT];

    //NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *filePath=[rawfilePath stringByAppendingPathComponent:@"color_config.plist"];
    NSMutableDictionary *rootSet=[[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    _point_times=[[rootSet objectForKey:@"POINT_TIMES"] intValue];
    
    _slotsArr=[[NSMutableArray alloc] initWithCapacity:1];
    int x=5;
    int y=350;
    int slotCount = 0;
    for(int i=0;i<_SLOT_COUNT;i++){
        slotCount += 1;
        SlotView *item=[[SlotView alloc] init];
        item.slot_id=i;
        item.rootDict = rootSet;
        item.selected = YES;
        item.delegate = self;
        
        [item.view setFrame:CGRectMake(x, y, item.view.frame.size.width, item.view.frame.size.height)];
        //item.delegate=self;
        [[[_tabView tabViewItemAtIndex:0] view] addSubview:item.view];
        //[item._selectedBtn setTitle:[NSString stringWithFormat:@"Slot-%d",i+1]];
        [item initView];
        
        if (slotCount%2 == 0) {
            x=5;
            y = y - 80;
        }else{
            x+=190;
        }
 
        [_slotsArr addObject:item];
    }
    NSLog(@"_slotsArr:%@",_slotsArr);
    //[self.window setBackgroundColor:NSDebug6Color];
    [self sendMsg2AllSlotView:@"LOCK:1"];
}

-(void)handlePopBtn:(NSPopUpButton *)popBtn{
    NSLog(@"popBtn index:%ld",(long)popBtn.indexOfSelectedItem);
    NSLog(@"popBtn item:%@",popBtn.selectedItem.title);
}
-(NSString *)scanIPs{
    /*
    NSString *strNSString;
    const char *pConstChar;
    strNSString = [[NSString alloc] initWithUTF8String:pConstChar];
    pConstChar = [strNSString UTF8String];
     */
    const char *pConstChar="ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d 'addr:'";
    //pConstChar = [cmdStr UTF8String];
    FILE *fp = NULL;
    char buf[10240] = {0};
    fp = popen(pConstChar,"r");
    if(fp == NULL){
        return @"";
    }
    fread(buf, 10240, 1, fp);
    printf("%s\n",buf);
    pclose(fp);
    NSString * string = [NSString stringWithFormat:@"%s", buf];
    NSLog(@"popen output:%@",string);
    return string;
}
-(void)handleModeBtn:(NSPopUpButton *)popBtn{
    if ([popBtn indexOfSelectedItem] == 0) {
        _GRR_MODE = false;
        [_grrLabel setHidden:YES];
    }else{
        [_grrLabel setHidden:NO];
        _GRR_MODE = true;
    }
    NSLog(@"ModeBtn index:%ld",(long)popBtn.indexOfSelectedItem);
    NSString *msg=[NSString stringWithFormat:@"ModeBtn item:%@",popBtn.selectedItem.title];
    dispatch_async(_printQueue, ^{
        [self printLogTask:msg];
    });
}
-(id)init{
    
    _logString=@"";

    _printQueue=dispatch_queue_create("com.printLog.queue", DISPATCH_QUEUE_SERIAL);
    _replySerialQueue=dispatch_queue_create("com.reply.serial", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(_printQueue, ^{
        [self printLogTask:@"Init..."];
    });
    _scriptName=@"config.plist";
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *filePath;
    filePath=[rawfilePath stringByAppendingPathComponent:_scriptName];
    _rootSet=[[NSDictionary alloc] initWithContentsOfFile:filePath];
    _testSet=[_rootSet objectForKey:@"cfg"];
    _SLOT_COUNT = [[_testSet objectForKey:@"Slots"] intValue];
    _swName=[_testSet objectForKey:@"SWname"];
    _swVersion=[_testSet objectForKey:@"SWversion"];
    _passCount=[[_testSet objectForKey:@"pass"] longLongValue];
    _failCount=[[_testSet objectForKey:@"fail"] longLongValue];
    _passWord=[_testSet objectForKey:@"PassWord"];
    _testTimeOut=[[_testSet objectForKey:@"TimeOut"] intValue];
    _snPreFix=[_testSet objectForKey:@"preSN"];
    //winOwner
    _winOwner=[_rootSet objectForKey:@"WinOwner"];

    //MODE
    _testSet=[_rootSet objectForKey:@"GRR"];
    _grr_PWD=[_testSet objectForKey:@"password"];
    
    _testSet=[_rootSet objectForKey:@"launchApp"];
    receiveStr=@"";
    
    _monitorPointsArr=[[NSMutableArray alloc] initWithCapacity:1];
    for (int i=0; i<_SLOT_COUNT; i++) {
        [_monitorPointsArr addObject:@""];
    }
    NSLog(@"_monitorPointsArr:%@",_monitorPointsArr);
    
    [self loadPositions];

    [self loadTestPlan];
    return self;
}
-(void)loadTestPlan{
    NSString *fileName=@"TestPlan.csv";
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *filePath=[rawfilePath stringByAppendingPathComponent:fileName];
    NSLog(@"testplan:%@",filePath);
    
    CSVParser *parser=[CSVParser new];
    [parser openFile:filePath];
    NSMutableArray *csvContent = [parser parseFile];
    //NSLog(@"%@", csvContent);
    [parser closeFile];
    //NSMutableArray *heading = [csvContent objectAtIndex:0];
    [csvContent removeObjectAtIndex:0];
    
    //NSArray *line=[csvContent objectAtIndex:0];
    //NSLog(@"%@", line);
    _testplan_data.itemsData=[[NSMutableArray alloc] initWithCapacity:[csvContent count]];
    _testplan_data.groupData=[[NSMutableArray alloc] initWithCapacity:[csvContent count]];
    _testplan_data.funcData=[[NSMutableArray alloc] initWithCapacity:[csvContent count]];
    _testplan_data.actionData=[[NSMutableArray alloc] initWithCapacity:[csvContent count]];
    _testplan_data.positionData=[[NSMutableArray alloc] initWithCapacity:[csvContent count]];
    _testplan_data.inputData=[[NSMutableArray alloc] initWithCapacity:[csvContent count]];
    _testplan_data.param1Data=[[NSMutableArray alloc] initWithCapacity:[csvContent count]];
    _testplan_data.param2Data=[[NSMutableArray alloc] initWithCapacity:[csvContent count]];
    _testplan_data.param3Data=[[NSMutableArray alloc] initWithCapacity:[csvContent count]];
    _testplan_data.responseData=[[NSMutableArray alloc] initWithCapacity:[csvContent count]];
    _testplan_data.timeoutData=[[NSMutableArray alloc] initWithCapacity:[csvContent count]];
    _testplan_data.delayData=[[NSMutableArray alloc] initWithCapacity:[csvContent count]];
    _testplan_data.exitEnableData=[[NSMutableArray alloc] initWithCapacity:[csvContent count]];
    _testplan_data.skipData=[[NSMutableArray alloc] initWithCapacity:[csvContent count]];
    
    for (int index=0; index<[csvContent count]; index++) {
        NSArray *line=[csvContent objectAtIndex:index];
        //NSLog(@"line:%@",line);
        //            Test Data:     ||      TestPlan:
        [_testplan_data.itemsData addObject:line[TP_TESTITEMS_INDEX]];
        [_testplan_data.groupData addObject:line[TP_GROUP_INDEX]];
        [_testplan_data.funcData addObject:line[TP_FUNC_INDEX]];
        [_testplan_data.actionData addObject:line[TP_ACTION_INDEX]];
        [_testplan_data.positionData addObject:line[TP_POSITION_INDEX]];
        [_testplan_data.inputData addObject:line[TP_INPUT_INDEX]];
        [_testplan_data.param1Data addObject:line[TP_PARAM1_INDEX]];
        [_testplan_data.param2Data addObject:line[TP_PARAM2_INDEX]];
        [_testplan_data.param3Data addObject:line[TP_PARAM3_INDEX]];
        [_testplan_data.responseData addObject:line[TP_RESPONSE_INDEX]];
        [_testplan_data.timeoutData addObject:line[TP_TIMEOUT_INDEX]];
        [_testplan_data.delayData addObject:line[TP_DELAY_INDEX]];
        [_testplan_data.exitEnableData addObject:line[TP_EXITENABLE_INDEX]];
        [_testplan_data.skipData addObject:line[TP_SKIP_INDEX]];
    }
}


-(void)updateYield:(NSString *)save_flag{
    //inputCount = failCount + passCount;
    //[_inputLabel setStringValue:[NSString stringWithFormat:@"Input:%d",inputCount]];
    [_passLabel setStringValue:[NSString stringWithFormat:@"%ld",_passCount]];
    [_failLabel setStringValue:[NSString stringWithFormat:@"%ld",_failCount]];
    long inputCount=_passCount+_failCount;
    NSString *yieldStr = @"0.00%";
    if(inputCount != 0){
        float yield = (_passCount*1.0000/inputCount) *100;
        yieldStr=[NSString stringWithFormat:@"%.2f",yield];
        yieldStr=[yieldStr stringByAppendingString:@"%"];
        [_yieldLabel setStringValue:yieldStr];
    }else{
        [_yieldLabel setStringValue:yieldStr];
    }
    NSLog(@"input:%ld pass:%ld fail:%ld yield:%@",inputCount,_passCount,_failCount,yieldStr);
    if([save_flag isEqualToString:@"YES"]){
        _testSet =[_rootSet objectForKey:@"cfg"];
        [_testSet setValue:[NSString stringWithFormat:@"%ld",_passCount] forKey:@"pass"];
        [_testSet setValue:[NSString stringWithFormat:@"%ld",_failCount] forKey:@"fail"];
        [_rootSet setValue:_testSet forKey:@"cfg"];
        NSString *portFilePath=[[NSBundle mainBundle] resourcePath];
        portFilePath =[portFilePath stringByAppendingPathComponent:_scriptName];
        [_rootSet writeToFile:portFilePath atomically:NO];
    }
}
//-(void)checkIPAndLaunchSW{
//    //first ping fixture IP
//    bool check_IP=[self checkNetIp:_fixture_IP];
//    NSString *msg=[NSString stringWithFormat:@"checkIP:%@ result:%d",_fixture_IP,check_IP];
//    dispatch_async(_printQueue, ^{
//        [self printLogTask:msg];
//    });
//    //launch test App
//    bool result=[[NSWorkspace sharedWorkspace] launchApplication:_appName];
//    NSLog(@"launchApp:%@ result:%d",_appName,result);
//    msg=[NSString stringWithFormat:@"launchApp:%@ result:%d",_appName,result];
//    dispatch_async(_printQueue, ^{
//        [self printLogTask:msg];
//    });
//    [NSThread sleepForTimeInterval:0.5f];
//
//}

-(IBAction)clearYieldBtnAction:(id)sender{
    _passCount=0;
    _failCount=0;
    [self updateYield:@"YES"];
    [self printAlarmWindow:@"Clear yield successful!"];
}
-(IBAction)homeBtnAction:(id)sender{
    [_tabView selectTabViewItemAtIndex:0];
}
-(IBAction)logBtnAction:(id)sender{
    [_tabView selectTabViewItemAtIndex:1];
}
-(IBAction)setBtnAction:(id)sender{
    if(_isLock){
        [self callPassWordVC];
    }else{
        [_tabView selectTabViewItemAtIndex:2];
    }
}

-(IBAction)lockBtnAction:(id)sender{
    if(_isLock){
        [self callPassWordVC];
    }else{
        _isLock=YES;
        [_lockBtn setImage:[NSImage imageNamed:@"lock_535.png"]];
        [self.window setBackgroundColor:NSNormalColor];
        [self sendMsg2AllSlotView:@"LOCK:1"];
    }
}
-(void)send2TT_PassWord:(BOOL )message{
    NSLog(@"password result:%hhd",message);
    if(!message){
        return;
    }
    _isLock=NO;
    [_lockBtn setImage:[NSImage imageNamed:@"unlock_535.png"]];
    //[_tabView selectTabViewItemAtIndex:2];
    [self.window setBackgroundColor:NSDebug6Color];
    [self sendMsg2AllSlotView:@"LOCK:0"];
}
-(void)callPassWordVC{
    //init myPassWord ViewController
    _passwordVC=[[myPassWord alloc]initWithNibName:@"myPassWord" bundle:nil];
    _passwordVC.delegate=self; //protocol delegate init **
    _passwordVC._passwordStr=_passWord;
    [_mainVC presentViewControllerAsSheet:_passwordVC];
}

-(IBAction)btnStartMouse:(id)sender{
    if(!MOUSE_XY_FLAG){
        mouseXYtimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(printMouseXY) userInfo:nil repeats:YES];
        [startMouse setTitle:@"Stop"];
        MOUSE_XY_FLAG = true;
        [mouseX setBackgroundColor:[NSColor greenColor]];
        [mouseY setBackgroundColor:[NSColor greenColor]];
    }else{
        [mouseXYtimer invalidate];
        mouseXYtimer = nil;
        [startMouse setTitle:@"Start"];
        MOUSE_XY_FLAG = false;
        [mouseX setBackgroundColor:[NSColor whiteColor]];
        [mouseY setBackgroundColor:[NSColor whiteColor]];
    }
}

-(IBAction)testButtonAction:(id)sender{
    NSString *title=[winTitleTF stringValue];
    //_snString=[_snTF stringValue];
    [NSThread detachNewThreadSelector:@selector(testBtnThread:) toTarget:self withObject:title];
}
-(void)testBtnThread:(NSString *)win{
    [self offsetPostions];
    NSString *msg=[_configView moveAndClickWithTargetX:100.0 TargetY:100.0];
    msg=[msg stringByAppendingString:@"\r\n Move and Click （100，100）"];
    dispatch_async(_printQueue, ^{
        [self printLogTask:msg];
    });
}
-(IBAction)setDevicesPanelBtnAction:(id)sender{
    NSLog(@"Open config View...");
    //[_ttLogView.view setFrameSize:NSMakeSize(640, 450)];
    [_mainVC presentViewControllerAsModalWindow:_configView];
}

-(IBAction)uploadMCUBtnAction:(id)sender{
    if ([_configView.MK_SerialPanel.serialPort isOpen]) {
        [self printAlarmWindow:@"Please close MCU port first!"];
    }else{
        NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
        NSString *appPath=[rawfilePath stringByAppendingString:@"/ArdUpload/Uploader.app"];
        NSLog(@"app:%@",appPath);
        [[NSWorkspace sharedWorkspace] launchApplication:appPath];
    }
}
//END Mouse View Action
-(void)operationFunc:(NSString *)recStr{
    recStr=[recStr stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    recStr=[recStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    dispatch_async(_printQueue, ^{
        [self printLogTask:@"_is_testing:YES"];
    });
    _snString=[recStr componentsSeparatedByString:@":"][1];
    [NSThread sleepForTimeInterval:0.1f];
    if (false == WinIsLaunch(_winOwner)) {
        dispatch_async(_printQueue, ^{
            [self printLogTask:@"overlay not lanuch,TEST FAIL!"];
        });
        for (int i=0; i<_SLOT_COUNT; i++) {
            _resultsArr[i] = @"ERROR";
        }
        [self finishWorkWithResult:@"ERROR" failItem:@"overlay not lanuch"];
    }
    if (![_configView mouseIsOK]) {
        dispatch_async(_printQueue, ^{
            [self printLogTask:@"mouse ERROR,TEST FAIL!"];
        });
        for (int i=0; i<_SLOT_COUNT; i++) {
            _resultsArr[i] = @"ERROR";
        }
        [self finishWorkWithResult:@"ERROR" failItem:@"mouse ERROR"];
    }else{
        dispatch_async(_printQueue, ^{
            [self printLogTask:@"Mouse&Keyboard Ready!"];
        });
       [self executeTestPlan];
    }

}
-(void)loadPositions{
    //move position
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *filePath1=[rawfilePath stringByAppendingPathComponent:@"positions.plist"];
    //NSLog(@"loadPosition file:%@",filePath1);
    NSDictionary *positionSet=[[NSDictionary alloc] initWithContentsOfFile:filePath1];
    //NSLog(@"%@",positionSet);
    NSArray *pos_keys=[positionSet allKeys];
    //NSLog(@"%@",pos_keys);
    _positionsDict=[[NSMutableDictionary alloc] initWithCapacity:1];
    
    for (NSString *k in pos_keys) {
        PositionXY *p_xy=[[PositionXY alloc] init];
        p_xy.x=[[[positionSet objectForKey:k] objectForKey:@"X"] floatValue];
        p_xy.y=[[[positionSet objectForKey:k] objectForKey:@"Y"] floatValue];
        [_positionsDict setObject:p_xy forKey:k];
        NSLog(@"[load-P-%@]x:%f y:%f",k,p_xy.x,p_xy.y);
        if ([k hasPrefix:@"MonitorP"]) {
            int index=[[k componentsSeparatedByString:@"_"][1] intValue];
            if (index < _SLOT_COUNT) {
                NSPoint point=NSMakePoint(p_xy.x, p_xy.y);
                _monitorPointsArr[index] = NSStringFromPoint(point);
            }
        }
    }
    
    _offset_X=[[[positionSet objectForKey:@"Offset"] objectForKey:@"X"] floatValue];
    _offset_Y=[[[positionSet objectForKey:@"Offset"] objectForKey:@"Y"] floatValue];
    
    NSLog(@"load_mointorPointsArr:%@",_monitorPointsArr);
}
//for myMouse view callback
-(IBAction)setOffsetAction:(id)sender{
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *filePath=[rawfilePath stringByAppendingPathComponent:@"positions.plist"];
    NSMutableDictionary *rootSet=[[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    NSDictionary *subSet=[rootSet objectForKey:@"Offset"];
    //float offset_y = 2.0;
    CGPoint point = GetPosition(_winOwner);
    _offset_X=point.x;
    _offset_Y=point.y;
    NSLog(@"_offset_x:%f y:%f",point.x,point.y);
    
    [subSet setValue:[NSString stringWithFormat:@"%f",point.x] forKey:@"X"];
    [subSet setValue:[NSString stringWithFormat:@"%f",point.y] forKey:@"Y"];
    //[rootSet setObject:positionSet forKey:subKey];
    //[rootSet setValue:positionSet forKey:subKey];
    [rootSet setObject:subSet forKey:@"Offset"];
    [rootSet writeToFile:filePath atomically:false];
    [self printAlarmWindow:[NSString stringWithFormat:@"Save Offset:(%f,%f) OK!",_offset_X,_offset_Y]];
}
-(void)offsetPostions{
    [self loadPositions];
    
    float offset_x=0.0;
    float offset_y=0.0;
    CGPoint point =GetPosition(_winOwner);
    NSLog(@"win_position_x:%f y:%f",point.x,point.y);
    offset_x=point.x-_offset_X;
    offset_y=point.y-_offset_Y;
    NSLog(@"offset_x:%f y:%f",offset_x,offset_y);
    
    NSArray *p_keys=[_positionsDict allKeys];
    for (NSString *k in p_keys) {
        PositionXY *p_xy=[_positionsDict objectForKey:k];
        p_xy.x = p_xy.x + offset_x;
        p_xy.y = p_xy.y + offset_y;
        [_positionsDict setObject:p_xy forKey:k];
        NSLog(@"[offset-P-%@]x:%f y:%f",k,p_xy.x,p_xy.y);
        if ([k hasPrefix:@"MonitorP"]) {
            int index=[[k componentsSeparatedByString:@"_"][1] intValue];
            if (index < _SLOT_COUNT) {
                NSPoint point=NSMakePoint(p_xy.x, p_xy.y);
                _monitorPointsArr[index] = NSStringFromPoint(point);
            }
        }
    }
    
    NSLog(@"offset_mointorPointsArr:%@",_monitorPointsArr);
}
-(void)refreshCheckPoint{
    float offset_x=0.0;
    float offset_y=0.0;
    CGPoint point =GetPosition(_winOwner);
    NSLog(@"win_position_x:%f y:%f",point.x,point.y);
    offset_x=point.x-_offset_X;
    offset_y=point.y-_offset_Y;
    
    NSLog(@"offset x:%f y:%f",offset_x,offset_y);
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *filePath=[rawfilePath stringByAppendingPathComponent:@"positions.plist"];
    NSMutableDictionary *positionSet=[[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    NSArray *pos_keys=[positionSet allKeys];
    //NSLog(@"%@",positionSet);
    //NSLog(@"%@",pos_keys);
    for (NSString *k in pos_keys) {
        if ([k hasPrefix:@"MonitorP"]) {
            PositionXY *p_xy=[[PositionXY alloc] init];
            p_xy.x=[[[positionSet objectForKey:k] objectForKey:@"X"] floatValue];
            p_xy.y=[[[positionSet objectForKey:k] objectForKey:@"Y"] floatValue];
            NSLog(@"raw p_xy name:%@ x:%f y:%f",k,p_xy.x,p_xy.y);
            int index=[[k componentsSeparatedByString:@"_"][1] intValue];
            if (index < _SLOT_COUNT) {
                NSPoint point=NSMakePoint(p_xy.x+offset_x, p_xy.y+offset_y);
                SlotView *slot = _slotsArr[index];
                slot.monitorPoint = point;
                [_slotsArr replaceObjectAtIndex:index withObject:slot];
                _monitorPointsArr[index] = NSStringFromPoint(point);
                NSLog(@"_monitorPointsArr index:%d point:%@",index,_monitorPointsArr[index]);
            }
        }
    }
    
    NSLog(@"refresh_mointorPointsArr:%@",_monitorPointsArr);
    
}
-(void)executeTestPlan{
    [self offsetPostions];
    for (int i=0; i<[_testplan_data.itemsData count]; i++) {

        NSString *thisStatus=@"FAIL";
        NSString *msg=@"";
        //NSDate *t1=[NSDate date];
        dispatch_async(_printQueue, ^{
            [self printLogTask:@"========================================="];
        });
        [NSThread sleepForTimeInterval:0.01f];
        NSString *thisItem=[_testplan_data.itemsData objectAtIndex:i];
        msg =[NSString stringWithFormat:@"Item:%@",thisItem];
        dispatch_async(_printQueue, ^{
            [self printLogTask:msg];
        });
        NSString *thisGroup=[_testplan_data.groupData objectAtIndex:i];
        NSString *thisFunc=[_testplan_data.funcData objectAtIndex:i];
        NSString *thisAction=[_testplan_data.actionData objectAtIndex:i];
        NSString *thisPosition=[_testplan_data.positionData objectAtIndex:i];
        NSString *thisInputStr=[_testplan_data.inputData objectAtIndex:i];
        NSString *thisParam1=[_testplan_data.param1Data objectAtIndex:i];
        NSString *thisParam2=[_testplan_data.param2Data objectAtIndex:i];
        NSString *thisParam3=[_testplan_data.param3Data objectAtIndex:i];
        NSString *thisResponse=[_testplan_data.responseData objectAtIndex:i];
        
        float thisTimeOut=[[_testplan_data.timeoutData objectAtIndex:i] floatValue];
        float thisDelay=[[_testplan_data.delayData objectAtIndex:i] floatValue];
        BOOL isExitEnable=[[_testplan_data.exitEnableData objectAtIndex:i] boolValue];
        BOOL isSkiped=[[_testplan_data.skipData objectAtIndex:i] boolValue];
        float point_x=0.0;
        float point_y=0.0;
        if ([thisPosition length] > 0) {
            PositionXY *p_xy=[_positionsDict objectForKey:thisPosition];
            point_x = p_xy.x;
            point_y = p_xy.y;
            msg =[NSString stringWithFormat:@"Position[%@]-x:%f y:%f",thisPosition,point_x,point_y];
            dispatch_async(_printQueue, ^{
                [self printLogTask:msg];
            });
        }
        if (isSkiped) {
            thisStatus = @"SKIPED";
            msg=@"skip this item";
        }else{
            if ([thisAction isEqualToString:@"MoveAndClick"]) {
                msg=[_configView moveAndClickWithTargetX:point_x TargetY:point_y];
                if ([msg containsString:@"OK"]) {
                    thisStatus = @"PASS";
                }
                else{
                    thisStatus = @"FAIL";
                }
            }
            else if([thisAction isEqualToString:@"Input"]){
                msg=[_configView inputString:_snString];
                if ([msg containsString:@"OK"]) {
                    thisStatus = @"PASS";
                }
                else{
                    thisStatus = @"FAIL";
                }
            }
            else if ([thisAction isEqualToString:@"Move"]) {
                msg=[_configView justMoveWithTargetX:point_x TargetY:point_y];
                if ([msg containsString:@"OK"]) {
                    thisStatus = @"PASS";
                }
                else{
                    thisStatus = @"FAIL";
                }
            }
            //Move2monitor
            else if ([thisAction isEqualToString:@"Move2monitor"]) {
                BOOL isOk = YES;
                for (NSString *pointStr in _monitorPointsArr) {
                    NSPoint point=NSPointFromString(pointStr);
                    msg=[_configView justMoveWithTargetX:point.x TargetY:point.y];
                    if (![msg containsString:@"OK"]) {
                        isOk = NO;
                    }
                    [NSThread sleepForTimeInterval:1.0];
                }
                thisStatus = (isOk == YES) ? @"PASS" : @"FAIL";
            }
            else if([thisAction isEqualToString:@"GotoZero"]) {
                msg=[_configView gotoZero];
                if ([msg containsString:@"OK"]) {
                    thisStatus = @"PASS";
                }
                else{
                    thisStatus = @"FAIL";
                }
            }
            else{
                msg=[NSString stringWithFormat:@"unknown action:%@",thisAction];
                thisStatus = @"FAIL";
            }
            msg=[msg stringByAppendingString:[NSString stringWithFormat:@"  Status:%@",thisStatus]];
            dispatch_async(_printQueue, ^{
                [self printLogTask:msg];
            });
            [NSThread sleepForTimeInterval:thisDelay];
        }
    }
    //monitor color change timer
    self._is_BUSY=false;
    self._WatchCount=0;
    self._use_checkColor_Timer = YES;
}
-(void)checkColorLoopFunc{
    if(!self._use_checkColor_Timer) return;
    self._WatchCount +=1;
    [self performSelectorOnMainThread:@selector(refreshWatchDog) withObject:nil waitUntilDone:YES];
    if(self._is_BUSY) return;
    self._is_BUSY=true;
    [NSThread detachNewThreadSelector:@selector(checkColorThread) toTarget:self withObject:nil];
}
-(void)checkColorThread{
    [self refreshCheckPoint];
    //NSString *msg;
    //int colorValue=[_colorView getColorValue:_check_point pTimes:_point_times];
    
    [_colorView updateSlots:&_slotsArr withTimes:_point_times];
    //NSArray *valuesArr=[_colorView getValueWithPoints:_monitorPointsArr withTimes:_point_times];
    //NSLog(@"_slotsArr:%@",_slotsArr);
    //_test_flag: 0x00 --IDLE; 0x01 --TEST; 0x02 --DONE
    int finish_count=0;
    for (int i=0;i<_SLOT_COUNT;i++) {
        SlotView *slot = _slotsArr[i];
        if (YES == slot.selected) {
            [self performSelectorOnMainThread:@selector(updateSlotStatus:) withObject:slot waitUntilDone:YES];
            if ([slot.status isEqualToString:@"PASS"] || [slot.status isEqualToString:@"FAIL"] ||
                [slot.status isEqualToString:@"ERROR"]) {
                finish_count += 1;
            }
        }else{
            finish_count += 1;
            slot.status=@"NA";
        }
        //[NSThread sleepForTimeInterval:0.1];
        _resultsArr[i] = slot.status;
    }

    if (self._WatchCount > _testTimeOut) {
        dispatch_async(_printQueue, ^{
            [self printLogTask:@"Testing TIMEOUT ERROR!"];
        });
        for (int i=0; i<_SLOT_COUNT; i++) {
            _resultsArr[i] = @"TIMEOUT";
        }
        finish_count = _SLOT_COUNT;
    }
    NSLog(@"==>>[_resultArr]:%@",_resultsArr);
    //[self performSelectorOnMainThread:@selector(printStatus) withObject:nil waitUntilDone:YES];
    
    if (finish_count == _SLOT_COUNT) {
        NSString *test_status=_resultsArr[0];
        for (int i= 1; i<_SLOT_COUNT; i++) {
            test_status=[test_status stringByAppendingString:@";"];
            test_status=[test_status stringByAppendingString:_resultsArr[i]];
        }
        [self finishWorkWithResult:@"DONE" failItem:test_status];
    }
    
    self._is_BUSY=false;
}
-(void)finishWorkWithResult:(NSString *)result failItem:(NSString *)failMsg{
    NSString *test_status=_resultsArr[0];
    for (int i= 1; i<_SLOT_COUNT; i++) {
        test_status=[test_status stringByAppendingString:@";"];
        test_status=[test_status stringByAppendingString:_resultsArr[i]];
    }
    dispatch_async(_printQueue, ^{
        [self printLogTask:[NSString stringWithFormat:@"Overlay Result:%@",test_status]];
    });
    self._test_flag = 0x02;

    NSString *msg=[NSString stringWithFormat:@"Action Result:%@",result];
    dispatch_async(_printQueue, ^{
        [self printLogTask:msg];
    });
    
    for (int i=0; i<_SLOT_COUNT; i++) {
        if ([_resultsArr[i] isEqualToString:@"PASS"]) {
            _passCount += 1;
        }else{
            _failCount += 1;
        }
    }
    [self performSelectorOnMainThread:@selector(updateYield:) withObject:@"YES" waitUntilDone:YES];
    [self performSelectorOnMainThread:@selector(showWorkStatus:) withObject:@"DONE" waitUntilDone:YES];
    //[NSThread sleepForTimeInterval:1.0];
    NSDate *now=[NSDate date];
    NSTimeInterval interval=[now timeIntervalSinceDate:_start_time];
    msg=[NSString stringWithFormat:@"duration:%.6fs",interval];
    dispatch_async(_printQueue, ^{
        [self printLogTask:msg];
    });
    dispatch_async(_printQueue, ^{
        [self printLogTask:@"Finish assistive work!"];
    });
    //save daily csv
    [self saveDailyCSV:_snString Result:result FailItem:failMsg];
    
    self._is_testing=false;
    self._use_checkColor_Timer = NO;
}
-(void)updateSlotStatus:(SlotView *)slot{
    [slot updateStatus];
}

-(void)showWorkStatus:(NSString *)status{
    if ([status isEqualToString:@"WORK"]) {
        [workStatusTF setStringValue:@"Working..."];
        [workStatusTF setBackgroundColor:[NSColor yellowColor]];
    }
    else if([status isEqualToString:@"DONE"]){
        [workStatusTF setStringValue:@"Done."];
        [workStatusTF setBackgroundColor:[NSColor systemBlueColor]];
    }else {
        [workStatusTF setStringValue:status];
        [workStatusTF setBackgroundColor:[NSColor redColor]];
    }
    [workStatusTF setNeedsDisplay:YES];
}
-(BOOL)checkNetIp:(NSString *)ipStr{
    NSString *msg=@"Check Server IP...;nocolor";
    BOOL bResult = true;
    NSString *cmd=[NSString stringWithFormat:@"ping -c5 %@",ipStr];
    NSString *receiveStr=[self cmdExe:cmd];
    //NSLog(@"%@",receiveStr);
    if(![receiveStr containsString:@"64 bytes"]) bResult = false;
    msg=[NSString stringWithFormat:@"checkNetIp:%@ result:%hhd",ipStr,bResult];
    dispatch_async(_printQueue, ^{
        [self printLogTask:msg];
    });
    if(!bResult){
        NSString *msg=@"ERROR:Fixture IP offline!";
        [self performSelectorOnMainThread:@selector(printAlarmWindow:) withObject:msg waitUntilDone:NO];
    }
    return bResult;
}
- (NSString *)cmdExe:(NSString *)cmd
{
    // 初始化并设置shell路径
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/bash"];
    // -c 用来执行string-commands（命令字符串），也就说不管后面的字符串里是什么都会被当做shellcode来执行
    NSArray *arguments = [NSArray arrayWithObjects: @"-c", cmd, nil];
    [task setArguments: arguments];
    
    // 新建输出管道作为Task的输出
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSPipe *errPipe=[NSPipe pipe];
    [task setStandardError:errPipe];
    
    // 开始task
    NSFileHandle *file = [pipe fileHandleForReading];
    NSFileHandle *errFile=[errPipe fileHandleForReading];
    [task launch];
    [task waitUntilExit]; //执行结束后,得到执行的结果字符串++++++
    NSData *data;
    data = [file readDataToEndOfFile];
    NSData *errData=[errFile readDataToEndOfFile];
    NSString *errStr= [[NSString alloc] initWithData: errData encoding:NSUTF8StringEncoding];
    if ([errStr length] != 0) {
        NSString *msg=[NSString stringWithFormat:@"runTerminalCMDwithParamERR:%@",errStr];
        NSLog(@"%@", msg);
        [self performSelectorOnMainThread:@selector(printAlarmWindow:) withObject:msg waitUntilDone:NO];
    }
    NSString *result_str;
    result_str = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding]; //---------------------------------
    return result_str;
}
-(IBAction)ScanWinBtnAction:(id)sender{
    //获取桌面打开窗口的列表
    NSArray *wins = scanOpenWin();
    for (NSString *title in wins) {
        dispatch_async(_printQueue, ^{
            [self printLogTask:title];
        });
    }
}
-(IBAction)callColViewAction:(id)sender{
    NSLog(@"Open Color View...");
    //[_ttLogView.view setFrameSize:NSMakeSize(640, 450)];
    [_mainVC presentViewControllerAsModalWindow:_colorView];
    //if (_checkColorTimer != nil) {
    //    [_checkColorTimer invalidate];
    //}
    
}

- (void)msgFromConfigView:(NSString *)msg {
    //receiveStr=@"";
    NSString *log =[NSString stringWithFormat:@"[configView]-%@",msg];
    
    dispatch_async(_printQueue, ^{
        [self printLogTask:log];
    });
    msg=[msg uppercaseString];
    if ([msg hasPrefix:@"SOCKET#"]) {
        NSString *request=[msg componentsSeparatedByString:@"#"][1];
        dispatch_async(_replySerialQueue, ^{
            [self replySerialTask:request];
        });
    }
}

-(void)replySerialTask:(NSString *)recStr{
    NSString *msg=@"";
    if ([recStr hasPrefix:@"STATUS"]) {
        [self replyTestStatus];
    }
    else if([recStr hasPrefix:@"READY"]){
        [self feedbackOk];
    }
    //receive: SN:DLCXXXXXXXXXXXXX ==>START TESTING
    else{
        if(self._is_testing){
            [self feedbackBUSY];
            msg=[NSString stringWithFormat:@"_is_testing:YES \r\n Please check program."];
            dispatch_async(_printQueue, ^{
                [self printLogTask:msg];
            });
        }else{
            //SN:DLCXXXXXXXXXXXXXX
            if([recStr hasPrefix:[NSString stringWithFormat:@"SN:%@",_snPreFix]]){
                //check all slot are not selected
                int selectedCount = 0;
                for (SlotView *view in self.slotsArr) {
                    if (YES == view.selected) {
                        selectedCount +=1;
                    }
                    NSLog(@"slot view:%d selected:%hhd",view.slot_id,view.selected);
                }
                if (0 == selectedCount) {
                    [self performSelectorOnMainThread:@selector(printAlarmWindow:) withObject:@"Any slots selected!" waitUntilDone:NO];
                    [self feedbackNG];
                    return;
                }
                //------------------------trigger testing-----------------------//
                self._test_flag=0x01;
                self._WatchCount=0;
                self._is_testing=YES;
                [self feedbackOk];
                [self performSelectorOnMainThread:@selector(showWorkStatus:) withObject:@"WORK" waitUntilDone:YES];
                _start_time=[NSDate date];
                _snString=@"";
                _logString=@"";
                dispatch_async(_printQueue, ^{
                    [self printLogTask:[NSString stringWithFormat:@"[RX]:%@",recStr]];
                });
                [NSThread detachNewThreadSelector:@selector(operationFunc:) toTarget:self withObject:recStr];
            }else{
                msg=[NSString stringWithFormat:@"Bad request:%@",recStr];
                dispatch_async(_printQueue, ^{
                    [self printLogTask:msg];
                });
                [self feedbackUnkownCmd];
            }
        }
    }
}
-(void)feedbackBUSY{
    NSString *msg;
    [NSThread sleepForTimeInterval:0.1];
    if([_configView justSendCmd:@"BUSY\r\n" withName:@"AUTO"]){
        msg=@"[TX]BUSY result:TRUE";
    }else{
        msg=@"[TX]BUSY result:FALSE";
    }
    dispatch_async(_printQueue, ^{
        [self printLogTask:msg];
    });
}
-(void)feedbackOk{
    NSString *msg;
    if([_configView justSendCmd:@"OK\r\n" withName:@"AUTO"]){
        msg=@"[TX]:OK result:TRUE";
    }else{
        msg=@"[TX]:OK result:FALSE";
    }
    dispatch_async(_printQueue, ^{
        [self printLogTask:msg];
    });
}
-(void)feedbackUnkownCmd{
    NSString *msg;
    if([_configView justSendCmd:@"UNKNOWN\r\n" withName:@"AUTO"]){
        msg=@"[TX]:UNKNOWN result:TRUE";
    }else{
        msg=@"[TX]:UNKNOWN result:FALSE";
    }
    dispatch_async(_printQueue, ^{
        [self printLogTask:msg];
    });
}
-(void)feedbackNG{
    NSString *msg;
    if([_configView justSendCmd:@"NG\r\n" withName:@"AUTO"]){
        msg=@"[TX]:NG result:TRUE";
    }else{
        msg=@"[TX]:NG result:FALSE";
    }
    dispatch_async(_printQueue, ^{
        [self printLogTask:msg];
    });
}
-(void)replyTestStatus{
    NSString *test_status=@"NA";
    switch (self._test_flag) {
        case 0x00:
            test_status=@"IDLE";
            break;
        case 0x01:
            test_status=@"TESTING";
            break;
        case 0x02:
            test_status=_resultsArr[0];
            for (int i= 1; i<_SLOT_COUNT; i++) {
                test_status=[test_status stringByAppendingString:@";"];
                test_status=[test_status stringByAppendingString:_resultsArr[i]];
            }
            break;
        default:
            test_status=@"ERROR";
            break;
    }
    NSString *status=[NSString stringWithFormat:@"%@\r\n",test_status];
    NSString *msg;
    if([_configView justSendCmd:status withName:@"AUTO"]){
        msg=[NSString stringWithFormat:@"[TX]:%@ result:TRUE",status];
    }else{
        msg=[NSString stringWithFormat:@"[TX]:%@ result:TRUE",status];
    }
    dispatch_async(_printQueue, ^{
        [self printLogTask:msg];
    });
    if (0x02 == self._test_flag) {
        dispatch_async(_printQueue, ^{
            [self saveLocalLog];
            
        });
    }
}

-(long)printAlarmWindow:(NSString *)info{
    NSLog(@"start run window");
    NSAlert *theAlert=[[NSAlert alloc] init];
    [theAlert addButtonWithTitle:@"OK"]; //1000
    //[theAlert addButtonWithTitle:@"No"]; //1001
    
    [theAlert setMessageText:@"Alarm!"];
    [theAlert setInformativeText:info];
    [theAlert setAlertStyle:0];
    //[theAlert setIcon:[NSImage imageNamed:@"alarm1.png"]];
    
    NSLog(@"End run window");
    // [theAlert beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
    //int choice = [theAlert runModal];
    
    return [theAlert runModal];
    
}
-(void)printLogTask:(NSString *)log{
    dispatch_async(dispatch_get_main_queue(),^{
        @synchronized (self){
            NSDateFormatter *dateFormat=[[NSDateFormatter alloc] init];
//            [dateFormat setDateStyle:NSDateFormatterMediumStyle];
//            [dateFormat setDateStyle:NSDateFormatterShortStyle];
            [dateFormat setDateFormat:@"[yyyy-MM-dd HH:mm:ss.SSS]"];
            
            NSString *dateText=[NSString string];
            dateText=[dateFormat stringFromDate:[NSDate date]];
            //dateText=[dateText stringByAppendingString:@"\n"];
            //_logString = [_logString stringByAppendingString:@"\r\n==============================\r\n"];
            self->_logString = [self->_logString stringByAppendingString:dateText];
            self->_logString = [self->_logString stringByAppendingString:log];
            self->_logString = [self->_logString stringByAppendingString:@"\r\n"];
            [self->_logView setString:self->_logString];
            [self->_logView scrollRangeToVisible:NSMakeRange([[self->_logView textStorage] length],0)];
            [self->_logView setNeedsDisplay: YES];
            //if([self._logString length] >10000) self._logString=@"";
            NSLog(@"%@",log);
        }
    });
}

-(void)refreshWatchDog{
    int result= self._WatchCount % 2;
    if(result == 0){
        [_watchdogLabel setBackgroundColor:[NSColor systemOrangeColor]];
    }else{
        [_watchdogLabel setBackgroundColor:[NSColor systemGreenColor]];
    }
    [_watchdogLabel setStringValue:[NSString stringWithFormat:@"%ds",self._WatchCount]];
}

//save CSV all in one
-(void)saveDailyCSV:(NSString *)sn Result:(NSString *)result FailItem:(NSString *)failitem{
    NSString *strMonth = [self getYearMonth]; //201901
    NSString *strCurrentDate = [self getCurrentDate]; //20190123
    NSString *logPath = [NSString stringWithFormat:@"/vault/%@/%@",_swName,strMonth];
    NSString *strFileName = [NSString stringWithFormat:@"%@_Total.csv", strCurrentDate];
    
    NSString *strFilePath = [NSString stringWithFormat:@"%@/%@", logPath, strFileName];
    //"SN,TestTime,Result,FailItem"
    NSString *testTime=[self getCurrentTime];
    NSString *csvData=[NSString stringWithFormat:@"%@,%@,%@,%@\r\n",sn,testTime,result,failitem];
    if(YES == [self createCsvFileWithPath:logPath withFilePath:strFilePath])
    {
        [self appendDataToFileWithString:csvData withFilePath:strFilePath];
    }
}
-(BOOL)createCsvFileWithPath:(NSString *)path withFilePath:(NSString *)strLogFilePath
{
    BOOL isDir = NO;
    NSError *errMsg;
    
    //1. Get execution tool's folder path
    NSFileManager *fm = [NSFileManager defaultManager];
    
    //2. If bDirExist&isDir are true, the directory exit
    BOOL bDirExist = [fm fileExistsAtPath:path isDirectory:&isDir];
    if (!(bDirExist == YES && isDir == YES))
    {
        if (NO == [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&errMsg])
            return NO;
    }
    
    //4. Check file exist or not
    //5. If file not exist, creat data to file
    //    bDirExist = [fm fileExistsAtPath:_logFilePath isDirectory:&isDir];
    if (NO == [fm fileExistsAtPath:strLogFilePath isDirectory:&isDir])
    {
        if (NO == [fm createFileAtPath:strLogFilePath contents:nil attributes:nil])
        {
            return NO;
        }
        
        NSString *strSum = [[NSString alloc] init];
        if (NO == [strSum writeToFile:strLogFilePath atomically:YES encoding:NSUTF8StringEncoding error:&errMsg])
        {
            return NO;
        }
        NSString *strTitle=@"SN,TestTime,Result,FailItem\r\n";
        [self appendDataToFileWithString:strTitle withFilePath:strLogFilePath];//第一次创建时，增加INFO
    }
    
    return YES;
}
//Save local single log in xxxx_log.txt
-(void)saveLocalLog{
    //_logString=[_logString stringByAppendingString:@"\r\n------END LOG------"];
    NSString *strMonth = [self getYearMonth]; //201901
    NSString *strCurrentDate = [self getCurrentDate]; //20190123
    NSString *logPath = [NSString stringWithFormat:@"/vault/%@/%@/%@",_swName,strMonth,strCurrentDate];
    NSString *strFileName = [NSString stringWithFormat:@"%@_log_%@.txt", _snString,[self getTimeFix]];
    
    NSString *strFilePath = [NSString stringWithFormat:@"%@/%@", logPath, strFileName];
    
    if(YES == [self createLOGFileWithPath:logPath withFilePath:strFilePath])
    {
        [self appendDataToFileWithString:_logString withFilePath:strFilePath];
    }
    
}
-(BOOL)createLOGFileWithPath:(NSString *)path withFilePath:(NSString *)strLogFilePath
{
    BOOL isDir = NO;
    NSError *errMsg;
    
    //1. Get execution tool's folder path
    NSFileManager *fm = [NSFileManager defaultManager];
    
    //2. If bDirExist&isDir are true, the directory exit
    BOOL bDirExist = [fm fileExistsAtPath:path isDirectory:&isDir];
    if (!(bDirExist == YES && isDir == YES))
    {
        if (NO == [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&errMsg])
            return NO;
    }
    
    //4. Check file exist or not
    //5. If file not exist, creat data to file
    //    bDirExist = [fm fileExistsAtPath:_logFilePath isDirectory:&isDir];
    if (NO == [fm fileExistsAtPath:strLogFilePath isDirectory:&isDir])
    {
        if (NO == [fm createFileAtPath:strLogFilePath contents:nil attributes:nil])
        {
            return NO;
        }
        
        NSString *strSum = [[NSString alloc] init];
        if (NO == [strSum writeToFile:strLogFilePath atomically:YES encoding:NSUTF8StringEncoding error:&errMsg])
        {
            return NO;
        }
        //NSString *strTitle=[self getCsvTitle];
        [self appendDataToFileWithString:@"----NEW LOG----\r\n" withFilePath:strLogFilePath];//第一次创建时，增加INFO
    }
    
    return YES;
}
- (BOOL)appendDataToFileWithString:(NSString *)string withFilePath:(NSString *)strFilePath
{
    NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:strFilePath];
    [myHandle seekToEndOfFile];
    [myHandle writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [myHandle closeFile];
    
    return YES;
}
-(void)printMouseXY{
    //NSPoint p=[NSEvent mouseLocation];
    CGEventRef ourEvent = CGEventCreate(NULL);
    NSPoint point = CGEventGetLocation(ourEvent);
    CFRelease(ourEvent);
    [mouseX setFloatValue:point.x];
    [mouseY setFloatValue:point.y];
}

#pragma mark - collect test result

-(BOOL)directoryIsExist:(NSString *)filePath
{
    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = NO;
    isExist = [fm fileExistsAtPath:filePath
                       isDirectory:&isDir];
    return (isExist && isDir);
}

-(BOOL)fileIsExist:(NSString *)filePath
{
    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = NO;
    isExist = [fm fileExistsAtPath:filePath
                       isDirectory:&isDir];
    
    return (isExist && !isDir);
}

-(NSDate *)getDateFromString:(NSString *)pstrDate
{
    NSDateFormatter *df1 = [[NSDateFormatter alloc] init];
    [df1 setDateFormat:@"yyyy.MM.dd-HH.mm.ss"];
    NSDate *dtPostDate = [df1 dateFromString:pstrDate];
    return dtPostDate;
}
-(NSString *)getYearMonth
{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYYMM"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    return currentTime;
}
- (NSString *)getCurrentDate
{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYYMMdd"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    return currentTime;
}
- (NSString *)getCurrentTime
{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY/MM/dd HH:mm:ss"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    return currentTime;
}
-(NSString *)getTimeFix{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"_HHmmssSSS"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    return currentTime;
}
/******END******Color Detect Function*****END*****/
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    
}

-(void)windowShouldClose:(id)sender{
    /*
    if (_checkColorTimer != nil) {
        [_checkColorTimer invalidate];
        _checkColorTimer=nil;
    }
     */
    [_configView closeDevices];
    [NSApp terminate:NSApp];
}


- (void)getOffsetY:(NSString *)offset_y {
    NSLog(@"lalala...");
}

#pragma mark ---Msg from SlotView
- (void)msgFromSlotView:(nonnull NSString *)msg {
    NSLog(@"msg from SlotView:%@",msg);
    @synchronized (self) {
        if ([msg hasPrefix:@"SELECTED:"]) {
            NSArray *msgArr=[msg componentsSeparatedByString:@":"];
            int slot_id=[msgArr[1] intValue];
            BOOL selectVal=[msgArr[2] boolValue];
            SlotView *slotview=self.slotsArr[slot_id];
            slotview.selected =selectVal;
            self.slotsArr[slot_id] = slotview;
            int selectedCount = 0;
            for (SlotView *view in self.slotsArr) {
                if (YES == view.selected) {
                    selectedCount +=1;
                }
                NSLog(@"slot view:%d selected:%hhd",view.slot_id,view.selected);
            }
            if (0 == selectedCount) {
                [self performSelectorOnMainThread:@selector(printAlarmWindow:) withObject:@"Any slots selected!" waitUntilDone:NO];
            }
        }
    }
}
#pragma mark ---Send Message To SlotView
-(void)sendMsg2AllSlotView:(NSString *)msg{
    for (SlotView *slotview in self.slotsArr) {
        [slotview sendMsg2SlotView:msg];
    }
}
-(void)sendMsg2ActiveSlotView:(NSString *)msg{
    
}
@end
