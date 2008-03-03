//--------------------------------------------------------
// ORAmi286Controller
// Created by Mark  A. Howe on Fri Sept 14, 2007
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
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

#pragma mark ***Imported Files

#import "ORAmi286Controller.h"
#import "ORAmi286Model.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORTimeRate.h"
#import "ORLevelMonitor.h"

@interface ORAmi286Controller (private)
- (void) populatePortListPopup;
@end

@implementation ORAmi286Controller

#pragma mark ***Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"Ami286"];
	return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scheduledUpdate) object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib
{
    [self populatePortListPopup];
    [[plotter0 yScale] setRngLow:0.0 withHigh:100.];
	[[plotter0 yScale] setRngLimitsLow:0.0 withHigh:100 withMinRng:10];
	[plotter0 setDrawWithGradient:YES];

    [super awakeFromNib];
}

#pragma mark ***Notifications

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORAmi286Lock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORAmi286ModelPortNameChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];
                                              
    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORAmi286ModelPollTimeChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(shipLevelsChanged:)
                         name : ORAmi286ModelShipLevelsChanged
						object: model];

    [notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];

    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(updateTimePlot:)
						 name : ORRateAverageChangedNotification
					   object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(updateMonitor:)
                         name : ORAmi286Update
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector(enabledMaskChanged:)
                         name : ORAmi286ModelEnabledMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fillStateChanged:)
                         name : ORAmi286FillStateChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(alarmLevelChanged:)
                         name : ORAmi286AlarmLevelChanged
						object: model];


}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"AMI 286 (Unit %d)",[model uniqueIdNumber]]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self stateChanged:nil];
    [self portStateChanged:nil];
    [self portNameChanged:nil];
	[self pollTimeChanged:nil];
	[self shipLevelsChanged:nil];
	[self updateTimePlot:nil];
	[self updateMonitor:nil];
	[self fillStateChanged:nil];
	[self alarmLevelChanged:nil];
	[self enabledMaskChanged:nil];
    [self miscAttributesChanged:nil];
}

- (void) enabledMaskChanged:(NSNotification*)aNote
{
	unsigned char aMask = [model enabledMask];
	int i;
	for(i=0;i<4;i++){
		BOOL bitSet = (aMask&(1<<i))>0;
		if(bitSet != [[enabledMaskMatrix cellWithTag:i] intValue]){
			[[enabledMaskMatrix cellWithTag:i] setState:bitSet];
		}
		[self loadLevelTimeValuesForIndex:i];
	}
	[self stateChanged:nil];
	[monitor0 setNeedsDisplay:YES];
	[monitor1 setNeedsDisplay:YES];
	[monitor2 setNeedsDisplay:YES];
	[monitor3 setNeedsDisplay:YES];
	[levelMatrix setNeedsDisplay:YES];
	[level1Matrix setNeedsDisplay:YES];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [plotter0 xScale]){
		[model setMiscAttributes:[[plotter0 xScale]attributes] forKey:@"XAttributes0"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter0 yScale]){
		[model setMiscAttributes:[[plotter0 yScale]attributes] forKey:@"YAttributes0"];
	};
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{

	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes0"];
		if(attrib){
			[[plotter0 xScale] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes0"];
		if(attrib){
			[[plotter0 yScale] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 yScale] setNeedsDisplay:YES];
		}
	}
}


- (void) updateTimePlot:(NSNotification*)aNote
{
	if(!aNote || ([aNote object] == [model timeRate:0])){
		[plotter0 setNeedsDisplay:YES];
	}
}

- (void) fillStateChanged:(NSNotification*)aNote
{
	int index = [[[aNote userInfo] objectForKey:@"Index"]intValue];
	if(index == 0)     [fillStatePU0 selectItemAtIndex:[model fillState:index]];
	else if(index == 1)[fillStatePU1 selectItemAtIndex:[model fillState:index]];
}

- (void) shipLevelsChanged:(NSNotification*)aNote
{
	[shipLevelsButton setIntValue: [model shipLevels]];
}


- (void) updateMonitor:(NSNotification*)aNote
{
	//we'll reduce updates to 1/sec
	if(!updateScheduled){
		updateScheduled = YES;	
		[self performSelector:@selector(scheduledUpdate) withObject:nil afterDelay:1];
	}
}

- (void) scheduledUpdate
{
	[monitor0 setNeedsDisplay:YES];
	[monitor1 setNeedsDisplay:YES];
	[monitor2 setNeedsDisplay:YES];
	[monitor3 setNeedsDisplay:YES];
	int i;
	for(i=0;i<4;i++){
		[self loadLevelTimeValuesForIndex:i];
		[self loadFillStatusForIndex:i];
		[self loadAlarmStatusForIndex:i];
	}
	updateScheduled = NO;	
}

- (void) loadLevelTimeValuesForIndex:(int)index
{
	
	unsigned char aMask = [model enabledMask];
	NSString* levelAsString;
	if(aMask & (1<<index)){
		levelAsString = [NSString stringWithFormat:@"%.1f%%",[model level:index]];
	}
	else {
		levelAsString = @"--";
	}
	[[levelMatrix cellWithTag:index] setStringValue:levelAsString];
	[[level1Matrix cellWithTag:index] setStringValue:levelAsString];

	unsigned long t = [model timeMeasured:index];
	NSCalendarDate* theDate;
	if(t){
		theDate = [NSCalendarDate dateWithTimeIntervalSince1970:t];
		[theDate setCalendarFormat:@"%m/%d %H:%M:%S"];
		[[timeMatrix cellWithTag:index] setObjectValue:theDate];
	}
	else [[timeMatrix cellWithTag:index] setObjectValue:@"--"];
}

- (void) alarmLevelChanged:(NSNotification*)aNote
{
	if(!aNote){
		int i;
		for(i=0;i<4;i++){
			[[hiAlarmMatrix cellWithTag:i] setFloatValue:[model hiAlarmLevel:i]];
			[[lowAlarmMatrix cellWithTag:i] setFloatValue:[model lowAlarmLevel:i]];
		}
	}
	else {
		int index = [[[aNote userInfo] objectForKey:@"Index"] intValue];
		[[hiAlarmMatrix cellWithTag:index] setFloatValue:[model hiAlarmLevel:index]];
		[[lowAlarmMatrix cellWithTag:index] setFloatValue:[model lowAlarmLevel:index]];
	}
}

- (void) loadFillStatusForIndex:(int)index
{	
	[[fillStatusMatrix cellWithTag:index] setStringValue:[model fillStatusName:[model fillStatus:index]]];
}

- (void) loadAlarmStatusForIndex:(int)index
{	
	NSTextField* tf = nil;
	if(index == 0)		tf = alarmStatus0;
	else if(index == 1) tf = alarmStatus1;
	else if(index == 2) tf = alarmStatus2;
	else if(index == 3) tf = alarmStatus3;
	int mask = [model alarmStatus:index];
	NSString* s = @"";
	if(mask & (1<<0))s = [s stringByAppendingString:@"HI Alarm\n"];
	if(mask & (1<<1))s = [s stringByAppendingString:@"A Alarm\n"];
	if(mask & (1<<2))s = [s stringByAppendingString:@"B Alarm\n"];
	if(mask & (1<<3))s = [s stringByAppendingString:@"LO Alarm\n"];
	if(mask & (1<<4))s = [s stringByAppendingString:@"RATE Alarm\n"];
	if(mask & (1<<5))s = [s stringByAppendingString:@"FILL Alarm\n"];
	if(mask & (1<<6))s = [s stringByAppendingString:@"EXPIRED Alarm\n"];
	if(mask & (1<<7))s = [s stringByAppendingString:@"CONTACT Alarm\n"];
	[tf setStringValue:s];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORAmi286Lock to:secure];
    [lockButton setEnabled:secure];
}

- (void) stateChanged:(NSNotification*)aNotification
{

//    BOOL runInProgress = [gOrcaGlobals runInProgress];
//    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORAmi286Lock];
    BOOL locked = [gSecurity isLocked:ORAmi286Lock];

    [lockButton setState: locked];

    [enabledMaskMatrix setEnabled:!locked];
    [portListPopup setEnabled:!locked];
    [openPortButton setEnabled:!locked];
    [pollTimePopup setEnabled:!locked];
    [shipLevelsButton setEnabled:!locked];

	int i;
	unsigned char aMask = [model enabledMask];
	for(i=0;i<4;i++){
		if(aMask & (1<<i)){
			[[lowAlarmMatrix cellWithTag:i] setEnabled:!locked];
			[[hiAlarmMatrix cellWithTag:i] setEnabled:!locked];
		}
		else {
			[[lowAlarmMatrix cellWithTag:i] setEnabled:NO];
			[[hiAlarmMatrix cellWithTag:i] setEnabled:NO];
		}
	}
}

- (void) portStateChanged:(NSNotification*)aNotification
{
    if(aNotification == nil || [aNotification object] == [model serialPort]){
        if([model serialPort]){
            [openPortButton setEnabled:YES];

            if([[model serialPort] isOpen]){
                [openPortButton setTitle:@"Close"];
                [portStateField setTextColor:[NSColor colorWithCalibratedRed:0.0 green:.8 blue:0.0 alpha:1.0]];
                [portStateField setStringValue:@"Open"];
            }
            else {
                [openPortButton setTitle:@"Open"];
                [portStateField setStringValue:@"Closed"];
                [portStateField setTextColor:[NSColor redColor]];
            }
        }
        else {
            [openPortButton setEnabled:NO];
            [portStateField setTextColor:[NSColor blackColor]];
            [portStateField setStringValue:@"---"];
            [openPortButton setTitle:@"---"];
        }
    }
}

- (void) pollTimeChanged:(NSNotification*)aNotification
{
	[pollTimePopup selectItemWithTag:[model pollTime]];
}

- (void) portNameChanged:(NSNotification*)aNotification
{
    NSString* portName = [model portName];
    
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;

    [portListPopup selectItemAtIndex:0]; //the default
    while (aPort = [enumerator nextObject]) {
        if([portName isEqualToString:[aPort name]]){
            [portListPopup selectItemWithTitle:portName];
            break;
        }
	}  
    [self portStateChanged:nil];
}

- (void) updateTank:(int)index
{
	switch(index){
		case 0: [monitor0 setNeedsDisplay:YES]; break;
		case 1: [monitor1 setNeedsDisplay:YES]; break;
		case 2: [monitor2 setNeedsDisplay:YES]; break;
		case 3: [monitor3 setNeedsDisplay:YES]; break;
	}
}


#pragma mark ***Actions
- (IBAction) loadHardwareAction:(id)sender;
{
	NS_DURING
		[self endEditing];
		[model loadHardware];
	NS_HANDLER
	NS_ENDHANDLER
}

- (IBAction) fillStateAction:(id)sender;
{
	if([model fillState:[sender tag]] != [sender indexOfSelectedItem]){
		[model setFillState:[sender tag] value:[sender indexOfSelectedItem]];
	}
}


- (IBAction) hiAlarmAction:(id)sender
{
	int index = [[hiAlarmMatrix selectedCell] tag];
	[model setHiAlarmLevel:index value:[sender floatValue]];
	[self updateTank:index];
}

- (IBAction) lowAlarmAction:(id)sender
{
	int index = [[lowAlarmMatrix selectedCell] tag];
	[model setLowAlarmLevel:index value:[sender floatValue]];
	[self updateTank:index];
}

- (void) enabledMaskAction:(id)sender
{
	int i;
	unsigned char aMask = 0;
	for(i=0;i<4;i++){
		if([[enabledMaskMatrix cellWithTag:i] intValue]) aMask |= (1<<i);
	}
	[model setEnabledMask:aMask];	
}

- (void) shipLevelsAction:(id)sender
{
	[model setShipLevels:[sender intValue]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORAmi286Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

- (IBAction) readLevelsAction:(id)sender
{
	[model readLevels];
}

- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:[[sender selectedItem] tag]];
}

#pragma mark ���Data Source
- (BOOL) willSupplyColors
{
	return YES;
}

- (NSColor*) colorForDataSet:(int)set
{
	if(set==0)return [NSColor redColor];
	else if(set==1)return [NSColor orangeColor];
	else if(set==2)return [NSColor blueColor];
	else return [NSColor blackColor];
}


- (int) numberOfDataSetsInPlot:(id)aPlotter
{
    return 4;
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	if(aPlotter == plotter0) return [[model timeRate:set] count];
	else return 0;
}

- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
	if(aPlotter == plotter0){
		int count = [[model timeRate:set] count];
		return [[model timeRate:set] valueAtIndex:count-x-1];
	}
	else return 0;
}

- (unsigned long)  	secondsPerUnit:(id) aPlotter
{
	return [[model timeRate:0] sampleTime]; //all should be the same, just return value for rate 0
}

- (void) setLevelMonitor:(ORLevelMonitor*)aMonitor lowAlarm:(float)aValue
{
	if(aMonitor == monitor0)[model setLowAlarmLevel:0 value:aValue];
	else if(aMonitor == monitor1)[model setLowAlarmLevel:1 value:aValue];
	else if(aMonitor == monitor2)[model setLowAlarmLevel:2 value:aValue];
	else if(aMonitor == monitor3)[model setLowAlarmLevel:3 value:aValue];
	[self scheduledUpdate]; //force update now
}

- (void) setLevelMonitor:(ORLevelMonitor*)aMonitor hiAlarm:(float)aValue
{
	if(aMonitor == monitor0)[model setHiAlarmLevel:0 value:aValue];
	else if(aMonitor == monitor1)[model setHiAlarmLevel:1 value:aValue];
	else if(aMonitor == monitor2)[model setHiAlarmLevel:2 value:aValue];
	else if(aMonitor == monitor3)[model setHiAlarmLevel:3 value:aValue];
	[self scheduledUpdate]; //force update now
}

- (float) levelMonitorHiAlarmLevel:(id)aLevelMonitor
{
	if(aLevelMonitor == monitor0)      return [model hiAlarmLevel:0];
	else if(aLevelMonitor == monitor1) return [model hiAlarmLevel:1];
	else if(aLevelMonitor == monitor2) return [model hiAlarmLevel:2];
	else if(aLevelMonitor == monitor3) return [model hiAlarmLevel:3];
	else return 0;
}
- (float) levelMonitorLowAlarmLevel:(id)aLevelMonitor
{
	if(aLevelMonitor == monitor0)      return [model lowAlarmLevel:0];
	else if(aLevelMonitor == monitor1) return [model lowAlarmLevel:1];
	else if(aLevelMonitor == monitor2) return [model lowAlarmLevel:2];
	else if(aLevelMonitor == monitor3) return [model lowAlarmLevel:3];
	else return 0;
}
- (float) levelMonitorLevel:(id)aLevelMonitor
{
	if(aLevelMonitor == monitor0)      return [model level:0];
	else if(aLevelMonitor == monitor1) return [model level:1];
	else if(aLevelMonitor == monitor2) return [model level:2];
	else if(aLevelMonitor == monitor3) return [model level:3];
	else return 0;
}

@end

@implementation ORAmi286Controller (private)

- (void) populatePortListPopup
{
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;
    [portListPopup removeAllItems];
    [portListPopup addItemWithTitle:@"--"];

	while (aPort = [enumerator nextObject]) {
        [portListPopup addItemWithTitle:[aPort name]];
	}    
}
@end

