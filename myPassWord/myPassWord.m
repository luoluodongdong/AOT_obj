//
//  myPassWord.m
//  TT_ICT
//
//  Created by 曹伟东 on 2019/1/2.
//  Copyright © 2019年 曹伟东. All rights reserved.
//

#import "myPassWord.h"

@interface myPassWord ()

@end

@implementation myPassWord

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    if (self._passwordStr == nil || [self._passwordStr  isEqual: @""]) {
        self._passwordStr=@"123";
    }
}
-(IBAction)inputPWDAction:(id)sender{
    NSString *inputStr=[_inputTF stringValue];
    if ([inputStr isEqualToString:self._passwordStr]) {
        [self.delegate send2TT_PassWord:YES];
        [self dismissController:self];
    }else{
        [_inputTF setBackgroundColor:[NSColor systemRedColor]];
        
    }
}
-(IBAction)backBtnAction:(id)sender{
    [self.delegate send2TT_PassWord:NO];
    
    [self dismissViewController:self];
}

- (void)send2TT_PassWord:(BOOL)message {
    
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    
}

@end
