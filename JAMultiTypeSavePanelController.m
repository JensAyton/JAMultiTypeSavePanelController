/*	
	JAMultiTypeSavePanelController.m
	
	
	© 2009 Jens Ayton
	
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


@interface JAMultiTypeSavePanelController ()

@property (copy, readwrite, nonatomic) NSArray *supportedUTIs;

@property (assign, nonatomic) IBOutlet NSView *accessoryView;
@property (assign, nonatomic) IBOutlet NSPopUpButton *formatPopUp;

- (void) prepareToRun;
- (void) cleanUp;

- (void) buildMenu;
- (void) selectUTI:(NSString *)uti;
- (void) updateSavePanelFileTypes;

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

@end


static NSInteger CompareMenuItems(id a, id b, void *context);
static NSArray *AllowedExtensionsForUTI(NSString *uti);


@implementation JAMultiTypeSavePanelController

@synthesize supportedUTIs = _supportedUTIs;
@synthesize sortTypesByName = _sortTypesByName;
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
	self.autoSaveSelectedUTIKey = nil;
	self.savePanel = nil;
	
	[super dealloc];
}


- (NSString *) selectedUTI
{
	return _selectedUTI;
}


- (void) setSelectedUTI:(NSString *)uti
{
	if (uti != nil && ![uti isEqualToString:_selectedUTI] && [self.supportedUTIs containsObject:uti])
	{
		[_selectedUTI autorelease];
		_selectedUTI = [uti retain];
		
		[self selectUTI:uti];
		[self updateSavePanelFileTypes];
	}
}


- (NSString *) autoSaveSelectedUTIKey
{
	return _autoSaveSelectedUTIKey;
}


- (void) setAutoSaveSelectedUTIKey:(NSString *)key
{
	if (![key isEqualToString:_autoSaveSelectedUTIKey])
	{
		[_autoSaveSelectedUTIKey release];
		_autoSaveSelectedUTIKey = [key retain];
		
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
	NSAssert(!_running, @"Can't set savePanel of JAMultiTypeSavePanelController while save panel is running.");
	
	if (panel != _savePanel)
	{
		[_savePanel autorelease];
		_savePanel = [panel retain];
	}
}


- (void)beginSheetForDirectory:(NSString *)path
						  file:(NSString *)name
				modalForWindow:(NSWindow *)docWindow
				 modalDelegate:(id)delegate
				didEndSelector:(SEL)didEndSelector
				   contextInfo:(void *)contextInfo
{
	[self prepareToRun];
	[self retain];		// Balanced in savePanelDidEnd:returnCode:contextInfo:
	_modalDelegate = [delegate retain];
	_selector = didEndSelector;
	
	[self.savePanel beginSheetForDirectory:path
									  file:name
						    modalForWindow:docWindow
							 modalDelegate:self
							didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
							   contextInfo:contextInfo];
}


- (void)beginForFile:(NSString *)name
	  modalForWindow:(NSWindow *)docWindow
	   modalDelegate:(id)delegate
	  didEndSelector:(SEL)didEndSelector
{
	[self beginSheetForDirectory:nil
							file:name
				  modalForWindow:docWindow
				   modalDelegate:delegate
				  didEndSelector:didEndSelector
					 contextInfo:nil];
}


- (NSInteger)runModalForDirectory:(NSString *)path file:(NSString *)name
{
	[self prepareToRun];
	NSInteger result = [self.savePanel runModalForDirectory:path file:name];
	[self cleanUp];
	return result;
}


- (NSInteger)runModal
{
	return [self runModalForDirectory:nil file:@""];
}


- (void) prepareToRun
{
	if (self.savePanel == nil)
	{
		self.savePanel = [NSSavePanel savePanel];
		self.savePanel.canSelectHiddenExtension = YES;
		_createdPanel = YES;
	}
	
	[NSBundle loadNibNamed:@"JAMultiTypeSavePanelController" owner:self];
	[self buildMenu];
	
	self.savePanel.accessoryView = self.accessoryView;
	[self updateSavePanelFileTypes];
	
	_running = YES;
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
	
	self.formatPopUp.menu = menu;
	
	if (self.selectedUTI != nil)  [self selectUTI:self.selectedUTI];
	else  self.selectedUTI = [[menu itemAtIndex:0] representedObject];
	
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
}


- (void) selectUTI:(NSString *)uti
{
	if (self.formatPopUp != nil)
	{
		NSInteger index = [self.formatPopUp indexOfItemWithRepresentedObject:uti];
		if (index != NSNotFound)
		{
			[self.formatPopUp selectItemAtIndex:index];
		}
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


- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
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
	
	if (_createdPanel)
	{
		self.savePanel = nil;
		_createdPanel = NO;
	}
	[self release];		// Balanced in beginSheetForDirectory:file:modalForWindow:modalDelegate:didEndSelector:contextInfo:
}

@end


static int CompareMenuItems(id a, id b, void *context)
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
		NSDictionary *thisUTIDecl = (NSDictionary *)UTTypeCopyDeclaration((CFStringRef)thisUTI);
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
