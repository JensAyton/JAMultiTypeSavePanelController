#import <Cocoa/Cocoa.h>

@class JAMultiTypeSavePanelController;

@interface TestController: NSObject
{
	IBOutlet NSWindow *window;
	IBOutlet NSTextView *textView;
	
	JAMultiTypeSavePanelController *saveController;
}

- (IBAction) save:(id)sender;
- (IBAction) saveUsingBlock:(id)sender;

@end
