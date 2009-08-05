/*	
	JAMultiTypeSavePanelController.h
	
	Wrapper for NSSavePanel with a user-selectable list of file types.
	
	
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

#import <Cocoa/Cocoa.h>


@interface JAMultiTypeSavePanelController: NSObject
{
@private
	NSView						*_accessoryView;
	NSPopUpButton				*_formatPopUp;
	NSArray						*_supportedUTIs;
	NSString					*_selectedUTI;
	NSString					*_autoSaveSelectedUTIKey;
	NSSavePanel					*_savePanel;
	id							_modalDelegate;
	SEL							_selector;
	BOOL						_sortTypesByName;
	BOOL						_running;
	BOOL						_createdPanel;
}

+ (id) controllerWithSupportedUTIs:(NSArray *)supportedUTIs;
- (id) initWithSupportedUTIs:(NSArray *)supportedUTIs;

@property (copy, readonly, nonatomic) NSArray *supportedUTIs;

@property (copy, nonatomic) NSString *selectedUTI;
@property (copy, nonatomic) NSString *autoSaveSelectedUTIKey;

@property BOOL sortTypesByName;	// Sort by name (default); if set to false, types are displayed in order of supportedUTIs array. Must be set before running panel.

@property (retain, nonatomic) NSSavePanel *savePanel;	// Optionally, specify a customized NSSavePanel (for example, if you want to set a prompt). Note that any accessory view will be replaced. If not set, savePanel will be valid in the modal delegate or after calling runModal[ForDirectory:].


/*	Exactly like the NSSavePanel equivalent, except that the didEndSelector's signature should match:
	- (void)savePanelDidEnd:(JAMultiTypeSavePanelController *)sheetController returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
*/
- (void)beginSheetForDirectory:(NSString *)path
						  file:(NSString *)name
				modalForWindow:(NSWindow *)docWindow
				 modalDelegate:(id)delegate
				didEndSelector:(SEL)didEndSelector
				   contextInfo:(void *)contextInfo;

/*	Simplified version of the above; directory path and contextInfo are nil.
*/
- (void)beginForFile:(NSString *)name
	  modalForWindow:(NSWindow *)docWindow
	   modalDelegate:(id)delegate
	  didEndSelector:(SEL)didEndSelector;

- (NSInteger)runModalForDirectory:(NSString *)path file:(NSString *)name;
- (NSInteger)runModal;

@end
