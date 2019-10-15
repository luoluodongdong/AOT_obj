//
//  mySerialPanel.m
//  SoftwareApp
//
//  Created by 曹伟东 on 2019/4/15.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import "mySerialPanel.h"
typedef NS_ENUM(NSInteger, ORSSerialRequestType) {
    ORSSerialRequestTypeMatchStr = 1,
    ORSSerialRequestTypeEndStr,
    ORSSerialRequestTypeReceivedStr,
    ORSSerialRequestTypeOther,
};

@interface MySerialPanel ()
{
    NSArray *_comArr;
    NSString *_receivedStr;
    //serial port request/response
    BOOL _SP_RESPONSE_END;
    BOOL _RESPONSE_TIMEOUT;
    BOOL _IS_SHOW;
}
@end

@implementation MySerialPanel
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"serial pannel did load...");
    [_descriptionLB setStringValue:self._description];
   
    
}

-(void)viewDidAppear{
    NSLog(@"serial pannel did appear...");
    _IS_SHOW=YES;
    [self refreshSerialPorts];
    if (self.serialPort.isOpen) {
        NSString *portName=self.serialPort.name;
        NSString *baud=[NSString stringWithFormat:@"%@",self.serialPort.baudRate];
        [_portBtn selectItemWithTitle:portName];
        [_baudBtn selectItemWithTitle:baud];
        _openBtn.title = @"Close";
        [_portBtn setEnabled:NO];
        [_baudBtn setEnabled:NO];
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
    self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
    _receivedStr=@"";
    _SP_RESPONSE_END=NO;
    _RESPONSE_TIMEOUT=NO;
    _IS_SHOW=NO;
}

-(IBAction)openBtnAction:(id)sender{
    if (self.serialPort.isOpen) {
        [self.serialPort close];
        
    }else{
        NSInteger index=[_portBtn indexOfSelectedItem];
        self.serialPort=[_comArr objectAtIndex:index];
        int baudRate=[[_baudBtn titleOfSelectedItem] intValue];
        self.serialPort.baudRate = [NSNumber numberWithInt:baudRate];
        [self.serialPort open];
        //PIN status output
        self.serialPort.DTR=TRUE;
        self.serialPort.RTS=TRUE;
        
    }
    
}
-(BOOL)autoOpenSerial:(NSString *)serialName baud:(int )baudRate{
    [self refreshSerialPorts];
    NSInteger index=0;
    BOOL find_serial = NO;
    for (int i=0; i<[_comArr count]; i++) {
        ORSSerialPort *serial=[_comArr objectAtIndex:index];
        if ([serial.name isEqualToString:serialName]) {
            find_serial = YES;
            break;
        }
        index +=1;
    }
    if(!find_serial) return NO;
    self.serialPort=[_comArr objectAtIndex:index];
    self.serialPort.baudRate=[NSNumber numberWithInt:baudRate];
    [self.serialPort open];
    [NSThread sleepForTimeInterval:0.5];
    if (self.serialPort.isOpen) {
        return YES;
    }else{
        return NO;
    }
}
-(IBAction)scanBtnAction:(id)sender{
    [self refreshSerialPorts];
}
-(IBAction)backBtnAction:(id)sender{
    [self dismissViewController:self];
}
-(IBAction)saveBtnAction:(id)sender{
    NSString *portName=[_portBtn titleOfSelectedItem];
    NSString *baudRate=[_baudBtn titleOfSelectedItem];
    NSString *idStr=[NSString stringWithFormat:@"%d",self._id];
    NSDictionary *cfgDict=@{@"Type":@"SERIAL",@"Addr":portName,@"BaudRate":baudRate,@"ID":idStr};
    BOOL result= [self.delegate saveConfigEvent:cfgDict];
    NSLog(@"save result:%hhd",result);
    if (result) {
        [self showPanel:@"Save params OK!"];
    }else{
        [self showPanel:@"Save params FAIL!"];
    }
}
-(void)refreshSerialPorts{
    [_portBtn removeAllItems];
    [_baudBtn removeAllItems];
    
    _comArr = self.serialPortManager.availablePorts;
    NSLog(@"_comArr:%@",_comArr);
    
    [_comArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ORSSerialPort *port = (ORSSerialPort *)obj;
        //printf("%lu. %s\n", (unsigned long)idx, [port.name UTF8String]);
        //[self->comPaths addItemWithObjectValue:port.name];
        [self->_portBtn addItemWithTitle:port.name];
        
    }];
    if ([_comArr count]>0) {
        [_portBtn selectItemAtIndex:0];
    }
    [_baudBtn addItemsWithTitles:@[@"1200",@"3600",@"4800",@"9600",@"19200",
                                   @"38400",@"57600",@"115200",@"230400"]];
    NSLog(@"refresh srialport ok");
}
-(IBAction)sendBtnAction:(id)sender{
    NSString *cmd=[_commandTF stringValue];
    if ([cmd length] == 0) return;
    [_logTF setStringValue:@""];
    [self sendCommand:cmd];
}

-(BOOL)sendCommand:(NSString *)cmd{
    _SP_RESPONSE_END=NO;
    _RESPONSE_TIMEOUT=NO;
    _receivedStr=@"";
    NSData *cmdData=[cmd dataUsingEncoding:NSUTF8StringEncoding];
    return [self.serialPort sendData:cmdData];
}
-(BOOL)sendCmd:(NSString *)cmd received:(NSString **)data withTimeOut:(double )to{
    if(!self.serialPort.isOpen) return YES;
    _SP_RESPONSE_END=NO;
    _RESPONSE_TIMEOUT=NO;
    _receivedStr=@"";
    [self sendCmdAndReceivedStr:cmd TimeOut:to];
    //waiting for serial port response
    while(!_SP_RESPONSE_END){
        [NSThread sleepForTimeInterval:0.02f];
        
    }
    [NSThread sleepForTimeInterval:0.05f];
    
    *data=_receivedStr;
    return _RESPONSE_TIMEOUT;
}
#pragma mark - ORSSerialPort request/response Mode
- (void)sendCmdWithTimeOut:(NSString *)cmd TimeOut:(double )kTimeoutDuration MatchStr:(NSString *)checkStr
{
    
    NSData *command = [cmd dataUsingEncoding:NSASCIIStringEncoding];
    ORSSerialPacketDescriptor *responseDescriptor =
    [[ORSSerialPacketDescriptor alloc] initWithMaximumPacketLength:1024
                                                          userInfo:nil
                                                 responseEvaluator:^BOOL(NSData *inputData) {
                                                     return [self matchString:checkStr withData:inputData] != nil;
                                                 }];
    ORSSerialRequest *request = [ORSSerialRequest requestWithDataToSend:command
                                                               userInfo:@(ORSSerialRequestTypeMatchStr)
                                                        timeoutInterval:kTimeoutDuration
                                                     responseDescriptor:responseDescriptor];
    [self.serialPort sendRequest:request];
}
- (void)sendCmdWithTimeOut:(NSString *)cmd TimeOut:(double )kTimeoutDuration endStr:(NSString *)endStr
{
    NSData *command = [cmd dataUsingEncoding:NSASCIIStringEncoding];
    ORSSerialPacketDescriptor *responseDescriptor =
    [[ORSSerialPacketDescriptor alloc] initWithMaximumPacketLength:1024
                                                          userInfo:nil
                                                 responseEvaluator:^BOOL(NSData *inputData) {
                                                     return [self endString:endStr withData:inputData] !=nil;
                                                 }];
    ORSSerialRequest *request = [ORSSerialRequest requestWithDataToSend:command
                                                               userInfo:@(ORSSerialRequestTypeEndStr)
                                                        timeoutInterval:kTimeoutDuration
                                                     responseDescriptor:responseDescriptor];
    [self.serialPort sendRequest:request];
}
- (void)sendCmdAndReceivedStr:(NSString *)cmd TimeOut:(double )kTimeoutDuration
{
    NSData *command = [cmd dataUsingEncoding:NSASCIIStringEncoding];
    ORSSerialPacketDescriptor *responseDescriptor =
    [[ORSSerialPacketDescriptor alloc] initWithMaximumPacketLength:1024
                                                          userInfo:nil
                                                 responseEvaluator:^BOOL(NSData *inputData) {
                                                     return [self receivedStringWithData:inputData] !=nil;
                                                 }];
    ORSSerialRequest *request = [ORSSerialRequest requestWithDataToSend:command
                                                               userInfo:@(ORSSerialRequestTypeReceivedStr)
                                                        timeoutInterval:kTimeoutDuration
                                                     responseDescriptor:responseDescriptor];
    [self.serialPort sendRequest:request];
}


- (void)serialPort:(ORSSerialPort *)serialPort didReceiveResponse:(NSData *)responseData toRequest:(ORSSerialRequest *)request
{
    ORSSerialRequestType requestType = [request.userInfo integerValue];
    switch (requestType) {
        case ORSSerialRequestTypeMatchStr: //1
            //[[self temperatureFromResponsePacket:responseData] integerValue];
            //[self myPrintf:@"matchStr OK"];
            _SP_RESPONSE_END=YES;
            break;
        case ORSSerialRequestTypeReceivedStr:
            
            _SP_RESPONSE_END=YES;
            
            break;
        case ORSSerialRequestTypeEndStr: //3
            // Don't call the setter to avoid continuing to send set commands indefinitely
            //[self willChangeValueForKey:@"LEDOn"];
            //_LEDOn = [[self LEDStateFromResponsePacket:responseData] boolValue];
            //[self didChangeValueForKey:@"LEDOn"];
            //[self myPrintf:@"endStr OK"];
            _SP_RESPONSE_END=YES;
            break;
        case ORSSerialRequestTypeOther: //2
        default:
            break;
    }
}
- (void)serialPort:(ORSSerialPort *)port requestDidTimeout:(ORSSerialRequest *)request
{
    //NSLog(@"command timed out!");
    
    _RESPONSE_TIMEOUT=YES;
    //[self myPrintf:@"Command timed out!"];
    _SP_RESPONSE_END=YES;
}
#pragma mark Parsing Responses

-(NSNumber *)matchString:(NSString *)checkStr withData:(NSData *)data{
    if (![data length]) return nil;
    NSString *dataAsString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    if(![dataAsString containsString:checkStr]) return nil;
    NSString *msg=[NSString stringWithFormat:@"MatchStr:responseData:%@ len:%ld",dataAsString,[dataAsString length]];
    //[self myPrintf:msg];
    return @([dataAsString integerValue]);
}
-(NSNumber *)endString:(NSString *)endStr withData:(NSData *)data{
    if (![data length]) return nil;
    NSString *dataAsString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    if(![dataAsString hasSuffix:endStr]) return nil;
    NSString *msg=[NSString stringWithFormat:@"EndStr:responseData:%@ len:%ld",dataAsString,[dataAsString length]];
    //[self myPrintf:msg];
    return @([dataAsString integerValue]);
}
-(NSString *)receivedStringWithData:(NSData *)data{
    if (![data length]) return nil;
    NSString *dataAsString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    if(![dataAsString containsString:@"\n"]) return nil;
    NSString *msg=[NSString stringWithFormat:@"RecStr:responseData:%@ len:%ld",dataAsString,[dataAsString length]];
    //[self myPrintf:msg];
    return dataAsString;
}
#pragma mark - ORSSerialPortDelegate Methods

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort
{
    _openBtn.title = @"Close";
    [_portBtn setEnabled:NO];
    [_baudBtn setEnabled:NO];
    [_scanBtn setEnabled:NO];
    [_commandTF setEnabled:YES];
    [_sendBtn setEnabled:YES];
    
    //save com path/baudrate
    //NSString *data=[NSString stringWithFormat:@"SaveCOM:%d:%@",self._id,self.serialPort.name];
    //[self.delegate send2TTdata:data];
    
}

- (void)serialPortWasClosed:(ORSSerialPort *)serialPort
{
    self.serialPort=nil;
    _openBtn.title = @"Open";
    [_portBtn setEnabled:YES];
    [_baudBtn setEnabled:YES];
    [_scanBtn setEnabled:YES];
    [_commandTF setEnabled:NO];
    [_sendBtn setEnabled:NO];
    
}

- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
    if ([data length] == 0) return;
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if(string == nil) return;
    [self.delegate receivedDataEvent:string id:self._id];
    _receivedStr=[_receivedStr stringByAppendingString:string];
    if ([_receivedStr hasSuffix:@"\r\n"]) {
        NSString *msg=[NSString stringWithFormat:@"Received txt:%@",_receivedStr];
        //[self myPrintf:msg];
        //_SP_RESPONSE_END=YES;
        NSLog(@"%@",msg);
        if (_IS_SHOW) {
            [_logTF setStringValue:msg];
            _receivedStr=@"";
        }
    }
    
}

- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort;
{
    // After a serial port is removed from the system, it is invalid and we must discard any references to it
    //self.serialPort = nil;
    //self.openCloseButton.title = @"Open";
}

- (void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error
{
    NSString *msg=[NSString stringWithFormat:@"Serial port %@ encountered an error: %@", serialPort, error];
    NSLog(@"%@",msg);
    //[self myPrintf:msg];
}

#pragma mark - Properties
- (void)setSerialPort:(ORSSerialPort *)port
{
    if (port != _serialPort)
    {
        //[self myPrintf:@"Do serialPort delegate..."];
        NSLog(@"Do serialPort delegate...");
        [_serialPort close];
        _serialPort.delegate = nil;
        _serialPort = port;
        _serialPort.delegate = self;
    }
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

- (void)receivedDataEvent:(NSString *)data id:(int)myID {
    
}

- (BOOL)saveConfigEvent:(NSDictionary *)info{
    return YES;
}

@end
