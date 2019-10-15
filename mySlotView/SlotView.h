//
//  SlotView.h
//  HelperForW1A
//
//  Created by Weidong Cao on 2019/10/11.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SlotView : NSViewController
{
    IBOutlet NSTextField *slotTF;
    IBOutlet NSTextField *resultTF;
}

@property (nonatomic,strong) IBOutlet NSImageView *capIV;
@property (nonatomic,assign) int slot_id;
@property (nonatomic,assign) NSPoint monitorPoint;
@property (nonatomic,assign) int colorVal;
@property (nonatomic,strong) NSString *status;
@property (nonatomic,strong) NSImage *capImage;
@property (nonatomic,strong) NSDictionary *rootDict;

-(void)initView;
-(void)updateStatus;
-(void)printCapImage;
@end

NS_ASSUME_NONNULL_END
