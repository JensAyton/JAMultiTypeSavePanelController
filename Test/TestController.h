#import <Cocoa/Cocoa.h>


@interface TestController: NSObject
{
	IBOutlet NSWindow *window;
	IBOutlet NSTextView *textView;
}

- (IBAction) save:(id)sender;
- (IBAction) saveUsingBlock:(id)sender;

@end
