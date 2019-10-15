//
//  myPassWord.h
//  TT_ICT
//
//  Created by 曹伟东 on 2019/1/2.
//  Copyright © 2019年 曹伟东. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol PassWordDelegate<NSObject>
-(void)send2TT_PassWord:(BOOL )message;
@end

@interface myPassWord : NSViewController<PassWordDelegate>
{
    IBOutlet NSButton *_backBtn;
    IBOutlet NSTextField *_inputTF;
}
@property (nonatomic) NSString *_passwordStr;

@property (nonatomic,weak) id<PassWordDelegate> delegate;

-(IBAction)backBtnAction:(id)sender;
-(IBAction)inputPWDAction:(id)sender;

@end
