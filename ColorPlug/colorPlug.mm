//
//  colorPlug.m
//  OBJ_OPCV
//
//  Created by 曹伟东 on 2019/2/18.
//  Copyright © 2019年 曹伟东. All rights reserved.
//

#import "colorPlug.h"
#import "SlotView.h"

#ifdef check
#define OS_X_STUPID_CHECK_MACRO check
#undef check
#endif

#ifdef __cplusplus
#undef NO
#undef YES
//#import <opencv2/opencv.hpp>
#include <opencv2/opencv.hpp>
#endif

#include <opencv2/opencv.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include "opencv2/imgcodecs.hpp"
#include "opencv2/objdetect.hpp"
#include "opencv2/core/core.hpp"
#include "opencv2/core/utility.hpp"
#include "opencv2/videoio.hpp"



#include <iostream>
#include <stdio.h>

#ifdef OS_X_STUPID_CHECK_MACRO
#define check OS_X_STUPID_CHECK_MACRO
#undef OS_X_STUPID_CHECK_MACRO
#endif
using namespace std;
using namespace cv;

@interface colorPlugView ()
{
    //myOpenCVUtils cvUtils;
    
    //int displayH, displayW;
    int pointIndex;
    NSTimer *mouseXYtimer;
    
    int _value_COLOR;
    //int _index_mode;
    
    NSMutableDictionary *rootSet;
}
@end

@implementation colorPlugView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self setTitle:@"Color Plug View"];
    //[self logUpdate:@"LogView Load..."];
    
    mouseXYtimer=nil;
    
    [_pointTimesBtn removeAllItems];
    [_pointTimesBtn addItemsWithTitles:@[@"1",@"2"]];
    [_pointTimesBtn selectItemAtIndex:1];
    
    pointIndex=2;
    
    [_modeBtn removeAllItems];
    [_modeBtn addItemsWithTitles:
        @[@"pTimes",@"Point",@"IDLE",@"TESTING",@"PASS",@"FAIL",@"ERROR"]];
    [_modeBtn selectItemAtIndex:0];
    //_index_mode = 0;
    
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *filePath=[rawfilePath stringByAppendingPathComponent:self._plistFile];
    rootSet=[[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    
    _value_COLOR=0;
}

//get pixel value of (x,y)
-(int)getColorValue:(NSPoint )point pTimes:(int )times{
    int value = 0;
    //get full screenshot
    Mat screenMat= [self getFullScreen];
    //edge protect
    int x=point.x + 100 > self.displayW ? times*self.displayW-100 : times*point.x;
    int y=point.y + 100 > self.displayH ? times*self.displayH-100 : times*point.y;
    //get ROI image of size 100*100
    Mat imageROI=screenMat(cv::Rect(x,y,100,100));
    screenMat.release();
    //get pixel value of (0,0)
    value= imageROI.at<uchar>(0,0);
    NSLog(@"Pixel value:%d",value);
    imageROI.release();
    
    return value;
}
-(NSArray *)getValueWithPoints:(NSArray *)pointArr withTimes:(int )t{
    NSMutableArray *Values=[[NSMutableArray alloc] initWithCapacity:1];
    //get full screenshot
    Mat screenMat= [self getFullScreen];
    int count=(int)[pointArr count];
    for (int i=0; i<count; i++) {
        NSPoint point=NSPointFromString(pointArr[i]);
        //edge protect
        int x=point.x + 100 > self.displayW ? t*self.displayW-100 : t*point.x;
        int y=point.y + 100 > self.displayH ? t*self.displayH-100 : t*point.y;
        //get ROI image of size 100*100
        Mat imageROI=screenMat(cv::Rect(x,y,100,100));
        
        //get pixel value of (0,0)
        int value=imageROI.at<uchar>(0,0);
        NSLog(@"Pixel value:%d",value);
        [Values addObject:[NSString stringWithFormat:@"%d",value]];
        imageROI.release();
    }
    screenMat.release();
    return Values;
}

-(void)updateSlots:(NSMutableArray *__strong *)slotsArr withTimes:(int )t{
    
    //NSMutableArray *Values=[[NSMutableArray alloc] initWithCapacity:1];
    //get full screenshot
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
    });
    Mat screenMat= [self getFullScreen];
    int count=(int)[*slotsArr count];
    for (int i=0; i<count; i++) {
        SlotView *slot = [*slotsArr objectAtIndex:i];
        
        NSPoint point=slot.monitorPoint;
        //edge protect
        int x=point.x + 100 > self.displayW ? t*self.displayW-100 : t*point.x;
        int y=point.y + 100 > self.displayH ? t*self.displayH-100 : t*point.y;
        //get ROI image of size 100*100
        Mat imageROI=screenMat(cv::Rect(x,y,100,100));
        
        //get pixel value of (0,0)
        slot.colorVal=imageROI.at<uchar>(0,0);
        //Vec3b *value3 =imageROI.ptr<Vec3b>(0,0); //cv2:BGR
        //NSLog(@"B_v:%d G_v:%d R_v:%d",(*value3)[0],(*value3)[1],(*value3)[2]);
        slot.capImage=[self mat2nsimage:imageROI];
        NSLog(@"Pixel value:%d",slot.colorVal);
        //save capture image
        //NSString *timeFix=[self getTimeFix];
        //NSString *nsPath=[NSString stringWithFormat:@"/vault/AOT_saveImages/Slot-%d%@.bmp",slot.slot_id,timeFix];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            //[self saveImage:slot.capImage path:nsPath];
            
            [self drawImage:imageROI :slot.capIV];
            //[Values addObject:[NSString stringWithFormat:@"%d",value]];
            
        });
        
        imageROI.release();
        [NSThread sleepForTimeInterval:0.05];
        //*slotsArr[i] = slot;
        [*slotsArr replaceObjectAtIndex:i withObject:slot];
    }
    screenMat.release();
}
- (void )saveImage:(NSImage *)image path:(NSString *)path
{
    // Cache the reduced image
    NSData *imageData = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
    BOOL y = [imageData writeToFile:path atomically:true];
    
    NSLog(@"Save Image: %d", y);
}
-(int)matchTwoImages:(Mat )pic1 image2:(Mat )pic2{
    Mat matDst1, matDst2;
    
    cv::resize(pic1, matDst1, cv::Size(8, 8), 0, 0, cv::INTER_CUBIC);
    cv::resize(pic2, matDst2, cv::Size(8, 8), 0, 0, cv::INTER_CUBIC);
    
    cv::cvtColor(matDst1, matDst1, COLOR_BGR2GRAY);
    cv::cvtColor(matDst2, matDst2, COLOR_BGR2GRAY);
    
    int iAvg1 = 0, iAvg2 = 0;
    int arr1[64], arr2[64];
    
    for (int i = 0; i < 8; i++)
    {
        uchar* data1 = matDst1.ptr<uchar>(i);
        uchar* data2 = matDst2.ptr<uchar>(i);
        
        int tmp = i * 8;
        
        for (int j = 0; j < 8; j++)
        {
            int tmp1 = tmp + j;
            
            arr1[tmp1] = data1[j] / 4 * 4;
            arr2[tmp1] = data2[j] / 4 * 4;
            
            iAvg1 += arr1[tmp1];
            iAvg2 += arr2[tmp1];
        }
    }
    
    iAvg1 /= 64;
    iAvg2 /= 64;
    
    for (int i = 0; i < 64; i++)
    {
        arr1[i] = (arr1[i] >= iAvg1) ? 1 : 0;
        arr2[i] = (arr2[i] >= iAvg2) ? 1 : 0;
    }
    
    int iDiffNum = 0;
    
    for (int i = 0; i < 64; i++)
        if (arr1[i] != arr2[i])
            ++iDiffNum;
    
    cout<<"iDiffNum = "<<iDiffNum<<endl;
    
    if (iDiffNum <= 5)
        cout<<"two images are very similar!"<<endl;
    else if (iDiffNum > 10)
        cout<<"they are two different images!"<<endl;
    else
        cout<<"two image are somewhat similar!"<<endl;
    return iDiffNum;
}
//NSImage 转换为 CGImageRef
- (CGImageRef)NSImageToCGImageRef:(NSImage*)image{
    
    NSData * imageData = [image TIFFRepresentation];
    
    CGImageRef imageRef;
    
    if(imageData){
        
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
        
        imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        
    }
    else{
        return NULL;
    }
    
    return imageRef;
    
}
-(IBAction)testBtnAction:(id)sender{
    Mat screenMat= [self getFullScreen];
    [self drawImage:screenMat :_screenView];
    Mat imageROI=screenMat(cv::Rect(0,0,100,100));
    [NSThread sleepForTimeInterval:0.05];
    [self drawImage:imageROI :_outputView];
    uchar value1= imageROI.at<uchar>(0,0);
    NSLog(@"value:%hhu",value1);
    screenMat.release();
    imageROI.release();
    NSLog(@"print mouse xy...");
    //NSPoint p=[NSEvent mouseLocation];
    CGEventRef ourEvent = CGEventCreate(NULL);
    NSPoint point = CGEventGetLocation(ourEvent);
    CFRelease(ourEvent);
    NSLog(@"X:%.f Y:%.f",point.x,point.y);
}
-(void)printMouseXY{
    NSLog(@"print mouse xy...");
    //NSPoint p=[NSEvent mouseLocation];
    CGEventRef ourEvent = CGEventCreate(NULL);
    NSPoint point = CGEventGetLocation(ourEvent);
    CFRelease(ourEvent);
    NSLog(@"X:%.f Y:%.f",point.x,point.y);
    
    //NSPoint p2=NSMakePoint(.x, (self.displayH-p.y));
    //_point_MOUSE=p2;
    [self drawROI:point];
}
-(void)drawROI:(NSPoint )point{
    Mat screenMat= [self getFullScreen];
    
    //[self drawImage:screenMat :_srcTV];
    float x=point.x + 50 > self.displayW ? pointIndex*self.displayW-100 : pointIndex*point.x;
    float y=point.y + 50 > self.displayH ? pointIndex*self.displayH-100 : pointIndex*point.y;
    
    Mat imageROI=screenMat(cv::Rect(x,y,100,100));
    screenMat.release();
    [NSThread sleepForTimeInterval:0.05];
    [self drawImage:imageROI :self->_outputView];
    uchar value1= imageROI.at<uchar>(0,0);
    _value_COLOR=value1;
    imageROI.release();
    //output.release();
    
    NSLog(@"value:%hhu",value1);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_printLabel setStringValue:
         [NSString stringWithFormat:@"mouseX:%.f mouseY:%.f\r\nX:%f Y:%f value:%hhu",point.x,point.y,x,y,value1]];
    });
    
}
-(Mat)getFullScreen{
    CGImageRef screenShot = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault);
    Mat outMat=[self CVMat:screenShot];
    CGImageRelease(screenShot);
    NSLog(@"outMat rows:%d colums:%d",outMat.rows,outMat.cols);
    return outMat;
}
-(Mat)CVMat:(CGImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
    CGFloat cols = CGImageGetWidth(image);
    CGFloat rows = CGImageGetHeight(image);
    
    NSLog(@"image width:%f height:%f",cols,rows);
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef =
    CGBitmapContextCreate(cvMat.data,  // Pointer to backing data
                          cols,    // Width of bitmap
                          rows,    // Height of bitmap
                          8,       // Bits per component
                          cvMat.step[0], // Bytes per row
                          colorSpace,  // Colorspace
                          kCGImageByteOrder32Little |
                          kCGImageAlphaPremultipliedFirst); // Bitmap info flags
    /*
     //顺序  +   argb  = argb
     kCGImageByteOrder32Big | kCGImageAlphaPremultipliedFirst
     //顺序  +   rgba  = rgba
     kCGImageByteOrder32Big | kCGImageAlphaPremultipliedLast
     //倒序   +  rgba   = abgr
     kCGImageByteOrder32Little | kCGImageAlphaPremultipliedLast
     //倒序 + argb = bgra;
     //kCGImageByteOrder32Little | kCGImageAlphaPremultipliedFirst
     */
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image);
    CGContextRelease(contextRef);
    
    return cvMat;
}
-(NSImage *)mat2nsimage:(Mat )matImage{
    NSImage* img = nil;
    NSBitmapImageRep* bitmapRep = nil;
    
    Mat dispImage;
    cvtColor(matImage, dispImage, COLOR_BGR2RGB);
    bitmapRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&dispImage.data pixelsWide:dispImage.cols pixelsHigh:dispImage.rows bitsPerSample:8 samplesPerPixel:3 hasAlpha:false isPlanar:false colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:dispImage.step bitsPerPixel:0];
    img = [[NSImage alloc] initWithSize:NSMakeSize(dispImage.cols, dispImage.rows)];
    
    
    [img addRepresentation:bitmapRep];
    
    dispImage.release();
    bitmapRep = nil;
    return img;
}
- (void)drawImage : (Mat)matImage : (NSImageView *)View{
    
    NSImage* img = nil;
    NSBitmapImageRep* bitmapRep = nil;
    
    Mat dispImage;
    cvtColor(matImage, dispImage, COLOR_BGR2RGB);
    bitmapRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&dispImage.data pixelsWide:dispImage.cols pixelsHigh:dispImage.rows bitsPerSample:8 samplesPerPixel:3 hasAlpha:false isPlanar:false colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:dispImage.step bitsPerPixel:0];
    img = [[NSImage alloc] initWithSize:NSMakeSize(dispImage.cols, dispImage.rows)];
    
    
    [img addRepresentation:bitmapRep];
    dispatch_async(dispatch_get_main_queue(), ^{
        [View setImage:img];
    });

    dispImage.release();
    
    bitmapRep = nil;
    img = nil;
}
-(IBAction)pointTimesBtnAction:(id)sender{
    if ([_pointTimesBtn indexOfSelectedItem] == 0) {
        pointIndex = 1;
    }else{
        pointIndex = 2;
    }
}
-(IBAction)saveBtnAction:(id)sender{
    NSLog(@"Save Btn press");
    //@[@"pTimes",@"Point",@"IDLE",@"TESTING",@"PASS",@"FAIL",@"ERROR"]]
    NSString *modeStr=@"pTimes";
    NSString *value=@"";
    NSString *key=@"";
    bool _save_dic = false;
    int index = (int)[_modeBtn indexOfSelectedItem];
    if (index == 0) {
        modeStr=@"pTimes";
        key=@"POINT_TIMES";
        value = [_pointTimesBtn titleOfSelectedItem];
        _save_dic=true;
    }
    else if(index == 1){
        modeStr=@"Point";
        //NSPoint p=[NSEvent mouseLocation];
        CGEventRef ourEvent = CGEventCreate(NULL);
        NSPoint point = CGEventGetLocation(ourEvent);
        CFRelease(ourEvent);
        NSString *x_Str=[NSString stringWithFormat:@"%f",point.x];
        NSString *y_Str=[NSString stringWithFormat:@"%f",point.y];
        [rootSet setValue:x_Str forKey:@"POINT_X"];
        [rootSet setValue:y_Str forKey:@"POINT_Y"];
        NSString *portFilePath=[[NSBundle mainBundle] resourcePath];
        portFilePath =[portFilePath stringByAppendingPathComponent:self._plistFile];
        [rootSet writeToFile:portFilePath atomically:false];
        
    }
    else if (index == 2) {
        modeStr=@"IDLE";
        key=@"IDLE_VALUE";
        value = [NSString stringWithFormat:@"%d",_value_COLOR];
        _save_dic=true;
    }
    else if (index == 3) {
        modeStr=@"TESTING";
        key=@"TESTING_VALUE";
        value = [NSString stringWithFormat:@"%d",_value_COLOR];
        _save_dic=true;
    }
    else if (index == 4) {
        modeStr=@"PASS";
        key=@"PASS_VALUE";
        value = [NSString stringWithFormat:@"%d",_value_COLOR];
        _save_dic=true;
    }
    else if (index == 5) {
        modeStr=@"FAIL";
        key=@"FAIL_VALUE";
        value = [NSString stringWithFormat:@"%d",_value_COLOR];
        _save_dic=true;
    }
    else if (index == 6) {
        modeStr=@"ERROR";
        key=@"ERROR_VALUE";
        value = [NSString stringWithFormat:@"%d",_value_COLOR];
        _save_dic=true;
    }
    
    if(_save_dic){
        [rootSet setValue:value forKey:key];
        NSString *portFilePath=[[NSBundle mainBundle] resourcePath];
        portFilePath =[portFilePath stringByAppendingPathComponent:self._plistFile];
        [rootSet writeToFile:portFilePath atomically:false];
    }
    
    [self printAlarmWindow:[NSString stringWithFormat:@"Save %@ OK.",modeStr]];
    
}
-(IBAction)modeBtnAction:(id)sender{
    //[self printAlarmWindow:@"lalala"];
    //_index_mode=(int)[_modeBtn indexOfSelectedItem];
    
}
-(IBAction)startBtnAction:(id)sender{
    if([[_startBtn title] isEqualToString:@"START"]){
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            self->mouseXYtimer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(printMouseXY) userInfo:nil repeats:true];
            [[NSRunLoop currentRunLoop] addTimer:self->mouseXYtimer forMode:NSRunLoopCommonModes];
            [[NSRunLoop currentRunLoop] run];
        });
        [_startBtn setTitle:@"STOP"];
        [_printLabel setBackgroundColor:[NSColor greenColor]];
    }else{
        [mouseXYtimer invalidate];
        mouseXYtimer = nil;
        [_startBtn setTitle:@"START"];
        [_printLabel setBackgroundColor:[NSColor whiteColor]];
    }
}

-(long)printAlarmWindow:(NSString *)info{
    NSLog(@"start run window");
    NSAlert *theAlert=[[NSAlert alloc] init];
    [theAlert addButtonWithTitle:@"OK"]; //1000
    //[theAlert addButtonWithTitle:@"No"]; //1001
    
    [theAlert setMessageText:@"Alarm!"];
    [theAlert setInformativeText:info];
    //[theAlert setAlertStyle:0];
    //[theAlert setIcon:[NSImage imageNamed:@"alarm1.png"]];
    
    NSLog(@"End run window");
    // [theAlert beginSheetModalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
    //int choice = [theAlert runModal];
    
    return [theAlert runModal];
    
}

-(void)viewWillDisappear{
    //self._isShowView=NO;
    if(mouseXYtimer != nil) {
        [mouseXYtimer invalidate];
        mouseXYtimer = nil;
        [_startBtn setTitle:@"START"];
    }
    NSLog(@"color view disappear!");
}
-(NSString *)getTimeFix{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"_YYYYMMddHHmmssSSS"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    return currentTime;
}
@end
