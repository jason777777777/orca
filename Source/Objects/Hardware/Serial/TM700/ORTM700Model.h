//--------------------------------------------------------
// ORTM700Model
// Created by Mark  A. Howe on Mon 5/14/2012
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#pragma mark •••Imported Files
#import "ORSerialPortModel.h"
#import "ORBitProcessing.h"

@class ORSafeQueue;

@interface ORTM700Model : ORSerialPortModel <ORBitProcessing>
{
    @private
		NSString*		lastRequest;
		ORSafeQueue*	cmdQueue;
		NSMutableData*	inComingData;
		int				deviceAddress;
		int				setRotorSpeed;
		int				actualRotorSpeed;
		int				pollTime;
		int				tmpRotSet;
		float			motorCurrent;
		BOOL			driveUnitOverTemp;
		BOOL			turboPumpOverTemp;
		BOOL			speedAttained;
		BOOL			turboAccelerating;
		BOOL			motorPower;
		BOOL			stationPower;
		BOOL			runUpTimeCtrl;
		int				runUpTime;
		NSString*		errorCode;
		BOOL            delay;
}

#pragma mark •••Initialization
- (void) dealloc;

#pragma mark •••Accessors
- (NSString*) errorCode;
- (void) setErrorCode:(NSString *)aCode;
- (int) runUpTime;
- (void) setRunUpTime:(int)aRunUpTime;
- (BOOL) runUpTimeCtrl;
- (void) setRunUpTimeCtrl:(BOOL)aRunUpTimeCtrl;
- (int) tmpRotSet;
- (void) setTmpRotSet:(int)aTmpRotSet;
- (int)  pollTime;
- (void) setPollTime:(int)aPollTime;
- (BOOL) stationPower;
- (void) setStationPower:(BOOL)aStationPower;
- (BOOL) motorPower;
- (void) setMotorPower:(BOOL)aMotorPower;
- (float) motorCurrent;
- (void) setMotorCurrent:(float)aMotorCurrent;
- (int) actualRotorSpeed;
- (void) setActualRotorSpeed:(int)aActualRotorSpeed;
- (int) setRotorSpeed;
- (void) setSetRotorSpeed:(int)aSetRotorSpeed;
- (BOOL) turboAccelerating;
- (void) setTurboAccelerating:(BOOL)aTurboAccelerating;
- (BOOL) speedAttained;
- (void) setSpeedAttained:(BOOL)aSpeedAttained;
- (BOOL) turboPumpOverTemp;
- (void) setTurboPumpOverTemp:(BOOL)aTurboPumpOverTemp;
- (BOOL) driveUnitOverTemp;
- (void) setDriveUnitOverTemp:(BOOL)aDriveUnitOverTemp;
- (int) deviceAddress;
- (void) setDeviceAddress:(int)aDeviceAddress;
- (NSString*) lastRequest;
- (void) setLastRequest:(NSString*)aCmdString;
- (void) openPort:(BOOL)state;
- (NSString*) auxStatusString;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Command Methods
- (void) sendDataRequest:(int)aParamNum;
- (void) sendDataSet:(int)aParamNum bool:(BOOL)aState;
- (void) sendDataSet:(int)aParamNum integer:(unsigned int)anInt; 
- (void) sendDataSet:(int)aParamNum real:(float)aFloat; 
- (void) sendDataSet:(int)aParamNum expo:(float)aFloat; 
- (void) sendDataSet:(int)aParamNum shortInteger:(unsigned short)aShort;

#pragma mark •••Port Methods
- (void) dataReceived:(NSNotification*)note;

#pragma mark •••HW Methods
- (void) initUnit;
- (void) getDeviceAddress;
- (void) getTurboTemp;
- (void) getDriveTemp;
- (void) getSpeedAttained;
- (void) getAccelerating;
- (void) getSetSpeed;
- (void) getRunUpTime;
- (void) getActualSpeed	;
- (void) getMotorCurrent;
- (void) getStandby;
- (void) getRunUpTimeCtrl;
- (void) updateAll;
- (void) sendMotorPower:(BOOL)aState;
- (void) sendStationPower:(BOOL)aState;
- (void) sendStandby:(BOOL)aState;
- (void) sendRunUpTimeCtrl:(BOOL)aState;
- (void) sendTmpRotSet:(int)aValue;
- (void) sendRunUpTime:(int)aValue;
- (void) sendErrorAck;
- (void) turnStationOn;
- (void) turnStationOff;

#pragma mark •••Adc Processing Protocol
- (void) processIsStarting;
- (void) processIsStopping; 
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value;
- (NSString*) processingTitle;

@end

extern NSString* ORTM700ModelErrorCodeChanged;
extern NSString* ORTM700ModelRunUpTimeChanged;
extern NSString* ORTM700ModelRunUpTimeCtrlChanged;
extern NSString* ORTM700ModelTmpRotSetChanged;
extern NSString* ORTM700ModelStationPowerChanged;
extern NSString* ORTM700ModelMotorPowerChanged;
extern NSString* ORTM700TurboAcceleratingChanged;
extern NSString* ORTM700TurboSpeedAttainedChanged;
extern NSString* ORTM700TurboOverTempChanged;
extern NSString* ORTM700DriveOverTempChanged;
extern NSString* ORTM700ModelMotorCurrentChanged;
extern NSString* ORTM700ModelMotorCurrentChanged;
extern NSString* ORTM700ModelActualRotorSpeedChanged;
extern NSString* ORTM700ModelSetRotorSpeedChanged;
extern NSString* ORTM700TurboStateChanged;
extern NSString* ORTM700ModelDeviceAddressChanged;
extern NSString* ORTM700Lock;
extern NSString* ORTM700ModelPollTimeChanged;
