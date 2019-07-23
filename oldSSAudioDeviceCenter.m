//
//  SSAudioDeviceCenter.m
//  SoundSource
//
//  Created by Quentin Carnicelli on 3/23/06.
//  Copyright 2006 Rogue Amoeba Software, LLC. All rights reserved.
//

#import "SSAudioDeviceCenter.h"

@implementation SSAudioDevice

- (id)initWithAudioDeviceID: (AudioDeviceID)deviceID source: (OSType)source isInput: (BOOL)flag
{
	if( deviceID == kAudioDeviceUnknown )
	{
		[self release];
		return nil;
	}

	if( (self = [super init]) != nil )
	{
		_deviceID = deviceID;
		_sourceType = source;
		_isInput = flag;
		_name = nil;
	}
	
	return self;
}

- (void)dealloc
{
	[_name release];
	[super dealloc];
}

- (NSString*)description
{
	return [NSString stringWithFormat: @"<%@: %@ (%d)>", [self class], [self name], [self coreAudioDeviceID]];
}

- (BOOL)isEqual: (SSAudioDevice*)device
{
	return ([self coreAudioDeviceID] == [device coreAudioDeviceID]) &&
		   ([self coreAudioSourceType] == [device coreAudioSourceType]) &&
		   ([self coreAudioIsInput] == [device coreAudioIsInput]);
}

- (NSComparisonResult)compare: (SSAudioDevice*)device
{
	return [[self name] caseInsensitiveCompare: [device name]];
}

- (NSString*)name
{
	if( !_name )
	{
		OSType sourceType = [self coreAudioSourceType];
		OSStatus err;
		UInt32 size;
		NSString* deviceName = nil;
		NSString* sourceName = nil;

		{
			size = sizeof(deviceName);
			err = AudioDeviceGetProperty( [self coreAudioDeviceID], 0, [self coreAudioIsInput], kAudioDevicePropertyDeviceNameCFString, &size, &deviceName);
			if( err  )
				deviceName = nil;
		}

		if( sourceType != 0 )
		{
			AudioValueTranslation trans;

			trans.mInputData		= &sourceType;
			trans.mInputDataSize	= sizeof(sourceType);
			trans.mOutputData		= &sourceName;
			trans.mOutputDataSize	= sizeof(sourceName);
			size = sizeof(AudioValueTranslation);
			err = AudioDeviceGetProperty( [self coreAudioDeviceID] , 0, [self coreAudioIsInput], kAudioDevicePropertyDataSourceNameForIDCFString, &size, &trans);
			if( err )
				sourceName = nil;
		}
					
		if( sourceName )
			_name = sourceName;
		else
			_name = deviceName;
	}
	
	return _name;
}

- (BOOL)canBeDefaultDevice
{
	OSStatus err;
	UInt32 canBe;
	UInt32 size = sizeof(canBe);
	
	err = AudioDeviceGetProperty( [self coreAudioDeviceID], 0, [self coreAudioIsInput], kAudioDevicePropertyDeviceCanBeDefaultDevice, &size, &canBe);

	return (err == noErr) && (canBe == 1);
}

- (BOOL)canBeDefaultSystemDevice
{
	OSStatus err;
	UInt32 canBe;
	UInt32 size = sizeof(canBe);
	
	err = AudioDeviceGetProperty( [self coreAudioDeviceID], 0, [self coreAudioIsInput], kAudioDevicePropertyDeviceCanBeDefaultSystemDevice, &size, &canBe);

	return (err == noErr) && (canBe == 1);
}

- (AudioDeviceID)coreAudioDeviceID
{
	return _deviceID;
}

- (OSType)coreAudioSourceType
{
	return _sourceType;
}

- (BOOL)coreAudioIsInput
{
	return _isInput;
}

@end

#pragma mark -

@implementation SSAudioDeviceCenter

- (id)init
{
	if( (self = [super init]) != nil )
	{
	}
	
	return self;
}

- (NSArray*)_allDevicesWithDeviceID: (AudioDeviceID)deviceID isInput: (BOOL)isInput
{
	NSMutableArray* objList = [NSMutableArray array];
	OSStatus		err;
	UInt32			size;
	int				i, count;
	OSType			*list;
	SSAudioDevice	*device;

	if( !AudioDeviceGetPropertyInfo(deviceID, 0, isInput, kAudioDevicePropertyDataSources, &size, NULL) )
	{
		count	= size / sizeof(OSType);
		if( count )
		{
			list	= alloca(size);
			if( !AudioDeviceGetProperty(deviceID, 0, isInput, kAudioDevicePropertyDataSources, &size, list))
			{
				for (i = 0; i < count; i++)
				{
					device = [[SSAudioDevice alloc] initWithAudioDeviceID: deviceID source: list[i] isInput: isInput];
					[objList addObject: device];
					[device release];
				}
			}
		}
	}

	if( ![objList count] )
	{
		device = [[SSAudioDevice alloc] initWithAudioDeviceID: deviceID source: 0 isInput: isInput];
		[objList addObject: device];
		[device release];
	}
	
	return objList;
}

- (NSArray*)_loadDeviceList: (BOOL)isInput
{
	NSMutableArray* deviceList = [NSMutableArray array];
	UInt32			size;
	int				i, count;
	AudioDeviceID*	list;
	NSArray*		tmpList;

	if (AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &size, NULL))
		return nil;

	count	= size / sizeof(AudioDeviceID);
	list	= (AudioDeviceID *) alloca(count * sizeof(AudioDeviceID));
	if (AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &size, list))
		return nil;

	for (i = 0; i < count; i++)
	{
		if (!AudioDeviceGetPropertyInfo(list[i], 0, isInput, kAudioDevicePropertyStreamConfiguration,  &size, NULL))
		{
			AudioBufferList* bufferList = (AudioBufferList*)malloc(size);
			
			if (!AudioDeviceGetProperty(list[i], 0, isInput, kAudioDevicePropertyStreamConfiguration, &size, bufferList))
			{
				if (bufferList->mNumberBuffers)
				{
					tmpList = [self _allDevicesWithDeviceID: list[i] isInput: isInput];
					if( tmpList )
						[deviceList addObjectsFromArray: tmpList];
				}
			}
		
			free( bufferList );
		}
	}

	return deviceList;
}

- (NSArray*)inputDevices
{
	return [self _loadDeviceList: YES];
}

- (NSArray*)outputDevices
{
	return [self _loadDeviceList: NO];
}

- (SSAudioDevice*)deviceWithID: (AudioDeviceID)deviceID isInput: (BOOL)isInput
{
	NSArray* deviceList = isInput ? [self inputDevices] : [self outputDevices];
	NSEnumerator* deviceEnum = [deviceList objectEnumerator];
	SSAudioDevice* device;
	
	while( (device = [deviceEnum nextObject]) != nil )
	{
		if( [device coreAudioDeviceID] == deviceID )
			return device;
	}

	return nil;
}

#pragma mark -

- (OSStatus)_setDefaultDeviceOfClass: (OSType)type to: (SSAudioDevice*)device
{
	AudioDeviceID deviceID = [device coreAudioDeviceID];
	OSStatus err;

	if( device == nil || deviceID == kAudioDeviceUnknown )
		return paramErr;

	err = AudioHardwareSetProperty(type, sizeof(deviceID), &deviceID);
	if( err )
	{
		NSLog( @"AudioHardwareSetProperty(%X): %d", type, err );
	}
	
	return err;
}

- (SSAudioDevice*)_defaultDeviceOfClass: (OSType)type
{
	SSAudioDevice*	device;
	AudioDeviceID	deviceID = kAudioDeviceUnknown;
	UInt32			size;
	
	size	= sizeof(deviceID);
	if( AudioHardwareGetProperty(type, &size, &deviceID) != noErr )
		return nil;
	if( deviceID == kAudioDeviceUnknown )
		return nil;

	device = [self deviceWithID: deviceID isInput: (type == kAudioHardwarePropertyDefaultInputDevice)];
	return device;
}

- (void)setSelectedInputDevice: (SSAudioDevice*)device
{
	[self _setDefaultDeviceOfClass: kAudioHardwarePropertyDefaultInputDevice to: device];
}

- (SSAudioDevice*)selectedInputDevice
{
	return [self _defaultDeviceOfClass: kAudioHardwarePropertyDefaultInputDevice];
}

- (void)setSelectedOutputDevice: (SSAudioDevice*)device
{
	[self _setDefaultDeviceOfClass: kAudioHardwarePropertyDefaultOutputDevice to: device];
}

- (SSAudioDevice*)selectedOutputDevice
{
	return [self _defaultDeviceOfClass: kAudioHardwarePropertyDefaultOutputDevice];
}

- (void)setSelectedSystemDevice: (SSAudioDevice*)device
{
	[self _setDefaultDeviceOfClass: kAudioHardwarePropertyDefaultSystemOutputDevice to: device];
}

- (SSAudioDevice*)selectedSystemDevice
{
	return [self _defaultDeviceOfClass: kAudioHardwarePropertyDefaultSystemOutputDevice];
}

@end
