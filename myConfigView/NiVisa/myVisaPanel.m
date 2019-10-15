//
//  mySerialPanel.m
//  SoftwareApp
//
//  Created by 曹伟东 on 2019/4/15.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import "myVisaPanel.h"
#import "NIVISAHelp.h"

@interface MyVisaPanel ()
{
    NSArray *_addrArr;
    NSString *_receivedStr;
    NSString *_address;
    //port request/response

    BOOL _IS_SHOW;
    BOOL _IS_OPENED;
}
@end

@implementation MyVisaPanel
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"VISA pannel did load...");
    //[_backBtn setHidden:YES];
    [_descriptionLB setStringValue:self._description];
   
    
}

-(void)viewDidAppear{
    NSLog(@"VISA pannel did appear...");
    _IS_SHOW=YES;
    [self refreshPorts];
    if (_IS_OPENED) {
        NSString *portName=_address;
        [_portBtn selectItemWithTitle:portName];
        _openBtn.title = @"Close";
        [_portBtn setEnabled:NO];
        [_scanBtn setEnabled:NO];
        [_commandTF setEnabled:YES];
        [_sendBtn setEnabled:YES];
    }else{
        [_commandTF setEnabled:NO];
        [_sendBtn setEnabled:NO];
    }
}

-(void)viewWillDisappear{
    _IS_SHOW=NO;
}

-(void)initView{
    //[super viewDidLoad];
    //self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
    openVISArm();
    self._instrFD=-1;
    _address=@"NA";
    _receivedStr=@"";
    _IS_OPENED=NO;    
    _IS_SHOW=NO;
}

-(IBAction)openBtnAction:(id)sender{
    if ([[_openBtn title] isEqualToString:@"Open"]) {
        _address=[_portBtn titleOfSelectedItem];
        self._instrFD=openDevice(_address, 9600, 2000);
        if (self._instrFD != -1) {
            //open successful
            _IS_OPENED=YES;
            _openBtn.title = @"Close";
            [_portBtn setEnabled:NO];
            [_scanBtn setEnabled:NO];
            [_commandTF setEnabled:YES];
            [_sendBtn setEnabled:YES];
        }else{
            _address=@"NA";
        }
    }else{
        int closeR=closeDevice(self._instrFD);
        if (closeR<0) {
            //close fail
            [self showPanel:@"Close instrument error!"];
        }else{
            //close successful
            _IS_OPENED=NO;
            _openBtn.title = @"Open";
            [_portBtn setEnabled:YES];
            [_scanBtn setEnabled:YES];
            [_commandTF setEnabled:NO];
            [_sendBtn setEnabled:NO];
        }
    }
    
}
-(BOOL)autoOpenInstrument:(NSString *)addr timeout:(int)to{
    [self refreshPorts];
    BOOL _find_addr=NO;
    for (int i=0; i<[_addrArr count]; i++) {
        NSString *item=[_addrArr objectAtIndex:i];
        if ([item isEqualToString:addr]) {
            _find_addr = YES;
            break;
        }
    }
    if(!_find_addr) return NO;
    self._instrFD=openDevice(addr, 9600, to);
    if (self._instrFD != -1) {
        //open successful
        _IS_OPENED=YES;
        _address=addr;
        _openBtn.title = @"Close";
        [_portBtn setEnabled:NO];
        [_scanBtn setEnabled:NO];
        [_commandTF setEnabled:YES];
        [_sendBtn setEnabled:YES];
    }else{
        //open fail
        return NO;
    }
    
    return YES;
}
-(IBAction)scanBtnAction:(id)sender{
    [self refreshPorts];
}
-(IBAction)backBtnAction:(id)sender{
    [self dismissViewController:self];
}
-(IBAction)saveBtnAction:(id)sender{
    NSString *portName=[_portBtn titleOfSelectedItem];
    NSString *idStr=[NSString stringWithFormat:@"%d",self._id];
    NSDictionary *cfgDict=@{@"Addr":portName,@"ID":idStr,@"Type":@"INSTR"};
    BOOL result= [self.delegate saveConfigEvent:cfgDict];
    NSLog(@"save result:%hhd",result);
    if (result) {
        [self showPanel:@"Save params OK!"];
    }else{
        [self showPanel:@"Save params FAIL!"];
    }
}
-(void)refreshPorts{
    [_portBtn removeAllItems];
    _addrArr=findAllDevices();
    NSLog(@"_addrArr:%@",_addrArr);
    [_portBtn addItemsWithTitles:_addrArr];
    
    if ([_addrArr count]>0) {
        [_portBtn selectItemAtIndex:0];
    }
    NSLog(@"refresh ports ok");
}
-(IBAction)sendBtnAction:(id)sender{
    NSString *cmd=[_commandTF stringValue];
    if ([cmd length] == 0) return;
    [_logTF setStringValue:@""];
    [self sendCommand:cmd];
    NSString *rec=readDevice(self._instrFD);
    [_logTF setStringValue:rec];
}

-(BOOL)sendCommand:(NSString *)cmd{
    if(self._instrFD==-1) return NO;
    [NSThread sleepForTimeInterval:0.1];
    if([cmd containsString:@";"]){
        NSArray *cmdArr=[cmd componentsSeparatedByString:@";"];
        for (int index=0; index<[cmdArr count]; index++) {
            NSString *cmd1=[cmdArr objectAtIndex:index];
            int sendR=writeDevice(self._instrFD, cmd1);
            if(sendR < 0) return NO;
            [NSThread sleepForTimeInterval:0.1];
        }
    }else{
        int sendR=writeDevice(self._instrFD, cmd);
        if(sendR < 0) return NO;
    }
    
    return YES;
}
-(NSString *)queryInstr:(NSString *)cmd{
    NSString *recData=@"";
    if(![self sendCommand:cmd]) return recData;
    [NSThread sleepForTimeInterval:0.2];
    recData=readDevice(self._instrFD);
    return recData;
}
//PUBLIC FUNC
-(NSString *)getInstrName{
    return [self queryInstr:@"*IDN?"];
}
-(BOOL)resetInstrument{
    BOOL result=[self sendCommand:@"*RST;*CLS"];
    if(!result) return NO;
    //[NSThread sleepForTimeInterval:1.0];
    return YES;
}
-(void)closeInstrument{
    if(_IS_OPENED) {
        closeDevice(self._instrFD);
        closeVISArm();
    }
}
//34970
-(NSString *)meas34970ResWithCable:(NSString *)cable withChannels:(NSString *)channels{
    NSString *cmd=[NSString stringWithFormat:@"CONF:RES AUTO,(%@)",channels];
    if ([cable isEqualToString:@"4"]) {
        cmd=[NSString stringWithFormat:@"CONF:FRES AUTO,(%@)",channels];
    }
    if(![self sendCommand:cmd]) return @"";
    
    cmd=[NSString stringWithFormat:@"ROUT:CHAN:DEL:AUTO 1,(%@)",channels];
    if(![self sendCommand:cmd]) return @"";
    
    cmd=[NSString stringWithFormat:@"ROUT:SCAN (%@)",channels];
    if(![self sendCommand:cmd]) return @"";
    
    cmd=@"TRIG:SOUR BUS;INIT;*TRG";
    if(![self sendCommand:cmd]) return @"";
    
    NSString *recData=[self queryInstr:@"SYST:ERR?"];
    if (![[recData uppercaseString] containsString:@"NO ERROR"]) return @"";
    
    return [self queryInstr:@"FETC?"];
}
//34465
-(BOOL)initDMM{
    return [self resetInstrument];
}
-(NSString *)measDMMResWithCable:(NSString *)cable{
    NSString *cmd=@"CONF:RES AUTO";
    if ([cable isEqualToString:@"4"]) cmd=@"CONF:FRES AUTO";
    if(![self sendCommand:cmd]) return @"";
    
    cmd=@"TRIG:SOUR BUS;INIT;*TRG";
    if(![self sendCommand:cmd]) return @"";
    
    NSString *recData=[self queryInstr:@"SYST:ERR?"];
    if (![[recData uppercaseString] containsString:@"NO ERROR"]) return @"";
    
    return [self queryInstr:@"FETC?"];
}
-(NSString *)measDMMDiode{
    NSString *cmd=@"CONF:DIOD";
    if(![self sendCommand:cmd]) return @"";
    
    return [self queryInstr:@"READ?"];
}
-(NSString *)measDMMCap:(NSString *)config{
    NSString *cmd=[NSString stringWithFormat:@"CONF:CAP %@",config];
    if(![self sendCommand:cmd]) return @"";
    
    return [self queryInstr:@"READ?"];
}
-(NSString *)measDMMVolt:(NSString *)config{
    NSString *cmd=[NSString stringWithFormat:@"CONF:VOLT:%@",config];
    if(![self sendCommand:cmd]) return @"";
    
    cmd=@"TRIG:SOUR BUS;INIT;*TRG";
    if(![self sendCommand:cmd]) return @"";
    
    NSString *recData=[self queryInstr:@"SYST:ERR?"];
    if (![[recData uppercaseString] containsString:@"NO ERROR"]) return @"";
    
    return [self queryInstr:@"FETC?"];
}
-(NSString *)measDMMCurr:(NSString *)config{
    NSString *cmd=[NSString stringWithFormat:@"CONF:CURR:%@",config];
    if(![self sendCommand:cmd]) return @"";
    
    cmd=@"TRIG:SOUR BUS;INIT;*TRG";
    if(![self sendCommand:cmd]) return @"";
    
    NSString *recData=[self queryInstr:@"SYST:ERR?"];
    if (![[recData uppercaseString] containsString:@"NO ERROR"]) return @"";
    
    return [self queryInstr:@"FETC?"];
}

//LOAD 63600
-(BOOL)loadON{
    NSString *cmd=@"LOAD ON";
    if(![self sendCommand:cmd]) return NO;
    
    return YES;
}
-(BOOL)loadOFF{
    NSString *cmd=@"LOAD OFF";
    if(![self sendCommand:cmd]) return NO;
    
    return YES;
}
//mode:@"CCH" channel:@"L1" current:@"2.4" A
-(BOOL)loadWithMode:(NSString *)mode Channel:(NSString *)ch Curr:(NSString *)cu{
    if(![self loadOFF]) return NO;
    
    NSString *cmd=[NSString stringWithFormat:@"MODE %@;CURR:STAT:%@ %@",mode,ch,cu];
    if(![self sendCommand:cmd]) return NO;
    
    if(![self loadON]) return NO;
    
    return YES;
}
//channel:@"1"
-(NSString *)loadMeasPow:(NSString *)channel{
    NSString *cmd=[NSString stringWithFormat:@"CHAN %@",channel];
    [self sendCommand:cmd];
    return [self queryInstr:@"MEAS:POW?"];
}
-(NSString *)loadMeasVolt:(NSString *)channel{
    NSString *cmd=[NSString stringWithFormat:@"CHAN %@",channel];
    [self sendCommand:cmd];
    return [self queryInstr:@"MEAS:VOLT?"];
}
-(NSString *)loadMeasCurr:(NSString *)channel{
    NSString *cmd=[NSString stringWithFormat:@"CHAN %@",channel];
    [self sendCommand:cmd];
    return [self queryInstr:@"MEAS:CURR?"];
}


//POWER 3615
-(BOOL)initPower{
    NSString *cmd=@"*RST;*CLS";
    if(![self sendCommand:cmd]) return NO;
    //[NSThread sleepForTimeInterval:1.0];
    
    cmd=@"SOUR:CURR:PROT:STAT 0";
    if(![self sendCommand:cmd]) return NO;
    
    cmd=@"SYST:TRA 0;SYST:PARA 0";
    if(![self sendCommand:cmd]) return NO;
    
    NSString *recData=[self queryInstr:@"SYST:ERR?"];
    if (![[recData uppercaseString] containsString:@"NO ERROR"]) return NO;
    
    return YES;
}
-(BOOL)outputPowerChannel:(NSString *)ch Volt:(NSString *)vt Curr:(NSString *)cr{
    NSString *cmd=@"SOUR:CURR:PROT:STAT 0";
    if(![self sendCommand:cmd]) return NO;
    
    cmd=[NSString stringWithFormat:@"SOUR:CHAN %@",ch];
    if(![self sendCommand:cmd]) return NO;
    
    cmd=[NSString stringWithFormat:@"SOUR:VOLT %@",vt];
    if(![self sendCommand:cmd]) return NO;
    
    cmd=[NSString stringWithFormat:@"SOUR:CURR %@",cr];
    if(![self sendCommand:cmd]) return NO;
    
    cmd=@"SOUR:VOLT:PROT 38.5";
    if ([ch isEqualToString:@"3"]) cmd=@"SOUR:VOLT:PROT 7.0";
    if(![self sendCommand:cmd]) return NO;
    
    cmd=@"OUTP:STAT 1";
    if(![self sendCommand:cmd]) return NO;
    
    NSString *recData=[self queryInstr:@"SYST:ERR?"];
    if (![[recData uppercaseString] containsString:@"NO ERROR"]) return NO;
    
    return YES;
}
-(NSString *)measPOWERVolt:(NSString *)channel{
    NSString *cmd=[NSString stringWithFormat:@"SOUR:CHAN %@",channel];
    if(![self sendCommand:cmd]) return @"";
    
    cmd=@"MEAS:VOLT?";
    return [self queryInstr:cmd];
}
-(NSString *)measPOWERCurr:(NSString *)channel{
    NSString *cmd=[NSString stringWithFormat:@"SOUR:CHAN %@",channel];
    if(![self sendCommand:cmd]) return @"";
    
    cmd=@"MEAS:CURR?";
    return [self queryInstr:cmd];
}
-(BOOL)outputPowerOFF{
    NSString *cmd=@"OUTP:STAT 0";
    if(![self sendCommand:cmd]) return NO;
    
    return YES;
}
//show information display
-(long)showPanel:(NSString *)thisEnquire{
    NSLog(@"start run showpanel window");
    NSAlert *theAlert=[[NSAlert alloc] init];
    [theAlert addButtonWithTitle:@"OK"]; //1000
    [theAlert setMessageText:@"Info"];
    [theAlert setInformativeText:thisEnquire];
    [theAlert setAlertStyle:0];
    //[theAlert setIcon:[NSImage imageNamed:@"Error_256px_5.png"]];
    NSLog(@"End run showpanel window");
    return [theAlert runModal];
}


- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    
}

- (BOOL)saveConfigEvent:(NSDictionary *)info{
    return YES;
}

@end
