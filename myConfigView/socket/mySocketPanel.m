//
//  mySocketPanel.m
//  LibTest
//
//  Created by Weidong Cao on 2019/6/21.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import "mySocketPanel.h"

#define READ_TIMEOUT 3
#define WRITE_TIMEOUT 3
#define SERVER_USERDATA 1000
#define CLIENT_USERDATA 2000

@interface MySocketPanel()

@property (nonatomic,strong) GCDAsyncSocket *socket;
@property (nonatomic,strong) NSString *ip;
@property (nonatomic,assign) int port;

@property (nonatomic,strong) NSMutableArray *socketArray;
@property (nonatomic,assign) BOOL IS_SHOW;

@property (nonatomic,assign) BOOL IS_REPLY;
@property (nonatomic,strong) NSMutableString *receiveStr;
//@property (nonatomic,strong) dispatch_semaphore_t semaphore;
@end

@implementation MySocketPanel
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"socket pannel did load...");
    [descriptionTF setStringValue:self._description];
    [modeBtn removeAllItems];
    [modeBtn addItemsWithTitles:@[@"client",@"server"]];
}

-(void)viewDidAppear{
    NSLog(@"socket pannel did appear...");
    _IS_SHOW=YES;
    [modeBtn selectItemWithTitle:_mode];
    //[self refreshPorts];
    if (_isConnected) {
        startBtn.title=@"Stop";
        [modeBtn setEnabled:NO];
        [ipTF setEnabled:NO];
        [portTF setEnabled:NO];
        [cmdTF setEnabled:YES];
        [sendBtn setEnabled:YES];

    }else{
        [cmdTF setEnabled:NO];
        [sendBtn setEnabled:NO];
    }
}

-(void)viewWillDisappear{
    _IS_SHOW=NO;
}
-(void)initView{
    //[super viewDidLoad];
    //self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
    _socketArray=[[NSMutableArray alloc] initWithCapacity:1];
    _receiveStr=[[NSMutableString alloc] initWithCapacity:1];
    _isConnected=NO;
    _IS_SHOW=NO;
    _IS_REPLY=NO;
    _socket=nil;
   
}
-(IBAction)backBtnAction:(id)sender{
    [self dismissViewController:self];
}
-(IBAction)modeBtnAction:(id)sender{
    _mode=[modeBtn titleOfSelectedItem];
    NSLog(@"mode:%@",_mode);
}
-(BOOL)autoStartSocket:(NSString *)ip port:(int )port{
    [ipTF setStringValue:ip];
    [portTF setIntValue:port];
    _ip=ip;
    _port=port;
    
    return [self startSocket];
}
-(IBAction)startBtnAction:(id)sender{
    if ([[startBtn title] isEqualToString:@"Start"]) {
        _ip=[ipTF stringValue];
        _port=[portTF intValue];
        [self startSocket];
    }else{
        [self stopSocket];
        [startBtn setTitle:@"Start"];
        [modeBtn setEnabled:YES];
        [ipTF setEnabled:YES];
        [portTF setEnabled:YES];
        [cmdTF setEnabled:NO];
        [sendBtn setEnabled:NO];
    }
    
}
-(BOOL)startSocket{
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()]; //  !!!! 用GCD的形式
    [_socket setDelegate:self];
    NSError *err = nil;
    if ([_mode isEqualToString:@"client"]) {
        _isConnected=NO;
        int t = [_socket connectToHost:_ip onPort:_port error:&err];
        NSString *msg=[NSString stringWithFormat:@"start status:%d error:%@",t,err];
        [self myPrint:msg];
        if(t){
            [modeBtn setEnabled:NO];
            [ipTF setEnabled:NO];
            [portTF setEnabled:NO];
            [cmdTF setEnabled:YES];
            [sendBtn setEnabled:YES];
            [startBtn setTitle:@"Stop"];
        }else{
            return NO;
        }
    }else{
        NSError *err;
        // 服务器socket实例化  在0x1234端口监听数据
        _socketArray=[[NSMutableArray alloc] initWithCapacity:1];;
        BOOL status =[_socket acceptOnInterface:_ip port:_port error:&err];
        NSString *msg=[NSString stringWithFormat:@"start status:%hhd error:%@",status,err];
        [self myPrint:msg];
        if(status){
            [modeBtn setEnabled:NO];
            [ipTF setEnabled:NO];
            [portTF setEnabled:NO];
            [startBtn setTitle:@"Stop"];
            _isConnected=YES;
        }else{
            return NO;
        }
        
    }
    
    return YES;
}
-(void)stopSocket{
    if ([_mode isEqualToString:@"client"]) {
        [_socket setDelegate:nil];
        [_socket disconnect];
        _socket=nil;
        
    }else{
        for (int i=0; i<[_socketArray count]; i++) {
            GCDAsyncSocket *client=[_socketArray objectAtIndex:i];
            [client disconnect];
            [client setDelegate:nil];
            
        }
        [_socket setDelegate:nil];
        [_socket disconnect];
    }
    _isConnected=NO;
    NSLog(@"stop socket");
}
-(IBAction)saveBtnAction:(id)sender{
    _mode=[modeBtn titleOfSelectedItem];
    _ip=[ipTF stringValue];
    _port=[portTF intValue];
    NSString *portStr=[NSString stringWithFormat:@"%d",_port];
    NSString *idStr=[NSString stringWithFormat:@"%d",self._id];
    NSDictionary *cfgDict=@{@"Type":@"SOCKET",@"IP":_ip,@"Port":portStr,@"Mode":_mode,@"ID":idStr};
    [self.delegate saveConfigEvent:cfgDict];
    [self showPanel:[NSString stringWithFormat:@"Save socket mode:%@ ip:%@ port:%d id:%d successful!",
                     _mode,_ip,_port,self._id]];
}
-(IBAction)sendBtnAction:(id)sender{
    NSString *cmd=[cmdTF stringValue];
    [NSThread detachNewThreadSelector:@selector(testQueryThread:) toTarget:self withObject:cmd];
}
-(void)testQueryThread:(NSString *)request{
    NSString *reply=[self query:request];
    [self myPrint:[NSString stringWithFormat:@"reply:%@",reply]];
}
-(BOOL)sendCommand:(NSString *)cmd{
    if (!_isConnected) {
        [self myPrint:@"[send Command]ERROR:no connect"];
        return NO;
    }
    NSData *data=[cmd dataUsingEncoding:NSUTF8StringEncoding];
    NSString *msg=[NSString stringWithFormat:@"[TX]%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    [self myPrint:msg];
    if ([_mode isEqualToString:@"client"]) {
        [_socket writeData:data withTimeout:WRITE_TIMEOUT tag:300];
        // 继续读取socket数据
        [_socket readDataWithTimeout:-1 tag:300];
    }
    else{
        if([_socketArray count] == 0){
            [self myPrint:@"No client connected,please check!"];
            return NO;
        }
        for (int i=0; i<[_socketArray count]; i++) {
            GCDAsyncSocket *client=[_socketArray objectAtIndex:i];
            [client writeData:data withTimeout:WRITE_TIMEOUT tag:300];
            // 继续读取socket数据
            [client readDataWithTimeout:-1 tag:300];
        }
        
    }
    return YES;
}
-(NSString *)query:(NSString *)request{
    if (!_isConnected) {
        [self myPrint:@"[query]ERROR:no connect"];
        return @"";
    }
    _IS_REPLY=NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [_receiveStr setString:@""];
    [self sendCommand:request];
    [NSThread detachNewThreadSelector:@selector(waitSignal:) toTarget:self withObject:semaphore];
    //等待(阻塞线程)
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return [_receiveStr copy];
}
-(void)waitSignal:(dispatch_semaphore_t )semaphore{
    double count=0.0;
    while (count<self.timeout) {
        [NSThread sleepForTimeInterval:0.02];
        count+=0.02;
        if(_IS_REPLY) break;
    }
    dispatch_semaphore_signal(semaphore);
}
-(NSArray *)getClientList{
    NSMutableArray *clientArr=[[NSMutableArray alloc] initWithCapacity:0];
    for (GCDAsyncSocket *newSocket in _socketArray) {
        // client ip地址  192..
        [clientArr addObject:[newSocket connectedHost]];
        
    }
    return [clientArr copy];
}
// 有新的socket向服务器链接自动回调
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    _isConnected=YES;
    [cmdTF setEnabled:YES];
    [sendBtn setEnabled:YES];
    [_socketArray addObject:newSocket];
    NSString *msg=[NSString stringWithFormat:@"Accept new client:%@ ip:%@",newSocket,[newSocket connectedHost]];
    [self myPrint:msg];
    
    // 如果下面的方法不写 只能接收一次socket链接
    
    [newSocket readDataWithTimeout:-1 tag:300];
    
}
// 网络连接成功后  自动回调
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    _isConnected=YES;
    if ([_mode isEqualToString:@"client"]) {
        [cmdTF setEnabled:YES];
        [sendBtn setEnabled:YES];
        //_socket = sock;
        NSString *msg=[NSString stringWithFormat:@"connected server:ip:%@ port:%d",host,port];
        [self myPrint:msg];
        //[self logUpdate:msg];
        // 继续读取socket数据
        [sock readDataWithTimeout:-1 tag:300];
        return;
    }
    NSString *msg=[NSString stringWithFormat:@"connected client:ip:%@ port:%d",host,port];
    [self myPrint:msg];
}
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *message=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self.delegate receivedData:message];
    NSString *msg=[NSString stringWithFormat:@"[RX]:%@",message];
    [self myPrint:msg];
    [_receiveStr setString:message];
    _IS_REPLY=YES;
    /*client mode*/
    if([_mode isEqualToString:@"client"]){
        // 继续读取socket数据
        [_socket readDataWithTimeout:-1 tag:300];
        return;
    }
    /*server mode*/
//    NSString *response=[self.delegate reply:message];
//    msg=[NSString stringWithFormat:@"[TX]:%@",response];
//    [self myPrint:msg];
//    NSData *newData=[response dataUsingEncoding:NSUTF8StringEncoding];
//    [sock writeData:newData withTimeout:-1 tag:300];
    // 继续读取socket数据
    [sock readDataWithTimeout:-1 tag:300];
    
}

/*重连
 
 实现代理方法
 
 -(void)onSocketDidDisconnect:(GCDAsyncSocket *)sock
 {
 NSLog(@"sorry the connect is failure %@",sock.userData);
 if (sock.userData == SocketOfflineByServer) {
 // 服务器掉线，重连
 [self socketConnectHost];
 }
 else if (sock.userData == SocketOfflineByUser) {
 // 如果由用户断开，不进行重连
 return;
 }
 
 }
 */
// 连接断开时  服务器自动回调
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err
{
    if ([_mode isEqualToString:@"client"] ) {
        _isConnected=NO;
        [cmdTF setEnabled:NO];
        [sendBtn setEnabled:NO];
        [modeBtn setEnabled:YES];
        [ipTF setEnabled:YES];
        [portTF setEnabled:YES];
        [startBtn setTitle:@"Start"];

        [self myPrint:@"[alert]****Disconnect****"];
        _socket=nil;
        return;
    }
    NSString *msg=[NSString stringWithFormat:@"Client:%@ disconnect!",sock];
    [self myPrint:msg];
    //[self logUpdate:msg];
    [_socketArray removeObject:sock];
    //NSLog(@"Client offline");
    //[clientTableView reloadData];
    if ([_socketArray count] == 0) {
        _isConnected=NO;
    }
}

// 向用户发出的消息  自动回调
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSString *msg=[NSString stringWithFormat:@"send to [%@] successful",[sock connectedHost]];
    [self myPrint:msg];
}
/*
 //read data timeout callback
 - (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
 elapsed:(NSTimeInterval)elapsed
 bytesDone:(NSUInteger)length{
 [self logUpdate:@"[RX]Read data timeout!"];
 [sock readDataWithTimeout:-1 tag:300];
 return 0.05;
 }
 
 - (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
 elapsed:(NSTimeInterval)elapsed
 bytesDone:(NSUInteger)length{
 
 [self logUpdate:@"[TX]Send data timeout!"];
 return -1;
 }
 */
-(void)myPrint:(NSString *)log{
    NSLog(@"%@",log);
    dispatch_async(dispatch_get_main_queue(), ^{
        //通知主线程更新
        [self->receivedTF setStringValue:log];
    });
    [self.delegate debugPrint:log withID:self._id];
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
- (void)debugPrint:(NSString *)log withID:(int)myID {
    
}

- (NSString *)reply:(NSString *)request {
    return @"";
}

- (BOOL)saveConfigEvent:(NSDictionary *)info{
    return YES;
}

- (BOOL)commitEditingAndReturnError:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    
}

@end
