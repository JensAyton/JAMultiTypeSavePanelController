#import "TestController.h"
#import "JAMultiTypeSavePanelController.h"


NSString * const	Word97Type									= @"com.microsoft.word.doc";
NSString * const	Word2003XMLType								= @"com.microsoft.word.wordml";
NSString * const	Word2007Type								= @"org.openxmlformats.wordprocessingml.document";
NSString * const	OpenDocumentTextType						= @"org.oasis-open.opendocument.text";


static NSDictionary *sTypes = nil;

void populateSTypes() {
	// Unfortunately, NSAttributedString will only give you types that are not UTIs and specify readable rather than writeable types, so we need to do this manually.
	if (sTypes == nil)
	{
		sTypes = [NSDictionary dictionaryWithObjectsAndKeys:
				  NSPlainTextDocumentType, kUTTypePlainText,
				  NSRTFTextDocumentType, (NSString *)kUTTypeRTF,
				  NSRTFDTextDocumentType, (NSString *)kUTTypeRTFD,
				  NSWebArchiveTextDocumentType, (NSString *)kUTTypeWebArchive,
				  NSHTMLTextDocumentType, (NSString *)kUTTypeHTML,
				  NSDocFormatTextDocumentType, Word97Type,
				  NSWordMLTextDocumentType, Word2003XMLType,
				  NSOfficeOpenXMLTextDocumentType, Word2007Type,
				  NSOpenDocumentTextDocumentType, OpenDocumentTextType,
				  nil];
		[sTypes retain];
	}
}

@interface TestController ()
- (void)savePanelDidEnd:(JAMultiTypeSavePanelController *)sheetController returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end


@implementation TestController

- (void) dealloc
{
	[saveController release];
	
	[super dealloc];
}

- (void) prepareSaveController {
	populateSTypes();
	
	if (saveController == nil)  saveController = [[JAMultiTypeSavePanelController alloc] initWithSupportedUTIs:[sTypes allKeys]];
	
	saveController.autoSaveSelectedUTIKey = @"type";
	
	// Documents that contain attachments can only be saved in formats that support embedded graphics. 
	if ([textView.textStorage containsAttachments])
	{
		saveController.enabledUTIs = [NSSet setWithObjects:(NSString *)kUTTypeRTFD, (NSString *)kUTTypeWebArchive, nil];
	}
	else
	{
		saveController.enabledUTIs = nil; // Setting enabledUTIs to nil prevents it from having any effect.
	}
}

- (IBAction) save:(id)sender
{
	[self prepareSaveController];
	
	[saveController beginForFile:@"untitled"
				  modalForWindow:window
				   modalDelegate:self
				  didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)];
}

#if NS_BLOCKS_AVAILABLE
- (IBAction) saveUsingBlock:(id)sender
{
	[self prepareSaveController];
	
	[saveController beginSheetForFileName:@"untitled"
						   modalForWindow:window 
						completionHandler:^(NSInteger returnCode) {
							// Alternatively, code similar to “-savePanelDidEnd:returnCode:contextInfo:” could be included here directly
							[self savePanelDidEnd:saveController returnCode:returnCode contextInfo:NULL];
						}];
}
#else
- (IBAction) saveUsingBlock:(id)sender
{
	NSLog(@"Blocks unavailable!");
}
#endif 
	 
- (void)savePanelDidEnd:(JAMultiTypeSavePanelController *)sheetController returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	
	NSLog(@"Save panel result: %i", returnCode);
	[sheetController.savePanel orderOut:nil];
	
	if (returnCode == NSOKButton)
	{
		NSError *error = nil;
		
		NSString *documentType = [sTypes objectForKey:sheetController.selectedUTI];
		NSLog(@"Saving as %@/%@", sheetController.selectedUTI, documentType);
		
		NSTextStorage *textStorage = textView.textStorage;
		
		NSRange range = {0, textStorage.length};
		NSDictionary *attributesDict = [NSDictionary dictionaryWithObject:documentType forKey:NSDocumentTypeDocumentAttribute];
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
		NSURL *fileURL = sheetController.savePanel.URL;
#else
		NSString *path = sheetController.savePanel.filename;
#endif
		
		NSFileWrapper *wrapper = nil;
		if (documentType == NSRTFDTextDocumentType || (documentType == NSPlainTextDocumentType))
		{
			wrapper = [textStorage fileWrapperFromRange:range documentAttributes:attributesDict error:&error];
		}
		else
		{
			NSData *data = [textStorage dataFromRange:range documentAttributes:attributesDict error:&error];
			if (data) {
				wrapper = [[[NSFileWrapper alloc] initRegularFileWithContents:data] autorelease];
				if (!wrapper && &error) error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
			}
		}
		
		BOOL OK = (wrapper != nil);
		
		if (OK)
		{
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
			OK = [wrapper writeToURL:fileURL 
							 options:(NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating) 
				 originalContentsURL:nil 
							   error:&error];
#else
			OK = [wrapper writeToFile:path atomically:YES updateFilenames:YES];
#endif
		}
		
		if (!OK)
		{
			[[NSAlert alertWithError:error] beginSheetModalForWindow:window
													   modalDelegate:nil
													  didEndSelector:NULL
														 contextInfo:nil];
		}
		
	}
}

@end
