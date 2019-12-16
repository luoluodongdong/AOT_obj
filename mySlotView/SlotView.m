//
//  SlotView.m
//  HelperForW1A
//
//  Created by Weidong Cao on 2019/10/11.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import "SlotView.h"

@interface SlotView ()
{
    NSDictionary *colorDict;
    int _VALUE_PASS,_VALUE_FAIL,_VALUE_ERROR,_VALUE_IDLE,_VALUE_TESTING;
}
@end

@implementation SlotView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}
-(void)initView{
    [selectBtn setTitle:[NSString stringWithFormat:@"Slot-%d",_slot_id+1]];
    [resultTF setBackgroundColor:[NSColor whiteColor]];
    [resultTF setStringValue:@"IDLE"];
    [resultTF setNeedsDisplay:YES];
    colorDict =@{@"IDLE":[NSColor whiteColor],
                 @"TESTING":[NSColor yellowColor],
                 @"PASS":[NSColor greenColor],
                 @"FAIL":[NSColor redColor],
                 @"ERROR":[NSColor redColor],
                 @"UNKNOWN":[NSColor redColor],
                 @"TIMEOUT":[NSColor redColor],
                 };
    _capImage=NULL;
    _VALUE_FAIL=[[_rootDict objectForKey:@"FAIL_VALUE"] intValue];
    _VALUE_PASS=[[_rootDict objectForKey:@"PASS_VALUE"] intValue];
    _VALUE_ERROR=[[_rootDict objectForKey:@"ERROR_VALUE"] intValue];
    _VALUE_IDLE=[[_rootDict objectForKey:@"IDLE_VALUE"] intValue];
    _VALUE_TESTING=[[_rootDict objectForKey:@"TESTING_VALUE"] intValue];
}
-(void)updateStatus{
    _status = @"UNKNOWN";
    if (_colorVal == _VALUE_IDLE) {
        _status = @"IDLE";
    }
    else if(_colorVal == _VALUE_TESTING){
        _status = @"TESTING";
    }
    else if(_colorVal == _VALUE_PASS){
        _status = @"PASS";
    }
    else if(_colorVal == _VALUE_FAIL){
        _status = @"FAIL";
    }
    else if(_colorVal == _VALUE_ERROR){
        _status = @"ERROR";
    }
    
    [resultTF setBackgroundColor:[colorDict objectForKey:_status]];
    [resultTF setStringValue:_status];
    [resultTF setNeedsDisplay:YES];
    
    //[self printCapImage];
}
-(void)printCapImage{
    if (_capImage) {
        [_capIV setImage:_capImage];
        [_capIV setNeedsDisplay:YES];
    }
}

#pragma mark ---Select Btn Action

-(IBAction)selectBtnAction:(id)sender{
    NSInteger isSelected = [selectBtn state];
    if (1 == isSelected) {
        [resultTF setBackgroundColor:[NSColor whiteColor]];
        [resultTF setStringValue:@"IDLE"];
        [_capIV setHidden:NO];
    }else{
        [_capIV setHidden:YES];
        [resultTF setBackgroundColor:[NSColor lightGrayColor]];
        [resultTF setStringValue:@""];
    }
    [self.delegate msgFromSlotView:[NSString stringWithFormat:@"SELECTED:%d:%ld",self.slot_id,isSelected]];
}
#pragma mark ---Msg From Frame
-(void)sendMsg2SlotView:(NSString *)msg{
    NSLog(@"[Slot-%d]:msg form frame:%@",self.slot_id+1,msg);
    @synchronized (self) {
        if ([msg hasPrefix:@"LOCK:"]) {
            NSArray *msgArr=[msg componentsSeparatedByString:@":"];
            [self performSelectorOnMainThread:@selector(changeLockState:) withObject:msgArr[1] waitUntilDone:NO];
        }
    }
    
}
-(void)changeLockState:(NSString *)isLocked{
    if ([isLocked isEqualToString:@"1"]) {
        [selectBtn setEnabled:NO];
    }else{
        [selectBtn setEnabled:YES];
    }
    
}
- (void)msgFromSlotView:(nonnull NSString *)msg {
    
}

- (BOOL)commitEditingAndReturnError:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    
}

@end
