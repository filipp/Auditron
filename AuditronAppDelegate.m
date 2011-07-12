//
//  AuditronAppDelegate.m
//  Auditron
//
//  Created by Filipp Lepalaan on 9.7.2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AuditronAppDelegate.h"

@implementation AuditronAppDelegate

@synthesize window;

-(void) savePanelDidEnd:(NSSavePanel *)savePanel returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	
	if (returnCode == NSOKButton) {
		
		NSFileManager *fm = [NSFileManager defaultManager];
		[fm moveItemAtPath:[self reportFile] toPath:[savePanel filename] error:NULL];
		
	}

}

-(void) saveResultsPanelDidEnd:(NSSavePanel *)savePanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
	if (returnCode == NSOKButton)
	{	
		NSString *filePath = [savePanel filename];
		NSArray *data = [self comparisonData];
		NSUInteger i, count = [data count];
		NSString *csv = [NSString stringWithString:@""];
		
		for (i = 0; i < count; i++)
		{
			NSDictionary *obj = [data objectAtIndex:i];
			NSString *csvRow = [NSString stringWithString:@"\""];
			csvRow = [csvRow stringByAppendingString:[[obj allValues] componentsJoinedByString:@"\";\""]];
			csv = [csv stringByAppendingString:[csvRow stringByAppendingString:@"\"\n"]];
		}
		
		[csv writeToFile:filePath atomically:YES 
				encoding:NSUnicodeStringEncoding 
				   error:NULL];
	}
	
}

-(void)setRecipientName:(NSString *)newName
{
	newName = [newName copy];
	[recipientName release];
	recipientName = newName;
}

-(void)setRecipientEmail:(NSString *)newEmail
{
	newEmail = [newEmail copy];
	[recipientEmail release];
	recipientEmail = newEmail;
}

-(NSString *)recipientName
{
	return recipientName;
}

-(NSString *)recipientEmail
{
	return recipientEmail;
}

-(void) sheetDidEnd:(NSWindow *)aSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	
	
}

-(void) prefsSheetDidEnd:(NSWindow *)aSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{

}

-(void) sendmail
{
	NSDictionary *errorDict;
	NSAppleEventDescriptor* returnDescriptor = NULL;
	
	NSString *subject = [NSString stringWithFormat:@"System Profiler Report for %@", hostName];
	
	NSString *source;
	
	if ([mailer isEqualToString:@"com.apple.mail"])
	{
		source = [NSString stringWithFormat:
				  @"tell application \"Mail\"\n\
				  set theMessage to make new outgoing message with properties {visible:true, subject:\"%@\", content:\"\"}\n\
				  tell theMessage\n\
				  make new to recipient at end of to recipients with properties {name:\"%@\", address:\"%@\"}\n\
				  end tell\n\
				  tell content of theMessage\n\
				  make new attachment with properties {file name:\"%@\"}\n\
				  end tell\n\
				  activate\n\
				  end tell", subject, [self recipientName], [self recipientEmail], reportFile];
	}
	else if ([mailer isEqualToString:@"com.microsoft.entourage"])
	{
		source = [NSString stringWithFormat:
				  @"tell application \"Microsoft Entourage\"\n\
				  set theRecipients to {{address:{display name:\"%@\", address:\"%@\"}, recipient type:to recipient}}\n\
				  set theMessage to make new outgoing message with properties {recipient:theRecipients, subject:\"%@\", attachment:{file:(POSIX file \"%@\")}}\n\
				  open theMessage\n\
				  activate\n\
				  end tell", [self recipientName], [self recipientEmail], subject, reportFile];
	} else {
		
		NSLog(@"Unsupported mailer: %@", mailer);
		
		NSSavePanel *panel = [NSSavePanel savePanel];
		[panel setCanCreateDirectories:YES];
		NSString *fileName = [NSString stringWithFormat:@"%@.spx.gz", hostName];
		[panel setNameFieldStringValue:fileName];
		[panel beginSheetForDirectory:nil
								 file:fileName
					   modalForWindow:window
						modalDelegate:self didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
						  contextInfo:NULL];
	}
	
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource:source];
	
	returnDescriptor = [as executeAndReturnError: &errorDict];
	[as release];
	
	if (returnDescriptor != NULL)
	{
		// successful execution
		if (kAENullEvent != [returnDescriptor descriptorType])
		{
			// script returned an AppleScript result
			if (cAEList == [returnDescriptor descriptorType])
			{
				// result is a list of other descriptors
			}
			else
			{
				// coerce the result to the appropriate ObjC type
			}
		} 
	}
	else
	{
		// no script result, handle error here
		NSLog(@"AppleScript failed: %@", [errorDict description]);
	}
}

-(NSString *)reportFile
{
	return reportFile;
}

-(NSMutableArray *)comparisonData
{
	return comparisonData;
}

- (IBAction)showPrefs:(id)sender
{
	[emailField setStringValue:[self recipientEmail]];
	[recipientField setStringValue:[self recipientName]];
	
	[NSApp beginSheet:configSheet 
	   modalForWindow:window 
		modalDelegate:self
	   didEndSelector:@selector(prefsSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)savePrefs:(id)sender
{
	NSString *email = [emailField stringValue];
	NSString *recipient = [recipientField stringValue];
	
	[self setRecipientEmail:email];
	[self setRecipientName:recipient];
	
	NSDictionary *prefs = [NSDictionary 
						   dictionaryWithObjects:[NSArray 
												  arrayWithObjects:email, recipient, nil] 
						   forKeys:[NSArray arrayWithObjects:@"email", @"recipient", nil]];
	NSBundle *mb = [NSBundle mainBundle];
	NSString *prefPath = [[mb resourcePath] stringByAppendingPathComponent:@"prefs.plist"];
	
	[prefs writeToFile:prefPath atomically:YES];
	
	[configSheet orderOut:sender];
	[NSApp endSheet:configSheet returnCode:1];
	
}

- (IBAction)build_report:(id)sender
{
	NSString *path = [NSString stringWithFormat:@"%@/%@.spx.gz", NSTemporaryDirectory(), hostName];
	
	[self setReportFile:path];
	
	NSArray *args = [NSArray arrayWithObjects:
					 @"-c", [NSString stringWithFormat:
							 @"/usr/sbin/system_profiler -xml -detailLevel full | /usr/bin/gzip > %@", 
							 path],
					 nil];
	
	NSTask *t = [NSTask launchedTaskWithLaunchPath:@"/bin/bash" arguments:args];
	[progress startAnimation:sender];
	
	[NSApp beginSheet:sheet 
	   modalForWindow:window 
		modalDelegate:self 
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	
	[t waitUntilExit];
	[sheet orderOut:sender];
	[NSApp endSheet:sheet];
	
	[self sendmail];
	
}

-(void) awakeFromNib
{
	[window center];
}

-(void) openPanelDidEnd:(NSOpenPanel *) openPanel returnCode:(int)returnCode contextInfo:(void *)x
{
	NSString *path;
	path = [openPanel filename];
	
	NSMutableArray *outData = [NSMutableArray arrayWithCapacity:100];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDirectoryEnumerator *dirEnum = [fm enumeratorAtPath:path];
	NSString *file;
	
	while (file = [dirEnum nextObject])
	{
		if ([[file pathExtension] isEqualToString:@"gz"])
		{
			NSMutableDictionary *spec = [NSMutableDictionary dictionaryWithCapacity:100];
			
			// uncompress and read plist
			NSTask *t = [[[NSTask alloc] init] autorelease];
			NSPipe *p = [[[NSPipe alloc] init] autorelease];
			NSFileHandle *rh = [p fileHandleForReading];
			
			[t setLaunchPath:@"/usr/bin/gzcat"];
			[t setArguments:[NSArray arrayWithObject:[path stringByAppendingPathComponent:file]]];
			[t setStandardOutput:p];
			[t launch];
			
			NSData *inData = nil;
			NSMutableData *totalData = [[[NSMutableData alloc] init] autorelease];
			
			while ((inData = [rh availableData]) && [inData length]) {
				[totalData appendData:inData];
			}
			
			[t waitUntilExit];
			NSString *plistError = nil;
			NSPropertyListSerialization *profile = [NSPropertyListSerialization 
													propertyListFromData:totalData mutabilityOption:0
													format:NULL 
													errorDescription:&plistError];
			
			// Interesting stuff in SPHardwareDataType:
			// serial_number, physical_memory, machine_model, bus_speed, current_processor_speed, cpu_type, l2_cache
			NSUInteger i, count = [profile count];
			for (i = 0; i < count; i++)
			{
				NSDictionary *obj = [profile objectAtIndex:i];
				if ([[obj valueForKey:@"_dataType"] isEqualToString:@"SPHardwareDataType"])
				{
					NSArray *items = [obj objectForKey:@"_items"];
					NSUInteger i, count = [items count];
					for (i = 0; i < count; i++)
					{
						NSDictionary *obj = [items objectAtIndex:i];
						[spec setObject:[obj valueForKey:@"serial_number"] forKey:@"Serial Number"];
						[spec setObject:[obj valueForKey:@"physical_memory"] forKey:@"RAM"];
						[spec setObject:[obj valueForKey:@"machine_model"] forKey:@"Model"];
						[spec setObject:[obj valueForKey:@"bus_speed"] forKey:@"Bus Speed"];
						[spec setObject:[obj valueForKey:@"current_processor_speed"] forKey:@"CPU Speed"];
						[spec setObject:[obj valueForKey:@"cpu_type"] forKey:@"CPU Type"];
						[spec setObject:[obj valueForKey:@"l2_cache"] forKey:@"CPU Cache"];
					}
				}
				
				// Interesting stuff in SPNetworkDataType:
				// Ethernet/MAC Address
				/*
				if ([[obj valueForKey:@"_dataType"] isEqualToString:@"SPNetworkDataType"])
				{
					NSArray *items = [obj objectForKey:@"_items"];
					NSUInteger i, count = [items count];
					for (i = 0; i < count; i++) {
						NSDictionary *obj = [items objectAtIndex:i];
						[spec setObject:[obj valueForKey:@"serial_number"] forKey:@"Serial Number"];
						[spec setObject:[obj valueForKey:@"physical_memory"] forKey:@"RAM"];
						[spec setObject:[obj valueForKey:@"machine_model"] forKey:@"Model"];
						[spec setObject:[obj valueForKey:@"bus_speed"] forKey:@"Bus Speed"];
						[spec setObject:[obj valueForKey:@"current_processor_speed"] forKey:@"CPU Speed"];
						[spec setObject:[obj valueForKey:@"cpu_type"] forKey:@"CPU Type"];
						[spec setObject:[obj valueForKey:@"l2_cache"] forKey:@"CPU Cache"];
					}
				}
				*/
				
				// Interesting stuff in SPSoftwareDataType:
				// 64bit_kernel_and_kexts, os_version, user_name, uptime
				if ([[obj valueForKey:@"_dataType"] isEqualToString:@"SPSoftwareDataType"])
				{
					NSArray *items = [obj objectForKey:@"_items"];
					NSUInteger i, count = [items count];
					for (i = 0; i < count; i++) {
						NSDictionary *obj = [items objectAtIndex:i];
						[spec setObject:[obj valueForKey:@"64bit_kernel_and_kexts"] forKey:@"64bit kernel"];
						[spec setObject:[obj valueForKey:@"os_version"] forKey:@"OS Version"];
						[spec setObject:[obj valueForKey:@"user_name"] forKey:@"Current User"];
						[spec setObject:[obj valueForKey:@"uptime"] forKey:@"Uptime"];
					}
				}
				
			}
			
			[outData addObject:[NSDictionary dictionaryWithDictionary:spec]];
			
		}
		
	}
	
	[self setComparisonData:outData];
	[resultsTable setDataSource:self];
	[fm release];
	
	md = [NSApp beginModalSessionForWindow:resultsWindow];
	
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self comparisonData] count];
}

- (IBAction)export_results:(id)sender
{	
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setCanCreateDirectories:YES];
	NSString *fileName = [NSString stringWithFormat:@"%@.csv", @"Audit Results"];
	[panel setNameFieldStringValue:fileName];
	[panel beginSheetForDirectory:nil
							 file:fileName
				   modalForWindow:resultsWindow
					modalDelegate:self didEndSelector:@selector(saveResultsPanelDidEnd:returnCode:contextInfo:)
					  contextInfo:NULL];
	
}

-(id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	NSDictionary *dataRecord = [[self comparisonData] objectAtIndex:rowIndex];
	return [dataRecord objectForKey:[tableColumn identifier]];
}
		 
- (IBAction)compare_results:(id)sender
{	
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:NO];
	[panel setCanChooseDirectories:YES];
	
	[panel beginSheetForDirectory:nil
							 file:nil modalForWindow:window
					modalDelegate:self
				   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
					  contextInfo:NULL];	
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{	
	NSBundle *mb = [NSBundle mainBundle];
	NSString *prefPath = [[mb resourcePath] stringByAppendingPathComponent:@"prefs.plist"];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	if (![fm fileExistsAtPath:prefPath]) {
		[NSApp beginSheet:configSheet 
		   modalForWindow:window 
			modalDelegate:self
		   didEndSelector:@selector(prefsSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	} else {
		NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefPath];
		[self setRecipientName:[prefs valueForKey:@"recipient"]];
		[self setRecipientEmail:[prefs valueForKey:@"email"]];
	}
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	NSProcessInfo *pi = [NSProcessInfo processInfo];
	hostName = [pi hostName];
	
	supportedMailers = [NSArray arrayWithObjects:@"com.apple.mail", @"com.microsoft.entourage", nil];
	
	NSArray *dataTypes = [NSArray arrayWithObjects:@"SPHardwareDataType", @"SPNetworkDataType",
						  @"SPSoftwareDataType", @"SPAudioDataType", @"SPBluetoothDataType",
						  @"SPDiagnosticsDataType", @"SPEthernetDataType", @"SPFireWireDataType",
						  @"SPDisplaysDataType", @"SPPrintersDataType", @"SPSerialATADataType",
						  @"SPUSBDataType", @"SPAirPortDataType", @"SPFirewallDataType",
						  @"SPNetworkLocationDataType", @"SPNetworkVolumeDataType",
						  @"SPApplicationsDataType", @"SPExtensionsDataType", nil];
	
	id helper;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    [defaults addSuiteNamed:@"com.apple.launchservices"];
    NSArray *helpers = [defaults objectForKey:@"LSHandlers"];
    NSEnumerator *helperEnum = [helpers objectEnumerator];
    mailer = [[[NSString alloc] init] autorelease];
	
    while (helper = [helperEnum nextObject]){
		NSString *key = [helper valueForKey:@"LSHandlerURLScheme"];
		if ([key isEqualToString:@"mailto"]) {
			mailer = [helper valueForKey:@"LSHandlerRoleAll"];
		}
    }
		
	// Run a minimal system profile to get some basic info...
	NSTask *t = [[[NSTask alloc] init] autorelease];
	NSArray *args = [NSArray arrayWithObjects:@"SPHardwareDataType", @"-xml", @"-detailLevel", @"full", nil];
	NSPipe *p = [[[NSPipe alloc] init] autorelease];
	
	[t setLaunchPath:@"/usr/sbin/system_profiler"];
	[t setStandardOutput:p];
	[t setArguments:args];
	[t launch];
	
	NSData *inData = nil;
	NSFileHandle *rh = [p fileHandleForReading];
	NSMutableData *totalData = [[[NSMutableData alloc] init] autorelease];
	
	while ((inData = [rh availableData]) && [inData length]) {
		[totalData appendData:inData];
	}
	
	[t waitUntilExit];
	NSString *plistError = nil;
	NSPropertyListSerialization *profile = [NSPropertyListSerialization 
											propertyListFromData:totalData
											mutabilityOption:0
											format:NULL 
											errorDescription:&plistError];
	
	NSArray *info = [profile lastObject];
	NSDictionary *items = [[info objectForKey:@"_items"] firstObject];
	
	[label_ram setStringValue:[items valueForKey:@"physical_memory"]];
	[label_machine setStringValue:[items valueForKey:@"machine_name"]];
	[label_serial setStringValue:[items valueForKey:@"serial_number"]];
	[label_os setStringValue:[pi operatingSystemVersionString]];
	
}

-(void) setReportFile:(NSString *)aFile
{
	aFile = [aFile copy];
	[reportFile release];
	reportFile = aFile;
}

-(void) setComparisonData:(NSMutableArray *)someData
{
	someData = [someData copy];
	[comparisonData release];
	comparisonData = someData;
}
		
@end
