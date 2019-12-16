//
//  SlotView.h
//  HelperForW1A
//
//  Created by Weidong Cao on 2019/10/11.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SlotViewDelegate <NSObject>

-(void)msgFromSlotView:(NSString *)msg;

@end

@interface SlotView : NSViewController<SlotViewDelegate>
{
    IBOutlet NSTextField *resultTF;
    IBOutlet NSButton *selectBtn;
}

@property (nonatomic,strong) IBOutlet NSImageView *capIV;
@property (nonatomic,assign) int slot_id;
@property (nonatomic,assign) NSPoint monitorPoint;
@property (nonatomic,assign) int colorVal;
@property (nonatomic,strong) NSString *status;
@property (nonatomic,strong) NSImage *capImage;
@property (nonatomic,strong) NSDictionary *rootDict;
@property (nonatomic,assign) BOOL selected;
@property (nonatomic,weak) id<SlotViewDelegate> delegate;

-(void)initView;
-(void)updateStatus;
-(void)printCapImage;

-(void)sendMsg2SlotView:(NSString *)msg;

-(IBAction)selectBtnAction:(id)sender;

@end

NS_ASSUME_NONNULL_END
