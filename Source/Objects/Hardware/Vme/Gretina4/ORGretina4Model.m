//-------------------------------------------------------------------------
//  ORGretina4Model.m
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORGretina4Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"
#import "ORVmeTests.h"

#define kCurrentFirmwareVersion 0x106

NSString* ORGretina4ModelDownSampleChanged			= @"ORGretina4ModelDownSampleChanged";
NSString* ORGretina4ModelRegisterIndexChanged		= @"ORGretina4ModelRegisterIndexChanged";
NSString* ORGretina4ModelRegisterWriteValueChanged	= @"ORGretina4ModelRegisterWriteValueChanged";
NSString* ORGretina4ModelSPIWriteValueChanged	    = @"ORGretina4ModelSPIWriteValueChanged";
NSString* ORGretina4ModelFpgaDownProgressChanged	= @"ORGretina4ModelFpgaDownProgressChanged";
NSString* ORGretina4ModelMainFPGADownLoadStateChanged		= @"ORGretina4ModelMainFPGADownLoadStateChanged";
NSString* ORGretina4ModelFpgaFilePathChanged				= @"ORGretina4ModelFpgaFilePathChanged";
NSString* ORGretina4ModelNoiseFloorIntegrationTimeChanged	= @"ORGretina4ModelNoiseFloorIntegrationTimeChanged";
NSString* ORGretina4ModelNoiseFloorOffsetChanged	= @"ORGretina4ModelNoiseFloorOffsetChanged";
NSString* ORGretina4CardInfoUpdated					= @"ORGretina4CardInfoUpdated";
NSString* ORGretina4RateGroupChangedNotification	= @"ORGretina4RateGroupChangedNotification";

NSString* ORGretina4NoiseFloorChanged			= @"ORGretina4NoiseFloorChanged";
NSString* ORGretina4ModelFIFOCheckChanged		= @"ORGretina4ModelFIFOCheckChanged";

NSString* ORGretina4ModelEnabledChanged			= @"ORGretina4ModelEnabledChanged";
NSString* ORGretina4ModelCFDEnabledChanged		= @"ORGretina4ModelCFDEnabledChanged";
NSString* ORGretina4ModelPoleZeroEnabledChanged	= @"ORGretina4ModelPoleZeroEnabledChanged";
NSString* ORGretina4ModelPoleZeroMultChanged	= @"ORGretina4ModelPoleZeroMultChanged";
NSString* ORGretina4ModelPZTraceEnabledChanged= @"ORGretina4ModelPZTraceEnabledChanged";
NSString* ORGretina4ModelDebugChanged			= @"ORGretina4ModelDebugChanged";
NSString* ORGretina4ModelPileUpChanged			= @"ORGretina4ModelPileUpChanged";
NSString* ORGretina4ModelPolarityChanged		= @"ORGretina4ModelPolarityChanged";
NSString* ORGretina4ModelTriggerModeChanged		= @"ORGretina4ModelTriggerModeChanged";
NSString* ORGretina4ModelLEDThresholdChanged	= @"ORGretina4ModelLEDThresholdChanged";
NSString* ORGretina4ModelCFDDelayChanged		= @"ORGretina4ModelCFDDelayChanged";
NSString* ORGretina4ModelCFDFractionChanged		= @"ORGretina4ModelCFDFractionChanged";
NSString* ORGretina4ModelCFDThresholdChanged	= @"ORGretina4ModelCFDThresholdChanged";
NSString* ORGretina4ModelDataDelayChanged		= @"ORGretina4ModelDataDelayChanged";
NSString* ORGretina4ModelDataLengthChanged		= @"ORGretina4ModelDataLengthChanged";
NSString* ORGretina4ModelMainFPGADownLoadInProgressChanged		= @"ORGretina4ModelMainFPGADownLoadInProgressChanged";
NSString* ORGretina4CardInited					= @"ORGretina4CardInited";
NSString* ORGretina4SettingsLock				= @"ORGretina4SettingsLock";
NSString* ORGretina4RegisterLock				= @"ORGretina4RegisterLock";
NSString* ORGretina4ModelSetEnableStatusChanged				= @"ORGretina4ModelSetEnableStatusChanged";

@interface ORGretina4Model (private)
- (void) programFlashBuffer:(NSData*)theData;
- (void) resetFlashStatus;
- (void) enableFlashEraseAndProg;
- (void) disableFlashEraseAndProg;
- (void) testFlashStatusRegisterWithNoFlashCmd;
- (void) testFlashStatusRegisterWithFlashCmd;
- (void) blockEraseFlashAtBlock:(unsigned long)blockNumber;
- (void) programFlashBufferAtAddress:(const void*)theData 
						startAddress:(unsigned long)anAddress 
				numberOfBytesToWrite:(unsigned long)aNumber;
- (void) blockEraseFlash;					   
- (void) programFlashBuffer:(NSData*)theData;
- (BOOL) verifyFlashBuffer:(NSData*)theData;
- (void) reloadMainFPGAFromFlash;
- (void) setProgressStateOnMainThread:(NSString*)aState;
- (void) updateDownLoadProgress;
- (void) downloadingMainFPGADone;
- (void) fpgaDownLoadThread:(NSData*)dataFromFile;
@end


@implementation ORGretina4Model
#pragma mark ���Static Declarations
//offsets from the base address
typedef struct {
	unsigned long offset;
	NSString* name;
	BOOL canRead;
	BOOL canWrite;
	BOOL hasChannels;
	BOOL displayOnMainGretinaPage;
} Gretina4RegisterInformation;
	
static Gretina4RegisterInformation register_information[kNumberOfGretina4Registers] = {
{0x00,  @"Board ID", YES, NO, NO, NO},                         
{0x04,  @"Programming done", YES, YES, NO, NO},                
{0x08,  @"External Window",  YES, YES, NO, YES},               
{0x0C,  @"Pileup Window", YES, YES, NO, YES},                  
{0x10,  @"Noise Window", YES,YES, NO, YES},                    
{0x14,  @"External trigger sliding length", YES, YES, NO, YES},
{0x18,  @"Collection time", YES, YES, NO, YES},                
{0x1C,  @"Integration time", YES, YES, NO, YES},               
{0x20,  @"Hardware Status", YES, YES, NO, NO},  
{0x24,	@"Data Package user defined data", YES,	YES, NO, NO}, //new for version 102b
{0x28,	@"Collection time low resolution", YES, YES, NO, NO}, //new for version 102b
{0x2C,	@"Integration time low resolution", YES, YES, NO, NO}, //new for version 102b
{0x30,	@"External FIFO monitor", YES, NO, NO, NO}, //new for version 102b
{0x40,  @"Control/Status", YES, YES, YES, YES},                
{0x80,  @"LED Threshold", YES, YES, YES, YES},                 
{0xC0,  @"CFD Parameters", YES, YES, YES, YES},                
{0x100, @"Raw data sliding length", YES, YES, YES, YES},       
{0x140, @"Raw data window length", YES, YES, YES, YES},        
{0x400, @"DAC", YES, YES, NO, NO},                             
{0x480, @"Slave Front bus status", YES, YES, NO, NO},          
{0x484, @"Channel Zero time stamp LSB", YES, YES, NO, NO},     
{0x488, @"Channel Zero time stamp MSB",  YES, YES, NO, NO}, 
{0x48C,	@"Central contact time stamp LSB", YES, YES, NO, NO}, //new for version 102b
{0x490,	@"Central contact time stamp MSB", YES, YES, NO, NO}, //new for version 102b
{0x494, @"Slave Sync counter", YES, YES, NO, NO}, //new for version 102b
{0x498, @"Slave Imperative sync counter", YES, YES, NO, NO}, //new for version 102b
{0x49C, @"Slave Latch status counter", YES, YES, NO, NO}, //new for version 102b
{0x4A0, @"Slave Header memory validate counter", YES, YES, NO, NO}, //new for version 102b
{0x4A4,	@"Slave Header memory read slow data counter", YES, YES, NO, NO}, //new for version 102b
{0x4A8, @"Slave Front end reset and calibration inject counters", YES, YES, NO, NO}, //new for version 102b
{0x4AC, @"Slave Front Bus Send Box 10 - 1", YES, YES, NO, NO}, //modifed address for version 102b Q: why hasChannels == NO?
{0x4D4, @"Slave Front bus register 0 - 10", YES, YES, NO, NO}, //Q: why hasChannels == NO?
{0x500, @"Master Logic Status", YES, YES, NO, NO},             
{0x504, @"SlowData CCLED timers", YES, YES, NO, NO},           
{0x508, @"DeltaT155_DeltaT255 (3)", YES, YES, NO, NO},         
{0x514, @"SnapShot ", YES, YES, NO, NO},                       
{0x518, @"XTAL ID ", YES, YES, NO, NO},                        
{0x51C, @"Length of Time to get Hit Pattern", YES, YES, NO, NO},
{0x520, @"Front Side Bus Register", YES, YES, NO, NO},  //This is a debug register
{0x524, @"Test digitizer Tx TTCL", YES, YES, NO, NO}, //new for version 102b
{0x528, @"Test digitizer Rx TTCL", YES, YES, NO, NO}, //new for version 102b
{0x52C, @"Slave Front Bus send box 10-1", YES, YES, NO, NO}, //new for version 102b
{0x554, @"FrontBus Registers 0-10", YES, YES, NO, NO}, //modifed address for version 102b     
{0x580, @"Master logic sync counter", YES, YES, NO, NO}, //new for version 102b
{0x584, @"Master logic imperative sync counter", YES, YES, NO, NO}, //new for version 102b
{0x588, @"Master logic latch status counter", YES, YES, NO, NO}, //new for version 102b
{0x58C, @"Master logic header memory validate counter", YES, YES, NO, NO}, //new for version 102b
{0x590,	@"Master logic header memory read slow data counter", YES, YES, NO, NO}, //new for version 102b
{0x594, @"Master logic front end reset and calibration inject counters", YES, YES, NO, NO}, //new for version 102b
{0x598, @"Master front bus sync counter", YES, YES, NO, NO}, //new for version 102b
{0x59C, @"Master front bus imperative sync counter", YES, YES, NO, NO}, //new for version 102b
{0x5A0, @"Master front bus latch status counter", YES, YES, NO, NO}, //new for version 102b
{0x5A4, @"Master front bus header memory validate counter", YES, YES, NO, NO}, //new for version 102b
{0x5A8,	@"Master front bus header memory read slow data counter", YES, YES, NO, NO}, //new for version 102b
{0x5AC, @"Master front bus front end reset and calibration inject counters", YES, YES, NO, NO}, //new for version 102b
{0x5B0, @"Serdes data package error", YES, YES, NO, NO}, //new for version 102b
{0x5B4, @"CC_LED enable", YES, YES, NO, NO}, //new for version 102b
{0x780, @"Debug data buffer address", YES, YES, NO, NO},       
{0x784, @"Debug data buffer data", YES, YES, NO, NO},          
{0x788, @"LED flag window", YES, YES, NO, NO},                 
{0x800, @"Aux io read", YES, YES, NO, NO},                     
{0x804, @"Aux io write", YES, YES, NO, NO},                    
{0x808, @"Aux io config", YES, YES, NO, NO},                   
{0x820, @"FB_Read", YES, YES, NO, NO},                         
{0x824, @"FB_Write", YES, YES, NO, NO},                        
{0x828, @"FB_Config", YES, YES, NO, NO},                       
{0x840, @"SD_Read", YES, YES, NO, NO},                         
{0x844, @"SD_Write", YES, YES, NO, NO},                        
{0x848, @"SD_Config", YES, YES, NO, NO},                       
{0x84C, @"Adc config", YES, YES, NO, NO},                      
{0x860, @"self trigger enable", YES, YES, NO, NO},             
{0x864, @"self trigger period", YES, YES, NO, NO},             
{0x868, @"self trigger count", YES, YES, NO, NO}, 
{0x870, @"FIFOInterfaceSMReg", YES, YES, NO, NO}, 
{0x874, @"Test signals register", YES, YES, NO, NO},
{0x1C0, @"Trapezoidal trigger settings", NO, YES, YES, YES}
};
                                      
static Gretina4RegisterInformation fpga_register_information[kNumberOfFPGARegisters] = {
{0x900,	@"Main Digitizer FPGA configuration register", YES, YES, NO, NO},  
{0x904,	@"Main Digitizer FPGA status register", YES, NO, NO, NO},          
{0x908,	@"Voltage and Temperature Status", YES, NO, NO, NO},               
{0x910,	@"General Purpose VME Control Settings", YES, YES, NO, NO},        
{0x914,	@"VME Timeout Value Register", YES, YES, NO, NO},                  
{0x920,	@"VME Version/Status", YES, NO, NO, NO},                           
{0x930,	@"VME FPGA Sandbox Register Block", YES, YES, NO, NO},             
{0x980,	@"Flash Address", YES, YES, NO, NO},                               
{0x984,	@"Flash Data with Auto-increment address", YES, YES, NO, NO},      
{0x988,	@"Flash Data", YES, YES, NO, NO},                                  
{0x98C,	@"Flash Command Register", YES, YES, NO, NO}                       
                                                                                       
};                                                        

enum {
    kExternalWindowIndex,
    kPileUpWindowIndex,
    kNoiseWindowIndex,
    kExtTrigLengthIndex,
    kCollectionTimeIndex,
    kIntegrationTimeIndex
};

static struct {
    NSString*	name;
    NSString*	units;
    unsigned long	regOffset;
    unsigned short	mask; 
    unsigned short	initialValue;
    float		ratio; //conversion constants
} cardConstants[kNumGretina4CardParams] = {
{@"External Window",	@"us",	0x08,	0x7FF,	0x190, 4./(float)0x190},
{@"Pileup Window",		@"us",	0x0C,	0x7FF,	0x0400,	10./(float)0x400},
{@"Noise Window",		@"ns",	0x10,	0x07F,	0x0040,	640./(float)0x40},
{@"Ext Trigger Length", @"us",	0x14,	0x7FF,	0x0190,	4.0/(float)0x190},
{@"Collection Time",	@"us",	0x18,	0x01FF,	0x01C2,	4.5/(float)0x1C2},
{@"Integration Time",	@"us",	0x1C,	0x03FF,	0x01C2,	4.5/(float)0x1C2},
};


#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self initParams];
    [self setAddressModifier:0x09];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
    [spiConnector release];
    [mainFPGADownLoadState release];
    [fpgaFilePath release];
    [waveFormRateGroup release];
    [cardInfo release];
	[fifoFullAlarm clearAlarm];
	[fifoFullAlarm release];
	[progressLock release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Gretina4Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORGretina4Controller"];
}

- (NSString*) helpURL
{
	return @"VME/Gretina.html";
}

- (Class) guardianClass
{
	return NSClassFromString(@"ORVme64CrateModel");
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,baseAddress+0x1000+0xffff);
}

- (void) makeConnectors
{
    //make and cache our connector. However this connector will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    [self setSpiConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    
	[spiConnector setConnectorImageType:kSmallDot]; 
	[spiConnector setConnectorType: 'SPIO' ];
	[spiConnector addRestrictedConnectionType: 'SPII' ]; //can only connect to SPI inputs
	[spiConnector setOffColor:[NSColor colorWithCalibratedRed:0 green:.68 blue:.65 alpha:1.]];
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    [self guardian:guardian positionConnectorsForCard:self];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORVmeCardSlotChangedNotification
	 object: self];
}

- (void) positionConnector:(ORConnector*)aConnector
{
    NSRect aFrame = [aConnector localFrame];
    float x =  17 + [self slot] * 16*.62 ;
    float y =  75;
    aFrame.origin = NSMakePoint(x,y);
    [aConnector setLocalFrame:aFrame];
}


- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
	
	[super setGuardian:aGuardian];
	
    if(oldGuardian != aGuardian){
        [oldGuardian removeDisplayOf:spiConnector];
    }
	
    [aGuardian assumeDisplayOf:spiConnector];
    [self guardian:aGuardian positionConnectorsForCard:self];
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    [aGuardian positionConnector:spiConnector forCard:self];
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian removeDisplayOf:spiConnector];
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian assumeDisplayOf:spiConnector];
}

#pragma mark ***Accessors
- (ORConnector*) spiConnector
{
    return spiConnector;
}

- (void) setSpiConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [spiConnector release];
    spiConnector = aConnector;
}

- (int) downSample
{
    return downSample;
}

- (void) setDownSample:(int)aDownSample
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDownSample:downSample];
    
    downSample = aDownSample;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelDownSampleChanged object:self];
}

- (int) registerIndex
{
    return registerIndex;
}

- (void) setRegisterIndex:(int)aRegisterIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterIndex:registerIndex];
    registerIndex = aRegisterIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelRegisterIndexChanged object:self];
}

- (unsigned long) registerWriteValue
{
    return registerWriteValue;
}

- (void) setRegisterWriteValue:(unsigned long)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterWriteValue:registerWriteValue];
    registerWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelRegisterWriteValueChanged object:self];
}

- (unsigned long) spiWriteValue
{
    return spiWriteValue;
}


- (void) setSPIWriteValue:(unsigned long)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterWriteValue:spiWriteValue];
    spiWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelSPIWriteValueChanged object:self];
}

- (NSString*) registerNameAt:(unsigned int)index
{
	if (index >= kNumberOfGretina4Registers) return @"";
	return register_information[index].name;
}

- (NSString*) fpgaRegisterNameAt:(unsigned int)index
{
	if (index >= kNumberOfFPGARegisters) return @"";
	return fpga_register_information[index].name;
}

- (unsigned long) readRegister:(unsigned int)index
{
	if (index >= kNumberOfGretina4Registers) return -1;
	if (![self canReadRegister:index]) return -1;
	unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[index].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue;
}

- (void) writeRegister:(unsigned int)index withValue:(unsigned long)value
{
	if (index >= kNumberOfGretina4Registers) return;
	if (![self canWriteRegister:index]) return;
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + register_information[index].offset
                         numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];	
}

- (BOOL) canReadRegister:(unsigned int)index
{
	if (index >= kNumberOfGretina4Registers) return NO;
	return register_information[index].canRead;
}

- (BOOL) canWriteRegister:(unsigned int)index
{
	if (index >= kNumberOfGretina4Registers) return NO;
	return register_information[index].canWrite;
}

- (BOOL) displayRegisterOnMainPage:(unsigned int)index
{
	if (index >= kNumberOfGretina4Registers) return NO;
	return register_information[index].displayOnMainGretinaPage;
}

- (unsigned long) readFPGARegister:(unsigned int)index;
{
	if (index >= kNumberOfFPGARegisters) return -1;
	if (![self canReadFPGARegister:index]) return -1;
	unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + fpga_register_information[index].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue;
}

- (void) writeFPGARegister:(unsigned int)index withValue:(unsigned long)value
{
	if (index >= kNumberOfFPGARegisters) return;
	if (![self canWriteFPGARegister:index]) return;
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + fpga_register_information[index].offset
                         numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];	
}

- (BOOL) canReadFPGARegister:(unsigned int)index
{
	if (index >= kNumberOfFPGARegisters) return NO;
	return fpga_register_information[index].canRead;
}

- (BOOL) canWriteFPGARegister:(unsigned int)index
{
	if (index >= kNumberOfFPGARegisters) return NO;
	return fpga_register_information[index].canWrite;
}

- (BOOL) displayFPGARegisterOnMainPage:(unsigned int)index
{
	if (index >= kNumberOfFPGARegisters) return NO;
	return fpga_register_information[index].displayOnMainGretinaPage;
}

- (BOOL) downLoadMainFPGAInProgress
{
	return downLoadMainFPGAInProgress;
}

- (void) setDownLoadMainFPGAInProgress:(BOOL)aState
{
	downLoadMainFPGAInProgress = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelMainFPGADownLoadInProgressChanged object:self];	
}

- (int) fpgaDownProgress
{
	int temp;
	[progressLock lock];
    temp = fpgaDownProgress;
	[progressLock unlock];
    return temp;
}

- (NSString*) mainFPGADownLoadState
{
	if(!mainFPGADownLoadState) return @"--";
    else return mainFPGADownLoadState;
}

- (void) setMainFPGADownLoadState:(NSString*)aMainFPGADownLoadState
{
	if(!aMainFPGADownLoadState) aMainFPGADownLoadState = @"--";
    [mainFPGADownLoadState autorelease];
    mainFPGADownLoadState = [aMainFPGADownLoadState copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelMainFPGADownLoadStateChanged object:self];
}

- (NSString*) fpgaFilePath
{
    return fpgaFilePath;
}

- (void) setFpgaFilePath:(NSString*)aFpgaFilePath
{
	if(!aFpgaFilePath)aFpgaFilePath = @"";
    [fpgaFilePath autorelease];
    fpgaFilePath = [aFpgaFilePath copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelFpgaFilePathChanged object:self];
}

- (float) noiseFloorIntegrationTime
{
    return noiseFloorIntegrationTime;
}

- (void) setNoiseFloorIntegrationTime:(float)aNoiseFloorIntegrationTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNoiseFloorIntegrationTime:noiseFloorIntegrationTime];
	
    if(aNoiseFloorIntegrationTime<.01)aNoiseFloorIntegrationTime = .01;
	else if(aNoiseFloorIntegrationTime>5)aNoiseFloorIntegrationTime = 5;
	
    noiseFloorIntegrationTime = aNoiseFloorIntegrationTime;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelNoiseFloorIntegrationTimeChanged object:self];
}

- (int) fifoState
{
    return fifoState;
}

- (void) setFifoState:(int)aFifoState
{
    fifoState = aFifoState;
}

- (int) noiseFloorOffset
{
    return noiseFloorOffset;
}

- (void) setNoiseFloorOffset:(int)aNoiseFloorOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNoiseFloorOffset:noiseFloorOffset];
    
    noiseFloorOffset = aNoiseFloorOffset;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelNoiseFloorOffsetChanged object:self];
}

- (ORRateGroup*) waveFormRateGroup
{
    return waveFormRateGroup;
}
- (void) setWaveFormRateGroup:(ORRateGroup*)newRateGroup
{
    [newRateGroup retain];
    [waveFormRateGroup release];
    waveFormRateGroup = newRateGroup;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORGretina4RateGroupChangedNotification
	 object:self];    
}

- (BOOL) noiseFloorRunning
{
	return noiseFloorRunning;
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (void) initParams
{
	
	int i;
	for(i=0;i<kNumGretina4Channels;i++){
		enabled[i]			= YES;
		debug[i]			= NO;
		pileUp[i]			= NO;
        cfdEnabled[i]		= NO;
		poleZeroEnabled[i]	= NO;
		poleZeroMult[i]	    = 0x600;
		pzTraceEnabled[i]	= NO;
		polarity[i]			= 0x3;
		triggerMode[i]		= 0x0;
		ledThreshold[i]		= 0x1FFFF;
		cfdDelay[i]			= 0x3f;
		cfdFraction[i]		= 0x0;
		cfdThreshold[i]		= 0x10;
		dataDelay[i]		= 0x1C2;
		dataLength[i]		= 0x3FF;
	}
	
    if(!cardInfo){
        cardInfo = [[NSMutableArray array] retain];
        int i;
        for(i=0;i<kNumGretina4CardParams;i++){
            [cardInfo addObject:[NSNumber numberWithInt:cardConstants[i].initialValue]];
        }
    }	
    fifoLostEvents = 0;
	isFlashWriteEnabled = NO;
}

- (void) cardInfo:(int)index setObject:(id)aValue
{	
    [[[self undoManager] prepareWithInvocationTarget:self] cardInfo:index setObject:[self cardInfo:index]];
    [cardInfo replaceObjectAtIndex:index withObject:aValue];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4CardInfoUpdated object:self];
}

- (id) rawCardValue:(int)index value:(id)aValue 
{	
    float theValue = [aValue floatValue];
	if (theValue < 0) theValue = 0;
    unsigned short theRawValue = theValue / cardConstants[index].ratio;
	if (theRawValue > cardConstants[index].mask) theRawValue = cardConstants[index].mask;
    return [NSNumber numberWithInt: theRawValue & cardConstants[index].mask];
}

- (id) convertedCardValue:(int)index
{	
    int theValue  = [[cardInfo objectAtIndex:index] intValue];
    float theConvertedValue = theValue * cardConstants[index].ratio;
    return [NSNumber numberWithFloat: theConvertedValue];
}


- (id) cardInfo:(int)index
{
    return [cardInfo objectAtIndex:index];
}


- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

#pragma mark ���Rates
- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumGretina4Channels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}
#pragma mark ���specific accessors
- (void) setExternalWindow:(int)aValue { [self cardInfo:kExternalWindowIndex  setObject:[NSNumber numberWithInt:aValue]]; }
- (void) setPileUpWindow:(int)aValue   { [self cardInfo:kPileUpWindowIndex    setObject:[NSNumber numberWithInt:aValue]]; }
- (void) setNoiseWindow:(int)aValue    { [self cardInfo:kNoiseWindowIndex     setObject:[NSNumber numberWithInt:aValue]]; }
- (void) setExtTrigLength:(int)aValue  { [self cardInfo:kExtTrigLengthIndex   setObject:[NSNumber numberWithInt:aValue]]; }
- (void) setCollectionTime:(int)aValue { [self cardInfo:kCollectionTimeIndex  setObject:[NSNumber numberWithInt:aValue]]; }
- (void) setIntegrationTime:(int)aValue { [self cardInfo:kIntegrationTimeIndex setObject:[NSNumber numberWithInt:aValue]]; }

- (int) externalWindowAsInt		{ return [[self cardInfo:kExternalWindowIndex] intValue]; }
- (int) pileUpWindowAsInt		{ return [[self cardInfo:kPileUpWindowIndex] intValue]; }
- (int) noiseWindowAsInt		{ return [[self cardInfo:kNoiseWindowIndex] intValue]; }
- (int) extTrigLengthAsInt		{ return [[self cardInfo:kExtTrigLengthIndex] intValue]; }
- (int) collectionTimeAsInt		{ return [[self cardInfo:kCollectionTimeIndex] intValue]; }
- (int) integrationTimeAsInt	{ return [[self cardInfo:kIntegrationTimeIndex] intValue]; }

- (void) setEnabled:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:chan withValue:enabled[chan]];
	enabled[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelEnabledChanged object:self];
}

- (void) setCFDEnabled:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setCFDEnabled:chan withValue:cfdEnabled[chan]];
	cfdEnabled[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelCFDEnabledChanged object:self];
}

- (void) setPoleZeroEnabled:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setPoleZeroEnabled:chan withValue:poleZeroEnabled[chan]];
	poleZeroEnabled[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelPoleZeroEnabledChanged object:self];
}

- (void) setPoleZeroMultiplier:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setPoleZeroMultiplier:chan withValue:poleZeroMult[chan]];
	poleZeroMult[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelPoleZeroMultChanged object:self];
}

- (void) setPZTraceEnabled:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setPZTraceEnabled:chan withValue:pzTraceEnabled[chan]];
	pzTraceEnabled[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelPZTraceEnabledChanged object:self];
}

- (void) setDebug:(short)chan withValue:(short)aValue	
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setDebug:chan withValue:debug[chan]];
	debug[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelDebugChanged object:self];
}

- (void) setPileUp:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setPileUp:chan withValue:pileUp[chan]];
	pileUp[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelPileUpChanged object:self];
}

- (void) setPolarity:(short)chan withValue:(int)aValue		
{
	if(aValue<0)aValue=0;
	else if(aValue>0x3)aValue= 0x3;
    [[[self undoManager] prepareWithInvocationTarget:self] setPolarity:chan withValue:polarity[chan]];
	polarity[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelPolarityChanged object:self];
}

- (void) setTriggerMode:(short)chan withValue:(int)aValue	
{ 
	if(aValue<0) aValue=0;
	else if(aValue>kTrapezoidalTriggerMode) aValue = kTrapezoidalTriggerMode;
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerMode:chan withValue:triggerMode[chan]];
	triggerMode[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelTriggerModeChanged object:self];
}

- (void) setLEDThreshold:(short)chan withValue:(int)aValue 
{ 
	if(aValue<0) aValue=0;
	if(triggerMode[chan] == kTrapezoidalTriggerMode) {
      if(aValue>0xFFFFFF) aValue = 0xFFFFFF;
    }
	else {
      if(aValue>0x1FFFF) aValue = 0x1FFFF;
    }
    [[[self undoManager] prepareWithInvocationTarget:self] setLEDThreshold:chan withValue:ledThreshold[chan]];
	ledThreshold[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelLEDThresholdChanged object:self];
}

- (void) setCFDDelay:(short)chan withValue:(int)aValue		
{
	if(aValue<0)aValue=0;
	else if(aValue>0x3F)aValue = 0x3F;
    [[[self undoManager] prepareWithInvocationTarget:self] setCFDDelay:chan withValue:cfdDelay[chan]];
	cfdDelay[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelCFDDelayChanged object:self];
}

- (void) setCFDFraction:(short)chan withValue:(int)aValue	
{ 
	if(aValue<0)aValue=0;
	else if(aValue>0x11)aValue = 0x11;
    [[[self undoManager] prepareWithInvocationTarget:self] setCFDFraction:chan withValue:cfdFraction[chan]];
	cfdFraction[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelCFDFractionChanged object:self];
}

- (void) setCFDThreshold:(short)chan withValue:(int)aValue  
{
	if(aValue<0)aValue=0;
	else if(aValue>0x1F)aValue = 0x1F;
    [[[self undoManager] prepareWithInvocationTarget:self] setCFDThreshold:chan withValue:cfdThreshold[chan]];
	cfdThreshold[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelCFDThresholdChanged object:self];
}

- (void) setDataDelay:(short)chan withValue:(int)aValue     
{
	if(aValue<0)aValue=0;
	else if(aValue>0x7FF)aValue = 0x7FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDataDelay:chan withValue:dataDelay[chan]];
	dataDelay[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelDataDelayChanged object:self];
}

- (void) setTraceLength:(short)chan withValue:(int)aValue
{
	[self setDataLength:chan withValue:(aValue+kGretina4HeaderLengthLongs*2)];
}

- (void) setDataLength:(short)chan withValue:(int)aValue    
{
	// The data length refers to the total length in the buffer, *NOT* the 
	// length of the trace.  That is, it includes the length of the header
	// so it can never be shorter than the header (*2 for words).
	
	if(aValue<kGretina4HeaderLengthLongs*2)aValue=kGretina4HeaderLengthLongs*2;
	else if(aValue>0x3FF)aValue = 0x3FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDataLength:chan withValue:dataLength[chan]];
	dataLength[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelDataLengthChanged object:self];
}

- (int) enabled:(short)chan			{ return enabled[chan]; }
- (int) cfdEnabled:(short)chan		{ return cfdEnabled[chan]; }
- (int) poleZeroEnabled:(short)chan	{ return poleZeroEnabled[chan]; }
- (int) poleZeroMult:(short)chan	{ return poleZeroMult[chan]; }
- (int) pzTraceEnabled:(short)chan  { return pzTraceEnabled[chan]; }
- (int) debug:(short)chan			{ return debug[chan]; }
- (int) pileUp:(short)chan			{ return pileUp[chan];}
- (int) polarity:(short)chan		{ return polarity[chan];}
- (int) triggerMode:(short)chan		{ return triggerMode[chan];}
- (int) ledThreshold:(short)chan	{ return ledThreshold[chan]; }
- (int) cfdDelay:(short)chan		{ return cfdDelay[chan]; }
- (int) cfdFraction:(short)chan		{ return cfdFraction[chan]; }
- (int) cfdThreshold:(short)chan	{ return cfdThreshold[chan]; }
- (int) dataDelay:(short)chan		{ return dataDelay[chan]; }
- (int) dataLength:(short)chan		{ return dataLength[chan]; }
- (int) traceLength:(short)chan		{ return dataLength[chan]-2*kGretina4HeaderLengthLongs; }


- (float) poleZeroTauConverted:(short)chan  { return poleZeroMult[chan]>0 ? 0.01*pow(2., 23)/poleZeroMult[chan] : 0; } //convert to us
- (float) cfdDelayConverted:(short)chan		{ return cfdDelay[chan]*630./(float)0x3F; }						//convert to ns
- (float) cfdThresholdConverted:(short)chan	{ return cfdThreshold[chan]*160./(float)0x10; }					//convert to kev
- (float) dataDelayConverted:(short)chan	{ return dataDelay[chan]*4.5/(float)0x01C2; }					//convert to ¬µs
- (float) traceLengthConverted:(short)chan	{ return (dataLength[chan]-2*kGretina4HeaderLengthLongs)*10.0; }//convert to ns, making sure to remove header length

- (void) setPoleZeroTauConverted:(short)chan withValue:(float)aValue 
{
    if(aValue > 0) aValue = 0.01*pow(2., 23)/aValue;
	[self setPoleZeroMultiplier:chan withValue:aValue]; 	//us -> raw
}

- (void) setCFDDelayConverted:(short)chan withValue:(float)aValue
{
	[self setCFDDelay:chan withValue:aValue*0x3F/630.];		//ns -> raw
}

- (void) setCFDThresholdConverted:(short)chan withValue:(float)aValue
{
	[self setCFDThreshold:chan withValue:aValue*0x10/160.];		//kev -> raw
}

- (void) setDataDelayConverted:(short)chan withValue:(float)aValue;
{
	[self setDataDelay:chan withValue:aValue*0x01C2/4.5];		//¬µs -> raw
} 

- (void) setTraceLengthConverted:(short)chan withValue:(float)aValue
{
	[self setDataLength:chan withValue:(aValue/10.0 + 2*kGretina4HeaderLengthLongs)];		//ns -> raw
}  

#pragma mark ���Hardware Access
- (unsigned long) baseAddress
{
	return (([self slot]+1)&0x1f)<<20;
}

- (short) readBoardID
{
    unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kBoardID].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue & 0xfff;
}

- (void) resetDCM
{
    //Start Slave clock
	//turn off SerDes driver
	unsigned long theValue = 0x11;
	[[self adapter] writeLongBlock:&theValue
						 atAddress:[self baseAddress] + register_information[kSDConfig].offset
                        numToWrite:1
                        withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	//reset DCM clock while keeping SerDes driver off
	// To reset the DCM, assert bit 9 of this register. 
	theValue = 0x211;
	[[self adapter] writeLongBlock:&theValue
						 atAddress:[self baseAddress] + register_information[kSDConfig].offset
                        numToWrite:1
                        withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	sleep(1); //wait for 1 second:
	
	theValue = 0x11;
	[[self adapter] writeLongBlock:&theValue
						 atAddress:[self baseAddress] + register_information[kSDConfig].offset
                        numToWrite:1
                        withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) resetBoard
{
    /* First disable all channels. This does not affect the model state,
	 just the board state. */
    int i;
    for(i=0;i<kNumGretina4Channels;i++){
        [self writeControlReg:i enabled:NO];
    }
	
    /* Then reset the DCM clock. (This will also reset the serdes.) */
    //[self resetDCM];  change by Jing: DCM is reset in initSerDes;
    
    /* Finally, initialize the serdes. */
    [self initSerDes];
}

/*
- (void) initSerDes
{
    unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kHardwareStatus].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
    if ((theValue & 0x7) == 0x7) return;
    theValue = 0x22;
    // First we set to loop back mode so the SD can lock. 
    [[self adapter] writeLongBlock:&theValue
						 atAddress:[self baseAddress] + register_information[kSDConfig].offset
                        numToWrite:1
                        withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
    NSDate* startDate = [NSDate date];
    while(1) {
        // Wait for the SD and DCM to lock 
        [[self adapter] readLongBlock:&theValue
                            atAddress:[self baseAddress] + register_information[kHardwareStatus].offset
                            numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		
        if ((theValue & 0x7) == 0x7) break;
		if([[NSDate date] timeIntervalSinceDate:startDate] > 2) {
			NSLog(@"Initializing SERDES timed out (slot %d). \n",[self slot]);
			return;
		}
    }
    theValue = 0x02;
    [[self adapter] writeLongBlock:&theValue
						 atAddress:[self baseAddress] + register_information[kSDConfig].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];    
}
*/

//new code version 1 (Jing Qian)
- (void) setClockSource: (unsigned long) clocksource
{
	//clock select.  0 = SerDes, 1 = ref, 2 = SerDes, 3 = Ext
	unsigned long theValue = clocksource;
    [[self adapter] writeLongBlock:&theValue
						 atAddress:[self baseAddress] + fpga_register_information[kVMEGPControl].offset
                        numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) resetMainFPGA
{
	unsigned long theValue = 0x10;
	[[self adapter] writeLongBlock:&theValue
						 atAddress:[self baseAddress] + fpga_register_information[kMainFPGAControl].offset
                        numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	sleep(1);
	
	/*
	NSDate* startDate = [NSDate date];
    while(1) {
        // Wait for the SD and DCM to lock 
        [[self adapter] readLongBlock:&theValue
                            atAddress:[self baseAddress] + register_information[kHardwareStatus].offset
                            numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		
        if ((theValue & 0x7) == 0x7) break;
		if([[NSDate date] timeIntervalSinceDate:startDate] > 1) {
			NSLog(@"Initializing SERDES timed out (slot %d). \n",[self slot]);
			return;
		}
    }
	*/
	
	theValue = 0x00;
	[[self adapter] writeLongBlock:&theValue
						 atAddress:[self baseAddress] + fpga_register_information[kMainFPGAControl].offset
                        numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) initSerDes
{
	//first set clock source
	//I can't find the variable for clock source, so I set it 0 temporarily
	//clock select.  0 = SerDes, 1 = ref, 2 = SerDes, 3 = Ext
	[self setClockSource:0x01];
	
	//main FPGA reset cycle
	[self resetMainFPGA];
	
	//wait for 10 seconds
	sleep(10);
	
	/*
	unsigned long theValue = 0;
	NSDate* startDate = [NSDate date];
    while(1) {
        // Wait for the SD and DCM to lock 
        [[self adapter] readLongBlock:&theValue
                            atAddress:[self baseAddress] + register_information[kHardwareStatus].offset
                            numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		
        if ((theValue & 0x7) == 0x7) break;
		if([[NSDate date] timeIntervalSinceDate:startDate] > 10) {
			NSLog(@"Initializing SERDES timed out (slot %d). \n",[self slot]);
			return;
		}
    }
	*/
	 
	//reset DCM
	[self resetDCM];
	
}

- (void) initBoard:(BOOL)doEnableChannels
{
	//find out the Main FPGA version
	unsigned long mainVersion = 0x00;
	[[self adapter] readLongBlock:&mainVersion
						atAddress:[self baseAddress] + register_information[kBoardID].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	//mainVersion = (mainVersion & 0xFFFF0000) >> 16;
	mainVersion = (mainVersion & 0xFFFFF000) >> 12;
	NSLog(@"Main FGPA version: 0x%x \n", mainVersion);
		
	if (mainVersion != kCurrentFirmwareVersion){
		NSLog(@"Main FPGA version does not match: it should be 0x%x, but now it is 0x%x \n", kCurrentFirmwareVersion,mainVersion);
		return;
	}
	
	//find out the VME FPGA version
	unsigned long vmeVersion = 0x00;
	[[self adapter] readLongBlock:&vmeVersion
						 atAddress:[self baseAddress] + fpga_register_information[kVMEFPGAVersionStatus].offset
                        numToRead:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	NSLog(@"VME FPGA serial number: 0x%x \n", (vmeVersion & 0x0000FFFF));
	NSLog(@"BOARD Revision number: 0x%x \n", ((vmeVersion & 0x00FF0000) >> 16));
	NSLog(@"VHDL Version number: 0x%x \n", ((vmeVersion & 0xFF000000) >> 24));
	
	
    //[self initSerDes];
    //write the card level params
	
	
	int i;
	for(i=0;i<kNumGretina4CardParams;i++){
		unsigned long theValue = [[cardInfo objectAtIndex:i] longValue];
		[[self adapter] writeLongBlock:&theValue
							atAddress:[self baseAddress] + cardConstants[i].regOffset
							numToWrite:1
							withAddMod:[self addressModifier]
							usingAddSpace:0x01];
	}
	
	//write the channel level params
	if (doEnableChannels) {
		for(i=0;i<kNumGretina4Channels;i++) {
			[self writeControlReg:i enabled:[self enabled:i]];
			[self writeLEDThreshold:i];
			[self writeCFDParameters:i];
			[self writeRawDataSlidingLength:i];
			[self writeRawDataWindowLength:i];
		}
	}
	else {
		for(i=0;i<kNumGretina4Channels;i++) {
			[self writeLEDThreshold:i];
			[self writeCFDParameters:i];
			[self writeRawDataSlidingLength:i];
			[self writeRawDataWindowLength:i];
		}
	}
		
	[self writeDownSample];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4CardInited object:self];
}

- (unsigned long) readControlReg:(int)channel
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kControlStatus].offset + 4*channel
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return theValue;
}

- (void) writeControlReg:(int)chan enabled:(BOOL)forceEnable
{
    /* writeControlReg writes the current model state to the board.  If forceEnable is NO, *
     * then all the channels are disabled.  Otherwise, the channels are enabled according  *
     * to the model state.                                                                 */
	
    BOOL startStop;
    if(forceEnable)	startStop= enabled[chan];
    else			startStop = NO;

    unsigned long theValue = (pzTraceEnabled[chan] << 14) | (poleZeroEnabled[chan] << 13) | (cfdEnabled[chan] << 12) | (polarity[chan] << 10) 
	| ((triggerMode[chan] & 0x3) << 3) | (pileUp[chan] << 2) | (debug[chan] << 1) | startStop;
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[self baseAddress] + register_information[kControlStatus].offset + 4*chan
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    unsigned long readBackValue = [self readControlReg:chan];
    if((readBackValue & 0xC1F) != (theValue & 0xC1F)){
        NSLogColor([NSColor redColor],@"Channel %d status reg readback != writeValue (0x%x != 0x%x)\n",chan,readBackValue & 0xC1F,theValue & 0xC1F);
    }
}

- (void) writeLEDThreshold:(int)channel
{    
    unsigned long theValue = ((poleZeroMult[channel]) << 20) | (ledThreshold[channel] & 0x1FFFF);
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[self baseAddress] + register_information[kLEDThreshold].offset + 4*channel
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    theValue = 0x0;
    if(triggerMode[channel] == kTrapezoidalTriggerMode) theValue = (1 << 31) | ledThreshold[channel];
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[self baseAddress] + register_information[kTrapezoidalTriggerReg].offset + 4*channel
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeCFDParameters:(int)channel
{    
    unsigned long theValue = ((cfdDelay[channel] & 0x3F) << 7) | ((cfdFraction[channel] & 0x3) << 5) | (cfdThreshold[channel]);
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[self baseAddress] + register_information[kCFDParameters].offset + 4*channel
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (void) writeRawDataSlidingLength:(int)channel
{    
    unsigned long theValue = (unsigned long)dataDelay[channel];
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[self baseAddress] + register_information[kRawDataSlidingLength].offset + 4*channel
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (void) writeRawDataWindowLength:(int)channel
{    
	unsigned long aValue = dataLength[channel];
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_information[kRawDataWindowLength].offset + 4*channel
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}


- (unsigned short) readFifoState
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    if((theValue & kGretina4FIFOEmpty)!=0)		return kEmpty;
    else if((theValue & kGretina4FIFOAllFull)!=0)		return kFull;
    else if((theValue & kGretina4FIFOAlmostFull)!=0)	return kAlmostFull;
    else if((theValue & kGretina4FIFOAlmostEmpty)!=0)	return kAlmostEmpty;
    else						return kHalfFull;
}

- (void) writeDownSample
{
    unsigned long theValue = (downSample << 28);
    [[self adapter] writeLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToWrite:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
}

- (int) readCardInfo:(int) index
{
    unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + cardConstants[index].regOffset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue & cardConstants[index].mask;
}

- (int) readExternalWindow { return [self readCardInfo:kExternalWindowIndex]; }

- (int) readPileUpWindow { return [self readCardInfo:kPileUpWindowIndex]; }

- (int) readNoiseWindow { return [self readCardInfo:kNoiseWindowIndex]; }

- (int) readExtTrigLength { return [self readCardInfo:kExtTrigLengthIndex]; }

- (int) readCollectionTime { return [self readCardInfo:kCollectionTimeIndex]; }

- (int) readIntegrationTime { return [self readCardInfo:kIntegrationTimeIndex]; }

- (int) readDownSample 
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue >> 28;
}


- (int) clearFIFO
{
    /* clearFIFO clears the FIFO and then resets the enabled flags on the board to whatever *
     * was currently set *ON THE BOARD*.                                                    */
	int count = 0;

    fifoStateAddress  = [self baseAddress] + register_information[kProgrammingDone].offset;
    fifoAddress       = [self baseAddress] + 0x1000;
	theController     = [self adapter];
	unsigned long  dataDump[0xffff];
	BOOL errorFound		  = NO;
	//NSDate* startDate = [NSDate date];

    short boardStateEnabled[kNumGretina4Channels];
    short modelStateEnabled[kNumGretina4Channels];
    int i;
    for(i=0;i<kNumGretina4Channels;i++) {
        /* First thing, disable all the channels so that nothing is filling the buffer. */
        /* Reading the *BOARD STATE* (i.e. *not* the *MODEL* state) */
        boardStateEnabled[i] = [self readControlReg:i] & 0x1;
        modelStateEnabled[i] = [self enabled:i];
        [self writeControlReg:i enabled:NO];
    }
    
    while(1){
		unsigned long val = 0;
		//read the fifo state
		[theController readLongBlock:&val
						   atAddress:fifoStateAddress
						   numToRead:1
						  withAddMod:[self addressModifier]
					   usingAddSpace:0x01];
		if((val & kGretina4FIFOEmpty) == 0){
			//read the first longword which should be the packet separator:
			unsigned long theValue;
			[theController readLongBlock:&theValue 
							   atAddress:fifoAddress 
							   numToRead:1 
							  withAddMod:[self addressModifier] 
						   usingAddSpace:0x01];
			
			if(theValue==kGretina4PacketSeparator){
				//read the first word of actual data so we know how much to read
				[theController readLongBlock:&theValue 
								   atAddress:fifoAddress 
								   numToRead:1 
								  withAddMod:[self addressModifier] 
							   usingAddSpace:0x01];
                                if(theValue == kGretina4PacketSeparator) {
				    NSLog(@"Clearing FIFO: got two packet separators in a row. Is the FIFO corrupted? (slot %d). \n",[self slot]);
				    break;
                                }
				
				[theController readLongBlock:dataDump 
								   atAddress:fifoAddress 
								   numToRead:((theValue & kGretina4NumberWordsMask)>>16)-1  //number longs left to read
								  withAddMod:[self addressModifier] 
							   usingAddSpace:0x01];
				count++;
			} 
			else {
				if (errorFound) {
					NSLog(@"Clearing FIFO: lost place in the FIFO twice, is the FIFO corrupted? (slot %d). \n",[self slot]);
					break;
				}
                NSLog(@"Clearing FIFO: FIFO corrupted on Gretina4 card (slot %d), searching for next event... \n",[self slot]);
                count += [self findNextEventInTheFIFO];
                NSLog(@"Clearing FIFO: Next event found on Gretina4 card (slot %d), continuing to clear FIFO. \n",[self slot]);
				errorFound = YES;
			}
		} 
		else { 
            /* The FIFO has been cleared. */
            break;
        }
		
    }
	
	[[self undoManager] disableUndoRegistration];
	@try {
		for(i=0;i<kNumGretina4Channels;i++) {
			/* Now reenable all the channels that were enabled before (on the *BOARD*). */
			[self setEnabled:i withValue:boardStateEnabled[i]];
			[self writeControlReg:i enabled:YES];
			[self setEnabled:i withValue:modelStateEnabled[i]];
		}
	}
	@catch(NSException* localException){
		@throw;
	}
	@finally {
		[[self undoManager] enableUndoRegistration];	
	}
	return count;
}

- (int) findNextEventInTheFIFO
{
    /* Somehow the FIFO got corrupted and is no longer aligned along event boundaries.           *
     * This function will read through to the next boundary and read out the next full event,    *
     * leaving the FIFO aligned along an event.  The function returns the number of events lost. */
    unsigned long val;
    //read the fifo state, sanity check to make sure there is actually another event.
    while (1) {
        [theController readLongBlock:&val
                           atAddress:fifoStateAddress
                           numToRead:1
                          withAddMod:[self addressModifier]
                       usingAddSpace:0x01];
        
        if((val & kGretina4FIFOEmpty) != 0) {
            /* We read until the FIFO is empty, meaning we are aligned */
            return 1; // We have only lost one event.
        } else {
            /* We need to continue reading until finding the packet separator */
            //read the first longword which should be the packet separator:
            unsigned long theValue;
            [theController readLongBlock:&theValue 
                               atAddress:fifoAddress 
                               numToRead:1 
                              withAddMod:[self addressModifier] 
                           usingAddSpace:0x01];
            
            if (theValue==kGretina4PacketSeparator) {
                //read the first word of actual data so we know how much to read
                [theController readLongBlock:&theValue 
                                   atAddress:fifoAddress 
                                   numToRead:1 
                                  withAddMod:[self addressModifier] 
                               usingAddSpace:0x01];
                unsigned long numberLeftToRead = ((theValue & kGretina4NumberWordsMask)>>16)-1;
                unsigned long* dataDump = malloc(sizeof(unsigned long)*numberLeftToRead);
                [theController readLongBlock:dataDump 
								   atAddress:fifoAddress 
								   numToRead:  numberLeftToRead //number longs left to read
								  withAddMod:[self addressModifier] 
							   usingAddSpace:0x01];
                free(dataDump);
                return 2; // We have lost two events
            }
            
            /* If we've gotten here, it means we have to continue some more. */
        } 
		
    }
}

- (void) findNoiseFloors
{
	if(noiseFloorRunning){
		noiseFloorRunning = NO;
	}
	else {
		noiseFloorState = 0;
		noiseFloorRunning = YES;
		[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:0];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4NoiseFloorChanged object:self];
}

- (void) stepNoiseFloor
{
	[[self undoManager] disableUndoRegistration];
	
    @try {
		unsigned long val;
		
		switch(noiseFloorState){
			case 0: //init
				//disable all channels
				[self initBoard:true];
				int i;
				for(i=0;i<kNumGretina4Channels;i++){
					oldEnabled[i] = [self enabled:i];
					[self setEnabled:i withValue:NO];
					[self writeControlReg:i enabled:NO];
					oldLEDThreshold[i] = [self ledThreshold:i];
					[self setLEDThreshold:i withValue:0x7fff];
					newLEDThreshold[i] = 0x7fff;
				}
				noiseFloorWorkingChannel = -1;
				//find first channel
				for(i=0;i<kNumGretina4Channels;i++){
					if(oldEnabled[i]){
						noiseFloorWorkingChannel = i;
						break;
					}
				}
				if(noiseFloorWorkingChannel>=0){
					noiseFloorLow			= 0;
					noiseFloorHigh		= 0x7FFF;
					noiseFloorTestValue	= 0x7FFF/2;              //Initial probe position
					[self setLEDThreshold:noiseFloorWorkingChannel withValue:noiseFloorHigh];
					[self writeLEDThreshold:noiseFloorWorkingChannel];
					[self setEnabled:noiseFloorWorkingChannel withValue:YES];
					[self writeControlReg:noiseFloorWorkingChannel enabled:YES];
					[self clearFIFO];
					noiseFloorState = 1;
				}
				else {
					noiseFloorState = 2; //nothing to do
				}
				break;
				
			case 1:
				if(noiseFloorLow <= noiseFloorHigh) {
					[self setLEDThreshold:noiseFloorWorkingChannel withValue:noiseFloorTestValue];
					[self writeLEDThreshold:noiseFloorWorkingChannel];
					noiseFloorState = 2;	//go check for data
				}
				else {
					newLEDThreshold[noiseFloorWorkingChannel] = noiseFloorTestValue + noiseFloorOffset;
					[self setEnabled:noiseFloorWorkingChannel withValue:NO];
					[self writeControlReg:noiseFloorWorkingChannel enabled:NO];
					[self setLEDThreshold:noiseFloorWorkingChannel withValue:0x7fff];
					[self writeLEDThreshold:noiseFloorWorkingChannel];
					noiseFloorState = 3;	//done with this channel
				}
				break;
				
			case 2:
				//read the fifo state
				[[self adapter] readLongBlock:&val
									atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
									numToRead:1
								   withAddMod:[self addressModifier]
								usingAddSpace:0x01];
				
				if((val & kGretina4FIFOEmpty) == 0){
					//there's some data in fifo so we're too low with the threshold
					[self setLEDThreshold:noiseFloorWorkingChannel withValue:0x7fff];
					[self writeLEDThreshold:noiseFloorWorkingChannel];
					[self clearFIFO];
					noiseFloorLow = noiseFloorTestValue + 1;
				}
				else noiseFloorHigh = noiseFloorTestValue - 1;										//no data so continue lowering threshold
				noiseFloorTestValue = noiseFloorLow+((noiseFloorHigh-noiseFloorLow)/2);     //Next probe position.
				noiseFloorState = 1;	//continue with this channel
				break;
				
			case 3:
				//go to next channel
				noiseFloorLow		= 0;
				noiseFloorHigh		= 0x7FFF;
				noiseFloorTestValue	= 0x7FFF/2;              //Initial probe position
				//find first channel
				int startChan = noiseFloorWorkingChannel+1;
				noiseFloorWorkingChannel = -1;
				for(i=startChan;i<kNumGretina4Channels;i++){
					if(oldEnabled[i]){
						noiseFloorWorkingChannel = i;
						break;
					}
				}
				if(noiseFloorWorkingChannel >= startChan){
					[self setEnabled:noiseFloorWorkingChannel withValue:YES];
					[self writeControlReg:noiseFloorWorkingChannel enabled:YES];
					noiseFloorState = 1;
				}
				else {
					noiseFloorState = 4;
				}
				break;
				
			case 4: //finish up	
				//load new results
				for(i=0;i<kNumGretina4Channels;i++){
					[self setEnabled:i withValue:oldEnabled[i]];
					[self setLEDThreshold:i withValue:newLEDThreshold[i]];
				}
				[self initBoard:true];
				noiseFloorRunning = NO;
				break;
		}
		if(noiseFloorRunning){
			[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:noiseFloorIntegrationTime];
		}
		else {
			[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4NoiseFloorChanged object:self];
		}
    }
	@catch(NSException* localException) {
        int i;
        for(i=0;i<kNumGretina4Channels;i++){
            [self setEnabled:i withValue:oldEnabled[i]];
            [self setLEDThreshold:i withValue:oldLEDThreshold[i]];
        }
		NSLog(@"Gretina4 LED threshold finder quit because of exception\n");
    }
	[[self undoManager] enableUndoRegistration];
}

- (void) startDownLoadingMainFPGA
{
	if(!progressLock)progressLock = [[NSLock alloc] init];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelFpgaDownProgressChanged object:self];
	
	stopDownLoadingMainFPGA = NO;
	NSData* dataFromFile = [NSData dataWithContentsOfFile:fpgaFilePath];
	
	//to minimize disruptions to the download thread we'll check and update the progress from the main thread via a timer.
	fpgaDownProgress = 0;
	
	[self setDownLoadMainFPGAInProgress: YES];
	[self updateDownLoadProgress];

	if(fpgaProgrammingThread)[fpgaProgrammingThread release];
	fpgaProgrammingThread = [[NSThread alloc] initWithTarget:self selector:@selector(fpgaDownLoadThread:) object:dataFromFile];
	[fpgaProgrammingThread setStackSize:4*1024*1024];
	[fpgaProgrammingThread start];
	
	//[NSThread detachNewThreadSelector:@selector(fpgaDownLoadThread:) toTarget:self withObject:dataFromFile];
}

- (void) stopDownLoadingMainFPGA
{
	if(downLoadMainFPGAInProgress){
		stopDownLoadingMainFPGA = YES;
	}
}


#pragma mark ���Data Taker
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORGretina4WaveformDecoder",             @"decoder",
								 [NSNumber numberWithLong:dataId],        @"dataId",
								 [NSNumber numberWithBool:YES],           @"variable",
								 [NSNumber numberWithLong:-1],			 @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Gretina4"];
    
    return dataDictionary;
}


#pragma mark ���HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}
- (int) numberOfChannels
{
    return kNumGretina4Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"External Window"];
    [p setFormat:@"##0" upperLimit:0x7ff lowerLimit:0 stepSize:1 units:cardConstants[kExternalWindowIndex].units];
    [p setSetMethod:@selector(setExternalWindow:) getMethod:@selector(externalWindowAsInt)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pileup Window"];
    [p setFormat:@"##0" upperLimit:0x7ff lowerLimit:0 stepSize:1 units:cardConstants[kPileUpWindowIndex].units];
    [p setSetMethod:@selector(setPileUpWindow:) getMethod:@selector(pileUpWindowAsInt)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Noise Window"];
    [p setFormat:@"##0" upperLimit:0x3f lowerLimit:0 stepSize:1 units:cardConstants[kNoiseWindowIndex].units];
    [p setSetMethod:@selector(setNoiseWindow:) getMethod:@selector(noiseWindowAsInt)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Ext Trig Length"];
    [p setFormat:@"##0" upperLimit:0x7ff lowerLimit:0 stepSize:1 units:cardConstants[kExtTrigLengthIndex].units];
    [p setSetMethod:@selector(setExtTrigLength:) getMethod:@selector(extTrigLengthAsInt)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Collection Time"];
    [p setFormat:@"##0" upperLimit:0xff lowerLimit:0 stepSize:1 units:cardConstants[kCollectionTimeIndex].units];
    [p setSetMethod:@selector(setCollectionTime:) getMethod:@selector(collectionTimeAsInt)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Integration Time"];
    [p setFormat:@"##0" upperLimit:0xff lowerLimit:0 stepSize:1 units:cardConstants[kIntegrationTimeIndex].units];
    [p setSetMethod:@selector(setIntegrationTime:) getMethod:@selector(integrationTimeAsInt)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Polarity"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPolarity:withValue:) getMethod:@selector(polarity:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Mode"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTriggerMode:withValue:) getMethod:@selector(triggerMode:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pile Up"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setPileUp:withValue:) getMethod:@selector(pileUp:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setEnabled:withValue:) getMethod:@selector(enabled:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Debug Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setDebug:withValue:) getMethod:@selector(debug:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"LED Threshold"];
    [p setFormat:@"##0" upperLimit:0x7fff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setLEDThreshold:withValue:) getMethod:@selector(ledThreshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"CFD Delay"];
    [p setFormat:@"##0" upperLimit:630 lowerLimit:0 stepSize:1 units:@"ns"];
    [p setSetMethod:@selector(setCFDDelayConverted:withValue:) getMethod:@selector(cfdDelayConverted:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"CFD Fraction"];
    [p setFormat:@"##0" upperLimit:0x3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setCFDFraction:withValue:) getMethod:@selector(cfdFraction:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"CFD Threshold"];
    [p setFormat:@"##0.0" upperLimit:160 lowerLimit:0 stepSize:1 units:@"Kev"];
	[p setCanBeRamped:YES];
    [p setSetMethod:@selector(setCFDThresholdConverted:withValue:) getMethod:@selector(cfdThresholdConverted:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Data Delay"];
    [p setFormat:@"##0.00" upperLimit:4.5 lowerLimit:0 stepSize:.01 units:@"us"];
    [p setSetMethod:@selector(setDataDelayConverted:withValue:) getMethod:@selector(dataDelayConverted:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Data Length"];
    [p setFormat:@"##0" upperLimit:0x3FF lowerLimit:1 stepSize:1 units:@"ns"];
    [p setSetMethod:@selector(setTraceLengthConverted:withValue:) getMethod:@selector(traceLengthConverted:)];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Down Sample"];
    [p setFormat:@"##0" upperLimit:4 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setDownSample:) getMethod:@selector(downSample)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:YES];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard:)];
    [a addObject:p];
    
    return a;
}


- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORGretina4Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORGretina4Model"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
 	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    
    id obj = [cardDictionary objectForKey:param];
    if(obj)return obj;
    else return [[cardDictionary objectForKey:param] objectAtIndex:aChannel];
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORGretina4Model"];    
    
    //cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    theController   = [self adapter];
    fifoAddress     = [self baseAddress] + 0x1000;
    fifoStateAddress= [self baseAddress] + register_information[kProgrammingDone].offset;
    
    short i;
    for(i=0;i<kNumGretina4Channels;i++) {
        [self writeControlReg:i enabled:NO];
    }
    [self clearFIFO];
    fifoLostEvents = 0;
    dataBuffer = (unsigned long*)malloc(0xffff * sizeof(unsigned long));
    [self startRates];
    
    [self initBoard:true];
    
	[self performSelector:@selector(checkFifoAlarm) withObject:nil afterDelay:1];
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    isRunning = YES;
    NSString* errorLocation = @"";
    @try {
        unsigned long val;
        //read the fifo state
        [theController readLongBlock:&val
                           atAddress:fifoStateAddress
                           numToRead:1
                          withAddMod:[self addressModifier]
                       usingAddSpace:0x01];
        fifoState = val;			
        if((val & kGretina4FIFOEmpty) == 0){
            unsigned long numLongs = 0;
            dataBuffer[numLongs++] = dataId | 0; //we'll fill in the length later
            dataBuffer[numLongs++] = location;
            
            //read the first longword which should be the packet separator:
            unsigned long theValue;
            [theController readLongBlock:&theValue 
                               atAddress:fifoAddress 
                               numToRead:1 
                              withAddMod:[self addressModifier] 
                           usingAddSpace:0x01];
            
            if(theValue==kGretina4PacketSeparator){
                
                //read the first word of actual data so we know how much to read
                [theController readLongBlock:&theValue 
                                   atAddress:fifoAddress 
                                   numToRead:1 
                                  withAddMod:[self addressModifier] 
                               usingAddSpace:0x01];
                
                dataBuffer[numLongs++] = theValue;
                
                ++waveFormCount[theValue & 0x7];  //grab the channel and inc the count
                
                unsigned long numLongsLeft  = ((theValue & kGretina4NumberWordsMask)>>16)-1;
                
                [theController readLong:&dataBuffer[numLongs] 
                              atAddress:fifoAddress 
                            timesToRead:numLongsLeft 
                             withAddMod:[self addressModifier] 
                          usingAddSpace:0x01];
				
                long totalNumLongs = (numLongs + numLongsLeft);
                dataBuffer[0] |= totalNumLongs; //see, we did fill it in...
                [aDataPacket addLongsToFrameBuffer:dataBuffer length:totalNumLongs];
            } else {
                //oops... the buffer read is out of sequence
                NSLogError([NSString stringWithFormat:@"slot %d",[self slot]],@"Packet Sequence Error -- Looking for next event",@"Gretina4",nil);
                fifoLostEvents += [self findNextEventInTheFIFO];
                NSLogError(@"Packet Sequence Error -- Next event found",@"Gretina4",[NSString stringWithFormat:@"slot %d",[self slot]],nil);
            }
        }
		
    }
	@catch(NSException* localException) {
        NSLogError(@"",@"Gretina4 Card Error",errorLocation,nil);
        [self incExceptionCount];
        [localException raise];
    }
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    @try {
		/* Disable all channels.  The remaining buffer should be readout. */
		int i;
		for(i=0;i<kNumGretina4Channels;i++){					
			[self writeControlReg:i enabled:NO];
		}
	}
	@catch(NSException* e){
        [self incExceptionCount];
        NSLogError(@"",@"Gretina4 Card Error",nil);
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    isRunning = NO;
    [waveFormRateGroup stop];
    //stop all channels
    short i;
    for(i=0;i<kNumGretina4Channels;i++){					
		waveFormCount[i] = 0;
    }
    free(dataBuffer);
    if ( fifoLostEvents != 0 ) {
        NSLogError( [NSString stringWithFormat:@" lost events due to buffer corruption: %d",fifoLostEvents],@"Gretina4 ",[NSString stringWithFormat:@"(slot %d):",[self slot]],
				   nil);
    }
}

- (void) checkFifoAlarm
{
	if(((fifoState & kGretina4FIFOAlmostFull) != 0) && isRunning){
		fifoEmptyCount = 0;
		if(!fifoFullAlarm){
			NSString* alarmName = [NSString stringWithFormat:@"FIFO Almost Full Gretina4 (slot %d)",[self slot]];
			fifoFullAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kDataFlowAlarm];
			[fifoFullAlarm setSticky:YES];
			[fifoFullAlarm setHelpString:@"The rate is too high. Adjust the LED Threshold accordingly."];
			[fifoFullAlarm postAlarm];
		}
	}
	else {
		fifoEmptyCount++;
		if(fifoEmptyCount>=5){
			[fifoFullAlarm clearAlarm];
			[fifoFullAlarm release];
			fifoFullAlarm = nil;
		}
	}
	if(isRunning){
		[self performSelector:@selector(checkFifoAlarm) withObject:nil afterDelay:1.5];
	}
	else {
		[fifoFullAlarm clearAlarm];
		[fifoFullAlarm release];
		fifoFullAlarm = nil;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelFIFOCheckChanged object:self];
}

- (void) reset
{
}


- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(isRunning)return NO;
    
    ++waveFormCount[channel];
    return YES;
}

- (unsigned long) waveFormCount:(int)aChannel
{
    return waveFormCount[aChannel];
}

-(void) startRates
{
    [self clearWaveFormCounts];
    [waveFormRateGroup start:self];
}

- (void) clearWaveFormCounts
{
    int i;
    for(i=0;i<kNumGretina4Channels;i++){
        waveFormCount[i]=0;
    }
}

- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	
    /* The current hardware specific data is:               *
     *                                                      *
     * 0: FIFO state address                                *
     * 1: FIFO empty state mask                             *
     * 2: FIFO address                                      *
     * 3: FIFO address AM                                   *
     * 4: FIFO size                                         */
    
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id	= kGretina; //should be unique
	configStruct->card_info[index].hw_mask[0] 	= dataId; //better be unique
	configStruct->card_info[index].slot			= [self slot];
	configStruct->card_info[index].crate		= [self crateNumber];
	configStruct->card_info[index].add_mod		= [self addressModifier];
	configStruct->card_info[index].base_add		= [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0]	= [self baseAddress] + register_information[kProgrammingDone].offset; //fifoStateAddress
    configStruct->card_info[index].deviceSpecificData[1]	= kGretina4FIFOEmpty; // fifoEmptyMask
    configStruct->card_info[index].deviceSpecificData[2]	= [self baseAddress] + 0x1000; // fifoAddress
    configStruct->card_info[index].deviceSpecificData[3]	= 0x0B; // fifoAM
    configStruct->card_info[index].deviceSpecificData[4]	= 0x1FFFF; // size of FIFO
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

#pragma mark ���Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setSpiConnector:			[decoder decodeObjectForKey:@"spiConnector"]];
    [self setDownSample:				[decoder decodeIntForKey:@"downSample"]];
    [self setRegisterIndex:				[decoder decodeIntForKey:@"registerIndex"]];
    [self setRegisterWriteValue:		[decoder decodeInt32ForKey:@"registerWriteValue"]];
    [self setSPIWriteValue:     		[decoder decodeInt32ForKey:@"spiWriteValue"]];
    [self setFpgaFilePath:				[decoder decodeObjectForKey:@"fpgaFilePath"]];
    [self setNoiseFloorIntegrationTime:	[decoder decodeFloatForKey:@"NoiseFloorIntegrationTime"]];
    [self setNoiseFloorOffset:			[decoder decodeIntForKey:@"NoiseFloorOffset"]];
    cardInfo = [[decoder decodeObjectForKey:@"cardInfo"] retain];
    
    
    [self setWaveFormRateGroup:[decoder decodeObjectForKey:@"waveFormRateGroup"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumGretina4Channels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
	int i;
	for(i=0;i<kNumGretina4Channels;i++){
		[self setEnabled:i		withValue:[decoder decodeIntForKey:[@"enabled"	    stringByAppendingFormat:@"%d",i]]];
		[self setDebug:i		withValue:[decoder decodeIntForKey:[@"debug"	    stringByAppendingFormat:@"%d",i]]];
		[self setPileUp:i		withValue:[decoder decodeIntForKey:[@"pileUp"	    stringByAppendingFormat:@"%d",i]]];
		[self setCFDEnabled:i 	withValue:[decoder decodeIntForKey:[@"cfdEnabled"   stringByAppendingFormat:@"%d",i]]];
		[self setPoleZeroEnabled:i withValue:[decoder decodeIntForKey:[@"poleZeroEnabled" stringByAppendingFormat:@"%d",i]]];
		[self setPoleZeroMultiplier:i withValue:[decoder decodeIntForKey:[@"poleZeroMult" stringByAppendingFormat:@"%d",i]]];
		[self setPZTraceEnabled:i withValue:[decoder decodeIntForKey:[@"pzTraceEnabled" stringByAppendingFormat:@"%d",i]]];
		[self setPolarity:i		withValue:[decoder decodeIntForKey:[@"polarity"     stringByAppendingFormat:@"%d",i]]];
		[self setTriggerMode:i	withValue:[decoder decodeIntForKey:[@"triggerMode"	stringByAppendingFormat:@"%d",i]]];
		[self setLEDThreshold:i withValue:[decoder decodeIntForKey:[@"ledThreshold" stringByAppendingFormat:@"%d",i]]];
		[self setCFDThreshold:i withValue:[decoder decodeIntForKey:[@"cfdThreshold" stringByAppendingFormat:@"%d",i]]];
		[self setCFDDelay:i		withValue:[decoder decodeIntForKey:[@"cfdDelay"		stringByAppendingFormat:@"%d",i]]];
		[self setCFDFraction:i	withValue:[decoder decodeIntForKey:[@"cfdFraction"	stringByAppendingFormat:@"%d",i]]];
		[self setDataDelay:i	withValue:[decoder decodeIntForKey:[@"dataDelay"	stringByAppendingFormat:@"%d",i]]];
		[self setDataLength:i	withValue:[decoder decodeIntForKey:[@"dataLength"	stringByAppendingFormat:@"%d",i]]];
	}
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:spiConnector				forKey:@"spiConnector"];
    [encoder encodeInt:downSample					forKey:@"downSample"];
    [encoder encodeInt:registerIndex				forKey:@"registerIndex"];
    [encoder encodeInt32:registerWriteValue			forKey:@"registerWriteValue"];
    [encoder encodeInt32:spiWriteValue			    forKey:@"spiWriteValue"];
    [encoder encodeObject:fpgaFilePath				forKey:@"fpgaFilePath"];
    [encoder encodeFloat:noiseFloorIntegrationTime	forKey:@"NoiseFloorIntegrationTime"];
    [encoder encodeInt:noiseFloorOffset				forKey:@"NoiseFloorOffset"];
    [encoder encodeObject:cardInfo					forKey:@"cardInfo"];
    [encoder encodeObject:waveFormRateGroup			forKey:@"waveFormRateGroup"];
	int i;
 	for(i=0;i<kNumGretina4Channels;i++){
		[encoder encodeInt:enabled[i]		forKey:[@"enabled"		stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:debug[i]			forKey:[@"debug"		stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:pileUp[i]		forKey:[@"pileUp"		stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:cfdEnabled[i]  	forKey:[@"cfdEnabled"  	stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:poleZeroEnabled[i] forKey:[@"poleZeroEnabled" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:poleZeroMult[i]  forKey:[@"poleZeroMult" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:pzTraceEnabled[i] forKey:[@"pzTraceEnabled" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:polarity[i]		forKey:[@"polarity"		stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:triggerMode[i]	forKey:[@"triggerMode"	stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:cfdFraction[i]	forKey:[@"cfdFraction"	stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:cfdDelay[i]		forKey:[@"cfdDelay"		stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:cfdThreshold[i]	forKey:[@"cfdThreshold" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:ledThreshold[i]	forKey:[@"ledThreshold" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:dataDelay[i]		forKey:[@"dataDelay"	stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:dataLength[i]	forKey:[@"dataLength"	stringByAppendingFormat:@"%d",i]];
	}
	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    short i;
    for(i=0;i<kNumGretina4CardParams;i++){
        [objDictionary setObject:[self cardInfo:i] forKey:cardConstants[i].name];
    }  
	[self addCurrentState:objDictionary cArray:enabled forKey:@"Enabled"];
	[self addCurrentState:objDictionary cArray:debug forKey:@"Debug Mode"];
	[self addCurrentState:objDictionary cArray:pileUp forKey:@"Pile Up"];
	[self addCurrentState:objDictionary cArray:polarity forKey:@"Polarity"];
	[self addCurrentState:objDictionary cArray:triggerMode forKey:@"Trigger Mode"];
	[self addCurrentState:objDictionary cArray:cfdDelay forKey:@"CFD Delay"];
	[self addCurrentState:objDictionary cArray:cfdFraction forKey:@"CFD Fraction"];
	[self addCurrentState:objDictionary cArray:cfdThreshold forKey:@"CFD Threshold"];
	[self addCurrentState:objDictionary cArray:dataDelay forKey:@"Data Delay"];
	[self addCurrentState:objDictionary cArray:dataLength forKey:@"Data Length"];
	[self addCurrentState:objDictionary cArray:cfdEnabled forKey:@"CFD Enabled"];
	[self addCurrentState:objDictionary cArray:poleZeroEnabled forKey:@"Pole Zero Enabled"];
	[self addCurrentState:objDictionary cArray:poleZeroMult forKey:@"Pole Zero Multiplier"];
	[self addCurrentState:objDictionary cArray:pzTraceEnabled forKey:@"PZ Trace Enabled"];
    
    NSMutableArray* ar = [NSMutableArray array];
	for(i=0;i<kNumGretina4Channels;i++){
		[ar addObject:[NSNumber numberWithLong:ledThreshold[i]]];
	}
    [objDictionary setObject:ar forKey:@"LED Threshold"];
    [objDictionary setObject:[NSNumber numberWithInt:downSample] forKey:@"Down Sample"];
	
	
    return objDictionary;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(short*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<kNumGretina4Channels;i++){
		[ar addObject:[NSNumber numberWithShort:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

- (NSArray*) autoTests 
{
	NSMutableArray* myTests = [NSMutableArray array];
	[myTests addObject:[ORVmeReadOnlyTest test:kBoardID wordSize:4 name:@"Board ID"]];
	[myTests addObject:[ORVmeReadWriteTest test:kControlStatus wordSize:4 validMask:0x000000ff name:@"Control/Status"]];
	return myTests;
}


#pragma mark ���SPI Interface
- (unsigned long) writeAuxIOSPI:(unsigned long)spiData
{
    // Set AuxIO to mode 3 and set bits 0-3 to OUT (bit 0 is under FPGA control)
    [self writeRegister:kAuxIOConfig withValue:0x3025];
    // Read kAuxIOWrite to preserve bit 0, and zero bits used in SPI protocol
    unsigned long spiBase = [self readRegister:kAuxIOWrite] & ~(kSPIData | kSPIClock | kSPIChipSelect); 
    unsigned long value;
    unsigned long readBack = 0;
	
    // set kSPIChipSelect to signify that we are starting
    [self writeRegister:kAuxIOWrite withValue:(kSPIChipSelect | kSPIClock | kSPIData)];
    // now write spiData starting from MSB on kSPIData, pulsing kSPIClock
    // each iteration
    int i;
    //NSLog(@"writing 0x%x\n", spiData);
    for(i=0; i<32; i++) {
        value = spiBase | kSPIChipSelect | kSPIData;
        if( (spiData & 0x80000000) != 0) value &= (~kSPIData);
        [self writeRegister:kAuxIOWrite withValue:value | kSPIClock];
        [self writeRegister:kAuxIOWrite withValue:value];
        readBack |= (([self readRegister:kAuxIORead] & kSPIRead) > 0) << (31-i);
        spiData = spiData << 1;
    }
    // unset kSPIChipSelect to signify that we are done
    [self writeRegister:kAuxIOWrite withValue:(kSPIClock | kSPIData)];
    //NSLog(@"readBack=%u (0x%x)\n", readBack, readBack);
    return readBack;
}

@end
@implementation ORGretina4Model (private)

- (void) updateDownLoadProgress
{
	//call only from main thread
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelFpgaDownProgressChanged object:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:(self) selector:@selector(updateDownLoadProgress) object:nil];
	if(downLoadMainFPGAInProgress)[self performSelector:@selector(updateDownLoadProgress) withObject:nil afterDelay:.1];
}

- (void) setFpgaDownProgress:(int)aFpgaDownProgress
{
	[progressLock lock];
    fpgaDownProgress = aFpgaDownProgress;
	[progressLock unlock];
}

- (void) setProgressStateOnMainThread:(NSString*)aState
{
	if(!aState)aState = @"--";
	//this post a notification to the GUI so it must be done on the main thread
	[self performSelectorOnMainThread:@selector(setMainFPGADownLoadState:) withObject:aState waitUntilDone:NO];
}

- (void) fpgaDownLoadThread:(NSData*)dataFromFile
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	@try {
		[dataFromFile retain];

		[self setProgressStateOnMainThread:@"Block Erase"];
		if(!stopDownLoadingMainFPGA) [self blockEraseFlash];
		[self setProgressStateOnMainThread:@"Programming"];
		if(!stopDownLoadingMainFPGA) [self programFlashBuffer:dataFromFile];
		[self setProgressStateOnMainThread:@"Verifying"];
		if(!stopDownLoadingMainFPGA) {
			if (![self verifyFlashBuffer:dataFromFile]) {
				[NSException raise:@"Gretina4 Exception" format:@"Verification of flash failed."];	
			}
		}
		[self setProgressStateOnMainThread:@"Loading FPGA"];
		if(!stopDownLoadingMainFPGA) [self reloadMainFPGAFromFlash];
		[self setProgressStateOnMainThread:@"--"];
		//[self setBuffer:(const unsigned short*)[dataFromFile bytes] length:[dataFromFile length]/2];		
		//[self performSelector:@selector(programFlashBuffer) withObject:self afterDelay:0.1];
	}
	@catch(NSException* localException) {
		[self setProgressStateOnMainThread:@"Exception"];
	}
	@finally {
		[self performSelectorOnMainThread:@selector(downloadingMainFPGADone) withObject:nil waitUntilDone:NO];
		[dataFromFile release];
	}
	[pool release];
}

- (void) programFlashBuffer:(NSData*)theData 
{
	[self enableFlashEraseAndProg];
	unsigned long address = 0x0;
	long totalSize = [theData length];
	[self setFpgaDownProgress:0.];
	while (address < totalSize ) {
		@try {
			[ self programFlashBufferAtAddress:([theData bytes] + address)
								  startAddress:address
						  numberOfBytesToWrite:( ( ([theData length]-address) > kGretina4FlashBufferBytes) 
												? kGretina4FlashBufferBytes : ([theData length]-address) )];
			address += kGretina4FlashBufferBytes;
			if(stopDownLoadingMainFPGA)break;
			
			if(address%(totalSize/1000) == 0){
				[self setFpgaDownProgress: 100. * address/(float)totalSize];
			}
		}
		@catch(NSException* localException) {
			NSLog(@"Gretina4 exception programming flash.\n");
			break;
		}
	}
	//if(!stopDownLoadingMainFPGA) 
	[self disableFlashEraseAndProg];
	//if(!stopDownLoadingMainFPGA) 
	[self resetFlashStatus];
	[self setFpgaDownProgress: 100];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	[self setFpgaDownProgress: 0];
}

- (void) blockEraseFlash
{
	/* We only erase the blocks currently used in the Gretina4 specification. */
	[self enableFlashEraseAndProg];
	unsigned int i;
	[self setFpgaDownProgress:0.];
	for (i=0; i<kGretina4UsedFlashBlocks; i++ ) {
		if(stopDownLoadingMainFPGA)return;
		@try {
			[self blockEraseFlashAtBlock:i];
			//[ORTimer delayNanoseconds:10000];
			[self setFpgaDownProgress: 100. * (i+1)/(float)kGretina4UsedFlashBlocks];
		}
		@catch(NSException* localException) {
			NSLog(@"Gretina4 exception erasing flash.\n");
		}
	}
	[self disableFlashEraseAndProg];
	
	[self resetFlashStatus];
	[self setFpgaDownProgress: 100];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	[self setFpgaDownProgress: 0];
}

-(void) resetFlashStatus
{
	unsigned long tempToWrite = kGretina4FlashClearSRCmd;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kFlashCommandRegister].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	tempToWrite = kGretina4FlashReadArrayCmd;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kFlashCommandRegister].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	tempToWrite = 0x0;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kFlashAddress].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) enableFlashEraseAndProg
{
	unsigned long tempToWrite = kGretina4FlashEnableWrite;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kVMEGPControl].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	isFlashWriteEnabled = YES;
}

- (void) disableFlashEraseAndProg
{
	unsigned long tempToWrite = kGretina4FlashDisableWrite;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kVMEGPControl].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	isFlashWriteEnabled = NO;
}

- (void) programFlashBufferAtAddress:(const void*)theData 
						startAddress:(unsigned long)anAddress 
				numberOfBytesToWrite:(unsigned long)aNumber
{
	static char bufferToWrite[kGretina4FlashBufferBytes];
	if ( aNumber > kGretina4FlashBufferBytes ) {
		[NSException raise:@"Gretina4 Exception" format:@"Trying to program too many bytes in flash memory."];
	}
	if ( !isFlashWriteEnabled ) {
		[NSException raise:@"Gretina4 Exception" format:@"Programming flash is not enabled."];
	}
	/* Load the words into the bufferToWrite */
	
	memcpy(bufferToWrite, theData, aNumber);
	
	if ( aNumber < kGretina4FlashBufferBytes ) {
		unsigned int i;
		for ( i=aNumber; i<kGretina4FlashBufferBytes; i++ ) {
			bufferToWrite[i] = 0;
		}
	} 	
	unsigned long tempToWrite = anAddress;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kFlashAddress].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	tempToWrite = kGretina4FlashWriteCmd;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kFlashCommandRegister].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	while(1) {
		if(stopDownLoadingMainFPGA)return;
		[ORTimer delayNanoseconds:100000];			
		
		// Checking status to make sure that flash is ready
		/* This is slightly different since we give another command if the status hasn't updated. */
		[[self adapter] readLongBlock:&tempToWrite
							atAddress:[self baseAddress] + fpga_register_information[kFlashData].offset
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];		
		
		if ( (tempToWrite & kGretina4FlashReady)  == 0 ) {
			tempToWrite = kGretina4FlashWriteCmd;
			[[self adapter] writeLongBlock:&tempToWrite
								 atAddress:[self baseAddress] + fpga_register_information[kFlashCommandRegister].offset
								numToWrite:1
								withAddMod:[self addressModifier]
							 usingAddSpace:0x01];			
		} else break;
	}

	// Setting how many we are trying to write
	tempToWrite = (aNumber/2) - 1;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kFlashCommandRegister].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	// Loading all the words in
	unsigned long i;
	for ( i=0; i<aNumber; i+=4 ) {
		tempToWrite =   (((unsigned long)bufferToWrite[i]) & 0xFF) |    
		(((unsigned long)(bufferToWrite[i+1]) <<  8) & 0xFF00) |    
		(((unsigned long)(bufferToWrite[i+2]) << 16) & 0xFF0000)|    
		(((unsigned long)(bufferToWrite[i+3]) << 24) & 0xFF000000);
		[[self adapter] writeLongBlock:&tempToWrite
							 atAddress:[self baseAddress] + fpga_register_information[kFlashDataWithAddrIncr].offset
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];	
	}
	
	// Finishing the write
	tempToWrite = kGretina4FlashConfirmCmd;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kFlashCommandRegister].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	[self testFlashStatusRegisterWithNoFlashCmd];
}

- (void) testFlashStatusRegisterWithNoFlashCmd
{
	unsigned long tempToRead;
	while(1) {
		if(stopDownLoadingMainFPGA)return;
		
		[ORTimer delayNanoseconds:100000];
		// Checking status to make sure that flash is ready
		[[self adapter] readLongBlock:&tempToRead
							atAddress:[self baseAddress] + fpga_register_information[kFlashData].offset
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];		
		if ( (tempToRead & kGretina4FlashReady) != 0 ) break;
		}
	
}

- (void) testFlashStatusRegisterWithFlashCmd
{
	unsigned long tempToWrite = kGretina4FlashStatusRegCmd;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kFlashCommandRegister].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	[self testFlashStatusRegisterWithNoFlashCmd];
}

- (void) blockEraseFlashAtBlock:(unsigned long)blockNumber
{
	
	/* First setup the block erase */
	if (!isFlashWriteEnabled) {
		[NSException raise:@"Gretina4 Exception" format:@"Erasing flash is not enabled."];
		return;
	}
	unsigned long tempToWrite = 0x0;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kFlashAddress].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	tempToWrite = kGretina4FlashBlockEraseCmd;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kFlashCommandRegister].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	/* Now denote which block we're going to do. */
	tempToWrite = blockNumber*kGretina4FlashBlockSize;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kFlashAddress].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	/* And confirm. */
	tempToWrite = kGretina4FlashConfirmCmd;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kFlashCommandRegister].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];					 
	/* Now make sure that it finishes correctly. We don't need to issue the flash command to
	 read the status register because the confirm command already sets that.  */
	[self testFlashStatusRegisterWithNoFlashCmd];
	
}

- (BOOL) verifyFlashBuffer:(NSData*)theData
{
	/* First reset to make sure it is read mode. */
	//[ORTimer delayNanoseconds:100000];
	[self resetFlashStatus];
	//[ORTimer delayNanoseconds:100000];

	unsigned int position = 0;
	unsigned long tempToRead;
	const char* dataPtr = (const char*)[theData bytes];
	unsigned long tempToCompare;
	[self setFpgaDownProgress:0.];
	while ( position < [theData length] ) {
		[[self adapter] readLongBlock:&tempToRead
							atAddress:[self baseAddress] + fpga_register_information[kFlashDataWithAddrIncr].offset
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];	
		/* Now check with */
		if ( position + 3 < [theData length] ) {
			tempToCompare = (((unsigned long)dataPtr[position]) & 0xFF) |    
			(((unsigned long)(dataPtr[position+1]) <<  8) & 0xFF00) |    
			(((unsigned long)(dataPtr[position+2]) << 16) & 0xFF0000)|    
			(((unsigned long)(dataPtr[position+3]) << 24) & 0xFF000000);
		} else {
			unsigned int numBytes = [theData length] - position - 1;
			tempToCompare = 0;
			unsigned int i;
			for ( i=0;i<numBytes;i++) {
				tempToCompare += (((unsigned long)dataPtr[position]) << i*8) & (0xFF << i*8); 
			}
		}
		if ( tempToRead != tempToCompare ) {
			[self setFpgaDownProgress: 0];
			return NO;
		}
		if(position%([theData length]/1000) == 0){
			[self setFpgaDownProgress: 100. * position/(float)[theData length]];
		}
		position += 4;
	}
	[self setFpgaDownProgress: 100];
	//[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	[self setFpgaDownProgress: 0];
	return YES;
}

- (void) reloadMainFPGAFromFlash
{
	unsigned long tempToWrite = kGretina4ResetMainFPGACmd;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kMainFPGAControl].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	tempToWrite = kGretina4ReloadMainFPGACmd;
	[[self adapter] writeLongBlock:&tempToWrite
						 atAddress:[self baseAddress] + fpga_register_information[kMainFPGAControl].offset
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	/* Now check if it is done reloading before releasing. */
	[[self adapter] readLongBlock:&tempToWrite
						atAddress:[self baseAddress] + fpga_register_information[kMainFPGAStatus].offset
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	while ( ( tempToWrite & kGretina4MainFPGAIsLoaded ) != kGretina4MainFPGAIsLoaded ) {
		
		[ORTimer delayNanoseconds:100000];			
		[[self adapter] readLongBlock:&tempToWrite
							atAddress:[self baseAddress] + fpga_register_information[kMainFPGAStatus].offset
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
	}
}

- (void) downloadingMainFPGADone
{
	[fpgaProgrammingThread release];
	fpgaProgrammingThread = nil;
	
	if(!stopDownLoadingMainFPGA) NSLog(@"Programming Complete.\n");
	else						 NSLog(@"Programming manually stopped before done\n");
	[self setDownLoadMainFPGAInProgress: NO];
	
}

@end
