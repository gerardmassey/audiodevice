#import <Foundation/Foundation.h>
#import "SSAudioDeviceCenter.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	SSAudioDeviceCenter* _deviceCenter = [[SSAudioDeviceCenter alloc] init];
		
	if (argc < 2) {
		printf("input: %s\noutput: %s\nsystem: %s\n", [[[_deviceCenter selectedInputDevice] name] UTF8String], [[[_deviceCenter selectedOutputDevice] name] UTF8String], [[[_deviceCenter selectedSystemDevice] name] UTF8String]);
	} else if (argc == 2) {
		if (strcmp(argv[1], "input") == 0) {
			printf("%s\n", [[[_deviceCenter selectedInputDevice] name] UTF8String]);
		} else if (strcmp(argv[1], "output") == 0) {
			printf("%s\n", [[[_deviceCenter selectedOutputDevice] name] UTF8String]);
		} else if (strcmp(argv[1], "system") == 0) {
			printf("%s\n", [[[_deviceCenter selectedSystemDevice] name] UTF8String]);
		} else {
			if (strcmp(argv[1], "-h") != 0 && strcmp(argv[1], "help") != 0)
				printf("invalid port!\n");
			printf("Usage:\naudiodevice   // list devices for input, output, and system audio\naudiodevice <port>   // display the audio device for the selected port\naudiodevice <port> list   // list available audio devices for the selected port\naudiodevice <port> <device>   // set the selected port to use the designated device (\"internal\" will select Internal Speakers or Headphones, whichever is active)\n");
			return 1;
		}
	} else if (argc == 3) {
		if (strcmp(argv[1], "input") == 0) {
			if (strcmp(argv[2], "list") == 0) {
				NSEnumerator *enumerator = [[_deviceCenter inputDevices] objectEnumerator];
				id item;
				while (item = [enumerator nextObject]) {
					printf("%s\n", [[item name] UTF8String]);
				}
			} else {
				NSEnumerator *enumerator = [[_deviceCenter inputDevices] objectEnumerator];
				id item;
				while (item = [enumerator nextObject]) {
					if (strcmp([[item name] UTF8String], argv[2]) == 0 || strcmp(argv[2], "internal") == 0) {
						SSAudioDevice* device = item;
						if( device && [device isKindOfClass: [SSAudioDevice class]] ) {
							[_deviceCenter setSelectedInputDevice: device];
							return 0;
						}
					}
				}
				printf("device not found!\n");
				return 1;
			}
		} else if (strcmp(argv[1], "output") == 0) {
			if (strcmp(argv[2], "list") == 0) {
				NSEnumerator *enumerator = [[_deviceCenter outputDevices] objectEnumerator];
				id item;
				while (item = [enumerator nextObject]) {
					printf("%s\n", [[item name] UTF8String]);
				}
			} else {
				NSEnumerator *enumerator = [[_deviceCenter outputDevices] objectEnumerator];
				id item;
				while (item = [enumerator nextObject]) {
					if (strcmp([[item name] UTF8String], argv[2]) == 0 || strcmp(argv[2], "internal") == 0) {
						SSAudioDevice* device = item;
						if( device && [device isKindOfClass: [SSAudioDevice class]] ) {
							[_deviceCenter setSelectedOutputDevice: device];
							return 0;
						}
					}
				}
				printf("device not found!\n");
				return 1;
			}
		} else if (strcmp(argv[1], "system") == 0) {
			if (strcmp(argv[2], "list") == 0) {
				NSEnumerator *enumerator = [[_deviceCenter outputDevices] objectEnumerator];
				id item;
				while (item = [enumerator nextObject]) {
					printf("%s\n", [[item name] UTF8String]);
				}
			} else {
				NSEnumerator *enumerator = [[_deviceCenter outputDevices] objectEnumerator];
				id item;
				while (item = [enumerator nextObject]) {
					if (strcmp([[item name] UTF8String], argv[2]) == 0 || strcmp(argv[2], "internal") == 0) {
						SSAudioDevice* device = item;
						if( device && [device isKindOfClass: [SSAudioDevice class]] ) {
							[_deviceCenter setSelectedSystemDevice: device];
							return 0;
						}
					}
				}
				printf("device not found!\n");
				return 1;
			}
		} else {
			printf("invalid port!\nUsage:\naudiodevice   // list devices for input, output, and system audio\naudiodevice <port>   // display the audio device for the selected port\naudiodevice <port> list   // list available audio devices for the selected port\naudiodevice <port> <device>   // set the selected port to use the designated device\n");
			return 1;
		}
	}
	
    [pool release];
    return 0;
}
