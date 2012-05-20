/*	
	JAMultiTypeSavePanelController.m
	
	
	© 2009–2011 Jens Ayton
	© 2011-2012 Jan Weiß
	
	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the “Software”),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
*/

#import "JAMultiTypeSavePanelController.h"
#import <objc/message.h>

#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
#if NS_BLOCKS_AVAILABLE
#define USE_BLOCKY_APIS 1
#endif
#endif


@interface JAMultiTypeSavePanelController ()

@property (copy, readwrite, nonatomic) NSArray *supportedUTIs;

- (void) prepareToRun;
- (void) cleanUp;

- (void) buildMenu;
- (BOOL) selectUTI:(NSString *)uti;
- (void) menuItemSelected:(NSMenuItem *)item;
- (void) updateSavePanelFileTypes;

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

@end


static NSInteger CompareMenuItems(id a, id b, void *context);
static NSArray *AllowedExtensionsForUTI(NSString *uti);


@implementation JAMultiTypeSavePanelController

@synthesize supportedUTIs = _supportedUTIs;
@synthesize enabledUTIs = _enabledUTIs;
@synthesize sortTypesByName = _sortTypesByName;

@synthesize accessoryView = _accessoryView;
@synthesize formatPopUp = _formatPopUp;


+ (id) controllerWithSupportedUTIs:(NSArray *)supportedUTIs
{
	return [[[self alloc] initWithSupportedUTIs:supportedUTIs] autorelease];
}


- (id) initWithSupportedUTIs:(NSArray *)supportedUTIs
{
	if ([supportedUTIs count] == 0)
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		self.supportedUTIs = supportedUTIs;
		self.enabledUTIs = nil;
		self.sortTypesByName = YES;
	}
	
	return self;
}


- (void) dealloc
{
	[_accessoryView release];
	_accessoryView = nil;
	_formatPopUp = nil;
	
	self.selectedUTI = nil;
	self.enabledUTIs = nil;
	self.autoSaveSelectedUTIKey = nil;
	self.savePanel = nil;
	
	[super dealloc];
}


- (NSString *) selectedUTI
{
	return [[_selectedUTI retain] autorelease];
}


- (void) setSelectedUTI:(NSString *)uti
{
	if (uti != nil && ![uti isEqualToString:_selectedUTI] && [self.supportedUTIs containsObject:uti])
	{
		[_selectedUTI autorelease];
		_selectedUTI = [uti copy];
		
		[self selectUTI:uti];
		[self updateSavePanelFileTypes];
	}
}


- (NSString *) autoSaveSelectedUTIKey
{
	return [[_autoSaveSelectedUTIKey retain] autorelease];
}


- (void) setAutoSaveSelectedUTIKey:(NSString *)key
{
	if (![key isEqualToString:_autoSaveSelectedUTIKey])
	{
		[_autoSaveSelectedUTIKey release];
		_autoSaveSelectedUTIKey = [key copy];
		
		if (key != nil)
		{
			NSString *selected = [[NSUserDefaults standardUserDefaults] stringForKey:key];
			if (selected != nil)
			{
				self.selectedUTI = selected;
			}
		}
	}
}


- (NSSavePanel *) savePanel
{
	return _savePanel;
}


- (void) setSavePanel:(NSSavePanel *)panel
{
	NSAssert(!_prepared, @"Can't set savePanel of JAMultiTypeSavePanelController after save panel has been prepared.");
	
	if (panel != _savePanel)
	{
		[_savePanel autorelease];
		_savePanel = [panel retain];
		_createdPanel = NO;
	}
}


- (void) beginSheetForDirectory:(NSString *)path
						   file:(NSString *)fileName
				 modalForWindow:(NSWindow *)docWindow
				  modalDelegate:(id)delegate
				 didEndSelector:(SEL)didEndSelector
					contextInfo:(void *)contextInfo
{
	[self retain];		// Balanced in savePanelDidEnd:returnCode:contextInfo:

	_modalDelegate = [delegate retain];
	_selector = didEndSelector;

#if USE_BLOCKY_APIS
	NSSavePanel *panel = self.savePanel;

	NSURL *directoryURL = (path != nil) ? [NSURL fileURLWithPath:path] : nil;

	[self beginSheetForDirectoryURL:directoryURL
							   file:fileName
					 modalForWindow:docWindow
				  completionHandler:^(NSInteger result)
	 {
		 [self savePanelDidEnd:panel returnCode:result contextInfo:contextInfo];
	 }];
#else
	[self prepareToRun];
	
	[self.savePanel beginSheetForDirectory:path
									  file:fileName
						    modalForWindow:docWindow
							 modalDelegate:self
							didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
							   contextInfo:contextInfo];
#endif
}


- (void) beginForFile:(NSString *)fileName
	   modalForWindow:(NSWindow *)docWindow
		modalDelegate:(id)delegate
	   didEndSelector:(SEL)didEndSelector
{
	[self beginSheetForDirectory:nil
							file:fileName
				  modalForWindow:docWindow
				   modalDelegate:delegate
				  didEndSelector:didEndSelector
					 contextInfo:nil];
}


- (NSInteger) runModalForDirectory:(NSString *)path file:(NSString *)fileName
{
	[self prepareToRun];
	NSInteger result;
	
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
	NSSavePanel *panel = self.savePanel;
	if (path != nil)  panel.directoryURL = [NSURL fileURLWithPath:path];
	else  panel.directoryURL = nil;
	panel.nameFieldStringValue = fileName;
	
	result = [panel runModal];
#else
	result = [self.savePanel runModalForDirectory:path file:fileName];
#endif
	
	[self cleanUp];
	return result;
}


- (NSInteger) runModal
{
	return [self runModalForDirectory:nil file:@""];
}


#if NS_BLOCKS_AVAILABLE
- (void) beginSheetForDirectoryURL:(NSURL *)directoryURL
							  file:(NSString *)fileName
					modalForWindow:(NSWindow *)window
				 completionHandler:(void (^)(NSInteger result))handler
{
	NSAssert(!_prepared, @"Can't begin another savePanel of JAMultiTypeSavePanelController while the previous savePanel is still being used.");

	[self prepareToRun];
	
	if (directoryURL != nil)
	{
		// Check if directoryURL is available and a directory.
		NSNumber *isDirectoryValue = nil;
		if ([directoryURL isFileURL]
			&& [directoryURL checkResourceIsReachableAndReturnError:NULL] 
			&& [directoryURL getResourceValue:&isDirectoryValue forKey:NSURLIsDirectoryKey error:NULL] 
			&& ([isDirectoryValue boolValue]) )
		{
			[self.savePanel setDirectoryURL:directoryURL];
		}
	}
	
	[self beginSheetForFileName:fileName
				 modalForWindow:(NSWindow *)window
			  completionHandler:handler];
}

- (void) beginSheetForFileName:(NSString *)fileName
				modalForWindow:(NSWindow *)window
			 completionHandler:(void (^)(NSInteger result))handler
{
	if (_prepared == NO) [self prepareToRun];

	if (fileName != nil)
	{
		[self.savePanel setNameFieldStringValue:fileName];
	}
	
	[self beginSheetModalForWindow:window
				 completionHandler:handler];
}


- (void) beginSheetModalForWindow:(NSWindow *)window
			    completionHandler:(void (^)(NSInteger result))handler
{
	if (_prepared == NO) [self prepareToRun];

	_running = YES;
	[self.savePanel beginSheetModalForWindow:window
						   completionHandler:^(NSInteger result)
	{
		handler(result);
		
		[self cleanUp];
	}];
}
#endif


- (void) prepareToRun
{
	if (_savePanel == nil)
	{
		_savePanel = [[NSSavePanel savePanel] retain];
		_savePanel.canSelectHiddenExtension = YES;
		_createdPanel = YES;
	}
	
	[NSBundle loadNibNamed:@"JAMultiTypeSavePanelController" owner:self];
	[self buildMenu];
	
	self.savePanel.accessoryView = self.accessoryView;
	[self updateSavePanelFileTypes];
	
	_prepared = YES;
}


- (void) buildMenu
{
	// Build list of menu items for UTIs.
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSMutableArray *menuItems = [NSMutableArray arrayWithCapacity:self.supportedUTIs.count];
	for (NSString *uti in self.supportedUTIs)
	{
		NSString *name = [workspace localizedDescriptionForType:uti];
		if (name.length > 1)
		{
			name = [[[name substringToIndex:1] capitalizedString] stringByAppendingString:[name substringFromIndex:1]];
		}
		else if (name == nil)
		{
			name = [workspace preferredFilenameExtensionForType:uti];
			if (name != nil)  name = [@"." stringByAppendingString:name];
			else  name = uti;
		}
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:name
													  action:@selector(menuItemSelected:)
											   keyEquivalent:@""];
		item.target = self;
		item.representedObject = uti;
		
		[menuItems addObject:item];
		[item release];
	}
	
	// Sort if required.
	if (self.sortTypesByName)
	{
		[menuItems sortUsingFunction:CompareMenuItems context:NULL];
	}
	
	// Build menu.
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Types"];	// Name is not user-visible.
	for (NSMenuItem *item in menuItems)
	{
		[menu addItem:item];
	}

	NSInteger firstEnabledItem = 0;

	if (_enabledUTIs != nil) {
		[menu setAutoenablesItems:NO];
		
		firstEnabledItem = -1;

		NSInteger count = [menu numberOfItems];
		NSMenuItem *item;
		
		for (int i = 0; i < count; i++) {
			item = [menu itemAtIndex:i];
			
			if (![_enabledUTIs member:item.representedObject])
			{
				[item setEnabled:NO];
			}
			else
			{
				if (firstEnabledItem == -1) firstEnabledItem = i;
			}
		}
	}
	else
	{
		[menu setAutoenablesItems:YES];
	}
	
	self.formatPopUp.menu = menu;
	
	if ( !(self.selectedUTI != nil && [self selectUTI:self.selectedUTI]) )
	{
		self.selectedUTI = [[menu itemAtIndex:firstEnabledItem] representedObject];
		[self selectUTI:self.selectedUTI];
	}
	
	[menu release];
}


- (void) cleanUp
{
	_running = NO;

	self.savePanel.accessoryView = nil;
	
	if (self.autoSaveSelectedUTIKey != nil)
	{
		[[NSUserDefaults standardUserDefaults] setObject:self.selectedUTI forKey:self.autoSaveSelectedUTIKey];
	}

	_prepared = NO;
}


- (BOOL) selectUTI:(NSString *)uti
{
	if (self.formatPopUp != nil)
	{
		NSMenu *menu = self.formatPopUp.menu;
		NSInteger index = [menu indexOfItemWithRepresentedObject:uti];
		NSMenuItem *item = [menu itemAtIndex:index];
		if ((index != NSNotFound) && [item isEnabled])
		{
			[self.formatPopUp selectItemAtIndex:index];
			return YES;
		}
		else
		{
			return NO;
		}
	}
	else
	{
		return NO;
	}
}


- (void) menuItemSelected:(NSMenuItem *)item
{
	self.selectedUTI = item.representedObject;
}


- (void) updateSavePanelFileTypes
{
	if (self.savePanel != nil)
	{
		self.savePanel.allowedFileTypes = AllowedExtensionsForUTI(self.selectedUTI);
	}
}


- (void) savePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (_modalDelegate != nil && _selector != NULL)
	{
		typedef void (*DelegateSend)(id, SEL, JAMultiTypeSavePanelController *, NSInteger, void *);
		DelegateSend send = (DelegateSend)objc_msgSend;
		send(_modalDelegate, _selector, self, returnCode, contextInfo);
	}
	
	[_modalDelegate release];
	_modalDelegate = nil;
	_selector = NULL;
	
	[self cleanUp];
	
	[self release];		// Balanced in beginSheetForDirectory:file:modalForWindow:modalDelegate:didEndSelector:contextInfo:
}

@end


static NSInteger CompareMenuItems(id a, id b, void *context)
{
#pragma unused (context)
	return [[a title] caseInsensitiveCompare:[b title]];
}


/*	Get list of file name extensions relevant to a given file type.
	
	This is recursive (breadth-first), so that, for instance, it would allow
	an HTML file to be saved as foo.txt if you really wanted it to.
*/
static NSArray *AllowedExtensionsForUTI(NSString *uti)
{
	if (uti == nil)  return nil;
	
	NSMutableArray *result = [NSMutableArray array];
	NSMutableArray *queue = [NSMutableArray arrayWithObject:uti];	// Queue of types to process.
	NSMutableSet *seenUTIs = [NSMutableSet set];					// Used to avoid handling a type more than once.
	
	while (queue.count != 0)
	{
		NSString *thisUTI = [queue objectAtIndex:0];
		[queue removeObjectAtIndex:0];
		if ([seenUTIs containsObject:thisUTI])  continue;
		[seenUTIs addObject:thisUTI];
		
		// Add UTIs this UTI conforms to to the queue.
		NSDictionary *thisUTIDecl = [NSMakeCollectable(UTTypeCopyDeclaration((CFStringRef)thisUTI)) autorelease];
		id thisConformsTo = [thisUTIDecl objectForKey:(NSString *)kUTTypeConformsToKey];
		// Conforms to may be an array or a single string.
		if ([thisConformsTo isKindOfClass:[NSString class]])  [queue addObject:thisConformsTo];
		else if ([thisConformsTo isKindOfClass:[NSArray class]])  [queue addObjectsFromArray:thisConformsTo];
		
		// Add extensions for this UTI to the result.
		NSDictionary *thisTypeTagSpec = [thisUTIDecl objectForKey:(NSString *)kUTTypeTagSpecificationKey];
		if ([thisTypeTagSpec isKindOfClass:[NSDictionary class]])
		{
			id thisExtensions = [thisTypeTagSpec objectForKey:(NSString *)kUTTagClassFilenameExtension];
			// Extensions may be an array or a single string.
			if ([thisExtensions isKindOfClass:[NSString class]])  [result addObject:thisExtensions];
			else if ([thisExtensions isKindOfClass:[NSArray class]])  [result addObjectsFromArray:thisExtensions];
		}
	}
	
	if (result.count == 0)  result = nil;
	return result;
}
