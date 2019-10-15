//
//  NIVISAHelp.h
//  NIVISAtest
//
//  Created by 曹伟东 on 2018/9/20.
//  Copyright © 2018年 曹伟东. All rights reserved.
//
#if defined(_MSC_VER) && !defined(_CRT_SECURE_NO_DEPRECATE)
/* Functions like strcpy are technically not secure because they do */
/* not contain a 'length'. But we disable this warning for the VISA */
/* examples since we never copy more than the actual buffer size.   */
#define _CRT_SECURE_NO_DEPRECATE
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "VISA/visa.h"

#define READ_BUFFER_SIZE 4096

static ViStatus status;
static ViUInt32 BytesToWrite;
static ViUInt32 retCount;
static ViUInt32 writeCount;
static unsigned char buffer[READ_BUFFER_SIZE];
static char stringinput[512];

static char instrDescriptor[VI_FIND_BUFLEN];
static ViUInt32 numInstrs;
static ViFindList findList;
static ViSession defaultRM, instr;
static ViStatus status;

bool VISA_OPEN = false;

int openVISArm(void);
int closeVISArm(void);
NSMutableArray *findAllDevices(void);

int openDevice(NSString *device,int baudRate,int timeOut);
int closeDevice(int fileDescriptor);
int writeDevice(int fileDescriptor,NSString *cmd);
NSString *readDevice(int fileDescriptor);

int openUSB(NSString *device, int timeout);
int closeUSB(int fileDescriptor);
int writeUSB(int fileDescritpor,NSString *cmd);
NSString *readUSB(int fileDescritpor);

int openSerialPort(NSString *device ,int baudRate,int timeOut);
int closeSerialPort(int fileDescriptor);
int writeRS232(int fileDescritpor,NSString *cmd);
NSString *readRS232(int fileDescritpor);

int openGPIB(NSString *device, int timeout);
int closeGPIB(int fileDescriptor);
int writeGPIB(int fileDescritpor,NSString *cmd);
NSString *readGPIB(int fileDescritpor);


NSMutableArray *findAllDevices(void)
{
    NSMutableArray *result = [[NSMutableArray alloc]init];
    /*
     * Find all the VISA resources in our system and store the number of resources
     * in the system in numInstrs.  Notice the different query descriptions a
     * that are available.
     
     Interface         Expression
     --------------------------------------
     GPIB              "GPIB[0-9]*::?*INSTR"
     VXI               "VXI?*INSTR"
     GPIB-VXI          "GPIB-VXI?*INSTR"
     Any VXI           "?*VXI[0-9]*::?*INSTR"
     Serial            "ASRL[0-9]*::?*INSTR"
     PXI               "PXI?*INSTR"
     All instruments   "?*INSTR"
     All resources     "?*"
     */
    status = viFindRsrc (defaultRM, "?*", &findList, &numInstrs, instrDescriptor);
    if (status < VI_SUCCESS)
    {
        printf ("An error occurred while finding resources.\nHit enter to continue.");
        fflush(stdin);
        //getchar();
        viClose (defaultRM);
        return result; //status;
    }
    
    printf("%d instruments, serial ports, and other resources found.\n\n",numInstrs);
    //printf("one:%s \n",instrDescriptor);
    NSString *temp = [NSString stringWithUTF8String:&instrDescriptor[0]];
    if([temp scriptingEndsWith:@"INSTR"]) [result addObject:temp];
    
    while (--numInstrs)
    {
        /* stay in this loop until we find all instruments */
        status = viFindNext (findList, instrDescriptor);  /* find next desriptor */
        if (status < VI_SUCCESS)
        {   /* did we find the next resource? */
            printf ("An error occurred finding the next resource.\nHit enter to continue.");
            fflush(stdin);
            //getchar();
           // viClose (defaultRM);
            return result;//status;
        }
        //printf("second:%s \n",instrDescriptor);
        //[result addObject:[NSString stringWithUTF8String:&instrDescriptor[0]]];
        NSString *temp = [NSString stringWithUTF8String:&instrDescriptor[0]];
        if([temp scriptingEndsWith:@"INSTR"]) [result addObject:temp];
        /* Now we will open a session to the instrument we just found */
        status = viOpen (defaultRM, instrDescriptor, VI_NULL, VI_NULL, &instr);
        if (status < VI_SUCCESS)
        {
            printf ("An error occurred opening a session to %s\n",instrDescriptor);
        }
        else
        {
            /* Now close the session we just opened.                            */
            /* In actuality, we would probably use an attribute to determine    */
            /* if this is the instrument we are looking for.                    */
            viClose (instr);
        }
    }    /* end while */
    
    NSLog(@"result:%@",result);
    
    status = viClose(findList);
  //  status = viClose (defaultRM);
    // printf ("\nHit enter to continue.");
    fflush(stdin);
    // getchar();
    
    return result;
}
int openVISArm(void){
    /*
     * First we must call viOpenDefaultRM to get the manager
     * handle.  We will store this handle in defaultRM.
     */
    status=viOpenDefaultRM (&defaultRM);
    if (status < VI_SUCCESS)
    {
        printf ("Could not open a session to the VISA Resource Manager!\n");
        //exit (EXIT_FAILURE);
    }else{
        printf("open a session to the VISA Resource Manger successful!\n");
        VISA_OPEN = true;
    }
    return status;
}
int closeVISArm(void){
    status = viClose (defaultRM);
    if (status < VI_SUCCESS)
    {
        printf ("Could not close a session to the VISA Resource Manager!\n");
        //exit (EXIT_FAILURE);
    }else{
        printf("close a session to the VISA Resource Manger successful!\n");
        VISA_OPEN = false;
    }
    
    return status;
}
int openSerialPort(NSString *device ,int baudRate, int timeOut){
    if([device containsString:@"ASRL"] && [device containsString:@"INSTR"]){
        printf("select right device.");
    }else{
        printf("select wrong device!");
        return -1;
    }
    const char* dev = [device UTF8String];
    //status = viOpen (defaultRM, "ASRL1::INSTR", VI_NULL, VI_NULL, &instr);
    status = viOpen (defaultRM, dev, VI_NULL, VI_NULL, &instr);
    if (status < VI_SUCCESS)
    {
        printf ("Cannot open a session to the device.\n");
        printf("Closing Sessions\nHit enter to continue.");
        fflush(stdin);
        //getchar();
        status = viClose(instr);
        return -1;
    }
    
    /*
     * At this point we now have a session open to the serial instrument.
     * Now we need to configure the serial port:
     */
    
    /* Set the timeout to 5 seconds (5000 milliseconds). */
    status = viSetAttribute (instr, VI_ATTR_TMO_VALUE, timeOut); //5000);
    
    /* Set the baud rate to 4800 (default is 9600). */
    status = viSetAttribute (instr, VI_ATTR_ASRL_BAUD, baudRate);
    
    /* Set the number of data bits contained in each frame (from 5 to 8).
     * The data bits for  each frame are located in the low-order bits of
     * every byte stored in memory.
     */
    status = viSetAttribute (instr, VI_ATTR_ASRL_DATA_BITS, 8);
    
    /* Specify parity. Options:
     * VI_ASRL_PAR_NONE  - No parity bit exists,
     * VI_ASRL_PAR_ODD   - Odd parity should be used,
     * VI_ASRL_PAR_EVEN  - Even parity should be used,
     * VI_ASRL_PAR_MARK  - Parity bit exists and is always 1,
     * VI_ASRL_PAR_SPACE - Parity bit exists and is always 0.
     */
    status = viSetAttribute (instr, VI_ATTR_ASRL_PARITY, VI_ASRL_PAR_NONE);
    
    /* Specify stop bit. Options:
     * VI_ASRL_STOP_ONE   - 1 stop bit is used per frame,
     * VI_ASRL_STOP_ONE_5 - 1.5 stop bits are used per frame,
     * VI_ASRL_STOP_TWO   - 2 stop bits are used per frame.
     */
    status = viSetAttribute (instr, VI_ATTR_ASRL_STOP_BITS, VI_ASRL_STOP_ONE);
    
    /* Specify that the read operation should terminate when a termination
     * character is received.
     */
    status = viSetAttribute (instr, VI_ATTR_TERMCHAR_EN, VI_FALSE);
    
    /* Set the termination character to 0xA
     */
    status = viSetAttribute (instr, VI_ATTR_TERMCHAR, 0xA);
    return instr;
}
int closeSerialPort(int fileDescriptor){
    printf("Closing Sessions\nHit enter to continue.");
    fflush(stdin);
    //getchar();
    status = viClose(fileDescriptor);
    return status;
}
int writeRS232(int fileDescritpor,NSString *cmd){

    cmd = [cmd stringByAppendingString:@"\n"];
    const char* cmdChar = [cmd UTF8String];
    strcpy(stringinput,cmdChar);
    //strcpy (stringinput,"*IDN?\n");
    status = viWrite (fileDescritpor, (ViBuf)stringinput, (ViUInt32)strlen(stringinput), &writeCount);
    if (status < VI_SUCCESS)
    {
        printf ("Error writing to the device.\n");
        printf("Closing Sessions\nHit enter to continue.");
        fflush(stdin);
        //getchar();
        viClose(fileDescritpor);
        //goto Close;
        
    }
    return status;
}
NSString *readRS232(int fileDescritpor){
    NSString *feedback =@"";
    memset(buffer,0,sizeof(buffer)/sizeof(char));
    status = viRead (fileDescritpor, buffer, READ_BUFFER_SIZE-1, &retCount);
    //status = viBufRead (fileDescritpor, buffer, READ_BUFFER_SIZE-1, &retCount);
    if (status < VI_SUCCESS)
    {
        printf ("Error reading a response from the device.\n");
    }
    else
    {
        printf ("\nData read: %*s\n", retCount, buffer);
        NSMutableString *tmpString = [NSMutableString string];
        for (int i=0; i<sizeof(buffer); i++)
        {
            [tmpString appendFormat:@"%c", buffer[i]];
        }
        feedback = tmpString;
    }
    return feedback;
}
int openUSB(NSString *device,int timeout){
    if([device containsString:@"USB"] && [device containsString:@"INSTR"]){
        printf("select right device.");
    }else{
        printf("select wrong device!");
        return -1;
    }
    const char* dev = [device UTF8String];
    status = viOpen (defaultRM,  dev, VI_NULL, VI_NULL, &instr);
    if (status < VI_SUCCESS)
    {
        printf ("Cannot open a session to the device.\n");
        printf("Closing Sessions\nHit enter to continue.");
        fflush(stdin);
        //getchar();
        status = viClose(instr);
        return -1;
    }
    
    /*
     * Set timeout value to 5000 milliseconds (5 seconds).
     */
    status = viSetAttribute (instr, VI_ATTR_TMO_VALUE, timeout);
    return  instr;
}
int closeUSB(int fileDescriptor){
    printf("Closing Sessions\nHit enter to continue.");
    fflush(stdin);
    //getchar();
    status = viClose(fileDescriptor);
    return status;
}
int writeUSB(int fileDescritpor,NSString *cmd){
    cmd = [cmd stringByAppendingString:@"\n"];
    const char* cmdChar = [cmd UTF8String];
    strcpy(stringinput,cmdChar);
    status = viWrite (fileDescritpor, (ViBuf)stringinput, (ViUInt32)strlen(stringinput), &writeCount);
    if (status < VI_SUCCESS)
    {
        printf("Error writing to the device\n");
        printf("Closing Sessions\nHit enter to continue.");
        fflush(stdin);
        //getchar();
        viClose(fileDescritpor);
    }
    return status;
}
NSString *readUSB(int fileDescritpor){
    NSString *feedback = @"";
    memset(buffer,0,sizeof(buffer)/sizeof(char));
    status = viRead (fileDescritpor, buffer, READ_BUFFER_SIZE-1, &retCount);
    if (status < VI_SUCCESS)
    {
        printf("Error reading a response from the device\n");
    }
    else
    {
        printf("Data read: %*s\n",retCount,buffer);
        NSMutableString *hexString = [NSMutableString string];
        for (int i=0; i<sizeof(buffer); i++)
        {
            [hexString appendFormat:@"%c", buffer[i]];
        }
        feedback = hexString;
        
    }
    return feedback;
}
int openGPIB(NSString *device, int timeout){
    if([device containsString:@"GPIB"] && [device containsString:@"INSTR"]){
        printf("select right device.");
    }else{
        printf("select wrong device!");
        return -1;
    }
    const char* dev = [device UTF8String];
    status = viOpen (defaultRM, dev, VI_NULL, VI_NULL, &instr);
    status = viSetAttribute (instr, VI_ATTR_TMO_VALUE, timeout);
    return instr;
}
int closeGPIB(int fileDescriptor){
    printf("Closing Sessions\nHit enter to continue.");
    fflush(stdin);
    //getchar();
    status = viClose(fileDescriptor);
    return status;
}
int writeGPIB(int fileDescritpor,NSString *cmd){
    cmd = [cmd stringByAppendingString:@"\n"];
    const char* cmdChar = [cmd UTF8String];
    printf("Data write: %s",cmdChar);
    strcpy(stringinput,cmdChar);
    BytesToWrite = (ViUInt32)strlen(stringinput);
    status = viWrite (fileDescritpor, (ViBuf)stringinput,BytesToWrite, &retCount);
    return status;
}
NSString *readGPIB(int fileDescritpor){
    NSString *feedback = @"";
    memset(buffer,0,sizeof(buffer)/sizeof(char));
    status = viRead (fileDescritpor, buffer, READ_BUFFER_SIZE - 1, &retCount);
    if (status < VI_SUCCESS)
    {
        printf("Error reading a response from the device\n");
    }
    else
    {
        printf("Data read: %*s\n",retCount,buffer);
        NSMutableString *hexString = [NSMutableString string];
        for (int i=0; i<sizeof(buffer); i++)
        {
            [hexString appendFormat:@"%c", buffer[i]];
        }
        feedback = hexString;
        
    }
    return feedback;
}
int openDevice(NSString *device,int baudRate,int timeOut){
    if([device containsString:@"ASRL"]){
        return openSerialPort(device, baudRate,timeOut);
    }else if([device containsString:@"USB"]){
        return openUSB(device,timeOut);
    }else if([device containsString:@"GPIB"]){
        return openGPIB(device,timeOut);
    }else if([device containsString:@"TCPIP"]){
        return openGPIB(device,timeOut);
    }
    else{
        return -1;
    }
}
int closeDevice(int fileDescriptor){
    return closeGPIB(fileDescriptor);
}
int writeDevice(int fileDescriptor,NSString *cmd){
    return writeGPIB(fileDescriptor, cmd);
}
NSString *readDevice(int fileDescriptor){
    return readGPIB(fileDescriptor);
}


