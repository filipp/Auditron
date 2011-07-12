//
//  AuditronAppDelegate.h
//  Auditron
//
//  Created by Filipp Lepalaan on 9.7.2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AuditronAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	IBOutlet NSWindow *sheet;
	IBOutlet NSWindow *resultsWindow;
	IBOutlet NSTableView *resultsTable;
	
	IBOutlet NSProgressIndicator *progress;
	
	IBOutlet NSTextField *label_os;
	IBOutlet NSTextField *label_ram;
	IBOutlet NSTextField *label_serial;
	IBOutlet NSTextField *label_machine;
	
	IBOutlet id *myButton;
	IBOutlet id *mainView;
	
	IBOutlet id *mySpinner;
	NSString *tempDir;
	NSString *reportFile;
	
	NSString *mailer;
	NSString *hostName;
	NSArray *supportedMailers;
	
	NSMutableArray *comparisonData;
	NSModalSession md;
	
}

@property (assign) IBOutlet NSWindow *window;

-(IBAction)compare_results:(id)sender;
-(IBAction)build_report:(id)sender;
-(void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
-(NSString *) reportFile;
-(NSMutableArray *) comparisonData;
-(void) setReportFile:(NSString *)aFile;
-(void) setComparisonData:(NSMutableArray *)newData;

@end
