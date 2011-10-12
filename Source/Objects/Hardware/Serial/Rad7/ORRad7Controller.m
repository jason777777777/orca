//--------------------------------------------------------
// ORRad7Controller
// Created by Mark  A. Howe on Fri Jul 22 2005
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

#import "ORRad7Controller.h"
#import "ORRad7Model.h"
#import "ORTimeSeriesPlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"

@interface ORRad7Controller (private)
- (void) populatePortListPopup;
- (void) saveUserSettingPanelDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info;
- (void) loadDialogFromHWPanelDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info;
- (void) eraseAllDataPanelDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info;
@end

@implementation ORRad7Controller

#pragma mark ***Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"Rad7"];
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib
{
    [self populatePortListPopup];
    [[plotter0 yAxis] setRngLow:0.0 withHigh:300.];
	[[plotter0 yAxis] setRngLimitsLow:-300.0 withHigh:500 withMinRng:4];

    [[plotter0 xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter0 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];

	ORTimeSeriesPlot* aPlot;
	aPlot= [[ORTimeSeriesPlot alloc] initWithTag:0 andDataSource:self];
	[plotter0 addPlot: aPlot];
	[aPlot release];

	ORTimeSeriesPlot* aPlot1;
	aPlot1= [[ORTimeSeriesPlot alloc] initWithTag:1 andDataSource:self];
	[aPlot1 setLineColor:[NSColor blueColor]];
	[plotter0 addPlot: aPlot1];
	[aPlot1 release];

	[super awakeFromNib];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Rad7 (Unit %d)",[model uniqueIdNumber]]];
}

#pragma mark ***Notifications

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRad7Lock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORRad7ModelPortNameChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];
                                              
    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORRad7ModelPollTimeChanged
                       object : nil];


    [notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];

    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(protocolChanged:)
                         name : ORRad7ModelProtocolChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cycleTimeChanged:)
                         name : ORRad7ModelCycleTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(recycleChanged:)
                         name : ORRad7ModelRecycleChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(modeChanged:)
                         name : ORRad7ModelModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(thoronChanged:)
                         name : ORRad7ModelThoronChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pumpModeChanged:)
                         name : ORRad7ModelPumpModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(toneChanged:)
                         name : ORRad7ModelToneChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(formatChanged:)
                         name : ORRad7ModelFormatChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(tUnitsChanged:)
                         name : ORRad7ModelTUnitsChanged
						object: model];


    [notifyCenter addObserver : self
                     selector : @selector(rUnitsChanged:)
                         name : ORRad7ModelRUnitsChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(operationStateChanged:)
                         name : ORRad7ModelOperationStateChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(statusChanged:)
                         name : ORRad7ModelStatusChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(runStateChanged:)
                         name : ORRad7ModelRunStateChanged
						object: model];
    [notifyCenter addObserver : self
                     selector : @selector(updatePlot:)
                         name : ORRad7ModelUpdatePlot
						object: model];	

    [notifyCenter addObserver : self
                     selector : @selector(updatePlot:)
                         name : ORRad7ModelDataPointArrayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(runToPrintChanged:)
                         name : ORRad7ModelRunToPrintChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(deleteDataOnStartChanged:)
                         name : ORRad7ModelDeleteDataOnStartChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(verboseChanged:)
                         name : ORRad7ModelVerboseChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(makeFileChanged:)
                         name : ORRad7ModelMakeFileChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(maxRadonChanged:)
                         name : ORRad7ModelMaxRadonChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(alarmLimitChanged:)
                         name : ORRad7ModelAlarmLimitChanged
						object: model];

}

- (void) updateWindow
{
    [super updateWindow];
    [self lockChanged:nil];
    [self portStateChanged:nil];
    [self portNameChanged:nil];
	[self pollTimeChanged:nil];
    [self miscAttributesChanged:nil];
	[self protocolChanged:nil];
	[self cycleTimeChanged:nil];
	[self recycleChanged:nil];
	[self modeChanged:nil];
	[self thoronChanged:nil];
	[self pumpModeChanged:nil];
	[self toneChanged:nil];
	[self formatChanged:nil];
	[self tUnitsChanged:nil];
	[self rUnitsChanged:nil];
	[self statusChanged:nil];
	[self operationStateChanged:nil];
	[self runStateChanged:nil];
	[self updatePlot:nil];
	[self runToPrintChanged:nil];
	[self deleteDataOnStartChanged:nil];
	[self verboseChanged:nil];
	[self makeFileChanged:nil];
	[self maxRadonChanged:nil];
	[self alarmLimitChanged:nil];
}

- (void) alarmLimitChanged:(NSNotification*)aNote
{
	[alarmLimitTextField setIntValue: [model alarmLimit]];
}

- (void) maxRadonChanged:(NSNotification*)aNote
{
	[maxRadonTextField setIntValue: [model maxRadon]];
}

- (void) makeFileChanged:(NSNotification*)aNote
{
	[makeFileCB setIntValue: [model makeFile]];
}

- (void) verboseChanged:(NSNotification*)aNote
{
	[verboseCB setIntValue: [model verbose]];
}

- (void) deleteDataOnStartChanged:(NSNotification*)aNote
{
	[deleteDataOnStartCB setIntValue: [model deleteDataOnStart]];
}

- (void) runToPrintChanged:(NSNotification*)aNote
{
	[runToPrintTextField setIntValue: [model runToPrint]];
}

- (void) updatePlot:(NSNotification*)aNote
{
	[plotter0 setNeedsDisplay:YES];
}

- (void) runStateChanged:(NSNotification*)aNote
{
	[self updateButtons];
}

- (void) statusChanged:(NSNotification*)aNote
{	
	[stateField setObjectValue:      [model statusForKey:kRad7RunStatus]];
	[runNumberField setObjectValue:  [model statusForKey:kRad7RunNumber]];
	[cycleNumberField setObjectValue:[model statusForKey:kRad7CycleNumber]];
	[pumpModeField setObjectValue:	 [model statusForKey:kRad7RunPumpStatus]];
	[countDownField setObjectValue:	 [model statusForKey:kRad7RunCountDown]];
	[countsField setObjectValue:	 [model statusForKey:kRad7NumberCounts]];
	[freeCyclesField setObjectValue: [model statusForKey:kRad7FreeCycles]];
	[lastRunNumberField setObjectValue:  [model statusForKey:kRad7LastRunNumber]];
	[lastCycleNumberField setObjectValue:[model statusForKey:kRad7LastCycleNumber]];
	[lastRadonField setObjectValue:[model statusForKey:kRad7LastRadon]];
	[lastRadonUnitsField setObjectValue:[model statusForKey:kRad7LastRadonUnits]];
	[processUnitsField setObjectValue:[model statusForKey:kRad7LastRadonUnits]];
	[lastRadonUncertaintyFieldField setObjectValue:[model statusForKey:kRad7LastRadonUncertainty]];

	
	[temperatureField setObjectValue:[model statusForKey:kRad7Temp]];
	[temperatureUnitsField setObjectValue:[model statusForKey:kRad7TempUnits]];
	[rhField setObjectValue:[model statusForKey:kRad7RH]];
	[batteryField setObjectValue:[model statusForKey:kRad7Battery]];
	[pumpCurrentField setObjectValue:[model statusForKey:kRad7PumpCurrent]];
	[hvField setObjectValue:[model statusForKey:kRad7HV]];
	[signalField setObjectValue:[model statusForKey:kRad7SignalVoltage]];
}


- (void) operationStateChanged:(NSNotification*)aNote
{
	[operationStateField setStringValue: [model operationStateString]];
	[self updateButtons];
}

- (void) tUnitsChanged:(NSNotification*)aNote
{
	[tUnitsPU selectItemAtIndex: [model tUnits]];
}

- (void) rUnitsChanged:(NSNotification*)aNote
{
	[rUnitsPU selectItemAtIndex: [model rUnits]];
}

- (void) formatChanged:(NSNotification*)aNote
{
	[formatPU selectItemAtIndex: [model formatSetting]];
}

- (void) toneChanged:(NSNotification*)aNote
{
	[tonePU selectItemAtIndex: [model tone]];
}

- (void) pumpModeChanged:(NSNotification*)aNote
{
	[pumpModePU selectItemAtIndex: [model pumpMode]];
}

- (void) thoronChanged:(NSNotification*)aNote
{
	[thoronPU selectItemAtIndex: [model thoron]];
}

- (void) modeChanged:(NSNotification*)aNote
{
	[modePU selectItemAtIndex: [model mode]];
}

- (void) recycleChanged:(NSNotification*)aNote
{
	[recycleTextField setIntValue: [model recycle]];
}

- (void) cycleTimeChanged:(NSNotification*)aNote
{
	[cycleTimeTextField setIntValue: [model cycleTime]];
}

- (void) protocolChanged:(NSNotification*)aNote
{
	[protocolPU selectItemAtIndex: [model protocol]];
	if([model protocol] == kRad7ProtocolNone)		[protocolTabView selectTabViewItemAtIndex:0];
	else if([model protocol] == kRad7ProtocolUser)	[protocolTabView selectTabViewItemAtIndex:1];
	else											[protocolTabView selectTabViewItemAtIndex:2];
	[self updateButtons];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [plotter0 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 xAxis]attributes] forKey:@"XAttributes0"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter0 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 yAxis]attributes] forKey:@"YAttributes0"];
	};
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{

	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 xAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 yAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 yAxis] setNeedsDisplay:YES];
		}
	}
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORRad7Lock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}

- (void) updateButtons
{
    BOOL locked = [gSecurity isLocked:ORRad7Lock];

    [lockButton setState: locked];

    [portListPopup setEnabled:!locked];
    [openPortButton setEnabled:!locked];
    [pollTimePopup setEnabled:!locked];
    

	//int opState = [model operationState];
	int runState = [model runState];
	//BOOL idle = (opState==kRad7Idle);
	BOOL counting = runState == kRad7RunStateCounting;
	if(!locked){
		if(runState== kRad7RunStateUnKnown){
			[startTestButton	setEnabled:	 NO];
			[stopTestButton		setEnabled:  NO];
			[eraseAllDataButton setEnabled:  NO];
			[printRunButton		setEnabled:  NO];
			[printCycleButton	setEnabled:  NO];
			[runToPrintTextField setEnabled:  NO];
			[deleteDataOnStartCB setEnabled:  NO];
			[verboseCB			 setEnabled:  NO];
			[makeFileCB			 setEnabled:  NO];
			[loadDialogButton	setEnabled:  NO];
		}
		else if(runState== kRad7RunStateCounting){
			[startTestButton	setEnabled:	 NO];
			[stopTestButton		setEnabled:  YES];
			[eraseAllDataButton setEnabled:  NO];
			[printRunButton		setEnabled:  NO];
			[printCycleButton	setEnabled:  YES];
			[runToPrintTextField setEnabled:  NO];
			[deleteDataOnStartCB setEnabled:  NO];
			[verboseCB			 setEnabled:  YES];
			[makeFileCB			 setEnabled:  YES];
			[loadDialogButton	setEnabled:  NO];
		}
		else {
			[startTestButton	setEnabled:	 YES];
			[stopTestButton		setEnabled:  NO];
			[eraseAllDataButton setEnabled:  YES];
			[printRunButton		setEnabled:  YES];
			[printCycleButton	setEnabled:  NO];
			[runToPrintTextField setEnabled: YES];
			[deleteDataOnStartCB setEnabled: YES];
			[verboseCB			 setEnabled:  NO];
			[makeFileCB			 setEnabled:  NO];
			[loadDialogButton	setEnabled:  YES];
		}
	}
	else {
		[startTestButton	setEnabled:	 NO];
		[stopTestButton		setEnabled:  NO];
		[eraseAllDataButton setEnabled:  NO];
		[printRunButton		setEnabled:  NO];
		[printCycleButton	setEnabled:  NO];
		[runToPrintTextField setEnabled:  NO];
		[deleteDataOnStartCB setEnabled:  NO];
		[verboseCB			 setEnabled:  NO];
		[makeFileCB			 setEnabled:  NO];
		[loadDialogButton	setEnabled:  NO];
	}
	
	//[initHWButton		setEnabled:  !counting && idle && !locked];
	
	[rUnitsPU setEnabled:	!counting && !locked];
	[tUnitsPU setEnabled:	!counting && !locked];
	[formatPU setEnabled:	!counting && !locked];
	[tonePU setEnabled:		!counting && !locked];
	[protocolPU setEnabled:	!counting && !locked];
	
	[saveUserProtocolButton setEnabled:[model protocol] == kRad7ProtocolNone];

	[alarmLimitTextField setEnabled:!locked];
	[maxRadonTextField setEnabled:	!locked];

	
	if([model protocol] == kRad7ProtocolUser || [model protocol] == kRad7ProtocolNone){
		[pumpModePU setEnabled:	!counting && !locked];
		[thoronPU setEnabled:	!counting && !locked];
		[modePU setEnabled:		!counting && !locked];
		[recycleTextField setEnabled: !counting && !locked];
		[cycleTimeTextField setEnabled: !counting && !locked];
		
	}
	else {
		switch([model protocol]){
			case kRad7ProtocolNone: 
				break;
				
			case kRad7ProtocolSniff:
				[useCycleField setObjectValue:		@"5"];
				[userRecycleField setObjectValue:	@"0"];
				[userModeField setObjectValue:		@"Sniff"];
				[userThoronField setObjectValue:	@"Off"];
				[userPumpModeField setObjectValue:	@"Auto"];
				break;
				
			case kRad7Protocol1Day:
				[useCycleField setObjectValue:		@"30"];
				[userRecycleField setObjectValue:	@"48"];
				[userModeField setObjectValue:		@"Auto"];
				[userThoronField setObjectValue:	@"Off"];
				[userPumpModeField setObjectValue:	@"Auto"];
				break;
				
			case kRad7Protocol2Day:
				[useCycleField setObjectValue:		@"60"];
				[userRecycleField setObjectValue:	@"48"];
				[userModeField setObjectValue:		@"Auto"];
				[userThoronField setObjectValue:	@"Off"];
				[userPumpModeField setObjectValue:	@"Auto"];
				break;
				
			case kRad7ProtocolWeeks:
				[useCycleField setObjectValue:		@"60"];
				[userRecycleField setObjectValue:	@"48"];
				[userModeField setObjectValue:		@"Auto"];
				[userThoronField setObjectValue:	@"Off"];
				[userPumpModeField setObjectValue:	@"Auto"];
				break;
				
			case kRad7ProtocolUser:
				break;
				
			case kRad7ProtocolGrab:
				[useCycleField setObjectValue:		@"5"];
				[userRecycleField setObjectValue:	@"4"];
				[userModeField setObjectValue:		@"Sniff"];
				[userThoronField setObjectValue:	@"Off"];
				[userPumpModeField setObjectValue:	@"Grab"];
				break;
				
			case kRad7ProtocolWat40:
				[useCycleField setObjectValue:		@"5"];
				[userRecycleField setObjectValue:	@"4"];
				[userModeField setObjectValue:		@"Wat-40"];
				[userThoronField setObjectValue:	@"Off"];
				[userPumpModeField setObjectValue:	@"Grab"];
				break;
				
			case kRad7ProtocolWat250:
				[useCycleField setObjectValue:		@"5"];
				[userRecycleField setObjectValue:	@"4"];
				[userModeField setObjectValue:		@"Wat250"];
				[userThoronField setObjectValue:	@"Off"];
				[userPumpModeField setObjectValue:	@"Grab"];
				break;
				
			case kRad7ProtocolThoron:
				[useCycleField setObjectValue:		@"5"];
				[userRecycleField setObjectValue:	@"0"];
				[userModeField setObjectValue:		@"Sniff"];
				[userThoronField setObjectValue:	@"On"];
				[userPumpModeField setObjectValue:	@"Auto"];
				break;
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


#pragma mark ***Actions

- (void) alarmLimitTextFieldAction:(id)sender
{
	[model setAlarmLimit:[sender intValue]];	
}

- (void) maxRadonTextFieldAction:(id)sender
{
	[model setMaxRadon:[sender intValue]];	
}

- (void) makeFileAction:(id)sender
{
	[model setMakeFile:[sender intValue]];	
}

- (void) verboseAction:(id)sender
{
	[model setVerbose:[sender intValue]];	
}

- (void) deleteDataOnStartAction:(id)sender
{
	[model setDeleteDataOnStart:[sender intValue]];	
}

- (void) runToPrintTextFieldAction:(id)sender
{
	[model setRunToPrint:[sender intValue]];	
}

- (void) tUnitsAction:(id)sender
{
	[model setTUnits:[sender indexOfSelectedItem]];	
}

- (void) rUnitsAction:(id)sender
{
	[model setRUnits:[sender indexOfSelectedItem]];	
}

- (void) formatAction:(id)sender
{
	[model setFormatSetting:[sender indexOfSelectedItem]];	
}

- (void) toneAction:(id)sender
{
	[model setTone:[sender indexOfSelectedItem]];	
}

- (void) pumpModeAction:(id)sender
{
	[model setPumpMode:[sender indexOfSelectedItem]];	
}

- (void) thoronAction:(id)sender
{
	[model setThoron:[sender indexOfSelectedItem]];	
}

- (void) modeAction:(id)sender
{
	[model setMode:[sender indexOfSelectedItem]];	
}

- (void) recycleTextFieldAction:(id)sender
{
	[model setRecycle:[sender intValue]];	
}

- (void) cycleTimeTextFieldAction:(id)sender
{
	[model setCycleTime:[sender intValue]];	
}

- (void) protocolAction:(id)sender
{
	[model setProtocol:[sender indexOfSelectedItem]];	
}


- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORRad7Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

- (IBAction) updateSettingsAction:(id)sender
{
	
	NSBeginAlertSheet(@"Load Dialog With Hardware Settings",
					  @"YES/Do it NOW",
					  @"Cancel",
					  nil,
					  [self window],
					  self,
					  @selector(loadDialogFromHWPanelDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"Really replace the settings in the dialog with the current HW settings?");
	
}

- (IBAction) eraseAllDataAction:(id)sender
{
	
	NSBeginAlertSheet(@"Erase All Data",
					  @"YES/Do it NOW",
					  @"Cancel",
					  nil,
					  [self window],
					  self,
					  @selector(eraseAllDataPanelDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"Really erase ALL data?");
	
}

- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:[[sender selectedItem] tag]];
}

- (IBAction) initAction:(id)sender
{
	[model initHardware];
}

- (IBAction) getStatusAction:(id)sender
{
	[model pollHardware];
}

- (IBAction) startAction:(id)sender
{
	[self endEditing];
	[startTestButton setEnabled:NO];
	[stopTestButton setEnabled:NO];
	[model performSelector:@selector(specialStart) withObject:nil afterDelay:0];
}

- (IBAction) stopAction:(id)sender
{
	[startTestButton setEnabled:NO];
	[stopTestButton setEnabled:NO];
	[model performSelector:@selector(specialStop) withObject:nil afterDelay:0];
}

- (IBAction) saveUserSettings:(id)sender;
{
	NSBeginAlertSheet(@"Save Settings As New User Protocol",
					  @"YES/Do it NOW",
					  @"Cancel",
					  nil,
					  [self window],
					  self,
					  @selector(saveUserSettingPanelDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"Really make the current settings the new user protocol?");
}

- (IBAction) dumpUserValuesAction:(id)sender
{
	[model dumpUserValues];
}

- (IBAction) printRunAction:(id)sender
{
	[self endEditing];
	[model printRun];
}

- (IBAction) printDataInProgress:(id)sender
{
	[model printDataInProgress];
}

#pragma mark ***Data Source
- (int) numberPointsInPlot:(id)aPlot
{
	return [model numPoints];
}

- (double) plotterStartTime:(id)aPlot
{
	return [model radonTime:0];
}

- (void) plotter:(id)aPlot index:(int)i x:(double*)xValue y:(double*)yValue
{
	int theTag = [aPlot tag];
	*xValue = [model radonTime:i];
	if(theTag == 0)		 *yValue = [model radonValue:i];
	else                 *yValue = [model rhValue:i];
}

@end

@implementation ORRad7Controller (private)

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

- (void) saveUserSettingPanelDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info
{
	[model saveUser];
}

- (void) loadDialogFromHWPanelDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info
{
	[model loadDialogFromHardware];
}

- (void) eraseAllDataPanelDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info
{
	[model dataErase];
}

@end

