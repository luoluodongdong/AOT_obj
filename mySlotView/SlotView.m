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
    [slotTF setStringValue:[NSString stringWithFormat:@"Slot-%d",_slot_id]];
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
@end
