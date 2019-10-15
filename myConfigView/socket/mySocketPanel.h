//
//  mySocketPanel.h
//  LibTest
//
//  Created by Weidong Cao on 2019/6/21.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GCDAsyncSocket.h"

@protocol SocketPanelDelegate<NSObject>
//save config;
-(BOOL)saveConfigEvent:(NSDictionary *)info;
//receivedData for connected server/client
-(void)receivedData:(NSString *)data;
//debug print
-(void)debugPrint:(NSString *)log withID:(int )myID;

@end

@interface MySocketPanel : NSViewController<GCDAsyncSocketDelegate,SocketPanelDelegate>
{
    IBOutlet NSButton *backBtn;
    IBOutlet NSTextField *descriptionTF;
    IBOutlet NSPopUpButton *modeBtn;
    IBOutlet NSTextField *ipTF;
    IBOutlet NSTextField *portTF;
    IBOutlet NSButton *startBtn;
    IBOutlet NSButton *saveBtn;
    IBOutlet NSTextField *cmdTF;
    IBOutlet NSButton *sendBtn;
    IBOutlet NSTextField *receivedTF;
}

@property (nonatomic,weak) id<SocketPanelDelegate> delegate;
//a description of the socket,exp:"Fixture socket setting"
@property (nonatomic,strong) NSString *_description;
//a id info of the socket,exp:2000
@property (nonatomic,assign) int _id;
//the mode of the socket,contain "client" and "server"
@property (nonatomic,strong) NSString *mode;
//the status of the socket
@property (atomic,assign) BOOL isConnected;
//*client mode* send a query to server,the waiting second for reply
@property (nonatomic,assign) double timeout;

/*!
 *Client & Server mode public func
 */
//init socket pannel
-(void)initView;
//auto start a socket for client or server
-(BOOL)autoStartSocket:(NSString *)ip port:(int )port;
//close the socket
-(void)stopSocket;
//send a command pass the socket channel
-(BOOL)sendCommand:(NSString *)msg;

/*!
 *just for server mode
 */
//get connected clients
-(NSArray *)getClientList;

/*!
 *just for client mode
 */
//*client mode* send a query to server
//!this func don't in main thread!
-(NSString *)query:(NSString *)request;


-(IBAction)backBtnAction:(id)sender;
-(IBAction)modeBtnAction:(id)sender;
-(IBAction)startBtnAction:(id)sender;
-(IBAction)saveBtnAction:(id)sender;
-(IBAction)sendBtnAction:(id)sender;

@end

